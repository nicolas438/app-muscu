import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../sessions/sessions_screen.dart';
import '../schedule/schedule_screen.dart';
import '../analytics/analytics_screen.dart';
import '../workout/active_workout_screen.dart';
import '../workout/workout_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          SessionsScreen(),
          ScheduleScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.house,
                  label: 'Accueil',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: LucideIcons.dumbbell,
                  label: 'Séances',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: LucideIcons.calendar,
                  label: 'Planning',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: LucideIcons.chart_line,
                  label: 'Stats',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.warning : AppColors.textTertiary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.warning : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Glowing underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.warning.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        final todaySession = provider.getTodaySession();
        final lastSameTypeWorkout = provider.getLastWorkoutOfTodayType();

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header style Baki
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'PRÊT AU COMBAT ?',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Image.asset(
                            'assets/images/app_icon.png',
                            width: 48,
                            height: 48,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Session Card with Baki Banner
                    _TodaySessionCard(session: todaySession),

                    const SizedBox(height: 24),
                    
                    // Wrapper with padding for remaining content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats
                          _QuickStats(
                            workouts: provider.completedWorkouts,
                            currentStreak: provider.streak.currentStreak,
                          ),

                          const SizedBox(height: 20),

                          // Streak/Flame Section
                          _StreakSection(
                            streak: provider.streak,
                            workoutsThisWeek: provider.workoutsThisWeek,
                            totalWorkouts: provider.totalCompletedWorkouts,
                            onUpdateGoal: (goal) => provider.updateWeeklyGoal(goal),
                          ),

                          const SizedBox(height: 24),

                          // Last workout of same type as today
                          if (lastSameTypeWorkout != null && todaySession != null) ...[
                            Text(
                              'DERNIÈRE SÉANCE ${todaySession.name.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _RecentWorkoutCard(workout: lastSameTypeWorkout),
                          ] else if (provider.completedWorkouts.isEmpty)
                            EmptyState(
                              icon: LucideIcons.dumbbell,
                              title: 'PAS ENCORE DE SÉANCE TERMINÉE',
                              subtitle: 'Lance ta première séance pour devenir plus fort !',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'MATIN DE GUERRIER 👊';
    if (hour < 18) return 'APRÈS-MIDI DE COMBAT 💪';
    return 'SOIRÉE DE CHAMPION 🔥';
  }
}

class _TodaySessionCard extends StatelessWidget {
  final WorkoutSession? session;

  const _TodaySessionCard({this.session});

  @override
  Widget build(BuildContext context) {
    final dayName = WeeklySchedule.getDayName(DateTime.now().weekday);

    if (session == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GradientCard(
          backgroundColor: AppColors.surfaceLight,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.textTertiary.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  LucideIcons.moon,
                  color: AppColors.textTertiary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'RÉCUPÉRATION',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Banner Baki pour la séance du jour (match other cards padding)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BakiBanner(
        sessionName: session!.name,
        subtitle: '${session!.exerciseRefs.length} exercices • Tape pour commencer',
        bannerIndex: session!.name.hashCode,
        onTap: () => _startWorkout(context, session!),
      ),
    );
  }

  void _startWorkout(BuildContext context, WorkoutSession session) {
    final activeProvider = context.read<ActiveWorkoutProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    activeProvider.startWorkout(session, workoutProvider);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ActiveWorkoutScreen(),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final List<CompletedWorkout> workouts;
  final int currentStreak;

  const _QuickStats({required this.workouts, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    // Stats for this week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekWorkouts = workouts.where((w) => w.date.isAfter(startOfWeek)).toList();

    final thisWeekCount = weekWorkouts.length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Cette semaine',
            value: '$thisWeekCount',
            subtitle: 'séances',
            icon: LucideIcons.calendar_check,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Série',
            value: '$currentStreak',
            subtitle: 'semaine${currentStreak > 1 ? 's' : ''} 🔥',
            icon: LucideIcons.flame,
            iconColor: currentStreak > 0 ? const Color(0xFFFF6B00) : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  final CompletedWorkout workout;

  const _RecentWorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMM', 'fr_FR');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workout: workout),
          ),
        );
      },
      child: GradientCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.dumbbell,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.sessionName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(workout.date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${workout.totalSets} séries',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakSection extends StatelessWidget {
  final UserStreak streak;
  final int workoutsThisWeek;
  final int totalWorkouts;
  final Function(int) onUpdateGoal;

  const _StreakSection({
    required this.streak,
    required this.workoutsThisWeek,
    required this.totalWorkouts,
    required this.onUpdateGoal,
  });

  @override
  Widget build(BuildContext context) {
    final goalMet = workoutsThisWeek >= streak.weeklyGoal;
    
    return GradientCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    goalMet ? LucideIcons.flame : LucideIcons.target,
                    color: goalMet ? const Color(0xFFFF6B00) : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'OBJECTIF SEMAINE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showGoalPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${streak.weeklyGoal} séances',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.chevron_down,
                        color: AppColors.textTertiary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Timeline / Frise chronologique
          _WeeklyTimeline(
            goal: streak.weeklyGoal,
            completed: workoutsThisWeek,
            goalMet: goalMet,
          ),
          
          const SizedBox(height: 16),
          
          // Streak info (only show if has streak)
          if (streak.currentStreak > 0 || goalMet)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: goalMet
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFFD700)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
                color: !goalMet ? AppColors.surfaceLight : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (goalMet) ...[
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${streak.currentStreak} semaine${streak.currentStreak > 1 ? 's' : ''} de suite !',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      LucideIcons.flame,
                      color: Color(0xFFFF6B00),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${streak.currentStreak} semaine${streak.currentStreak > 1 ? 's' : ''} de suite',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Total workouts counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.dumbbell,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$totalWorkouts séance${totalWorkouts > 1 ? 's' : ''} au total',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (streak.bestStreak > 0)
                Row(
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Record: ${streak.bestStreak} sem.',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OBJECTIF HEBDOMADAIRE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Combien de séances veux-tu faire par semaine ?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(7, (index) {
                final goal = index + 1;
                final isSelected = goal == streak.weeklyGoal;
                return GestureDetector(
                  onTap: () {
                    onUpdateGoal(goal);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$goal',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Widget de frise chronologique pour les séances de la semaine
class _WeeklyTimeline extends StatelessWidget {
  final int goal;
  final int completed;
  final bool goalMet;

  const _WeeklyTimeline({
    required this.goal,
    required this.completed,
    required this.goalMet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(goal * 2 - 1, (index) {
        // Indices pairs = points, indices impairs = lignes
        if (index.isEven) {
          final pointIndex = index ~/ 2;
          final isCompleted = pointIndex < completed;
          final isCurrent = pointIndex == completed;
          
          return _TimelinePoint(
            pointIndex: pointIndex,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: pointIndex == goal - 1,
            goalMet: goalMet,
          );
        } else {
          final lineIndex = index ~/ 2;
          final isActive = lineIndex < completed;
          
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isActive 
                  ? (goalMet ? const Color(0xFFFF6B00) : AppColors.primary)
                  : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
      }),
    );
  }
}

class _TimelinePoint extends StatelessWidget {
  final int pointIndex;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final bool goalMet;

  const _TimelinePoint({
    required this.pointIndex,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.goalMet,
  });

  @override
  Widget build(BuildContext context) {
    final size = isCompleted || isCurrent ? 32.0 : 24.0;
    
    // Si c'est le dernier point et l'objectif est atteint, montrer la flamme
    if (isLast && goalMet) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFFD700)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text('🔥', style: TextStyle(fontSize: 18)),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCompleted 
          ? AppColors.primary 
          : (isCurrent ? AppColors.surfaceLight : AppColors.surfaceLight),
        shape: BoxShape.circle,
        border: isCurrent 
          ? Border.all(color: AppColors.primary, width: 2)
          : null,
        boxShadow: isCompleted 
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
      ),
      child: Center(
        child: isCompleted
          ? const Icon(
              LucideIcons.check,
              color: Colors.white,
              size: 16,
            )
          : Text(
              '${pointIndex + 1}',
              style: TextStyle(
                color: isCurrent ? AppColors.textPrimary : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}
