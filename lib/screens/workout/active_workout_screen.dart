import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';
import 'workout_summary_screen.dart';

/// Durées de repos proposées, en secondes.
const List<int> _restChoices = [30, 45, 60, 75, 90, 120, 150, 180, 240, 300];

/// Écran d'entraînement : tous les exercices de la séance sous forme de
/// tableaux de séries à valider une à une, avec minuteur de repos.
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
                style: AppText.body.copyWith(color: AppColors.textSoft),
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

  /// Demande confirmation lorsque la séance est vide ou que des séries
  /// prévues n'ont pas été validées. Renvoie `true` si la séance doit être
  /// enregistrée.
  Future<bool> _confirmFinish(ActiveWorkoutProvider provider) async {
    final workout = provider.currentWorkout!;

    if (workout.totalSets == 0) {
      final abandon = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucune série validée'),
          content: const Text(
            'Coche les séries réalisées pour les enregistrer. '
            'Une séance vide ne compte pas pour ton objectif.',
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

    final pending = workout.exerciseLogs.fold<int>(
      0,
      (sum, log) => sum + log.sets.where((s) => !s.isCompleted).length,
    );
    if (pending == 0) return true;

    final finish = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la séance ?'),
        content: Text(
          pending > 1
              ? '$pending séries ne sont pas cochées : elles ne seront pas enregistrées.'
              : 'Une série n\'est pas cochée : elle ne sera pas enregistrée.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continuer')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminer')),
        ],
      ),
    );
    return finish == true;
  }

  /// Termine la séance : enregistrement, célébration des records, puis
  /// carte de bilan qui remplace l'écran d'entraînement.
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

      if (records.isNotEmpty) {
        await navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (_, __, ___) => PRSequenceModal(records: records),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }

      // Le bilan remplace l'écran d'entraînement ; la séance n'est libérée
      // qu'à sa fermeture, pour éviter un écran vide pendant la transition.
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => WorkoutSummaryScreen(workout: completed, records: records),
        ),
      );
      provider.reset();
    } finally {
      _isFinishing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Exercices
  // ---------------------------------------------------------------------------

  Future<void> _addExercise(ActiveWorkoutProvider provider) async {
    final workoutProvider = context.read<WorkoutProvider>();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExercisePicker(exercises: workoutProvider.globalExercises),
    );
    if (name == null || !mounted) return;
    provider.addOffSessionExercise(name, workoutProvider);
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveWorkoutProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    final workout = provider.currentWorkout;

    if (workout == null) {
      return const Scaffold(body: Center(child: Text('Aucune séance en cours.')));
    }

    final logs = workout.exerciseLogs;
    final rest = provider.rest;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onLeaveRequested(provider);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.chevron_down),
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
            _ProgressStrip(logs: logs),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, AppSpace.xxl),
                children: [
                  if (logs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpace.xxl),
                      child: Text(
                        'Aucun exercice dans cette séance pour l\'instant.',
                        style: AppText.label,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (var i = 0; i < logs.length; i++) ...[
                    _ExerciseCard(
                      // Clé stable : l'état des champs suit l'exercice.
                      key: ValueKey(logs[i].id),
                      logIndex: i,
                      log: logs[i],
                      previousSets: workoutProvider.getPreviousSetsForExercise(logs[i].exerciseName),
                      restSeconds: provider.restSettings.secondsFor(logs[i].exerciseName),
                    ),
                    const SizedBox(height: AppSpace.m),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => _addExercise(provider),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: const Text('Ajouter un exercice'),
                  ),
                ],
              ),
            ),
            if (rest != null) _RestBar(rest: rest),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EN-TÊTE
// =============================================================================

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
        color: AppColors.textSoft,
      ),
    );
  }
}

/// Avancement de la séance : une barre par exercice, remplie selon la part
/// de séries validées.
class _ProgressStrip extends StatelessWidget {
  final List<ExerciseLog> logs;

