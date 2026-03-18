import '../models/schedule_builder_models.dart';
import '../models/schedule_course_model.dart';
import 'schedule_module_api_client.dart';

class ScheduleCourseService {
  final ScheduleModuleApiClient _apiClient;

  ScheduleCourseService({required ScheduleModuleApiClient apiClient})
    : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<List<ScheduleCourseModel>> getCourses() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/courses/',
        queryParameters: {'skip': 0, 'limit': 500},
      );

      return _asList(response.data)
          .map(
            (item) => ScheduleCourseModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleCourseModel> createCourse(ScheduleCoursePayload payload) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/courses/',
        data: payload.toJson(),
      );
      return ScheduleCourseModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleCourseModel> updateCourse(
    int courseId,
    ScheduleCoursePayload payload,
  ) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/courses/$courseId',
        data: payload.toJson(),
      );
      return ScheduleCourseModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteCourse(int courseId) async {
    try {
      await _apiClient.delete<void>('/api/v1/courses/$courseId');
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  ScheduleCoursePayload fromLegacyCourse(
    String name,
    int weeklyHours,
    int classroomId,
  ) {
    return ScheduleCoursePayload(
      name: name,
      weeklyHours: weeklyHours,
      classroomId: classroomId,
    );
  }
}
