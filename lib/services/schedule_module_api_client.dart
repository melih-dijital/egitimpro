import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/schedule_builder_models.dart';
import 'auth_service.dart';
import 'school_context_service.dart';

class ScheduleModuleApiClient {
  static const String baseUrl = 'https://api.dovizlens.online';

  final AuthService _authService;
  final SchoolContextService _schoolContextService;
  final SchoolContext? _schoolContext;
  late final Dio _dio;

  ScheduleModuleApiClient({
    AuthService? authService,
    SchoolContextService? schoolContextService,
    SchoolContext? schoolContext,
    Dio? dio,
  }) : _authService = authService ?? AuthService(),
       _schoolContextService = schoolContextService ?? SchoolContextService(),
       _schoolContext = schoolContext {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: const {Headers.contentTypeHeader: Headers.jsonContentType},
          ),
        );

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = _authService.currentSession?.accessToken;
            if (token == null || token.isEmpty) {
              throw const ScheduleApiException('Geçerli erişim tokenı bulunamadı.');
            }

            final schoolId =
                _schoolContext?.schoolId ??
                (await _schoolContextService.getCurrentSchoolContext()).schoolId;

            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-School-Id'] = '$schoolId';
            options.headers.putIfAbsent(
              Headers.contentTypeHeader,
              () => Headers.jsonContentType,
            );

            handler.next(options);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: toApiException(error),
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Uint8List> downloadBytes(String pathOrUrl) async {
    final response = await _dio.get<List<int>>(
      pathOrUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  ScheduleApiException toApiException(Object error) {
    if (error is ScheduleApiException) {
      return error;
    }

    if (error is DioException) {
      final responseData = error.response?.data;
      String message = 'İşlem başarısız oldu';

      if (responseData is Map) {
        message =
            responseData['detail']?.toString() ??
            responseData['message']?.toString() ??
            message;
      } else if (responseData is String && responseData.trim().isNotEmpty) {
        message = responseData;
      } else if (error.error is ScheduleApiException) {
        message = (error.error as ScheduleApiException).message;
      } else if (error.message != null && error.message!.trim().isNotEmpty) {
        message = error.message!;
      }

      return ScheduleApiException(message, statusCode: error.response?.statusCode);
    }

    return ScheduleApiException(error.toString());
  }

  Future<int> resolveSchoolId() async {
    return _schoolContext?.schoolId ??
        (await _schoolContextService.getCurrentSchoolContext()).schoolId;
  }
}

/// Kullanım örneği:
/// final schoolContext = await SchoolContextService().getCurrentSchoolContext();
/// final client = ScheduleModuleApiClient(schoolContext: schoolContext);
/// final response = await client.get<List<dynamic>>('/api/v1/teachers/');
/// final teachers = (response.data ?? [])
///     .map((json) => ScheduleTeacher.fromJson(json as Map<String, dynamic>))
///     .toList();
