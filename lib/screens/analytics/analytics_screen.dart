import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';

/// Échelle de temps des statistiques.
enum _PeriodType { week, month, all }

/// Indicateur suivi sur le graphique de progression.
enum _Metric { maxWeight, oneRepMax }

/// Performance d'un exercice lors d'une séance.
class _ExercisePoint {
  final DateTime date;
  final double maxWeight;
  final double oneRepMax;
  final int sets;

  const _ExercisePoint({
    required this.date,
    required this.maxWeight,
    required this.oneRepMax,
    required this.sets,
  });

  double valueOf(_Metric metric) => metric == _Metric.maxWeight ? maxWeight : oneRepMax;
}

/// Onglet « Stats » : volume d'entraînement par période et progression
/// d'un exercice, comparée à la période précédente.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _PeriodType _periodType = _PeriodType.month;

  /// Date de référence de la période affichée (semaine ou mois la contenant).
  DateTime _anchor = DateTime.now();

  String? _selectedExercise;
  _Metric _metric = _Metric.maxWeight;

  // ---------------------------------------------------------------------------
  // Périodes
  // ---------------------------------------------------------------------------

  DateTimeRange _periodFor(DateTime anchor, List<CompletedWorkout> workouts) {
    switch (_periodType) {
      case _PeriodType.week:
        final monday = UserStreak.getStartOfWeek(anchor);
        return DateTimeRange(
          start: monday,
          end: DateTime(monday.year, monday.month, monday.day + 6),
        );
      case _PeriodType.month:
        return DateTimeRange(
          start: DateTime(anchor.year, anchor.month, 1),
          end: DateTime(anchor.year, anchor.month + 1, 0),
        );
      case _PeriodType.all:
        final now = DateTime.now();
        final first = workouts.isEmpty ? now : workouts.last.date;
        return DateTimeRange(start: DateTime(first.year, first.month, first.day), end: now);
    }
  }

  /// Période précédente de même nature, ou `null` pour « Tout ».
  DateTimeRange? _previousPeriod(List<CompletedWorkout> workouts) {
    switch (_periodType) {
      case _PeriodType.week:
        return _periodFor(_anchor.subtract(const Duration(days: 7)), workouts);
      case _PeriodType.month:
        return _periodFor(DateTime(_anchor.year, _anchor.month - 1, 1), workouts);
      case _PeriodType.all:
        return null;
    }
  }

  void _shift(int direction) {
    setState(() {
      _anchor = _periodType == _PeriodType.week
          ? _anchor.add(Duration(days: 7 * direction))
          : DateTime(_anchor.year, _anchor.month + direction, 1);
    });
  }

  String _periodLabel(DateTimeRange period) {
    switch (_periodType) {
      case _PeriodType.week:
        return 'Semaine du ${DateFormat('d MMMM', 'fr_FR').format(period.start)}';
      case _PeriodType.month:
        return capitalize(DateFormat('MMMM yyyy', 'fr_FR').format(period.start));
      case _PeriodType.all:
        return 'Depuis le ${DateFormat('d MMMM yyyy', 'fr_FR').format(period.start)}';
    }
  }

  // ---------------------------------------------------------------------------
  // Données
  // ---------------------------------------------------------------------------

  /// Performances de [exerciseName] sur [period], de la plus ancienne à la plus récente.
  List<_ExercisePoint> _pointsFor(
    List<CompletedWorkout> workouts,
    String exerciseName,
    DateTimeRange period,
  ) {
    final start = period.start;
    final endExclusive = DateTime(period.end.year, period.end.month, period.end.day + 1);
    final points = <_ExercisePoint>[];

    for (final workout in workouts) {
      if (workout.date.isBefore(start) || !workout.date.isBefore(endExclusive)) continue;
      for (final log in workout.exerciseLogs) {
        if (log.exerciseName != exerciseName || log.sets.isEmpty) continue;
        points.add(_ExercisePoint(
          date: workout.date,
          maxWeight: log.maxWeight,
          oneRepMax: log.bestEstimatedOneRepMax,
          sets: log.sets.length,
        ));
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Exercice affiché par défaut : le dernier réalisé.
  String? _defaultExercise(List<CompletedWorkout> workouts) {
    for (final workout in workouts) {
      for (final log in workout.exerciseLogs) {
        if (log.sets.isNotEmpty) return log.exerciseName;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final workouts = provider.completedWorkouts;

    if (workouts.every((w) => w.totalSets == 0)) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: LucideIcons.chart_line,
            title: 'Pas encore de statistiques',
            message: 'Termine une première séance : ta progression s\'affichera ici.',
          ),
        ),
      );
    }

    final period = _periodFor(_anchor, workouts);
    final previous = _previousPeriod(workouts);
    final stats = provider.getStatsForPeriod(period);

    final now = DateTime.now();
    final nextStart = _periodType == _PeriodType.week
        ? period.start.add(const Duration(days: 7))
        : DateTime(period.start.year, period.start.month + 1, 1);
    final canGoNext = _periodType != _PeriodType.all && !nextStart.isAfter(now);
    final canGoPrevious = _periodType != _PeriodType.all && workouts.last.date.isBefore(period.start);

    final exerciseName = _selectedExercise ?? _defaultExercise(workouts);
    final points = exerciseName == null ? <_ExercisePoint>[] : _pointsFor(workouts, exerciseName, period);
    final previousPoints = (exerciseName == null || previous == null)
        ? <_ExercisePoint>[]
        : _pointsFor(workouts, exerciseName, previous);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.l, AppSpace.page, AppSpace.xxl),
          children: [
            const Text('Statistiques', style: AppText.display),
            const SizedBox(height: AppSpace.l),

            _Segmented<_PeriodType>(
              value: _periodType,
              options: const {
                _PeriodType.week: 'Semaine',
                _PeriodType.month: 'Mois',
                _PeriodType.all: 'Tout',
              },
              onChanged: (type) => setState(() {
                _periodType = type;
                _anchor = DateTime.now();
              }),
            ),
            const SizedBox(height: AppSpace.m),

            // Navigation entre périodes.
            Row(
              children: [
                IconButton(
                  onPressed: canGoPrevious ? () => _shift(-1) : null,
                  tooltip: 'Période précédente',
                  icon: const Icon(LucideIcons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _periodLabel(period),
                    style: AppText.heading,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: canGoNext ? () => _shift(1) : null,
                  tooltip: 'Période suivante',
                  icon: const Icon(LucideIcons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),

            Panel(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.xl),
              child: StatRow(
                figures: [
                  StatFigure(value: '${stats.totalWorkouts}', label: stats.totalWorkouts > 1 ? 'séances' : 'séance'),
                  StatFigure(value: '${stats.totalSets}', label: stats.totalSets > 1 ? 'séries' : 'série'),
                  StatFigure(value: formatVolume(stats.totalVolume), label: 'soulevés'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            // Progression d'un exercice.
            SectionTitle(
              'Progression',
              trailing: _Segmented<_Metric>(
                compact: true,
                value: _metric,
                options: const {_Metric.maxWeight: 'Charge', _Metric.oneRepMax: '1RM estimé'},
                onChanged: (metric) => setState(() => _metric = metric),
              ),
            ),
            _ExerciseSelector(
              selected: exerciseName,
              options: provider.getAllExerciseNames(),
              onChanged: (name) => setState(() => _selectedExercise = name),
            ),
            const SizedBox(height: AppSpace.m),
            Panel(
              padding: const EdgeInsets.fromLTRB(AppSpace.s, AppSpace.xl, AppSpace.l, AppSpace.m),
              child: points.isEmpty
                  ? const SizedBox(
                      height: 160,
                      child: Center(
                        child: Text('Pas de séance sur cette période.', style: AppText.label),
                      ),
                    )
                  : _ProgressChart(points: points, metric: _metric),
            ),
            if (points.isNotEmpty) ...[
              const SizedBox(height: AppSpace.m),
              _ComparisonPanel(
                current: points,
                previous: previousPoints,
                metric: _metric,
                hasPreviousPeriod: previous != null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Contrôle segmenté générique.
class _Segmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final bool compact;

  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[
      for (final entry in options.entries)
        _segment(entry.key, entry.value),
    ];

    return Container(
      height: compact ? 34 : 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: compact ? segments : segments.map((s) => Expanded(child: s)).toList(),
      ),
    );
  }

  Widget _segment(T key, String label) {
    final selected = key == value;
    return GestureDetector(
      onTap: () => onChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: compact ? AppSpace.m : AppSpace.s),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            color: selected ? AppColors.ink : AppColors.inkSoft,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}

/// Champ de sélection de l'exercice, ouvrant une liste avec recherche.
class _ExerciseSelector extends StatelessWidget {
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _ExerciseSelector({required this.selected, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Panel(
      onTap: () => _open(context),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.m + 2),
      child: Row(
        children: [
          const Icon(LucideIcons.dumbbell, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Text(selected ?? 'Choisir un exercice', style: AppText.heading),
          ),
          const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.inkSoft),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExercisePickerList(options: options, selected: selected),
    );
    if (choice != null) onChanged(choice);
  }
}

class _ExercisePickerList extends StatefulWidget {
  final List<String> options;
  final String? selected;

  const _ExercisePickerList({required this.options, required this.selected});

  @override
  State<_ExercisePickerList> createState() => _ExercisePickerListState();
}

class _ExercisePickerListState extends State<_ExercisePickerList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((name) => name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Rechercher un exercice',
                prefixIcon: Icon(LucideIcons.search, size: 20, color: AppColors.inkFaint),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
              children: [
                for (final name in filtered)
                  ListTile(
                    title: Text(name, style: AppText.heading),
                    trailing: name == widget.selected
                        ? const Icon(LucideIcons.check, color: AppColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    onTap: () => Navigator.pop(context, name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Courbe de progression d'un exercice, séance par séance.
class _ProgressChart extends StatelessWidget {
  final List<_ExercisePoint> points;
  final _Metric metric;

  const _ProgressChart({required this.points, required this.metric});

  /// Pas de graduation « rond » (1, 2, 2,5, 5 ou 10 × puissance de 10).
  static double _niceStep(double range) {
    if (range <= 0) return 5;
    final raw = range / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final factor in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (raw <= factor * magnitude) return factor * magnitude;
    }
    return 10 * magnitude;
  }

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.valueOf(metric)).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final step = _niceStep(maxValue - minValue);
    final minY = (minValue / step).floor() * step - (maxValue == minValue ? step : 0);
    final maxY = (maxValue / step).ceil() * step + (maxValue == minValue ? step : 0);

    // Au plus cinq dates sous l'axe pour rester lisible.
    final int labelEvery = math.max(1, (points.length / 5).ceil());

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: math.max(0, minY),
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step,
            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.line, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: step,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: AppSpace.s),
                  child: Text(
                    formatWeight(value),
                    style: AppText.caption,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= points.length || index % labelEvery != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s),
                    child: Text(DateFormat('d/M').format(points[index].date), style: AppText.caption),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) => spots.map((spot) {
                final point = points[spot.spotIndex];
                return LineTooltipItem(
                  '${formatKg(spot.y)}\n${DateFormat('d MMM', 'fr_FR').format(point.date)}',
                  AppText.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), values[i]),
              ],
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.surface,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Meilleure performance de la période, comparée à la période précédente.
class _ComparisonPanel extends StatelessWidget {
  final List<_ExercisePoint> current;
  final List<_ExercisePoint> previous;
  final _Metric metric;
  final bool hasPreviousPeriod;

  const _ComparisonPanel({
    required this.current,
    required this.previous,
    required this.metric,
    required this.hasPreviousPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final best = current.map((p) => p.valueOf(metric)).reduce(math.max);
    final previousBest = previous.isEmpty ? null : previous.map((p) => p.valueOf(metric)).reduce(math.max);
    final first = current.first.valueOf(metric);
    final last = current.last.valueOf(metric);

    final String compareLabel;
    final double? delta;
    if (previousBest != null) {
      compareLabel = 'par rapport à la période précédente';
      delta = best - previousBest;
    } else if (current.length > 1) {
      compareLabel = 'entre la première et la dernière séance';
      delta = last - first;
    } else {
      compareLabel = hasPreviousPeriod
          ? 'aucune séance sur la période précédente'
          : 'une seule séance pour l\'instant';
      delta = null;
    }

    final Color deltaColor = delta == null || delta == 0
        ? AppColors.inkSoft
        : (delta > 0 ? AppColors.success : AppColors.record);
    final String deltaText = delta == null
        ? '–'
        : '${delta > 0 ? '+' : delta < 0 ? '−' : ''}${formatKg(delta.abs())}';

    return Panel(
      child: Row(
        children: [
          Expanded(
            child: StatFigure(
              value: formatKg(best),
              label: metric == _Metric.maxWeight ? 'meilleure charge' : 'meilleur 1RM estimé',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: StatFigure(value: deltaText, label: compareLabel, color: deltaColor),
          ),
        ],
      ),
    );
  }
}
