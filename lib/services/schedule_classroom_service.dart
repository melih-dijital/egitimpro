import '../models/schedule_builder_models.dart';
import '../models/schedule_classroom_model.dart';
import 'schedule_module_api_client.dart';

class ScheduleClassroomService {
  final ScheduleModuleApiClient _apiClient;

  ScheduleClassroomService({required ScheduleModuleApiClient apiClient})
    : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<List<ScheduleClassroomModel>> getClassrooms() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/classrooms/',
        queryParameters: {'skip': 0, 'limit': 200},
      );

      return _asList(response.data)
          .map(
            (item) => ScheduleClassroomModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleClassroomModel> createClassroom(
    ScheduleClassroomPayload payload,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/classrooms/',
        data: payload.toJson(),
      );
      return ScheduleClassroomModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleClassroomModel> updateClassroom(
    int classroomId,
    ScheduleClassroomPayload payload,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/classrooms/$classroomId',
        data: payload.toJson(),
      );
      return ScheduleClassroomModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteClassroom(int classroomId) async {
    try {
      await _apiClient.delete<void>('/api/v1/classrooms/$classroomId');
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  ScheduleClassroomPayload fromLegacyClassroom(
    String name,
    int gradeLevel,
  ) {
    return ScheduleClassroomPayload(name: name, gradeLevel: gradeLevel);
  }
}
