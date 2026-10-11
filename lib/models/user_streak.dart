/// Modèle pour le système de streak (flammes)
class UserStreak {
  final int currentStreak;
  final int bestStreak;
  final int weeklyGoal;
  final DateTime? lastWeekCompleted;
  final List<WeekRecord> weekHistory;

  UserStreak({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.weeklyGoal = 3,
    this.lastWeekCompleted,
    this.weekHistory = const [],
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      weeklyGoal: json['weeklyGoal'] ?? 3,
      lastWeekCompleted: json['lastWeekCompleted'] != null
          ? DateTime.parse(json['lastWeekCompleted'])
          : null,
      weekHistory: (json['weekHistory'] as List?)
              ?.map((w) => WeekRecord.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'weeklyGoal': weeklyGoal,
      'lastWeekCompleted': lastWeekCompleted?.toIso8601String(),
      'weekHistory': weekHistory.map((w) => w.toJson()).toList(),
    };
  }

  UserStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    int? weeklyGoal,
    DateTime? lastWeekCompleted,
    List<WeekRecord>? weekHistory,
  }) {
    return UserStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      lastWeekCompleted: lastWeekCompleted ?? this.lastWeekCompleted,
      weekHistory: weekHistory ?? this.weekHistory,
    );
  }

  /// Vérifie si l'objectif de la semaine en cours est atteint
  bool isCurrentWeekGoalMet(int workoutsThisWeek) {
    return workoutsThisWeek >= weeklyGoal;
  }

  /// Obtient le numéro de semaine ISO
  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDifference = date.difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  /// Obtient le lundi de la semaine
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Obtient le dimanche de la semaine
  static DateTime getEndOfWeek(DateTime date) {
    final startOfWeek = getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6));
  }
}

/// Enregistrement d'une semaine
class WeekRecord {
  final int weekNumber;
  final int year;
  final int workoutsCompleted;
  final int goalAtTime;
  final bool goalMet;

  WeekRecord({
    required this.weekNumber,
    required this.year,
    required this.workoutsCompleted,
    required this.goalAtTime,
    required this.goalMet,
  });

  factory WeekRecord.fromJson(Map<String, dynamic> json) {
    return WeekRecord(
      weekNumber: json['weekNumber'] ?? 0,
      year: json['year'] ?? DateTime.now().year,
      workoutsCompleted: json['workoutsCompleted'] ?? 0,
      goalAtTime: json['goalAtTime'] ?? 3,
      goalMet: json['goalMet'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'year': year,
      'workoutsCompleted': workoutsCompleted,
      'goalAtTime': goalAtTime,
      'goalMet': goalMet,
    };
  }
}
