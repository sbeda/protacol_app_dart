import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../voice/voice_capture_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeProvider.notifier).loadWorkspace());
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);

    return homeState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        error: error.toString(),
        onRetry: () {
          ref.read(homeProvider.notifier).loadWorkspace();
        },
      ),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final ws = data.workspace;
        final firstQuote = ws.quotes.isNotEmpty ? ws.quotes.first : null;

        return RefreshIndicator(
          onRefresh: () => ref.read(homeProvider.notifier).loadWorkspace(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(name: 'Владислав'),
              const SizedBox(height: 16),
              _Quote(
                text: firstQuote?.text ?? '',
                author: firstQuote?.author ?? '',
              ),
              const SizedBox(height: 20),
              _MetricsGrid(
                potential: ws.realizedPotential.today,
                experimentDay: ws.daysSinceRegistration,
                burnoutRisk: 'Высокий',
                insights: 15,
              ),
              const SizedBox(height: 32),
              const _VoiceDiaryButton(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ошибка: $error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 28),
          onPressed: () {},
        ),
        const Spacer(),
        Text('С возвращением, $name!', style: AppTextStyles.text16Light),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _Quote extends StatelessWidget {
  final String text;
  final String author;
  const _Quote({required this.text, required this.author});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: AppTextStyles.text13Thin,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          author.isNotEmpty ? '— $author —' : '',
          style: AppTextStyles.text12ThinItalic,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final int potential;
  final int experimentDay;
  final String burnoutRisk;
  final int insights;

  const _MetricsGrid({
    required this.potential,
    required this.experimentDay,
    required this.burnoutRisk,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GlassCard(child: _PotentialContent(value: potential)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassCard(child: _ExperimentContent(day: experimentDay)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GlassCard(child: _BurnoutContent(level: burnoutRisk)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlassCard(child: _InsightsContent(count: insights)),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.accent, AppColors.borderBlue],
            ),
          ),
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.85),
              borderRadius: BorderRadius.circular(19),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PotentialContent extends StatelessWidget {
  final int value;
  const _PotentialContent({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Реализованный\nпотенциал',
          style: AppTextStyles.cardTitle14,
        ),
        const Spacer(),
        Text('$value%', style: AppTextStyles.cardValueLarge),
      ],
    );
  }
}

class _ExperimentContent extends StatelessWidget {
  final int day;
  const _ExperimentContent({required this.day});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Эксперимент', style: AppTextStyles.cardTitle14),
            const SizedBox(height: 4),
            Text(
              'День',
              style: AppTextStyles.text14Light,
              textAlign: TextAlign.right,
            ),
            const Spacer(),
            Text(
              '$day',
              style: AppTextStyles.cardValueMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Icon(
            Icons.science_outlined,
            color: AppColors.textPrimary.withOpacity(0.4),
            size: 56,
          ),
        ),
      ],
    );
  }
}

class _BurnoutContent extends StatelessWidget {
  final String level;
  const _BurnoutContent({required this.level});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Риск истощения', style: AppTextStyles.cardTitle14),
            const SizedBox(height: 8),
            Text(
              level,
              style: AppTextStyles.italicValue.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Icon(
            Icons.warning_amber_rounded,
            color: AppColors.textPrimary.withOpacity(0.4),
            size: 56,
          ),
        ),
      ],
    );
  }
}

class _InsightsContent extends StatelessWidget {
  final int count;
  const _InsightsContent({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Инсайты', style: AppTextStyles.cardTitle14),
            const Spacer(),
            Text(
              '$count',
              style: AppTextStyles.cardValueMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Icon(
            Icons.lightbulb_outline,
            color: AppColors.textPrimary.withOpacity(0.4),
            size: 56,
          ),
        ),
      ],
    );
  }
}

class _VoiceDiaryButton extends StatelessWidget {
  const _VoiceDiaryButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.35),
                    AppColors.accent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
            ),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.55),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const VoiceCaptureScreen(),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Equalizer(),
                      const SizedBox(height: 20),
                      Text(
                        'Как прошёл ваш день?',
                        style: AppTextStyles.text13Thin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Equalizer extends StatelessWidget {
  const _Equalizer();

  @override
  Widget build(BuildContext context) {
    const heights = [22.0, 40.0, 58.0, 40.0, 22.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < heights.length; i++) ...[
          Container(
            width: 6,
            height: heights[i],
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          if (i != heights.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
