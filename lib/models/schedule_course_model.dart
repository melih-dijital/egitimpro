class ScheduleCourseModel {
  final int id;
  final String name;
  final int weeklyHours;
  final int classroomId;
  final String classroomName;

  const ScheduleCourseModel({
    required this.id,
    required this.name,
    required this.weeklyHours,
    required this.classroomId,
    required this.classroomName,
  });

  factory ScheduleCourseModel.fromJson(Map<String, dynamic> json) {
    return ScheduleCourseModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      weeklyHours: (json['weekly_hours'] as num?)?.toInt() ?? 1,
      classroomId: (json['classroom_id'] as num?)?.toInt() ?? 0,
      classroomName: json['classroom_name']?.toString() ?? '',
    );
  }
}

class ScheduleCoursePayload {
  final String name;
  final int weeklyHours;
  final int classroomId;

  const ScheduleCoursePayload({
    required this.name,
    required this.weeklyHours,
    required this.classroomId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'weekly_hours': weeklyHours,
    'classroom_id': classroomId,
  };
}
