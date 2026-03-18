class SchoolContext {
  final int schoolId;
  final String schoolName;
  final String role;

  const SchoolContext({
    required this.schoolId,
    required this.schoolName,
    required this.role,
  });
}

class ScheduleApiException implements Exception {
  final String message;
  final int? statusCode;

  const ScheduleApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ScheduleUnavailableTime {
  final int day;
  final int hour;

  const ScheduleUnavailableTime({required this.day, required this.hour});

  factory ScheduleUnavailableTime.fromJson(Map<String, dynamic> json) {
    return ScheduleUnavailableTime(
      day: (json['day'] as num?)?.toInt() ?? 0,
      hour: (json['hour'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {'day': day, 'hour': hour};
}

class ScheduleTeacher {
  final int id;
  final String name;
  final int maxDailyHours;
  final List<ScheduleUnavailableTime> unavailableTimes;

  const ScheduleTeacher({
    required this.id,
    required this.name,
    required this.maxDailyHours,
    required this.unavailableTimes,
  });

  factory ScheduleTeacher.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacher(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      maxDailyHours: (json['max_daily_hours'] as num?)?.toInt() ?? 8,
      unavailableTimes: ((json['unavailable_times'] as List?) ?? const [])
          .map((item) => ScheduleUnavailableTime.fromJson(item))
          .toList(),
    );
  }
}

class ScheduleClassroom {
  final int id;
  final String name;
  final int gradeLevel;

  const ScheduleClassroom({
    required this.id,
    required this.name,
    required this.gradeLevel,
  });

  factory ScheduleClassroom.fromJson(Map<String, dynamic> json) {
    return ScheduleClassroom(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      gradeLevel: (json['grade_level'] as num?)?.toInt() ?? 1,
    );
  }
}

class ScheduleCourse {
  final int id;
  final String name;
  final int weeklyHours;
  final int classroomId;
  final String classroomName;

  const ScheduleCourse({
    required this.id,
    required this.name,
    required this.weeklyHours,
    required this.classroomId,
    required this.classroomName,
  });

  factory ScheduleCourse.fromJson(Map<String, dynamic> json) {
    return ScheduleCourse(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      weeklyHours: (json['weekly_hours'] as num?)?.toInt() ?? 1,
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      classroomName: json['classroom_name']?.toString() ?? '',
    );
  }
}

class ScheduleTeacherCourse {
  final int teacherId;
  final int courseId;
  final String teacherName;
  final String courseName;

  const ScheduleTeacherCourse({
    required this.teacherId,
    required this.courseId,
    required this.teacherName,
    required this.courseName,
  });

  factory ScheduleTeacherCourse.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacherCourse(
      teacherId: (json['teacher_id'] as num).toInt(),
      courseId: (json['course_id'] as num).toInt(),
      teacherName: json['teacher_name']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
    );
  }
}

class ScheduleRunBrief {
  final int id;
  final DateTime createdAt;
  final String status;

  const ScheduleRunBrief({
    required this.id,
    required this.createdAt,
    required this.status,
  });

  factory ScheduleRunBrief.fromJson(Map<String, dynamic> json) {
    return ScheduleRunBrief(
      id: (json['id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'unknown',
    );
  }
}

class ScheduleRunDetail {
  final int id;
  final int schoolId;
  final String createdByUserId;
  final DateTime createdAt;
  final String status;
  final Map<String, dynamic> meta;

  const ScheduleRunDetail({
    required this.id,
    required this.schoolId,
    required this.createdByUserId,
    required this.createdAt,
    required this.status,
    required this.meta,
  });

  factory ScheduleRunDetail.fromJson(Map<String, dynamic> json) {
    return ScheduleRunDetail(
      id: (json['id'] as num).toInt(),
      schoolId: (json['school_id'] as num?)?.toInt() ?? 0,
      createdByUserId: json['created_by_user_id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      status: json['status']?.toString() ?? 'unknown',
      meta: Map<String, dynamic>.from(json['meta'] as Map? ?? const {}),
    );
  }
}

class ScheduleRunClassroomSummary {
  final int classroomId;
  final String classroomName;
  final int lessonCount;

  const ScheduleRunClassroomSummary({
    required this.classroomId,
    required this.classroomName,
    required this.lessonCount,
  });

  factory ScheduleRunClassroomSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleRunClassroomSummary(
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      classroomName: json['classroom_name']?.toString() ?? '',
      lessonCount: (json['lesson_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScheduleGenerationResult {
  final bool success;
  final String message;
  final int scheduleRunId;
  final String status;
  final DateTime createdAt;
  final int totalEntries;
  final List<ScheduleRunClassroomSummary> classrooms;

  const ScheduleGenerationResult({
    required this.success,
    required this.message,
    required this.scheduleRunId,
    required this.status,
    required this.createdAt,
    required this.totalEntries,
    required this.classrooms,
  });

  factory ScheduleGenerationResult.fromJson(Map<String, dynamic> json) {
    return ScheduleGenerationResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      scheduleRunId: (json['schedule_run_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      totalEntries: (json['total_entries'] as num?)?.toInt() ?? 0,
      classrooms: ((json['classrooms'] as List?) ?? const [])
          .map((item) => ScheduleRunClassroomSummary.fromJson(item))
          .toList(),
    );
  }
}

class SchedulePdfFile {
  final int id;
  final int schoolId;
  final int scheduleRunId;
  final int classroomId;
  final String filePath;
  final DateTime createdAt;

  const SchedulePdfFile({
    required this.id,
    required this.schoolId,
    required this.scheduleRunId,
    required this.classroomId,
    required this.filePath,
    required this.createdAt,
  });

  factory SchedulePdfFile.fromJson(Map<String, dynamic> json) {
    return SchedulePdfFile(
      id: (json['id'] as num).toInt(),
      schoolId: (json['school_id'] as num?)?.toInt() ?? 0,
      scheduleRunId: (json['schedule_run_id'] as num?)?.toInt() ?? 0,
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      filePath: json['file_path']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  String get fileName {
    final parts = filePath.split('/');
    return parts.isEmpty ? filePath : parts.last;
  }
}

class ScheduleEntry {
  final int id;
  final int classroomId;
  final String classroomName;
  final int teacherId;
  final String teacherName;
  final int courseId;
  final String courseName;
  final int day;
  final int hour;
  final int scheduleRunId;

  const ScheduleEntry({
    required this.id,
    required this.classroomId,
    required this.classroomName,
    required this.teacherId,
    required this.teacherName,
    required this.courseId,
    required this.courseName,
    required this.day,
    required this.hour,
    required this.scheduleRunId,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      classroomName: json['classroom_name']?.toString() ?? '',
      teacherId: (json['teacher_id'] as num?)?.toInt() ?? 0,
      teacherName: json['teacher_name']?.toString() ?? '',
      courseId: (json['course_id'] as num?)?.toInt() ?? 0,
      courseName: json['course_name']?.toString() ?? '',
      day: (json['day'] as num?)?.toInt() ?? 0,
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      scheduleRunId: (json['schedule_run_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScheduleDashboardData {
  final int teacherCount;
  final int classroomCount;
  final int courseCount;
  final int mappingCount;
  final int runCount;

  const ScheduleDashboardData({
    required this.teacherCount,
    required this.classroomCount,
    required this.courseCount,
    required this.mappingCount,
    required this.runCount,
  });
}