  const _ProgressStrip({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s),
      child: Row(
        children: [
          for (var i = 0; i < logs.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: logs[i].sets.isEmpty
                      ? 0
                      : logs[i].completedSets.length / logs[i].sets.length,
                  minHeight: 4,
                  color: AppColors.success,
                  backgroundColor: AppColors.surfaceRaised,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CARTE D'EXERCICE
// =============================================================================

/// Un exercice de la séance : tableau des séries (précédent, charge,
/// répétitions, validation) et réglage du temps de repos.
class _ExerciseCard extends StatelessWidget {
  final int logIndex;
  final ExerciseLog log;
  final List<ExerciseSet> previousSets;
  final int restSeconds;

  const _ExerciseCard({
    super.key,
    required this.logIndex,
    required this.log,
    required this.previousSets,
    required this.restSeconds,
  });

  Future<void> _showOptions(BuildContext context) async {
    final provider = context.read<ActiveWorkoutProvider>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.s),
              child: Text(log.exerciseName, style: AppText.title),
            ),
            ListTile(
              leading: const Icon(LucideIcons.clock),
              title: const Text('Temps de repos'),
              trailing: Text(formatClock(Duration(seconds: restSeconds)), style: AppText.label),
              onTap: () => Navigator.pop(ctx, 'rest'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.plus),
              title: const Text('Ajouter une série'),
              onTap: () => Navigator.pop(ctx, 'add'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash_2, color: AppColors.error),
              title: Text('Retirer de la séance', style: AppText.body.copyWith(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    switch (choice) {
      case 'rest':
        await showRestPicker(context, log.exerciseName);
      case 'add':
        provider.addSet(logIndex);
      case 'remove':
        provider.removeExercise(logIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActiveWorkoutProvider>();
    final allDone = log.sets.isNotEmpty && log.completedSets.length == log.sets.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.m, AppSpace.s, AppSpace.s),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de l'exercice et options.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.exerciseName,
                      style: AppText.title.copyWith(
                        fontSize: 18,
                        color: allDone ? AppColors.success : AppColors.text,
                      ),
                    ),
                    if (log.isOffSession)
                      const Text('Ajouté pendant la séance', style: AppText.caption),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showOptions(context),
                tooltip: 'Options de l\'exercice',
                icon: const Icon(Icons.more_vert, size: 22, color: AppColors.textSoft),
              ),
            ],
          ),

          // Temps de repos de l'exercice, modifiable d'un appui.
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.m),
            child: InkWell(
              onTap: () => showRestPicker(context, log.exerciseName),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: AppColors.rest),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      'Repos ${formatClock(Duration(seconds: restSeconds))}',
                      style: AppText.label.copyWith(color: AppColors.rest, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const _SetHeader(),
          for (var i = 0; i < log.sets.length; i++)
            Dismissible(
              key: ValueKey(log.sets[i].id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => provider.deleteSet(logIndex, i),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpace.l),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: const Icon(LucideIcons.trash_2, size: 18, color: AppColors.error),
              ),
              child: _SetRow(
                key: ValueKey('row-${log.sets[i].id}'),
                logIndex: logIndex,
                setIndex: i,
                set: log.sets[i],
                previous: i < previousSets.length ? previousSets[i] : null,
              ),
            ),
          TextButton.icon(
            onPressed: () => provider.addSet(logIndex),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSoft,
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Ajouter une série'),
          ),
        ],
      ),
    );
  }
}

/// Largeurs des colonnes du tableau des séries.
class _Cols {
  static const double set = 32;
  static const double weight = 72;
  static const double reps = 60;
  static const double check = 48;
  static const double gap = AppSpace.s;
}

class _SetHeader extends StatelessWidget {
  const _SetHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpace.xs, right: AppSpace.s),
      child: Row(
        children: [
          SizedBox(width: _Cols.set, child: Text('Série', style: AppText.caption)),
          Expanded(child: Text('Précédent', style: AppText.caption)),
          SizedBox(
            width: _Cols.weight,
            child: Text('kg', style: AppText.caption, textAlign: TextAlign.center),
          ),
          SizedBox(width: _Cols.gap),
          SizedBox(
            width: _Cols.reps,
            child: Text('Reps', style: AppText.caption, textAlign: TextAlign.center),
          ),
          SizedBox(width: _Cols.gap),
          SizedBox(width: _Cols.check),
        ],
      ),
    );
  }
}

