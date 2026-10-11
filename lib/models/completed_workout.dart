import 'exercise_log.dart';

class CompletedWorkout {
  final String id;
  final String sessionId;
  final String sessionName;
  final DateTime date;
  final DateTime startTime;
  DateTime? endTime;
  List<ExerciseLog> exerciseLogs;
  String? notes;

  CompletedWorkout({
    required this.id,
    required this.sessionId,
    required this.sessionName,
    required this.date,
    required this.startTime,
    this.endTime,
    List<ExerciseLog>? exerciseLogs,
    this.notes,
  }) : exerciseLogs = exerciseLogs ?? [];

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  double get totalVolume => exerciseLogs.fold(0, (sum, log) => sum + log.totalVolume);

  int get totalSets => exerciseLogs.fold(0, (sum, log) => sum + log.sets.length);

  int get totalReps => exerciseLogs.fold(0, (sum, log) => sum + log.totalReps);

  CompletedWorkout copyWith({
    String? id,
    String? sessionId,
    String? sessionName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    List<ExerciseLog>? exerciseLogs,
    String? notes,
  }) {
    return CompletedWorkout(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sessionName: sessionName ?? this.sessionName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exerciseLogs: exerciseLogs ?? List.from(this.exerciseLogs),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'sessionName': sessionName,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exerciseLogs': exerciseLogs.map((l) => l.toJson()).toList(),
      'notes': notes,
    };
  }

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) {
    return CompletedWorkout(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      sessionName: json['sessionName'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      exerciseLogs: (json['exerciseLogs'] as List<dynamic>?)
              ?.map((l) => ExerciseLog.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }
}
