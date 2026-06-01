import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/voice_action.dart';
import '../../services/voice_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:dio/dio.dart';

enum _Stage {
  idle,
  recording,
  processing,
  result,
  analyzing,
  actions,
  executing,
  done,
  error,
}

class VoiceCaptureScreen extends ConsumerStatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  ConsumerState<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen> {
  final _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;
  final _textController = TextEditingController();

  _Stage _stage = _Stage.idle;
  int _seconds = 0;
  Timer? _timer;
  String? _recordPath;
  String _errorMessage = '';

  List<VoiceAction> _actions = [];
  int _mood = 4;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  String _humanError(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code == 504 || code == 502 || code == 503) {
        return 'Сервер не успел обработать запись. Попробуй короче или повтори через минуту.';
      }
      if (code == 402) {
        return 'Лимит минут на сегодня исчерпан.';
      }
      if (code == 401) {
        return 'Авторизация истекла, войди заново.';
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Долго не приходит ответ. Проверь интернет или повтори.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Нет связи с сервером.';
      }
      return 'Ошибка сервера: ${code ?? "?"}';
    }
    return e.toString();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'Доступ к микрофону не разрешён';
        });
      }
      return;
    }
    await _recorder.openRecorder();
    if (mounted) setState(() => _recorderReady = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_recorderReady) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Микрофон ещё не готов';
      });
      return;
    }
    try {
      // Reset recorder state before each session
      if (_recorder.isStopped == false) {
        await _recorder.stopRecorder();
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);

      _recordPath = path;
      _seconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _seconds++);
      });

      setState(() => _stage = _Stage.recording);
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = _humanError(e);
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stopRecorder();
      debugPrint('[voice] stopRecorder returned path=$path');

      if (path == null) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'Запись не сохранилась';
        });
        return;
      }

      final file = File(path);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      debugPrint('[voice] file exists=$exists size=$size bytes');

      if (!exists || size < 1000) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage =
              'Запись получилась пустой (size=$size). Попробуй ещё раз.';
        });
        return;
      }

      setState(() => _stage = _Stage.processing);

      final result = await ref.read(voiceServiceProvider).transcribe(file);
      _textController.text = result.text;
      setState(() => _stage = _Stage.result);
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = _humanError(e);
      });
    }
  }

  // _confirmText, _executeSelected, _close, _timerText, build, _buildBody — остаются без изменений

  Future<void> _confirmText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Текст пустой';
      });
      return;
    }
    setState(() => _stage = _Stage.analyzing);

    try {
      final result = await ref.read(voiceServiceProvider).analyze(text);
      setState(() {
        _actions = result.actions.isEmpty
            ? [
                VoiceAction(
                  type: 'diary',
                  title: 'Запись в дневник',
                  description: text.length > 100
                      ? '${text.substring(0, 100)}…'
                      : text,
                  enabled: true,
                  data: text,
                ),
              ]
            : result.actions;
        _mood = result.mood;
        _stage = _Stage.actions;
      });
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Не удалось проанализировать: $e';
      });
    }
  }

  Future<void> _executeSelected() async {
    final enabled = _actions.where((a) => a.enabled).toList();
    if (enabled.isEmpty) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Выбери хотя бы одно действие';
      });
      return;
    }

    setState(() => _stage = _Stage.executing);

    try {
      String? diaryText;
      final habits = <dynamic>[];
      final goals = <dynamic>[];
      for (final a in enabled) {
        if (a.type == 'diary') diaryText = a.data as String?;
        if (a.type == 'habit') habits.add(a.data);
        if (a.type == 'goal') goals.add(a.data);
      }
      await ref
          .read(voiceServiceProvider)
          .execute(
            diaryText: diaryText,
            mood: _mood,
            habits: habits,
            goals: goals,
          );
      if (mounted) setState(() => _stage = _Stage.done);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Не удалось выполнить: $e';
      });
    }
  }

  void _close() => Navigator.of(context).pop();

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.75),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.idle:
        return _IdleView(onStart: _startRecording, onClose: _close);
      case _Stage.recording:
        return _RecordingView(timer: _timerText, onStop: _stopRecording);
      case _Stage.processing:
        return const _CenterMessage(text: 'Обрабатывается…');
      case _Stage.result:
        return _ResultView(
          controller: _textController,
          onCancel: () => setState(() => _stage = _Stage.idle),
          onConfirm: _confirmText,
        );
      case _Stage.analyzing:
        return const _CenterMessage(text: 'Анализируем…');
      case _Stage.actions:
        return _ActionsView(
          actions: _actions,
          onToggle: (index, value) {
            setState(() => _actions[index].enabled = value);
          },
          onBack: () => setState(() => _stage = _Stage.result),
          onConfirm: _executeSelected,
        );
      case _Stage.executing:
        return const _CenterMessage(text: 'Выполняем…');
      case _Stage.done:
        return const _CenterMessage(text: 'Готово ✓', accent: true);
      case _Stage.error:
        return _ErrorView(
          message: _errorMessage,
          onClose: _close,
          onRetry: () => setState(() => _stage = _Stage.idle),
        );
    }
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onClose;
  const _IdleView({required this.onStart, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CloseRow(onClose: onClose),
        const Spacer(),
        GestureDetector(
          onTap: onStart,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.2),
              border: Border.all(color: AppColors.accent, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: AppColors.accent, size: 56),
          ),
        ),
        const SizedBox(height: 16),
        Text('Нажми для записи', style: AppTextStyles.text14ExtraLight),
        const Spacer(),
      ],
    );
  }
}

