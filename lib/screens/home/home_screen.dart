import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';
import '../analytics/analytics_screen.dart';
import '../schedule/schedule_screen.dart';
import '../sessions/sessions_screen.dart';
import '../workout/start_workout.dart';
import '../workout/workout_detail_screen.dart';

/// Écran racine : navigation entre Accueil, Séances, Planning et Stats.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Propose de reprendre une séance interrompue une fois l'écran affiché.
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerToResumeWorkout());
  }

  /// Propose de reprendre la séance laissée en cours lors de la dernière
  /// fermeture de l'application.
  Future<void> _offerToResumeWorkout() async {
    final activeProvider = context.read<ActiveWorkoutProvider>();
    if (!activeProvider.hasActiveWorkout) return;

    final workout = activeProvider.currentWorkout!;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reprendre ta séance ?'),
        content: Text(
          '« ${workout.sessionName} » n\'a pas été terminée. '
          '${plural(workout.totalSets, 'série')} déjà ${workout.totalSets > 1 ? 'enregistrées' : 'enregistrée'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abandonner'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (resume == true) {
      openActiveWorkout(context);
    } else {
      activeProvider.cancelWorkout();
    }
  }

  void _selectTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TodayTab(onOpenSessions: () => _selectTab(1)),
          const SessionsScreen(),
          const ScheduleScreen(),
          const AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.house), label: 'Accueil'),
            NavigationDestination(icon: Icon(LucideIcons.dumbbell), label: 'Séances'),
            NavigationDestination(icon: Icon(LucideIcons.calendar), label: 'Planning'),
            NavigationDestination(icon: Icon(LucideIcons.chart_line), label: 'Stats'),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ONGLET ACCUEIL
// =============================================================================

class _TodayTab extends StatelessWidget {
  final VoidCallback onOpenSessions;

