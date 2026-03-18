class ScheduleClassroomModel {
  final int id;
  final String name;
  final int gradeLevel;

  const ScheduleClassroomModel({
    required this.id,
    required this.name,
    required this.gradeLevel,
  });

  factory ScheduleClassroomModel.fromJson(Map<String, dynamic> json) {
    return ScheduleClassroomModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      gradeLevel: (json['grade_level'] as num?)?.toInt() ?? 1,
    );
  }
}

class ScheduleClassroomPayload {
  final String name;
  final int gradeLevel;

  const ScheduleClassroomPayload({
    required this.name,
    required this.gradeLevel,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'grade_level': gradeLevel,
  };
}