/// Ligne d'une série : valeurs précédentes en indication, saisie de la
/// charge et des répétitions, et case de validation.
class _SetRow extends StatefulWidget {
  final int logIndex;
  final int setIndex;
  final ExerciseSet set;
  final ExerciseSet? previous;

  const _SetRow({
    super.key,
    required this.logIndex,
    required this.setIndex,
    required this.set,
    required this.previous,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final _weightController = TextEditingController(
    text: widget.set.weight > 0 ? formatWeight(widget.set.weight) : '',
  );
  late final _repsController = TextEditingController(
    text: widget.set.reps > 0 ? '${widget.set.reps}' : '',
  );

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  double? get _typedWeight => double.tryParse(_weightController.text.replaceAll(',', '.'));
  int? get _typedReps => int.tryParse(_repsController.text);

  void _onChanged() {
    context.read<ActiveWorkoutProvider>().updateSet(
          widget.logIndex,
          widget.setIndex,
          weight: _typedWeight ?? 0,
          reps: _typedReps ?? 0,
        );
  }

  /// Valide la série. Un champ laissé vide reprend la valeur de la séance
  /// précédente, affichée en indication : valider sans rien taper refait
  /// exactement la même série.
  void _toggle() {
    final provider = context.read<ActiveWorkoutProvider>();

    if (widget.set.isCompleted) {
      provider.setCompleted(widget.logIndex, widget.setIndex, completed: false);
      return;
    }

    final weight = _typedWeight ?? widget.previous?.weight;
    final reps = _typedReps ?? widget.previous?.reps;
    if (weight == null || reps == null || reps <= 0) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique la charge et le nombre de répétitions.')),
      );
      return;
    }

    _weightController.text = formatWeight(weight);
    _repsController.text = '$reps';
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    provider.setCompleted(
      widget.logIndex,
      widget.setIndex,
      completed: true,
      weight: weight,
      reps: reps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.set.isCompleted;
    final previous = widget.previous;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSpace.xs, right: AppSpace.s),
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: done ? AppColors.success.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Cols.set,
            child: Text(
              '${widget.setIndex + 1}',
              style: AppText.figureM.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              previous == null ? '–' : '${formatWeight(previous.weight)} × ${previous.reps}',
              style: AppText.label.copyWith(color: AppColors.textFaint),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _Cols.weight,
            child: _NumberField(
              controller: _weightController,
              hint: previous == null ? '0' : formatWeight(previous.weight),
              decimal: true,
              done: done,
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: _Cols.gap),
          SizedBox(
            width: _Cols.reps,
            child: _NumberField(
              controller: _repsController,
              hint: previous == null ? '0' : '${previous.reps}',
              decimal: false,
              done: done,
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: _Cols.gap),
          SizedBox(
            width: _Cols.check,
            height: 40,
            child: Material(
              color: done ? AppColors.success : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.s),
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(AppRadius.s),
                child: Tooltip(
                  message: done ? 'Annuler la validation' : 'Valider la série',
                  child: Icon(
                    LucideIcons.check,
                    size: 20,
                    color: done ? Colors.white : AppColors.textFaint,
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

/// Champ numérique compact du tableau des séries.
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final bool done;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.hint,
    required this.decimal,
    required this.done,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: AppText.figureM.copyWith(fontSize: 19),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.figureM.copyWith(fontSize: 19, color: AppColors.textFaint),
        isDense: true,
        filled: true,
        fillColor: done ? Colors.transparent : AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.s + 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// =============================================================================
// MINUTEUR DE REPOS
// =============================================================================

/// Bandeau du repos en cours : compte à rebours, ajustement et sortie.
///
/// L'affichage est recalculé à partir de l'heure de fin : il reste juste
/// après un passage en arrière-plan. À zéro, une série de vibrations signale
/// la reprise (l'alerte système prend le relais si l'écran est verrouillé).
class _RestBar extends StatefulWidget {
  final ActiveRest rest;

  const _RestBar({required this.rest});

  @override
  State<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends State<_RestBar> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    if (widget.rest.isRunningAt(DateTime.now())) {
      setState(() {});
      return;
    }
    _ticker.cancel();
    _buzz();
    context.read<ActiveWorkoutProvider>().onRestElapsed();
  }

  /// Trois impulsions de vibration rapprochées.
  Future<void> _buzz() async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActiveWorkoutProvider>();
    final rest = widget.rest;
    final remaining = rest.remainingAt(DateTime.now());
    final progress = rest.totalSeconds == 0
        ? 0.0
        : (remaining.inMilliseconds / (rest.totalSeconds * 1000)).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              color: AppColors.rest,
              backgroundColor: AppColors.surfaceRaised,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, AppSpace.m),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Repos', style: AppText.caption.copyWith(color: AppColors.rest)),
                      Text(
                        formatClock(remaining + const Duration(milliseconds: 999)),
                        style: AppText.figureL.copyWith(color: AppColors.rest, fontSize: 40),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _RestButton(label: '−15', onTap: () => provider.adjustRest(-15)),
                  const SizedBox(width: AppSpace.s),
                  _RestButton(label: '+15', onTap: () => provider.adjustRest(15)),
                  const SizedBox(width: AppSpace.s),
                  FilledButton(
                    onPressed: provider.skipRest,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.rest,
                      foregroundColor: AppColors.background,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                    ),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RestButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: SizedBox(
          width: 52,
          height: 48,
          child: Center(child: Text(label, style: AppText.figureM.copyWith(fontSize: 18))),
        ),
      ),
    );
  }
}

/// Choix du temps de repos d'un exercice, et du lancement automatique.
Future<void> showRestPicker(BuildContext context, String exerciseName) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => _RestPickerSheet(exerciseName: exerciseName),
  );
}

class _RestPickerSheet extends StatelessWidget {
  final String exerciseName;

