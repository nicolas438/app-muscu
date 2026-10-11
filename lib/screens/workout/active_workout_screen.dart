import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';

/// Pas d'incrément de la charge avec les boutons − et + (plus petit
/// écart courant entre deux paires de disques).
const double _weightStep = 2.5;

/// Écran d'entraînement : saisie des séries exercice par exercice.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  /// Vrai pendant l'enregistrement de fin de séance (évite un double appui).
  bool _isFinishing = false;

  // ---------------------------------------------------------------------------
  // Sortie de l'écran
  // ---------------------------------------------------------------------------

  /// Propose de mettre la séance en pause (elle reste reprenable depuis
  /// l'accueil) ou de l'abandonner.
  Future<void> _onLeaveRequested(ActiveWorkoutProvider provider) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Quitter la séance ?', style: AppText.title),
              const SizedBox(height: AppSpace.xs),
              Text(
                'En pause, tes séries sont conservées : tu pourras reprendre depuis l\'accueil.',
                style: AppText.body.copyWith(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'pause'),
                child: const Text('Mettre en pause'),
              ),
              const SizedBox(height: AppSpace.s),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'continue'),
                child: const Text('Continuer la séance'),
              ),
              const SizedBox(height: AppSpace.s),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'abandon'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Abandonner sans enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case 'pause':
        Navigator.of(context).pop();
      case 'abandon':
        Navigator.of(context).pop();
        provider.cancelWorkout();
    }
  }

  // ---------------------------------------------------------------------------
  // Fin de séance
  // ---------------------------------------------------------------------------

  /// Demande confirmation lorsque la séance est vide ou incomplète.
  ///
  /// Renvoie `true` si la séance doit être enregistrée.
  Future<bool> _confirmFinish(ActiveWorkoutProvider provider) async {
    final workout = provider.currentWorkout!;

    if (workout.totalSets == 0) {
      final abandon = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucune série enregistrée'),
          content: const Text(
            'Une séance vide n\'est pas enregistrée et ne compte pas pour ton objectif.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Abandonner'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (abandon == true && mounted) {
        Navigator.of(context).pop();
        provider.cancelWorkout();
      }
      return false;
    }

    final skipped = workout.exerciseLogs.where((log) => log.sets.isEmpty).length;
    if (skipped == 0) return true;

    final finish = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la séance ?'),
        content: Text(
          '${plural(skipped, 'exercice')} sans série. '
          '${skipped > 1 ? 'Ils ne seront pas enregistrés.' : 'Il ne sera pas enregistré.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuer')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminer')),
        ],
      ),
    );
    return finish == true;
  }

  /// Termine la séance : sauvegarde, célébration des records, bilan, puis retour.
  ///
  /// Les fenêtres sont affichées tant que l'écran est encore ouvert, puis
  /// l'écran est fermé : l'ordre inverse rendait leur affichage aléatoire.
  Future<void> _finishWorkout(ActiveWorkoutProvider provider) async {
    if (_isFinishing) return;
    _isFinishing = true;

    // Dépendances capturées avant toute opération asynchrone.
    final workoutProvider = context.read<WorkoutProvider>();
    final navigator = Navigator.of(context);

    try {
      if (!await _confirmFinish(provider)) return;

      final completed = await provider.completeWorkout();
      if (completed == null) return;

      // Records calculés avant l'ajout à l'historique, pour ne comparer
      // qu'aux séances précédentes.
      final records = workoutProvider.checkForNewPRs(completed);

      // Met à jour l'historique en mémoire et l'objectif hebdomadaire.
      await workoutProvider.saveCompletedWorkout(completed);

      if (records.isNotEmpty && mounted) {
        await navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => PRSequenceModal(records: records),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }

      if (mounted) await _showSummary(completed, records.length);

      navigator.pop();
      provider.reset();
    } finally {
      _isFinishing = false;
    }
  }

  /// Bilan de fin de séance.
  Future<void> _showSummary(CompletedWorkout workout, int recordCount) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Séance terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpace.s),
            StatRow(
              figures: [
                StatFigure(value: formatDuration(workout.duration), label: 'durée'),
                StatFigure(value: '${workout.totalSets}', label: workout.totalSets > 1 ? 'séries' : 'série'),
              ],
            ),
            const SizedBox(height: AppSpace.l),
            Text(
              recordCount > 0
                  ? '${formatVolume(workout.totalVolume)} soulevés et ${plural(recordCount, 'record')} battu${recordCount > 1 ? 's' : ''}.'
                  : '${formatVolume(workout.totalVolume)} soulevés. Bien joué.',
              style: AppText.body.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercice hors séance
  // ---------------------------------------------------------------------------

  Future<void> _addOffSessionExercise(ActiveWorkoutProvider provider) async {
    final workoutProvider = context.read<WorkoutProvider>();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OffSessionPicker(exercises: workoutProvider.globalExercises),
    );
    if (name == null || !mounted) return;

    provider.addOffSessionExercise(name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name ajouté à la séance.'),
        duration: const Duration(seconds: 2),
        // Flottant et décalé pour ne pas masquer les boutons du bas.
        margin: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, 96),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveWorkoutProvider>();
    final workout = provider.currentWorkout;

    if (workout == null) {
      return const Scaffold(body: Center(child: Text('Aucune séance en cours.')));
    }

    final currentLog = provider.currentExerciseLog;
    final index = provider.currentExerciseIndex;
    final isLast = index >= workout.exerciseLogs.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onLeaveRequested(provider);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: 'Quitter la séance',
            onPressed: () => _onLeaveRequested(provider),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(workout.sessionName, style: AppText.heading, overflow: TextOverflow.ellipsis),
              _Chrono(startTime: workout.startTime),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.m),
              child: FilledButton(
                onPressed: () => _finishWorkout(provider),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  textStyle: AppText.label.copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('Terminer'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _ExerciseTabs(
              logs: workout.exerciseLogs,
              currentIndex: index,
              onSelect: provider.goToExercise,
              onAdd: () => _addOffSessionExercise(provider),
            ),
            Expanded(
              child: currentLog == null
                  ? const EmptyState(
                      icon: LucideIcons.list,
                      title: 'Aucun exercice',
                      message: 'Ajoute un exercice avec le bouton « + » ci-dessus.',
                    )
                  : _ExercisePanel(
                      // Nouvel état (saisie, suggestion) à chaque changement d'exercice.
                      key: ValueKey(currentLog.id),
                      log: currentLog,
                      position: index + 1,
                      total: workout.exerciseLogs.length,
                      onAddSet: (weight, reps) {
                        provider.addSet(weight: weight, reps: reps);
                        HapticFeedback.mediumImpact();
                      },
                      onDeleteSet: provider.deleteSet,
                    ),
            ),
            _BottomBar(
              canGoBack: index > 0,
              isLast: isLast,
              onPrevious: provider.previousExercise,
              onNext: provider.nextExercise,
              onFinish: () => _finishWorkout(provider),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chronomètre de séance, isolé pour ne reconstruire que lui chaque seconde.
class _Chrono extends StatefulWidget {
  final DateTime startTime;

  const _Chrono({required this.startTime});

  @override
  State<_Chrono> createState() => _ChronoState();
}

class _ChronoState extends State<_Chrono> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatClock(DateTime.now().difference(widget.startTime)),
      style: AppText.caption.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.inkSoft,
      ),
    );
  }
}

