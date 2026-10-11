import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';

/// Onglet « Planning » : une séance (ou du repos) pour chaque jour de la semaine.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final today = DateTime.now().weekday;

    final plannedDays = [
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        if (_sessionFor(provider, day) != null) day,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.l, AppSpace.page, AppSpace.xxl),
          children: [
            const Text('Planning', style: AppText.display),
            const SizedBox(height: AppSpace.xs),
            Text(
              plannedDays.isEmpty
                  ? 'Touche un jour pour y prévoir une séance.'
                  : '${plural(plannedDays.length, 'séance')} prévue${plannedDays.length > 1 ? 's' : ''} par semaine.',
              style: AppText.label,
            ),
            const SizedBox(height: AppSpace.xl),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++) ...[
                    if (day > DateTime.monday) const Divider(indent: AppSpace.l, endIndent: AppSpace.l),
                    _DayRow(
                      dayOfWeek: day,
                      isToday: day == today,
                      session: _sessionFor(provider, day),
                      onTap: () => _pickSession(context, provider, day),
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

  static WorkoutSession? _sessionFor(WorkoutProvider provider, int day) {
    final id = provider.schedule.getSession(day);
    return id == null ? null : provider.getSessionById(id);
  }

  void _pickSession(BuildContext context, WorkoutProvider provider, int day) {
    final current = _sessionFor(provider, day);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        void choose(String? sessionId) {
          provider.updateSchedule(day, sessionId);
          Navigator.pop(ctx);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.m),
                  child: Text(WeeklySchedule.getDayName(day), style: AppText.title),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(AppSpace.m, 0, AppSpace.m, AppSpace.l),
                    children: [
                      _SessionOption(
                        leading: const Icon(LucideIcons.moon, size: 20, color: AppColors.textSoft),
                        title: 'Repos',
                        selected: current == null,
                        onTap: () => choose(null),
                      ),
                      for (final session in provider.sessions)
                        _SessionOption(
                          leading: PlateMarker(color: AppColors.sessionColor(session.color), size: 20),
                          title: session.name,
                          subtitle: plural(session.exerciseRefs.length, 'exercice'),
                          selected: current?.id == session.id,
                          onTap: () => choose(session.id),
                        ),
                      if (provider.sessions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpace.l),
                          child: Text(
                            'Crée d\'abord une séance dans l\'onglet Séances.',
                            style: AppText.body.copyWith(color: AppColors.textSoft),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayRow extends StatelessWidget {
  final int dayOfWeek;
  final bool isToday;
  final WorkoutSession? session;
  final VoidCallback onTap;

  const _DayRow({
    required this.dayOfWeek,
    required this.isToday,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.l),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    WeeklySchedule.getDayName(dayOfWeek),
                    style: AppText.heading.copyWith(
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isToday)
                    Text(
                      'Aujourd\'hui',
                      style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            Expanded(
              child: session == null
                  ? const Text('Repos', style: AppText.label)
                  : Row(
                      children: [
                        PlateMarker(color: AppColors.sessionColor(session!.color), size: 14),
                        const SizedBox(width: AppSpace.s),
                        Expanded(
                          child: Text(
                            session!.name,
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(LucideIcons.chevron_right, size: 18, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _SessionOption extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SessionOption({
    required this.leading,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(width: 28, child: Center(child: leading)),
      title: Text(title, style: AppText.heading),
      subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.caption),
      trailing: selected ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
      selected: selected,
      selectedTileColor: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
    );
  }
}
