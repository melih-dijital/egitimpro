import '../models/schedule_teacher_course_model.dart';
import 'schedule_module_api_client.dart';

class ScheduleTeacherCourseService {
  final ScheduleModuleApiClient _apiClient;

  ScheduleTeacherCourseService({required ScheduleModuleApiClient apiClient})
    : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<List<ScheduleTeacherCourseModel>> getTeacherCourseMappings() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/teacher-courses/',
      );

      return _asList(response.data)
          .map(
            (item) => ScheduleTeacherCourseModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacherCourseModel> createTeacherCourseMapping(
    ScheduleTeacherCoursePayload payload,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/teacher-courses/',
        data: payload.toJson(),
      );
      return ScheduleTeacherCourseModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteTeacherCourseMapping({
    required int teacherId,
    required int courseId,
  }) async {
    try {
      await _apiClient.delete<void>(
        '/api/v1/teacher-courses/$teacherId/$courseId',
      );
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }
}
