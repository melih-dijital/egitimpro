class ScheduleRunModel {
  final int id;
  final DateTime createdAt;
  final String status;

  const ScheduleRunModel({
    required this.id,
    required this.createdAt,
    required this.status,
  });

  factory ScheduleRunModel.fromJson(Map<String, dynamic> json) {
    return ScheduleRunModel(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'unknown',
    );
  }
}

class ScheduleRunDetailModel {
  final int id;
  final int schoolId;
  final String createdByUserId;
  final DateTime createdAt;
  final String status;
  final Map<String, dynamic> meta;

  const ScheduleRunDetailModel({
    required this.id,
    required this.schoolId,
    required this.createdByUserId,
    required this.createdAt,
    required this.status,
    required this.meta,
  });

  factory ScheduleRunDetailModel.fromJson(Map<String, dynamic> json) {
    return ScheduleRunDetailModel(
      id: (json['id'] as num).toInt(),
      schoolId: (json['school_id'] as num?)?.toInt() ?? 0,
      createdByUserId: json['created_by_user_id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'unknown',
      meta: Map<String, dynamic>.from(json['meta'] as Map? ?? const {}),
    );
  }
}

class ScheduleRunClassroomSummaryModel {
  final int classroomId;
  final String classroomName;
  final int lessonCount;

  const ScheduleRunClassroomSummaryModel({
    required this.classroomId,
    required this.classroomName,
    required this.lessonCount,
  });

  factory ScheduleRunClassroomSummaryModel.fromJson(Map<String, dynamic> json) {
    return ScheduleRunClassroomSummaryModel(
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      classroomName: json['classroom_name']?.toString() ?? '',
      lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScheduleRunCreateResult {
  final bool success;
  final String message;
  final int scheduleRunId;
  final String status;
  final DateTime createdAt;
  final int totalEntries;
  final List<ScheduleRunClassroomSummaryModel> classrooms;

  const ScheduleRunCreateResult({
    required this.success,
    required this.message,
    required this.scheduleRunId,
    required this.status,
    required this.createdAt,
    required this.totalEntries,
    required this.classrooms,
  });

  factory ScheduleRunCreateResult.fromJson(Map<String, dynamic> json) {
    return ScheduleRunCreateResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      scheduleRunId: (json['schedule_run_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      totalEntries: (json['total_entries'] as num?)?.toInt() ?? 0,
      classrooms: ((json['classrooms'] as List?) ?? const [])
          .map(
            (item) => ScheduleRunClassroomSummaryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
