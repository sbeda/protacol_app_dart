import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit.dart';
import '../../providers/habits_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(habitsProvider.notifier).loadHabits());
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(4, (i) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 3 - i));
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final days = _days;

    return Column(
      children: [
        const _TopActions(),
        const SizedBox(height: 4),
        const _SessionCard(title: 'Чтение литературы', time: '00:00:00'),
        const SizedBox(height: 28),
        _DaysHeader(days: days),
        const SizedBox(height: 12),
        Expanded(
          child: habitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Ошибка: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (habits) {
              if (habits.isEmpty) {
                return Center(
                  child: Text(
                    'Нет привычек',
                    style: AppTextStyles.text14ExtraLight,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: habits.length,
                itemBuilder: (context, index) => _HabitRow(
                  habit: habits[index],
                  days: days,
                  formatDate: _formatDate,
                ),
              );
            },
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
          _ActionIcon(icon: Icons.add, onTap: () {}),
          const SizedBox(width: 20),
          _ActionIcon(icon: Icons.edit_outlined, onTap: () {}),
          const SizedBox(width: 20),
          _ActionIcon(icon: Icons.help_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: AppColors.textPrimary, size: 26),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String time;
  const _SessionCard({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.accent, AppColors.borderBlue],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.85),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Сессии', style: AppTextStyles.text16Light),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: AppTextStyles.text14ExtraLight.copyWith(
                                color: AppColors.accent,
                                fontStyle: FontStyle.italic,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.folder_open,
                        color: AppColors.textPrimary.withOpacity(0.7),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.help_outline,
                        color: AppColors.textPrimary.withOpacity(0.7),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w300,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      _PlayButton(onTap: () {}),
                      const SizedBox(width: 14),
                      _StopButton(onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(
            color: AppColors.accent.withOpacity(0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.25),
              blurRadius: 18,
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow, color: AppColors.accent, size: 32),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StopButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.accent,
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 18),
          ],
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DaysHeader extends StatelessWidget {
  final List<DateTime> days;
  const _DaysHeader({required this.days});

  static const _names = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  String _dayName(int weekday) => _names[weekday - 1];

  String _dayFormatted(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),
          ...days.map(
            (d) => SizedBox(
              width: 56,
              child: Column(
                children: [
                  Text(_dayName(d.weekday), style: AppTextStyles.text16Light),
                  const SizedBox(height: 2),
                  Text(
                    _dayFormatted(d),
                    style: AppTextStyles.text16Light.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  final Habit habit;
  final List<DateTime> days;
  final String Function(DateTime) formatDate;

  const _HabitRow({
    required this.habit,
    required this.days,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(habitsProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.title,
              style: AppTextStyles.text14ExtraLight.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 18,
                color: AppColors.textPrimary.withOpacity(0.85),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...days.map((d) {
            final status = habit.statusForDate(d);
            final isChecked = status == 'completed';
            return SizedBox(
              width: 56,
              child: Center(
                child: _HabitCheckbox(
                  checked: isChecked,
                  onTap: () {
                    notifier.saveChanges([
                      {
                        'habit_id': habit.id.toString(),
                        'date': formatDate(d),
                        'status': isChecked ? 'not_completed' : 'completed',
                      },
                    ]);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HabitCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  const _HabitCheckbox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: checked ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: AppColors.accent.withOpacity(checked ? 1.0 : 0.6),
            width: 1.4,
          ),
          boxShadow: checked
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: checked
            ? const Icon(Icons.check, color: AppColors.textPrimary, size: 22)
            : null,
      ),
    );
  }
}
