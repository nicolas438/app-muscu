import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';

/// Détail d'une séance terminée : bilan, séries de chaque exercice et records.
class WorkoutDetailScreen extends StatelessWidget {
  final CompletedWorkout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette séance ?'),
        content: const Text('Elle disparaîtra de ton historique et de tes statistiques.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<WorkoutProvider>().deleteCompletedWorkout(workout.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final recordNames = provider.checkForNewPRs(workout).map((r) => r.exerciseName).toSet();
    final logs = workout.exerciseLogs.where((log) => log.sets.isNotEmpty).toList();
    final date = capitalize(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(workout.date));
    final start = DateFormat('HH:mm', 'fr_FR').format(workout.startTime);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          tooltip: 'Retour',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash_2, size: 20),
            tooltip: 'Supprimer la séance',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xxl),
        children: [
          Text('$date, à $start', style: AppText.label),
          const SizedBox(height: AppSpace.xs),
          Text(workout.sessionName, style: AppText.display),
          const SizedBox(height: AppSpace.xl),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xl),
            child: StatRow(
              figures: [
                StatFigure(value: formatDuration(workout.duration), label: 'durée'),
                StatFigure(value: '${workout.totalSets}', label: workout.totalSets > 1 ? 'séries' : 'série'),
                StatFigure(value: formatVolume(workout.totalVolume), label: 'soulevés'),
              ],
            ),
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.l),
            Text(workout.notes!, style: AppText.body.copyWith(color: AppColors.inkSoft)),
          ],
          const SizedBox(height: AppSpace.xxl),
          const SectionTitle('Exercices'),
          if (logs.isEmpty)
            Text(
              'Aucune série n\'a été enregistrée pendant cette séance.',
              style: AppText.body.copyWith(color: AppColors.inkSoft),
            ),
          for (final log in logs) ...[
            _ExerciseLogPanel(log: log, isRecord: recordNames.contains(log.exerciseName)),
            const SizedBox(height: AppSpace.m),
          ],
        ],
      ),
    );
  }
}

class _ExerciseLogPanel extends StatelessWidget {
  final ExerciseLog log;
  final bool isRecord;

  const _ExerciseLogPanel({required this.log, required this.isRecord});

  @override
  Widget build(BuildContext context) {
    final best = log.bestSet;

    return Panel(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.l, AppSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(log.exerciseName, style: AppText.heading)),
              if (log.isOffSession) const _Tag(label: 'Hors séance', color: AppColors.inkSoft),
              if (isRecord) ...[
                const SizedBox(width: AppSpace.s),
                const _Tag(label: 'Record', color: AppColors.record, filled: true),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.s),
          for (var i = 0; i < log.sets.length; i++)
            _SetLine(index: i, set: log.sets[i], isBest: identical(log.sets[i], best)),
        ],
      ),
    );
  }
}

/// Ligne d'une série : numéro, charge × répétitions et 1RM estimé.
class _SetLine extends StatelessWidget {
  final int index;
  final ExerciseSet set;
  final bool isBest;

  const _SetLine({required this.index, required this.set, required this.isBest});

  @override
  Widget build(BuildContext context) {
    final color = isBest ? AppColors.ink : AppColors.inkSoft;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${index + 1}', style: AppText.caption),
          ),
          Expanded(
            child: Text(
              '${formatWeight(set.weight)} kg × ${set.reps}',
              style: AppText.figureM.copyWith(fontSize: 19, color: color),
            ),
          ),
          Text(
            '1RM ${formatKg(set.estimatedOneRepMax)}',
            style: AppText.caption.copyWith(
              color: isBest ? AppColors.ink : AppColors.inkFaint,
              fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Tag({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : null,
        border: filled ? null : Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
