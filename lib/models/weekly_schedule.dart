class WeeklySchedule {
  Map<int, String?> schedule; // Map<dayOfWeek (1-7), sessionId?>

  WeeklySchedule({
    Map<int, String?>? schedule,
  }) : schedule = schedule ?? {
          1: null, // Monday
          2: null, // Tuesday
          3: null, // Wednesday
          4: null, // Thursday
          5: null, // Friday
          6: null, // Saturday
          7: null, // Sunday
        };

  void setSession(int dayOfWeek, String? sessionId) {
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      schedule[dayOfWeek] = sessionId;
    }
  }

  String? getSession(int dayOfWeek) {
    return schedule[dayOfWeek];
  }

  static String getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return '';
    }
  }

  static String getDayShortName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mer';
      case 4:
        return 'Jeu';
      case 5:
        return 'Ven';
      case 6:
        return 'Sam';
      case 7:
        return 'Dim';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule.map((key, value) => MapEntry(key.toString(), value)),
    };
  }

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final scheduleMap = (json['schedule'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(int.parse(key), value as String?)) ??
        {};
    return WeeklySchedule(schedule: scheduleMap);
  }
}
