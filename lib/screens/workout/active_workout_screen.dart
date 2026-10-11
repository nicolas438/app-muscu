import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../services/storage_service.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  /// Vrai pendant l'enregistrement de fin de séance.
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed = context.read<ActiveWorkoutProvider>().elapsedTime;
      });
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveWorkoutProvider>(
      builder: (context, provider, _) {
        if (provider.currentWorkout == null) {
          return const Scaffold(
            body: Center(child: Text('Aucun entraînement en cours')),
          );
        }

        final workout = provider.currentWorkout!;
        final currentLog = provider.currentExerciseLog;

        return WillPopScope(
          onWillPop: () => _confirmExit(context, provider),
          child: Scaffold(
            appBar: AppBar(
              title: Text(workout.sessionName),
              leading: IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: () => _confirmExit(context, provider),
              ),
              actions: [
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.clock, size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_elapsed),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Terminer est accessible à tout moment, quel que soit
                // l'exercice affiché (exercice sauté, ajout hors séance…).
                IconButton(
                  icon: const Icon(LucideIcons.check, color: AppColors.success),
                  tooltip: 'Terminer la séance',
                  onPressed: () => _finishWorkout(context, provider),
                ),
              ],
            ),
            body: Column(
              children: [
                // Exercise Tabs
                _ExerciseTabs(
                  exercises: workout.exerciseLogs,
                  currentIndex: provider.currentExerciseIndex,
                  onTap: provider.goToExercise,
                ),

                // Current Exercise
                Expanded(
                  child: currentLog != null
                      ? _ExercisePanel(
                          exerciseLog: currentLog,
                          onAddSet: (weight, reps) {
                            provider.addSet(weight: weight, reps: reps);
                            HapticFeedback.lightImpact();
                          },
                          onUpdateSet: (index, weight, reps) {
                            provider.updateSet(index, weight: weight, reps: reps);
                          },
                          onDeleteSet: provider.deleteSet,
                          onAddOffSessionExercise: () => _showOffSessionDialog(context, provider),
                        )
                      : const Center(child: Text('Aucun exercice')),
                ),

                // Bottom Navigation
                _BottomControls(
                  currentIndex: provider.currentExerciseIndex,
                  totalExercises: workout.exerciseLogs.length,
                  onPrevious: provider.previousExercise,
                  onNext: provider.nextExercise,
                  onFinish: () => _finishWorkout(context, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmExit(BuildContext context, ActiveWorkoutProvider provider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'entraînement ?'),
        content: const Text('Ton entraînement ne sera pas sauvegardé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.cancelWorkout();
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
    return false;
  }

  /// Termine la séance : sauvegarde, célébration des records, bilan, puis retour.
  ///
  /// Les fenêtres sont affichées tant que l'écran est encore ouvert : fermer
  /// l'écran d'abord rendait leur affichage aléatoire (contexte détruit).
  Future<void> _finishWorkout(BuildContext context, ActiveWorkoutProvider provider) async {
    // Capture des dépendances avant toute opération asynchrone.
    final workoutProvider = context.read<WorkoutProvider>();
    final navigator = Navigator.of(context);

    // Évite une double sauvegarde en cas d'appuis rapprochés sur « Terminer ».
    if (_isFinishing) return;
    _isFinishing = true;

    try {
      final completed = await provider.completeWorkout();
      if (completed == null) return;

      // Records calculés avant l'ajout à l'historique, pour comparer
      // uniquement avec les séances précédentes.
      final newPRs = workoutProvider.checkForNewPRs(completed);

      // Passe par WorkoutProvider pour mettre à jour l'historique en mémoire
      // et l'objectif hebdomadaire (flammes).
      await workoutProvider.saveCompletedWorkout(completed);

      if (newPRs.isNotEmpty && mounted) {
        await _showPRCelebration(newPRs);
      }

      if (mounted) {
        await _showCompletionDialog(completed);
      }

      // Retour à l'écran précédent, puis libération de la séance terminée.
      navigator.pop();
      provider.reset();
    } finally {
      _isFinishing = false;
    }
  }

  Future<void> _showOffSessionDialog(BuildContext context, ActiveWorkoutProvider provider) async {
    final workoutProvider = context.read<WorkoutProvider>();
    
    // First, show exercise picker or create new
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _OffSessionExercisePickerDialog(
        availableExercises: workoutProvider.globalExercises,
      ),
    );

    if (result != null && mounted) {
      final exerciseName = result['exerciseName'] as String;
      
      // Add exercise log without any sets (will be filled during workout)
      provider.addOffSessionExercise(exerciseName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$exerciseName ajouté ! Tu peux saisir tes séries.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          // Flottant et décalé pour ne pas masquer les boutons du bas.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      );
    }
  }

  Future<void> _showPRCelebration(Map<String, Map<String, double>> prs) async {
    if (!mounted || prs.isEmpty) return;

    // Push a single modal that sequences all PRs internally so the
    // "Continuer" button advances to the next PR without closing the modal.
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return PRSequenceModal(prs: prs);
        },
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Affiche le bilan de la séance et attend sa fermeture.
  Future<void> _showCompletionDialog(CompletedWorkout workout) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.trophy, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            const Text('VICTOIRE ! 💪'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatRow(label: 'Durée', value: _formatDuration(workout.duration)),
            _StatRow(label: 'Exercices', value: '${workout.exerciseLogs.length}'),
            _StatRow(label: 'Séries', value: '${workout.totalSets}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FERMER'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ExerciseTabs extends StatelessWidget {
  final List<ExerciseLog> exercises;
  final int currentIndex;
  final Function(int) onTap;

  const _ExerciseTabs({
    required this.exercises,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final isSelected = index == currentIndex;
          final log = exercises[index];
          final hasData = log.sets.isNotEmpty;
          final isOffSession = log.isOffSession;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: isOffSession ? Border.all(color: AppColors.accent, width: 1.5) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOffSession) ...[
                    Icon(
                      LucideIcons.notebook_pen,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      log.exerciseName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (hasData) ...[
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.check,
                      size: 14,
                      color: isSelected ? Colors.white : AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExercisePanel extends StatefulWidget {
  final ExerciseLog exerciseLog;
  final Function(double weight, int reps) onAddSet;
  final Function(int index, double? weight, int? reps) onUpdateSet;
  final Function(int index) onDeleteSet;
  final VoidCallback onAddOffSessionExercise;

  const _ExercisePanel({
    required this.exerciseLog,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onDeleteSet,
    required this.onAddOffSessionExercise,
  });

  @override
  State<_ExercisePanel> createState() => _ExercisePanelState();
}

class _ExercisePanelState extends State<_ExercisePanel> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double? _suggestedWeight;
  int? _suggestedReps;
  DateTime? _suggestedDate;
  bool _suggestionCleared = false;

  @override
  void initState() {
    super.initState();
    _loadLastValues();
  }

  @override
  void didUpdateWidget(covariant _ExercisePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseLog.id != widget.exerciseLog.id) {
      _loadLastValues();
    }
  }

  void _loadLastValues() {
    if (widget.exerciseLog.sets.isNotEmpty) {
      final lastSet = widget.exerciseLog.sets.last;
      _weightController.text = lastSet.weight.toString();
      _repsController.text = lastSet.reps.toString();
    } else {
      _weightController.text = '';
      _repsController.text = '';
    }

    // Load suggestion from past completed workouts (if any)
    try {
      final provider = context.read<WorkoutProvider>();
      final suggestion = provider.getLastPerformanceForExercise(widget.exerciseLog.exerciseName);
      if (suggestion != null) {
        _suggestedWeight = (suggestion['weight'] as num).toDouble();
        _suggestedReps = suggestion['reps'] as int;
        _suggestedDate = suggestion['date'] as DateTime;
        _suggestionCleared = false;
      } else {
        _suggestedWeight = null;
        _suggestedReps = null;
        _suggestedDate = null;
        _suggestionCleared = false;
      }
    } catch (_) {
      _suggestedWeight = null;
      _suggestedReps = null;
      _suggestedDate = null;
      _suggestionCleared = false;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          Row(
            children: [
              if (widget.exerciseLog.isOffSession)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.notebook_pen, size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'HORS SÉANCE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  widget.exerciseLog.exerciseName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Compact outlined button, constrained to avoid header overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: OutlinedButton.icon(
                  onPressed: widget.onAddOffSessionExercise,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    side: const BorderSide(width: 1.5, color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: AppColors.accent,
                    backgroundColor: Colors.transparent,
                  ),
                  icon: const Icon(LucideIcons.notebook_pen, size: 16, color: AppColors.accent),
                  label: const Text(
                    'Hors‑séance',
                    style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Input Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Poids (kg)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.surfaceHighlight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reps',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _repsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: AppColors.surfaceHighlight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Ajouter la série',
                    icon: LucideIcons.plus,
                    onPressed: _addSet,
                  ),
                ),
                const SizedBox(height: 12),
                // Suggestion from last performance
                if (_suggestedWeight != null && !_suggestionCleared) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dernière séance: ${_suggestedWeight!.toStringAsFixed(_suggestedWeight! % 1 == 0 ? 0 : 1)} kg x ${_suggestedReps}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              if (_suggestedDate != null)
                                Text(
                                  '${_suggestedDate!.day}/${_suggestedDate!.month}/${_suggestedDate!.year}',
                                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          AppButton(
                            label: 'Utiliser',
                            icon: LucideIcons.check,
                            onPressed: () {
                              _weightController.text = _suggestedWeight!.toString();
                              _repsController.text = _suggestedReps!.toString();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Effacer',
                            icon: LucideIcons.x,
                            isOutlined: true,
                            onPressed: () {
                              _suggestionCleared = true;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Off-session exercise button removed from bottom — moved to header
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sets List
          if (widget.exerciseLog.sets.isNotEmpty) ...[
            const Text(
              'Séries',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.exerciseLog.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(
                setNumber: index + 1,
                set: set,
                onDelete: () => widget.onDeleteSet(index),
              );
            }),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.list, color: AppColors.textTertiary, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Aucune série enregistrée',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      'Ajoute ta première série !',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addSet() {
    // Fermer le clavier
    FocusScope.of(context).unfocus();
    
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);

    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un poids valide')),
      );
      return;
    }

    if (reps == null || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre un nombre de reps valide')),
      );
      return;
    }

    widget.onAddSet(weight, reps);
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final ExerciseSet set;
  final VoidCallback onDelete;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$setNumber',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                const Icon(LucideIcons.weight, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${set.weight} kg',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(LucideIcons.repeat, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${set.reps} reps',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash_2, size: 18),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentIndex;
  final int totalExercises;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomControls({
    required this.currentIndex,
    required this.totalExercises,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = currentIndex == 0;
    final isLast = currentIndex == totalExercises - 1;

    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // Previous Button
            Expanded(
              child: AppButton(
                label: 'Précédent',
                icon: LucideIcons.chevron_left,
                isOutlined: true,
                onPressed: isFirst ? null : onPrevious,
              ),
            ),
            const SizedBox(width: 12),

            // Progress indicator
            Text(
              '${currentIndex + 1}/$totalExercises',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),

            // Next/Finish Button
            Expanded(
              child: isLast
                  ? GradientButton(
                      label: 'Terminer',
                      icon: LucideIcons.check,
                      gradient: const LinearGradient(
                        colors: [AppColors.success, AppColors.successLight],
                      ),
                      onPressed: onFinish,
                    )
                  : AppButton(
                      label: 'Suivant',
                      icon: LucideIcons.chevron_right,
                      onPressed: onNext,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog for picking or creating off-session exercise
class _OffSessionExercisePickerDialog extends StatefulWidget {
  final List<GlobalExercise> availableExercises;

  const _OffSessionExercisePickerDialog({
    required this.availableExercises,
  });

  @override
  State<_OffSessionExercisePickerDialog> createState() => _OffSessionExercisePickerDialogState();
}

class _OffSessionExercisePickerDialogState extends State<_OffSessionExercisePickerDialog> {
  String _searchQuery = '';
  final _newExerciseNameController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _newExerciseNameController.dispose();
    super.dispose();
  }

  List<GlobalExercise> get _filteredExercises {
    if (_searchQuery.isEmpty) return widget.availableExercises;
    return widget.availableExercises
        .where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Ajouter un exercice hors-séance',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionne un exercice existant ou crée-en un nouveau',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // Search bar
            if (!_isCreatingNew) ...[
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textTertiary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Exercise list or create form
            if (_isCreatingNew) ...[
              TextField(
                controller: _newExerciseNameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom de l\'exercice',
                  hintText: 'Ex: Bench Press',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _isCreatingNew = false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = _newExerciseNameController.text.trim();
                        if (name.isEmpty) return;

                        // Create global exercise
                        final newExercise = GlobalExercise(
                          id: StorageService().generateId(),
                          name: name,
                        );
                        await context.read<WorkoutProvider>().addGlobalExercise(newExercise);

                        if (mounted) {
                          Navigator.pop(context, {
                            'exerciseId': newExercise.id,
                            'exerciseName': newExercise.name,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: const Text('Créer'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // List of exercises
              Expanded(
                child: _filteredExercises.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun exercice trouvé',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.dumbbell,
                                color: AppColors.warning,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              exercise.name,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                            onTap: () {
                              Navigator.pop(context, {
                                'exerciseId': exercise.id,
                                'exerciseName': exercise.name,
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Create new button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isCreatingNew = true),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Créer un nouvel exercice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
