class ScheduleTeacherCourseModel {
  final int teacherId;
  final int courseId;
  final String teacherName;
  final String courseName;

  const ScheduleTeacherCourseModel({
    required this.teacherId,
    required this.courseId,
    required this.teacherName,
    required this.courseName,
  });

  factory ScheduleTeacherCourseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleTeacherCourseModel(
      teacherId: (json['teacher_id'] as num).toInt(),
      courseId: (json['course_id'] as num).toInt(),
      teacherName: json['teacher_name']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
    );
  }
}

class ScheduleTeacherCoursePayload {
  final int teacherId;
  final int courseId;

  const ScheduleTeacherCoursePayload({
    required this.teacherId,
    required this.courseId,
  });

  Map<String, dynamic> toJson() => {
    'teacher_id': teacherId,
    'course_id': courseId,
  };
}
