import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Hebdomadaire'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayOfWeek = index + 1;
              final sessionId = provider.schedule.getSession(dayOfWeek);
              final session = sessionId != null ? provider.getSessionById(sessionId) : null;
              final isToday = DateTime.now().weekday == dayOfWeek;

              return _DayCard(
                dayOfWeek: dayOfWeek,
                session: session,
                isToday: isToday,
                sessions: provider.sessions,
                onSessionChanged: (newSessionId) {
                  provider.updateSchedule(dayOfWeek, newSessionId);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayOfWeek;
  final WorkoutSession? session;
  final bool isToday;
  final List<WorkoutSession> sessions;
  final Function(String?) onSessionChanged;

  const _DayCard({
    required this.dayOfWeek,
    this.session,
    required this.isToday,
    required this.sessions,
    required this.onSessionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = WeeklySchedule.getDayName(dayOfWeek);
    
    Color? sessionColor;
    if (session != null) {
      final colorIndex = session!.color != null
          ? int.tryParse(session!.color!) ?? 0
          : session!.name.hashCode % AppColors.sessionColors.length;
      sessionColor = AppColors.sessionColors[colorIndex.abs() % AppColors.sessionColors.length];
    }

    return GradientCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: isToday ? AppColors.surfaceHighlight : AppColors.surface,
      onTap: () => _showSessionPicker(context),
      child: Row(
        children: [
          // Day indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  WeeklySchedule.getDayShortName(dayOfWeek),
                  style: TextStyle(
                    color: isToday ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isToday)
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Day name and session
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (session != null)
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sessionColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session!.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Repos',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Arrow
          const Icon(
            LucideIcons.chevron_right,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showSessionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir une séance pour ${WeeklySchedule.getDayName(dayOfWeek)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Rest option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.bed, color: AppColors.textTertiary),
                ),
                title: const Text('Repos', style: TextStyle(color: AppColors.textPrimary)),
                selected: session == null,
                onTap: () {
                  onSessionChanged(null);
                  Navigator.pop(ctx);
                },
              ),

              const Divider(),

              // Sessions list (scrollable)
              Expanded(
                child: sessions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Aucune séance créée. Crée d\'abord une séance dans l\'onglet "Séances".',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, idx) {
                          final s = sessions[idx];
                          final colorIndex = s.color != null
                              ? int.tryParse(s.color!) ?? 0
                              : s.name.hashCode % AppColors.sessionColors.length;
                          final sColor = AppColors.sessionColors[colorIndex.abs() % AppColors.sessionColors.length];

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: sColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(LucideIcons.dumbbell, color: sColor),
                            ),
                            title: Text(s.name, style: const TextStyle(color: AppColors.textPrimary)),
                            subtitle: Text(
                              '${s.exerciseRefs.length} exercices',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            selected: session?.id == s.id,
                            onTap: () {
                              onSessionChanged(s.id);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