  const _TodayTab({required this.onOpenSessions});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final activeProvider = context.watch<ActiveWorkoutProvider>();
    final today = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final recent = provider.getRecentWorkouts();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.l, AppSpace.page, AppSpace.xxl),
        children: [
          // En-tête : date du jour et série de semaines en cours.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(capitalize(today), style: AppText.label),
                    const SizedBox(height: AppSpace.xs),
                    const Text('Aujourd\'hui', style: AppText.display),
                  ],
                ),
              ),
              _StreakBadge(streak: provider.streak.currentStreak),
            ],
          ),
          const SizedBox(height: AppSpace.xl),

          _TodayCard(
            session: provider.getTodaySession(),
            activeWorkout: activeProvider.hasActiveWorkout ? activeProvider.currentWorkout : null,
            lastWorkout: provider.getTodaySession() == null
                ? null
                : provider.getLastWorkoutOfSession(provider.getTodaySession()!),
            onOpenSessions: onOpenSessions,
          ),
          const SizedBox(height: AppSpace.l),

          _WeekPanel(provider: provider),
          const SizedBox(height: AppSpace.xxl),

          const SectionTitle('Historique'),
          if (recent.isEmpty)
            Text(
              'Tes séances terminées apparaîtront ici.',
              style: AppText.body.copyWith(color: AppColors.inkSoft),
            )
          else
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) const Divider(indent: AppSpace.l, endIndent: AppSpace.l),
                    _HistoryRow(workout: recent[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pastille indiquant le nombre de semaines d'affilée où l'objectif est tenu.
class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Tooltip(
      message: '${plural(streak, 'semaine')} d\'affilée avec l\'objectif atteint',
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.m, AppSpace.s, AppSpace.l, AppSpace.s),
        decoration: BoxDecoration(
          color: active ? AppColors.flame : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.flame, size: 18, color: active ? AppColors.ink : AppColors.inkFaint),
            const SizedBox(width: AppSpace.xs),
            Text(
              '$streak',
              style: AppText.figureM.copyWith(color: active ? AppColors.ink : AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc principal de l'accueil : la séance du jour, la séance en cours,
/// ou un jour de repos. C'est le seul bloc sombre de l'écran.
class _TodayCard extends StatelessWidget {
  final WorkoutSession? session;
  final CompletedWorkout? activeWorkout;
  final CompletedWorkout? lastWorkout;
  final VoidCallback onOpenSessions;

  const _TodayCard({
    required this.session,
    required this.activeWorkout,
    required this.lastWorkout,
    required this.onOpenSessions,
  });

  @override
  Widget build(BuildContext context) {
    final String caption;
    final String title;
    final String? detail;
    final Widget action;
    Color? plateColor;

    if (activeWorkout != null) {
      // Une séance est en cours : la reprendre est la seule chose qui compte.
      caption = 'Séance en cours';
      title = activeWorkout!.sessionName;
      detail = '${plural(activeWorkout!.totalSets, 'série')} '
          '${activeWorkout!.totalSets > 1 ? 'enregistrées' : 'enregistrée'}';
      action = FilledButton.icon(
        onPressed: () => openActiveWorkout(context),
        icon: const Icon(LucideIcons.play, size: 18),
        label: const Text('Reprendre la séance'),
      );
    } else if (session != null) {
      caption = 'Prévu aujourd\'hui';
      title = session!.name;
      plateColor = AppColors.sessionColor(session!.color);
      final count = plural(session!.exerciseRefs.length, 'exercice');
      detail = lastWorkout == null
          ? count
          : '$count, dernière fois le ${DateFormat('d MMMM', 'fr_FR').format(lastWorkout!.date)}';
      action = FilledButton.icon(
        onPressed: () => startWorkout(context, session!),
        icon: const Icon(LucideIcons.play, size: 18),
        label: const Text('Commencer la séance'),
      );
    } else {
      caption = 'Rien de prévu';
      title = 'Jour de repos';
      detail = 'Envie de t\'entraîner quand même ? Lance n\'importe quelle séance.';
      action = OutlinedButton(
        onPressed: onOpenSessions,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24, width: 1.5),
        ),
        child: const Text('Voir mes séances'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (plateColor != null) ...[
                PlateMarker(color: plateColor, size: 14),
                const SizedBox(width: AppSpace.s),
              ],
              Text(caption, style: AppText.label.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: AppSpace.s),
          Text(title, style: AppText.display.copyWith(color: Colors.white, fontSize: 38)),
          if (detail != null) ...[
            const SizedBox(height: AppSpace.s),
            Text(detail, style: AppText.body.copyWith(color: Colors.white60)),
          ],
          const SizedBox(height: AppSpace.xl),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }
}

/// Objectif hebdomadaire : semaine jour par jour et progression.
class _WeekPanel extends StatelessWidget {
  final WorkoutProvider provider;

  const _WeekPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final streak = provider.streak;
    final done = provider.workoutsThisWeek;
    final goal = streak.weeklyGoal;
    final goalMet = done >= goal;

    return Panel(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.l, AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Cette semaine', style: AppText.heading)),
              TextButton(
                onPressed: () => _showGoalPicker(context, goal),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  textStyle: AppText.label,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Objectif : ${plural(goal, 'séance')}'),
                    const SizedBox(width: AppSpace.xs),
                    const Icon(LucideIcons.chevron_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          _WeekStrip(provider: provider),
          const SizedBox(height: AppSpace.l),

          // Barre de progression segmentée : un segment par séance visée.
          Row(
            children: [
              for (var i = 0; i < goal; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < done
                          ? (goalMet ? AppColors.flame : AppColors.success)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Row(
            children: [
              Expanded(
                child: Text(
                  goalMet
                      ? 'Objectif atteint, la semaine est validée.'
                      : '${(done).clamp(0, goal)} sur $goal, encore ${plural(goal - done, 'séance')}.',
                  style: AppText.label.copyWith(color: goalMet ? AppColors.ink : AppColors.inkSoft),
                ),
              ),
              if (streak.bestStreak > 0)
                Text('Record : ${plural(streak.bestStreak, 'sem.', 'sem.')}', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }

  void _showGoalPicker(BuildContext context, int currentGoal) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Objectif hebdomadaire', style: AppText.title),
              const SizedBox(height: AppSpace.xs),
              Text(
                'Combien de séances par semaine ? Chaque semaine tenue ajoute une flamme.',
                style: AppText.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpace.xl),
              Row(
                children: [
                  for (var goal = 1; goal <= 7; goal++) ...[
                    if (goal > 1) const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: _GoalOption(
                        value: goal,
                        selected: goal == currentGoal,
                        onTap: () {
                          provider.updateWeeklyGoal(goal);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _GoalOption({required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.chalk,
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              '$value',
              style: AppText.figureM.copyWith(color: selected ? Colors.white : AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les sept jours de la semaine : séance faite, séance prévue ou repos.
class _WeekStrip extends StatelessWidget {
  final WorkoutProvider provider;

  const _WeekStrip({required this.provider});

  static const _letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = UserStreak.getStartOfWeek(now);
    final doneDays = provider.workoutsInWeekOf(now).map((w) => w.date.weekday).toSet();

    return Row(
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Expanded(
            child: _DayDot(
              letter: _letters[day - 1],
              dayOfMonth: DateTime(monday.year, monday.month, monday.day + day - 1).day,
              isToday: day == now.weekday,
              isDone: doneDays.contains(day),
              plannedColor: _plannedColor(day),
            ),
          ),
      ],
    );
  }

  Color? _plannedColor(int day) {
    final id = provider.schedule.getSession(day);
    if (id == null) return null;
    final session = provider.getSessionById(id);
    return session == null ? null : AppColors.sessionColor(session.color);
  }
}

class _DayDot extends StatelessWidget {
  final String letter;
  final int dayOfMonth;
  final bool isToday;
  final bool isDone;
  final Color? plannedColor;

  const _DayDot({
    required this.letter,
    required this.dayOfMonth,
    required this.isToday,
    required this.isDone,
    required this.plannedColor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget marker;
    if (isDone) {
      marker = Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(LucideIcons.check, size: 18, color: Colors.white),
      );
    } else {
      marker = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isToday ? AppColors.chalk : null,
          border: Border.all(
            color: isToday ? AppColors.ink : AppColors.line,
            width: isToday ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: plannedColor != null
            ? PlateMarker(color: plannedColor!, size: 12)
            : Text(
                '$dayOfMonth',
                style: AppText.caption.copyWith(
                  color: isToday ? AppColors.ink : AppColors.inkFaint,
                  fontWeight: FontWeight.w600,
                ),
              ),
      );
    }

    return Column(
      children: [
        Text(
          letter,
          style: AppText.caption.copyWith(
            color: isToday ? AppColors.ink : AppColors.inkFaint,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpace.s),
        marker,
      ],
    );
  }
}

/// Ligne d'historique : séance passée, avec accès au détail.
class _HistoryRow extends StatelessWidget {
  final CompletedWorkout workout;

  const _HistoryRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final session = context.read<WorkoutProvider>().getSessionById(workout.sessionId);
    final color = session == null ? AppColors.plateGrey : AppColors.sessionColor(session.color);
    final date = capitalize(DateFormat('EEEE d MMM', 'fr_FR').format(workout.date));

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.m + 2),
        child: Row(
          children: [
            PlateMarker(color: color, size: 16),
            const SizedBox(width: AppSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.sessionName, style: AppText.heading, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$date, ${formatDuration(workout.duration)}', style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.s),
            Text('${workout.totalSets}', style: AppText.figureM),
            const SizedBox(width: AppSpace.xs),
            Text(workout.totalSets > 1 ? 'séries' : 'série', style: AppText.caption),
            const SizedBox(width: AppSpace.s),
            const Icon(LucideIcons.chevron_right, size: 18, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