class _RecordingView extends StatelessWidget {
  final String timer;
  final VoidCallback onStop;
  const _RecordingView({required this.timer, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Spacer(),
        Text(
          timer,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 64,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onStop,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.5),
                  blurRadius: 35,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Идёт запись', style: AppTextStyles.text14ExtraLight),
        const Spacer(),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _ResultView({
    required this.controller,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CloseRow(onClose: onCancel),
        const SizedBox(height: 16),
        Text('Распознанный текст', style: AppTextStyles.text16Light),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.card,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: AppTextStyles.text14ExtraLight,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GhostButton(label: 'Отменить', onTap: onCancel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(label: 'Подтвердить', onTap: onConfirm),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ActionsView extends StatelessWidget {
  final List<VoiceAction> actions;
  final void Function(int index, bool value) onToggle;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  const _ActionsView({
    required this.actions,
    required this.onToggle,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CloseRow(onClose: onBack, icon: Icons.arrow_back),
        const SizedBox(height: 16),
        Text('Предложенные действия', style: AppTextStyles.text16Light),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final a = actions[i];
              return _ActionRow(action: a, onChanged: (v) => onToggle(i, v));
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GhostButton(label: 'Назад', onTap: onBack),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryButton(label: 'Выполнить', onTap: onConfirm),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoiceAction action;
  final ValueChanged<bool> onChanged;
  const _ActionRow({required this.action, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!action.enabled),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
          border: Border.all(
            color: action.enabled
                ? AppColors.accent.withOpacity(0.6)
                : AppColors.textPrimary.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: action.enabled ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: AppColors.accent.withOpacity(
                    action.enabled ? 1.0 : 0.5,
                  ),
                  width: 1.2,
                ),
              ),
              child: action.enabled
                  ? const Icon(
                      Icons.check,
                      color: AppColors.textPrimary,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: AppTextStyles.text14ExtraLight),
                  if (action.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.description,
                      style: AppTextStyles.text14Light.copyWith(
                        color: AppColors.archivedText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final String text;
  final bool accent;
  const _CenterMessage({required this.text, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!accent) const CircularProgressIndicator(),
          if (!accent) const SizedBox(height: 16),
          Text(
            text,
            style: AppTextStyles.text16Light.copyWith(
              color: accent ? AppColors.accent : AppColors.textPrimary,
              fontSize: accent ? 24 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.message,
    required this.onClose,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CloseRow(onClose: onClose),
        const Spacer(),
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: AppTextStyles.text14ExtraLight,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          child: _PrimaryButton(label: 'Попробовать снова', onTap: onRetry),
        ),
        const Spacer(),
      ],
    );
  }
}

class _CloseRow extends StatelessWidget {
  final VoidCallback onClose;
  final IconData icon;
  const _CloseRow({required this.onClose, this.icon = Icons.close});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: Icon(icon, color: AppColors.textPrimary, size: 28),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.accent.withOpacity(0.2),
          border: Border.all(color: AppColors.accent, width: 1.2),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 18),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.text14ExtraLight.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppTextStyles.text14ExtraLight),
      ),
    );
  }
}
