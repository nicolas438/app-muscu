import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedExercise;
  int _selectedMonthOffset = 0; // 0 = current month, -1 = last month, etc.
  String _periodType = 'month'; // 'week', 'month', 'all'
  List<DateTimeRange> _monthWeeks = [];
  int _selectedWeekIndex = 0;

  DateTime get _selectedMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthOffset);
  }

  int _indexOfTodayInWeeks(List<DateTimeRange> weeks) {
    final today = DateTime.now();
    for (var i = 0; i < weeks.length; i++) {
      final w = weeks[i];
      if (!today.isBefore(w.start) && !today.isAfter(w.end)) return i;
    }
    return 0;
  }

  void _changeMonthOffset(int delta) {
    setState(() {
      _selectedMonthOffset += delta;
      _monthWeeks = _computeWeeksForMonth(_selectedMonth);
      // If we're in week view and we moved to the current month, select the week containing today
      final now = DateTime.now();
      final isCurr = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
      if (_periodType == 'week') {
        if (isCurr) {
          _selectedWeekIndex = _indexOfTodayInWeeks(_monthWeeks);
        } else {
          // clamp to available weeks
          if (_monthWeeks.isEmpty) _selectedWeekIndex = 0;
          else _selectedWeekIndex = _selectedWeekIndex.clamp(0, _monthWeeks.length - 1);
        }
      }
    });
  }

  List<DateTimeRange> _computeWeeksForMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    // Find the Monday on or before the first day
    final firstWeekStart = first.subtract(Duration(days: (first.weekday - 1)));

    final weeks = <DateTimeRange>[];
    DateTime currentStart = firstWeekStart;
    while (currentStart.isBefore(last) || currentStart.isAtSameMomentAs(last)) {
      final currentEnd = currentStart.add(const Duration(days: 6));
      final rangeStart = currentStart.isBefore(first) ? first : currentStart;
      final rangeEnd = currentEnd.isAfter(last) ? last : currentEnd;
      weeks.add(DateTimeRange(start: rangeStart, end: rangeEnd));
      currentStart = currentStart.add(const Duration(days: 7));
    }

    return weeks;
  }

  DateTimeRange get _selectedPeriod {
    final now = DateTime.now();
    switch (_periodType) {
      case 'week':
        if (_monthWeeks.isEmpty) {
          // fallback: week containing today
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return DateTimeRange(start: start, end: now);
        }
        final idx = _selectedWeekIndex.clamp(0, _monthWeeks.length - 1);
        return _monthWeeks[idx];
      case 'month':
        return DateTimeRange(
          start: DateTime(_selectedMonth.year, _selectedMonth.month, 1),
          end: DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
        );
      case 'all':
      default:
        return DateTimeRange(
          start: DateTime(2020), // A date far back
          end: now,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          final exerciseNames = provider.getAllExerciseNames();
          final monthStats = provider.getMonthlyStats(_selectedMonth.year, _selectedMonth.month);

          if (provider.completedWorkouts.isEmpty) {
            return EmptyState(
              icon: LucideIcons.chart_bar,
              title: 'Pas encore de données',
              subtitle: 'Complète des séances pour voir tes statistiques',
            );
          }

          // Vérifier si on est sur le mois actuel
          final now = DateTime.now();
          final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;

          // Ensure month weeks are computed for the selected month
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final weeks = _computeWeeksForMonth(_selectedMonth);
            if (mounted && (weeks.length != _monthWeeks.length || _monthWeeks.isEmpty)) {
              setState(() {
                _monthWeeks = weeks;
                if (_selectedWeekIndex >= _monthWeeks.length) _selectedWeekIndex = 0;
                // if currently in week view and selected week is outside, clamp
              });
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector (always visible)
                // Navigation limited: earliest month is Jan 2026.
                Builder(builder: (context) {
                  final earliest = DateTime(2026, 1, 1);
                  final selectedNormalized = DateTime(_selectedMonth.year, _selectedMonth.month);
                  final canPrevious = selectedNormalized.isAfter(earliest);
                  final canNext = _selectedMonthOffset < 0;

                  return _MonthSelector(
                    selectedMonth: _selectedMonth,
                    onPrevious: canPrevious ? () => _changeMonthOffset(-1) : null,
                    onNext: canNext ? () => _changeMonthOffset(1) : null,
                  );
                }),
                const SizedBox(height: 12),

                // Period Type Selector (always visible) — choose Month / Week / All
                // Only allow week/all when viewing the current month
                _PeriodTypeSelector(
                  selectedType: _periodType,
                  allowWeekAndAll: isCurrentMonth,
                  onTypeChanged: (type) => setState(() {
                    // If the selected month is not the current month, force 'month'
                    if (!isCurrentMonth) {
                      _periodType = 'month';
                      return;
                    }

                    _periodType = type;
                    // when switching to week, compute weeks and default to current week
                    if (type == 'week') {
                      _monthWeeks = _computeWeeksForMonth(_selectedMonth);
                      final now = DateTime.now();
                      final isCurr = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
                      if (isCurr) {
                        _selectedWeekIndex = _indexOfTodayInWeeks(_monthWeeks);
                      } else {
                        _selectedWeekIndex = 0;
                      }
                    }
                  }),
                ),
                const SizedBox(height: 12),

                // If week selected, show week-in-month selector
                if (_periodType == 'week') ...[
                  const SizedBox(height: 8),
                  _WeekSelector(
                    weeks: _monthWeeks,
                    selectedIndex: _selectedWeekIndex,
                    onChanged: (idx) => setState(() => _selectedWeekIndex = idx),
                  ),
                ],

                // Stats Cards
                _MonthlyStatsCards(
                  stats: _periodType == 'month'
                      ? monthStats
                      : provider.getStatsForPeriod(_selectedPeriod),
                ),
                const SizedBox(height: 24),

                // Exercise Selector
                const Text(
                  'Progression par exercice',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                if (exerciseNames.isEmpty)
                  const Text(
                    'Aucun exercice enregistré',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else ...[
                  // Exercise Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedExercise,
                        hint: const Text(
                          'Sélectionne un exercice',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        dropdownColor: AppColors.surface,
                        items: exerciseNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(
                              name,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedExercise = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chart
                  if (_selectedExercise != null)
                    _ExerciseChart(
                      exerciseName: _selectedExercise!,
                      provider: provider,
                      period: _selectedPeriod,
                    ),
                ],

                const SizedBox(height: 24),

                // Comparison Section
                if (_selectedExercise != null)
                  _ComparisonSection(
                    exerciseName: _selectedExercise!,
                    provider: provider,
                    period: _selectedPeriod,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodTypeSelector extends StatelessWidget {
  final String selectedType;
  final bool allowWeekAndAll;
  final Function(String) onTypeChanged;

  const _PeriodTypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
    this.allowWeekAndAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PeriodTypeButton(
            label: 'Semaine',
            isSelected: selectedType == 'week',
            onTap: allowWeekAndAll ? () => onTypeChanged('week') : () {},
            isDisabled: !allowWeekAndAll,
          ),
          _PeriodTypeButton(
            label: 'Mois',
            isSelected: selectedType == 'month',
            onTap: () => onTypeChanged('month'),
          ),
          _PeriodTypeButton(
            label: 'Tout',
            isSelected: selectedType == 'all',
            onTap: allowWeekAndAll ? () => onTypeChanged('all') : () {},
            isDisabled: !allowWeekAndAll,
          ),
        ],
      ),
    );
  }
}

class _PeriodTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDisabled;

  const _PeriodTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.selectedMonth,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy', 'fr_FR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevron_left),
            color: AppColors.textSecondary,
            onPressed: onPrevious,
          ),
          Text(
            formatter.format(selectedMonth).capitalize(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevron_right),
            color: onNext != null ? AppColors.textSecondary : AppColors.textTertiary,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _MonthlyStatsCards extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _MonthlyStatsCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Séances',
            value: '${stats['totalWorkouts']}',
            icon: LucideIcons.calendar_check,
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Séries',
            value: '${stats['totalSets']}',
            icon: LucideIcons.layers,
            iconColor: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final List<DateTimeRange> weeks;
  final int selectedIndex;
  final Function(int) onChanged;

  const _WeekSelector({required this.weeks, required this.selectedIndex, required this.onChanged});

  String _formatRangeShort(DateTimeRange r) {
    final df = DateFormat('d MMM', 'fr_FR');
    return '${df.format(r.start)} - ${df.format(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(weeks.length, (i) {
            final label = 'S${i + 1} • ${_formatRangeShort(weeks[i])}';
            final selected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                selected: selected,
                onSelected: (_) => onChanged(i),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ExerciseChart extends StatefulWidget {
  final String exerciseName;
  final WorkoutProvider provider;
  final DateTimeRange period;

  const _ExerciseChart({
    required this.exerciseName,
    required this.provider,
    required this.period,
  });

  @override
  State<_ExerciseChart> createState() => _ExerciseChartState();
}

class _ExerciseChartState extends State<_ExerciseChart> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _ExerciseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final periodChanged = oldWidget.period.start != widget.period.start ||
        oldWidget.period.end != widget.period.end;

    if (oldWidget.exerciseName != widget.exerciseName || periodChanged) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await widget.provider.getExerciseProgression(
      widget.exerciseName,
      startDate: widget.period.start,
      endDate: widget.period.end,
    );
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Aucune donnée pour cet exercice',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trending_up, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Poids maximum',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surfaceLight,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}kg',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _data.length) return const SizedBox();
                        final date = _data[value.toInt()]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['maxWeight'] as double),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final data = _data[spot.spotIndex];
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} kg\n${data['totalReps']} reps',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
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

class _ComparisonSection extends StatelessWidget {
  final String exerciseName;
  final WorkoutProvider provider;
  final DateTimeRange period;

  const _ComparisonSection({
    required this.exerciseName,
    required this.provider,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate previous period with same duration
    final duration = period.end.difference(period.start);
    final previousPeriodEnd = period.start.subtract(const Duration(days: 1));
    final previousPeriodStart = previousPeriodEnd.subtract(duration);
    
    // Get workouts for current period
    final currentPeriodWorkouts = provider.completedWorkouts.where((w) {
      return w.date.isAfter(period.start.subtract(const Duration(days: 1))) &&
             w.date.isBefore(period.end.add(const Duration(days: 1)));
    }).toList();

    // Get workouts for previous period
    final previousPeriodWorkouts = provider.completedWorkouts.where((w) {
      return w.date.isAfter(previousPeriodStart.subtract(const Duration(days: 1))) &&
             w.date.isBefore(previousPeriodEnd.add(const Duration(days: 1)));
    }).toList();

    // Calculate max weight for selected exercise
    double currentMax = 0;
    double previousMax = 0;

    for (var workout in currentPeriodWorkouts) {
      for (var log in workout.exerciseLogs) {
        if (log.exerciseName == exerciseName && log.maxWeight > currentMax) {
          currentMax = log.maxWeight;
        }
      }
    }

    for (var workout in previousPeriodWorkouts) {
      for (var log in workout.exerciseLogs) {
        if (log.exerciseName == exerciseName && log.maxWeight > previousMax) {
          previousMax = log.maxWeight;
        }
      }
    }

    final diff = currentMax - previousMax;
    final diffPercent = previousMax > 0 ? (diff / previousMax * 100) : 0;
    
    // Format labels based on period
    final formatter = DateFormat('d MMM', 'fr_FR');
    final currentLabel = '${formatter.format(period.start)} - ${formatter.format(period.end)}';
    final previousLabel = '${formatter.format(previousPeriodStart)} - ${formatter.format(previousPeriodEnd)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.git_compare, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Comparaison',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ComparisonCard(
                  label: previousLabel,
                  value: '${previousMax.toStringAsFixed(1)} kg',
                  isOld: true,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.arrow_right, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonCard(
                  label: currentLabel,
                  value: '${currentMax.toStringAsFixed(1)} kg',
                  isOld: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: diff >= 0
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  diff >= 0 ? LucideIcons.trending_up : LucideIcons.trending_down,
                  color: diff >= 0 ? AppColors.success : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  diff >= 0
                      ? '+${diff.toStringAsFixed(1)} kg (+${diffPercent.toStringAsFixed(1)}%)'
                      : '${diff.toStringAsFixed(1)} kg (${diffPercent.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: diff >= 0 ? AppColors.success : AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isOld;

  const _ComparisonCard({
    required this.label,
    required this.value,
    required this.isOld,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOld ? AppColors.surfaceLight : AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: isOld ? null : Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isOld ? AppColors.textSecondary : AppColors.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isOld ? AppColors.textPrimary : AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
