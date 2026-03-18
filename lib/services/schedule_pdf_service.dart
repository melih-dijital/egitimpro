import 'dart:typed_data';

import '../models/schedule_pdf_model.dart';
import 'schedule_module_api_client.dart';

class SchedulePdfService {
  final ScheduleModuleApiClient _apiClient;

  SchedulePdfService({required ScheduleModuleApiClient apiClient})
      : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<SchedulePdfGenerateResult> generateRunPdf(int runId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/schedule-runs/$runId/pdf',
      );
      return SchedulePdfGenerateResult.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<List<SchedulePdfModel>> getRunPdfs(int runId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/schedule-runs/$runId/pdfs',
      );
      return _asList(response.data)
          .map(
            (item) => SchedulePdfModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  String buildPdfUrl({
    required int schoolId,
    required int runId,
    required String fileName,
  }) {
    return '${ScheduleModuleApiClient.baseUrl}/files/$schoolId/$runId/$fileName';
  }

  Future<Uint8List> downloadPdfBytes(SchedulePdfModel pdf) async {
    try {
      final schoolId = await _apiClient.resolveSchoolId();

      final url = buildPdfUrl(
        schoolId: schoolId,
        runId: pdf.scheduleRunId,
        fileName: pdf.fileName,
      );

      return await _apiClient.downloadBytes(url);
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }
}
