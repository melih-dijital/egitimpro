import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/schedule_builder_models.dart';
import 'schedule_module_api_client.dart';

class ScheduleBuilderService {
  final SchoolContext schoolContext;
  final ScheduleModuleApiClient _apiClient;

  ScheduleBuilderService({
    required this.schoolContext,
    ScheduleModuleApiClient? apiClient,
  }) : _apiClient =
           apiClient ?? ScheduleModuleApiClient(schoolContext: schoolContext);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Future<List<ScheduleTeacher>> getTeachers() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/teachers/',
        queryParameters: {'skip': 0, 'limit': 200},
      );
      return _asList(response.data)
          .map((item) => ScheduleTeacher.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacher> createTeacher({
    required String name,
    required int maxDailyHours,
    required List<ScheduleUnavailableTime> unavailableTimes,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/teachers/',
        data: {
          'name': name,
          'max_daily_hours': maxDailyHours,
          'unavailable_times': unavailableTimes.map((item) => item.toJson()).toList(),
        },
      );
      return ScheduleTeacher.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacher> updateTeacher({
    required int teacherId,
    required String name,
    required int maxDailyHours,
    required List<ScheduleUnavailableTime> unavailableTimes,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/teachers/$teacherId',
        data: {
          'name': name,
          'max_daily_hours': maxDailyHours,
          'unavailable_times': unavailableTimes.map((item) => item.toJson()).toList(),
        },
      );
      return ScheduleTeacher.fromJson(_asMap(response.data));
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

  Future<List<ScheduleClassroom>> getClassrooms() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/classrooms/',
        queryParameters: {'skip': 0, 'limit': 200},
      );
      return _asList(response.data)
          .map((item) => ScheduleClassroom.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleClassroom> createClassroom({
    required String name,
    required int gradeLevel,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/classrooms/',
        data: {'name': name, 'grade_level': gradeLevel},
      );
      return ScheduleClassroom.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleClassroom> updateClassroom({
    required int classroomId,
    required String name,
    required int gradeLevel,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/classrooms/$classroomId',
        data: {'name': name, 'grade_level': gradeLevel},
      );
      return ScheduleClassroom.fromJson(_asMap(response.data));
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

  Future<List<ScheduleCourse>> getCourses() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/courses/',
        queryParameters: {'skip': 0, 'limit': 500},
      );
      return _asList(response.data)
          .map((item) => ScheduleCourse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleCourse> createCourse({
    required String name,
    required int weeklyHours,
    required int classroomId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/courses/',
        data: {
          'name': name,
          'weekly_hours': weeklyHours,
          'classroom_id': classroomId,
        },
      );
      return ScheduleCourse.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleCourse> updateCourse({
    required int courseId,
    required String name,
    required int weeklyHours,
    required int classroomId,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/v1/courses/$courseId',
        data: {
          'name': name,
          'weekly_hours': weeklyHours,
          'classroom_id': classroomId,
        },
      );
      return ScheduleCourse.fromJson(_asMap(response.data));
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

  Future<List<ScheduleTeacherCourse>> getTeacherCourses() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/teacher-courses/',
      );
      return _asList(response.data)
          .map((item) => ScheduleTeacherCourse.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleTeacherCourse> createTeacherCourse({
    required int teacherId,
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/teacher-courses/',
        data: {'teacher_id': teacherId, 'course_id': courseId},
      );
      return ScheduleTeacherCourse.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteTeacherCourse({
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

  Future<ScheduleGenerationResult> generateSchedule() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/schedule-runs/',
      );
      return ScheduleGenerationResult.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<List<ScheduleRunBrief>> getScheduleRuns() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/schedule-runs/',
        queryParameters: {'skip': 0, 'limit': 100},
      );
      return _asList(response.data)
          .map((item) => ScheduleRunBrief.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleRunDetail> getScheduleRunDetail(int runId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/schedule-runs/$runId',
      );
      return ScheduleRunDetail.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<void> deleteScheduleRun(int runId) async {
    try {
      await _apiClient.delete<void>('/api/v1/schedule-runs/$runId');
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<List<SchedulePdfFile>> getRunPdfs(int runId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/schedule-runs/$runId/pdfs',
      );
      return _asList(response.data)
          .map((item) => SchedulePdfFile.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<Map<String, dynamic>> generateRunPdfs({
    required int runId,
    required String schoolName,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/schedule-runs/$runId/pdf',
      );
      return Map<String, dynamic>.from(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<List<ScheduleEntry>> getScheduleEntries({int? runId}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/schedules/',
        queryParameters: runId == null ? null : {'schedule_run_id': runId},
      );
      return _asList(response.data)
          .map((item) => ScheduleEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleDashboardData> getDashboardData() async {
    final results = await Future.wait([
      getTeachers(),
      getClassrooms(),
      getCourses(),
      getTeacherCourses(),
      getScheduleRuns(),
    ]);

    return ScheduleDashboardData(
      teacherCount: (results[0] as List).length,
      classroomCount: (results[1] as List).length,
      courseCount: (results[2] as List).length,
      mappingCount: (results[3] as List).length,
      runCount: (results[4] as List).length,
    );
  }

  String buildPdfUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    if (filePath.startsWith('/files/')) {
      return '${ScheduleModuleApiClient.baseUrl}$filePath';
    }

    return '${ScheduleModuleApiClient.baseUrl}/files/$filePath';
  }

  Future<Uint8List> downloadPdfBytes(String filePath) async {
    try {
      return await _apiClient.downloadBytes(buildPdfUrl(filePath));
    } on DioException catch (error) {
      throw _apiClient.toApiException(error);
    }
  }
}
