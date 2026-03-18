class SchedulePdfModel {
  final int id;
  final int scheduleRunId;
  final String fileName;
  final String filePath;
  final DateTime createdAt;

  const SchedulePdfModel({
    required this.id,
    required this.scheduleRunId,
    required this.fileName,
    required this.filePath,
    required this.createdAt,
  });

  factory SchedulePdfModel.fromJson(Map<String, dynamic> json) {
    return SchedulePdfModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      scheduleRunId: (json['schedule_run_id'] as num?)?.toInt() ?? 0,
      fileName: json['file_name']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SchedulePdfGenerateResult {
  final bool success;
  final String message;

  const SchedulePdfGenerateResult({
    required this.success,
    required this.message,
  });

  factory SchedulePdfGenerateResult.fromJson(Map<String, dynamic> json) {
    return SchedulePdfGenerateResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'PDF olusturma islemi tamamlandi.',
    );
  }
}
