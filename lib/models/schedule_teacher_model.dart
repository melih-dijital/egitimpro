class ScheduleTeacherUnavailableTime {
  final int day;
  final int hour;

  const ScheduleTeacherUnavailableTime({
    required this.day,
    required this.hour,
  });

  factory ScheduleTeacherUnavailableTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacherUnavailableTime(
      day: (json['day'] as num?)?.toInt() ?? 0,
      hour: (json['hour'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'day': day, 'hour': hour};
}

class ScheduleTeacherModel {
  final int id;
  final String name;
  final int maxDailyHours;
  final List<ScheduleTeacherUnavailableTime> unavailableTimes;

  const ScheduleTeacherModel({
    required this.id,
    required this.name,
    required this.maxDailyHours,
    required this.unavailableTimes,
  });

  factory ScheduleTeacherModel.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacherModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      maxDailyHours: (json['max_daily_hours'] as num?)?.toInt() ?? 8,
      unavailableTimes: ((json['unavailable_times'] as List?) ?? const [])
          .map(
            (item) => ScheduleTeacherUnavailableTime.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class ScheduleTeacherPayload {
  final String name;
  final int maxDailyHours;
  final List<ScheduleTeacherUnavailableTime> unavailableTimes;

  const ScheduleTeacherPayload({
    required this.name,
    required this.maxDailyHours,
    required this.unavailableTimes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'max_daily_hours': maxDailyHours,
    'unavailable_times': unavailableTimes.map((item) => item.toJson()).toList(),
  };
}

class ScheduleTeacherUploadResult {
  final String message;
  final int savedCount;
  final int errorCount;
  final List<Map<String, dynamic>> saved;
  final List<Map<String, dynamic>> errors;

  const ScheduleTeacherUploadResult({
    required this.message,
    required this.savedCount,
    required this.errorCount,
    required this.saved,
    required this.errors,
  });

  factory ScheduleTeacherUploadResult.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacherUploadResult(
      message: json['message']?.toString() ?? '',
      savedCount: (json['saved_count'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      saved: ((json['saved'] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      errors: ((json['errors'] as List?) ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }
}
