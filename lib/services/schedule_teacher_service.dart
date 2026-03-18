import 'package:dio/dio.dart';

import '../models/schedule_builder_models.dart';
import '../models/schedule_teacher_model.dart';
import 'schedule_module_api_client.dart';

class ScheduleTeacherService {
  final ScheduleModuleApiClient _apiClient;

  ScheduleTeacherService({required ScheduleModuleApiClient apiClient})
    : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<List<ScheduleTeacherModel>> getTeachers() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/teachers/',
        queryParameters: {'skip': 0, 'limit': 200},
      );

      return _asList(response.data)
          .map(
            (item) => ScheduleTeacherModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacherModel> createTeacher(
    ScheduleTeacherPayload payload,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/teachers/',
        data: payload.toJson(),
      );
      return ScheduleTeacherModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacherModel> updateTeacher(
    int teacherId,
    ScheduleTeacherPayload payload,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/teachers/$teacherId',
        data: payload.toJson(),
      );
      return ScheduleTeacherModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteTeacher(int teacherId) async {
    try {
      await _apiClient.delete<void>('/api/v1/teachers/$teacherId');
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacherUploadResult> uploadTeachers({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/teachers/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {Headers.contentTypeHeader: 'multipart/form-data'},
        ),
      );

      return ScheduleTeacherUploadResult.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  ScheduleTeacherPayload fromLegacyTeacher(
    String name,
    int maxDailyHours,
    List<ScheduleUnavailableTime> unavailableTimes,
  ) {
    return ScheduleTeacherPayload(
      name: name,
      maxDailyHours: maxDailyHours,
      unavailableTimes: unavailableTimes
          .map(
            (item) => ScheduleTeacherUnavailableTime(
              day: item.day,
              hour: item.hour,
            ),
          )
          .toList(),
    );
  }
}
