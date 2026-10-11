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

  /// Lundi (à minuit) de la semaine contenant [date].
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Dimanche (à minuit) de la semaine contenant [date].
  static DateTime getEndOfWeek(DateTime date) {
    final monday = getStartOfWeek(date);
    return DateTime(monday.year, monday.month, monday.day + 6);
  }

  /// Numéro de semaine ISO 8601 (1 à 53).
  ///
  /// Selon la norme, la semaine 1 est celle qui contient le premier jeudi
  /// de l'année : le 1er janvier peut donc appartenir à la semaine 52 ou 53
  /// de l'année précédente.
  static int getWeekNumber(DateTime date) {
    final thursday = _thursdayOfWeek(date);
    final firstJanuary = DateTime.utc(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstJanuary).inDays;
    return dayOfYear ~/ 7 + 1;
  }

  /// Année ISO de la semaine contenant [date] (différente de l'année civile
  /// pour les quelques jours situés à cheval sur deux années).
  static int getWeekYear(DateTime date) => _thursdayOfWeek(date).year;

  /// Nombre de semaines entières séparant les semaines de [from] et [to].
  ///
  /// Le calcul part des lundis de chaque semaine en UTC, ce qui le rend
  /// insensible aux changements d'heure et au passage d'une année à l'autre.
  static int weeksBetween(DateTime from, DateTime to) {
    final fromMonday = getStartOfWeek(from);
    final toMonday = getStartOfWeek(to);
    final days = DateTime.utc(toMonday.year, toMonday.month, toMonday.day)
        .difference(DateTime.utc(fromMonday.year, fromMonday.month, fromMonday.day))
        .inDays;
    return days ~/ 7;
  }

  /// Jeudi de la semaine contenant [date], en UTC (référence ISO 8601).
  static DateTime _thursdayOfWeek(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    return day.add(Duration(days: DateTime.thursday - date.weekday));
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
