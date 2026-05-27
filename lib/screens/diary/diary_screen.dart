import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/diary_entry.dart';
import '../../providers/diary_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class _Emotion {
  final int mood;
  final String emoji;
  const _Emotion(this.mood, this.emoji);
}

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final _entryController = TextEditingController();
  final _searchController = TextEditingController();
  int _activeTab = 0;
  int? _selectedMood;
  bool _isSaving = false;

  static const _emotions = [
    _Emotion(1, '😊'),
    _Emotion(2, '😢'),
    _Emotion(3, '😠'),
    _Emotion(4, '🧘'),
    _Emotion(5, '😴'),
  ];

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _entryController.text.trim();

    if (text.length < 10) {
      _showSnack('Минимальная длина записи — 10 символов');
      return;
    }
    if (_selectedMood == null) {
      _showSnack('Выберите эмоцию');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await ref
          .read(diaryProvider.notifier)
          .createEntry(text: text, mood: _selectedMood!);
      _entryController.clear();
      if (mounted) setState(() => _selectedMood = null);
    } catch (e) {
      if (mounted) _showSnack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(diaryProvider);

    return Column(
      children: [
        const _TopActions(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _NewEntryCard(
                entryController: _entryController,
                activeTab: _activeTab,
                onTabChanged: (i) => setState(() => _activeTab = i),
                emotions: _emotions,
                selectedMood: _selectedMood,
                onMoodSelected: (m) => setState(() => _selectedMood = m),
                onSave: _isSaving ? null : _save,
                isSaving: _isSaving,
              ),
              const SizedBox(height: 16),
              entriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Ошибка загрузки: $err',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return _ArchiveSection(
                      searchController: _searchController,
                      entries: const [],
                      emptyText: 'Записей пока нет',
                    );
                  }
                  return _ArchiveSection(
                    searchController: _searchController,
                    entries: entries,
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: AppColors.textPrimary,
              size: 28,
            ),
            onPressed: () {},
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.help_outline,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassFrame({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.accent, AppColors.borderBlue],
            ),
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.85),
              borderRadius: BorderRadius.circular(27),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NewEntryCard extends StatelessWidget {
  final TextEditingController entryController;
  final int activeTab;
  final ValueChanged<int> onTabChanged;
  final List<_Emotion> emotions;
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;
  final VoidCallback? onSave;
  final bool isSaving;

  const _NewEntryCard({
    required this.entryController,
    required this.activeTab,
    required this.onTabChanged,
    required this.emotions,
    required this.selectedMood,
    required this.onMoodSelected,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassFrame(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TabsHeader(
            tabs: const ['Дневниковая запись', 'Быстрое заполнение'],
            activeIndex: activeTab,
            onChanged: onTabChanged,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: entryController,
            maxLines: 5,
            style: AppTextStyles.text14ExtraLight,
            decoration: InputDecoration(
              hintText: 'Расскажи, что произошло сегодня',
              hintStyle: AppTextStyles.text14ExtraLight.copyWith(
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _EmotionPicker(
                  emotions: emotions,
                  selectedMood: selectedMood,
                  onSelected: onMoodSelected,
                ),
              ),
              const SizedBox(width: 12),
              _SaveButton(onTap: onSave, isLoading: isSaving),
            ],
          ),
          const SizedBox(height: 14),
          _VoiceField(onTap: () {}),
        ],
      ),
    );
  }
}

class _TabsHeader extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  const _TabsHeader({
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          GestureDetector(
            onTap: () => onChanged(i),
            child: Text(
              tabs[i],
              style: AppTextStyles.text14ExtraLight.copyWith(
                color: i == activeIndex
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withOpacity(0.5),
              ),
            ),
          ),
          if (i != tabs.length - 1)
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: AppColors.accent.withOpacity(0.6),
            ),
        ],
      ],
    );
  }
}

class _EmotionPicker extends StatelessWidget {
  final List<_Emotion> emotions;
  final int? selectedMood;
  final ValueChanged<int> onSelected;

  const _EmotionPicker({
    required this.emotions,
    required this.selectedMood,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: emotions.map((e) {
        final isActive = e.mood == selectedMood;
        return GestureDetector(
          onTap: () => onSelected(e.mood),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(isActive ? 0.25 : 0.12),
              border: Border.all(
                color: AppColors.accent.withOpacity(isActive ? 0.9 : 0.0),
                width: 1.2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(e.emoji, style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  const _SaveButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textPrimary.withOpacity(isDisabled ? 0.2 : 0.4),
            width: 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            : Text(
                'Сохранить',
                style: AppTextStyles.text12Regular.copyWith(
                  color: AppColors.textPrimary.withOpacity(
                    isDisabled ? 0.4 : 1,
                  ),
                ),
              ),
      ),
    );
  }
}

class _VoiceField extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.mic_none_outlined,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ArchiveSection extends StatelessWidget {
  final TextEditingController searchController;
  final List<DiaryEntry> entries;
  final String? emptyText;

  const _ArchiveSection({
    required this.searchController,
    required this.entries,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassFrame(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          _SearchField(controller: searchController),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                emptyText ?? 'Ничего не найдено',
                style: AppTextStyles.text14ExtraLight.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            )
          else
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DiaryEntryRow(data: e),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textPrimary.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.text14ExtraLight,
              decoration: InputDecoration(
                hintText: 'Поиск',
                hintStyle: AppTextStyles.text14ExtraLight.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textPrimary.withOpacity(0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryEntryRow extends StatelessWidget {
  final DiaryEntry data;
  const _DiaryEntryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.textPrimary.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.18),
            ),
            alignment: Alignment.center,
            child: Text(data.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.text14Light.copyWith(
                color: AppColors.archivedText,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(data.formattedDate, style: AppTextStyles.text12Regular),
        ],
      ),
    );
  }
}
