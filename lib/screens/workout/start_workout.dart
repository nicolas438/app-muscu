import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'active_workout_screen.dart';

/// Ouvre l'écran de la séance en cours.
void openActiveWorkout(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
  );
}

/// Démarre [session] puis ouvre l'écran d'entraînement.
///
/// Si une autre séance est déjà en cours, l'utilisateur choisit entre la
/// reprendre et l'abandonner : elle n'est jamais écrasée sans confirmation.
Future<void> startWorkout(BuildContext context, WorkoutSession session) async {
  final activeProvider = context.read<ActiveWorkoutProvider>();
  final workoutProvider = context.read<WorkoutProvider>();

  if (session.exerciseRefs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajoute au moins un exercice à cette séance pour la lancer.')),
    );
    return;
  }

  if (activeProvider.hasActiveWorkout) {
    final current = activeProvider.currentWorkout!;

    // Même séance déjà lancée : on la reprend simplement.
    if (current.sessionId == session.id) {
      openActiveWorkout(context);
      return;
    }

    final startNew = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Une séance est en cours'),
        content: Text(
          '« ${current.sessionName} » n\'est pas terminée. '
          'Démarrer « ${session.name} » l\'abandonnera sans l\'enregistrer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Abandonner et démarrer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );

    // Fenêtre fermée sans choix : rien ne change.
    if (startNew == null || !context.mounted) return;
    if (!startNew) {
      openActiveWorkout(context);
      return;
    }
  }

  activeProvider.startWorkout(session, workoutProvider);
  if (context.mounted) openActiveWorkout(context);
}