  const _RestPickerSheet({required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveWorkoutProvider>();
    final current = provider.restSettings.secondsFor(exerciseName);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Temps de repos', style: AppText.title),
            const SizedBox(height: AppSpace.xs),
            Text('Après chaque série de $exerciseName.', style: AppText.label),
            const SizedBox(height: AppSpace.l),
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                for (final seconds in _restChoices)
                  ChoiceChip(
                    label: Text(formatClock(Duration(seconds: seconds))),
                    selected: seconds == current,
                    showCheckmark: false,
                    selectedColor: AppColors.rest,
                    backgroundColor: AppColors.surfaceRaised,
                    side: BorderSide.none,
                    labelStyle: AppText.figureM.copyWith(
                      fontSize: 17,
                      color: seconds == current ? AppColors.background : AppColors.text,
                    ),
                    onSelected: (_) => provider.setRestSecondsFor(exerciseName, seconds),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: provider.restSettings.autoStart,
              onChanged: provider.setAutoStartRest,
              activeColor: AppColors.rest,
              title: const Text('Lancer le repos automatiquement', style: AppText.heading),
              subtitle: const Text('Dès qu\'une série est cochée.', style: AppText.caption),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AJOUT D'EXERCICE
// =============================================================================

/// Choix d'un exercice à ajouter : bibliothèque ou saisie libre.
class _ExercisePicker extends StatefulWidget {
  final List<GlobalExercise> exercises;

  const _ExercisePicker({required this.exercises});

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
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
                  style: AppText.body.copyWith(color: AppColors.textSoft),
                ),
                const SizedBox(height: AppSpace.l),
                TextField(
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher ou saisir un nom',
                    prefixIcon: Icon(LucideIcons.search, size: 20, color: AppColors.textFaint),
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