/// Bandeau des exercices de la séance, avec l'ajout d'un exercice hors séance.
class _ExerciseTabs extends StatelessWidget {
  final List<ExerciseLog> logs;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const _ExerciseTabs({
    required this.logs,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page - AppSpace.xs, vertical: AppSpace.s),
        children: [
          for (var i = 0; i < logs.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: _ExerciseChip(
                label: logs[i].exerciseName,
                selected: i == currentIndex,
                done: logs[i].sets.isNotEmpty,
                offSession: logs[i].isOffSession,
                onTap: () => onSelect(i),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Tooltip(
              message: 'Ajouter un exercice hors séance',
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(LucideIcons.plus, size: 18, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool done;
  final bool offSession;
  final VoidCallback onTap;

  const _ExerciseChip({
    required this.label,
    required this.selected,
    required this.done,
    required this.offSession,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.ink;

    return Material(
      color: selected ? AppColors.ink : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[
                Icon(LucideIcons.check, size: 14, color: selected ? Colors.white : AppColors.success),
                const SizedBox(width: AppSpace.xs),
              ] else if (offSession) ...[
                Icon(LucideIcons.plus, size: 14, color: foreground),
                const SizedBox(width: AppSpace.xs),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saisie des séries de l'exercice affiché.
class _ExercisePanel extends StatefulWidget {
  final ExerciseLog log;
  final int position;
  final int total;
  final void Function(double weight, int reps) onAddSet;
  final void Function(int index) onDeleteSet;

  const _ExercisePanel({
    super.key,
    required this.log,
    required this.position,
    required this.total,
    required this.onAddSet,
    required this.onDeleteSet,
  });

  @override
  State<_ExercisePanel> createState() => _ExercisePanelState();
}

class _ExercisePanelState extends State<_ExercisePanel> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  LastPerformance? _lastPerformance;

  @override
  void initState() {
    super.initState();
    _lastPerformance =
        context.read<WorkoutProvider>().getLastPerformanceForExercise(widget.log.exerciseName);
    _prefill();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  /// Pré-remplit la saisie : dernière série de l'exercice en cours, sinon
  /// meilleure série de la dernière séance.
  void _prefill() {
    if (widget.log.sets.isNotEmpty) {
      _fill(widget.log.sets.last.weight, widget.log.sets.last.reps);
    } else if (_lastPerformance != null) {
      _fill(_lastPerformance!.bestSet.weight, _lastPerformance!.bestSet.reps);
    }
  }

  void _fill(double weight, int reps) {
    _weightController.text = formatWeight(weight);
    _repsController.text = '$reps';
  }

  double? get _weight => double.tryParse(_weightController.text.replaceAll(',', '.'));
  int? get _reps => int.tryParse(_repsController.text);

  void _stepWeight(double delta) {
    final next = ((_weight ?? 0) + delta).clamp(0, 999).toDouble();
    setState(() => _weightController.text = formatWeight(next));
    HapticFeedback.selectionClick();
  }

  void _stepReps(int delta) {
    final next = ((_reps ?? 0) + delta).clamp(0, 999);
    setState(() => _repsController.text = '$next');
    HapticFeedback.selectionClick();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final weight = _weight;
    final reps = _reps;

    if (weight == null || weight < 0) {
      _showError('Indique une charge valide, par exemple 62,5.');
      return;
    }
    if (reps == null || reps <= 0) {
      _showError('Indique au moins une répétition.');
      return;
    }
    widget.onAddSet(weight, reps);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        margin: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, 96),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final last = _lastPerformance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, AppSpace.xl),
      children: [
        Text(
          log.isOffSession
              ? 'Exercice ${widget.position} sur ${widget.total}, hors séance'
              : 'Exercice ${widget.position} sur ${widget.total}',
          style: AppText.label,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(log.exerciseName, style: AppText.display),
        const SizedBox(height: AppSpace.m),

        // Repère : meilleure série de la dernière séance.
        if (last != null)
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: AppColors.inkFaint),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: Text(
                  'Dernière fois, le ${DateFormat('d MMM', 'fr_FR').format(last.date)} : '
                  '${formatWeight(last.bestSet.weight)} kg × ${last.bestSet.reps}',
                  style: AppText.label,
                ),
              ),
            ],
          )
        else
          const Text('Première fois sur cet exercice.', style: AppText.label),
        const SizedBox(height: AppSpace.l),

        // Saisie de la série.
        Panel(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            children: [
              _Stepper(
                label: 'Charge',
                unit: 'kg',
                controller: _weightController,
                decimal: true,
                onMinus: () => _stepWeight(-_weightStep),
                onPlus: () => _stepWeight(_weightStep),
              ),
              const Divider(height: AppSpace.xl),
              _Stepper(
                label: 'Répétitions',
                unit: 'reps',
                controller: _repsController,
                decimal: false,
                onMinus: () => _stepReps(-1),
                onPlus: () => _stepReps(1),
              ),
              const SizedBox(height: AppSpace.l),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(LucideIcons.check, size: 20),
                  label: Text('Valider la série ${log.sets.length + 1}'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),

        // Journal des séries de l'exercice.
        SectionTitle(
          'Séries',
          trailing: log.sets.isEmpty
              ? null
              : Text('Meilleure : ${formatKg(log.bestEstimatedOneRepMax)} (1RM)', style: AppText.caption),
        ),
        if (log.sets.isEmpty)
          Text(
            'Aucune série pour l\'instant.',
            style: AppText.body.copyWith(color: AppColors.inkSoft),
          )
        else
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < log.sets.length; i++) ...[
                  if (i > 0) const Divider(indent: AppSpace.l, endIndent: AppSpace.l),
                  _SetRow(
                    number: i + 1,
                    set: log.sets[i],
                    onReuse: () => setState(() => _fill(log.sets[i].weight, log.sets[i].reps)),
                    onDelete: () => widget.onDeleteSet(i),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Valeur modifiable au clavier ou avec deux larges boutons − et +,
/// pensés pour être utilisés entre deux séries.
class _Stepper extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _Stepper({
    required this.label,
    required this.unit,
    required this.controller,
    required this.decimal,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppText.label),
            const Spacer(),
            Text(unit, style: AppText.caption),
          ],
        ),
        const SizedBox(height: AppSpace.s),
        Row(
          children: [
            _StepButton(icon: LucideIcons.minus, tooltip: 'Diminuer', onTap: onMinus),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                style: AppText.figureXL,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppText.figureXL.copyWith(color: AppColors.line),
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            _StepButton(icon: LucideIcons.plus, tooltip: 'Augmenter', onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.chalk,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Icon(icon, size: 24, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Ligne du journal : touche pour reprendre ces valeurs, croix pour supprimer.
class _SetRow extends StatelessWidget {
  final int number;
  final ExerciseSet set;
  final VoidCallback onReuse;
  final VoidCallback onDelete;

  const _SetRow({
    required this.number,
    required this.set,
    required this.onReuse,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReuse,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xs, AppSpace.xs, AppSpace.xs),
        child: Row(
          children: [
            SizedBox(width: 28, child: Text('$number', style: AppText.caption)),
            Expanded(
              child: Text(
                '${formatWeight(set.weight)} kg × ${set.reps}',
                style: AppText.figureM,
              ),
            ),
            Text('1RM ${formatKg(set.estimatedOneRepMax)}', style: AppText.caption),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Supprimer la série',
              icon: const Icon(LucideIcons.x, size: 18, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de navigation entre exercices.
class _BottomBar extends StatelessWidget {
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.canGoBack,
    required this.isLast,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, AppSpace.m),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canGoBack ? onPrevious : null,
                  icon: const Icon(LucideIcons.chevron_left, size: 18),
                  label: const Text('Précédent'),
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: isLast
                    ? FilledButton(
                        onPressed: onFinish,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                        child: const Text('Terminer'),
                      )
                    : FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Suivant'),
                            SizedBox(width: AppSpace.xs),
                            Icon(LucideIcons.chevron_right, size: 18),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choix d'un exercice hors séance : bibliothèque ou saisie libre.
class _OffSessionPicker extends StatefulWidget {
  final List<GlobalExercise> exercises;

  const _OffSessionPicker({required this.exercises});

  @override
  State<_OffSessionPicker> createState() => _OffSessionPickerState();
}

class _OffSessionPickerState extends State<_OffSessionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises
        .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final exactMatch = widget.exercises.any((e) => e.name.toLowerCase() == _query.toLowerCase());

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter un exercice', style: AppText.title),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Il s\'ajoute à cette séance uniquement, et compte pour tes records.',
                  style: AppText.body.copyWith(color: AppColors.inkSoft),
                ),
                const SizedBox(height: AppSpace.l),
                TextField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher ou saisir un nom',
                    prefixIcon: Icon(LucideIcons.search, size: 20, color: AppColors.inkFaint),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
              children: [
                if (_query.isNotEmpty && !exactMatch)
                  ListTile(
                    leading: const Icon(LucideIcons.plus, color: AppColors.primary),
                    title: Text(
                      'Ajouter « $_query »',
                      style: AppText.heading.copyWith(color: AppColors.primary),
                    ),
                    onTap: () => Navigator.pop(context, _query),
                  ),
                for (final exercise in filtered)
                  ListTile(
                    title: Text(exercise.name, style: AppText.heading),
                    subtitle: exercise.category == null
                        ? null
                        : Text(exercise.category!, style: AppText.caption),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    onTap: () => Navigator.pop(context, exercise.name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
