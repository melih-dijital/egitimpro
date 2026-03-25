import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_builder_models.dart';

class SchoolContextService {
  static final SchoolContextService _instance = SchoolContextService._internal();

  factory SchoolContextService() => _instance;

  SchoolContextService._internal();

  static const String _baseUrl = 'https://api.dovizlens.online';
  static const String _bootstrapPath = '/api/v1/school-memberships/bootstrap';
  String? _lastBootstrapError;

  SupabaseClient get _client => Supabase.instance.client;

  Future<SchoolContext> getCurrentSchoolContext() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ScheduleApiException('Oturum bulunamadi.');
    }

    final metadata = _metadataOf(user);
    final schoolName = _stringValue(metadata['school_name']) ?? 'Okul Adi';

    _lastBootstrapError = null;
    final bootstrappedContext = await bootstrapCurrentSchoolContext();
    if (bootstrappedContext != null) {
      return bootstrappedContext;
    }

    Object? membershipLookupError;
    try {
      final response = await _client
          .from('user_school_memberships')
          .select('school_id, role')
          .eq('user_id', user.id)
          .order('id')
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return SchoolContext(
          schoolId: (response['school_id'] as num).toInt(),
          schoolName: schoolName,
          role: response['role']?.toString() ?? 'admin',
        );
      }
    } catch (e) {
      membershipLookupError = e;
      debugPrint('[SchoolContext] Supabase user_school_memberships sorgusu basarisiz: $e');
    }

    final fallbackSchoolId = _intValue(metadata['school_id']);
    if (fallbackSchoolId != null) {
      return SchoolContext(
        schoolId: fallbackSchoolId,
        schoolName: schoolName,
        role: _stringValue(metadata['school_role']) ?? 'admin',
      );
    }

    throw ScheduleApiException(
      _buildMissingContextMessage(
        bootstrapError: _lastBootstrapError,
        membershipLookupError: membershipLookupError,
      ),
    );
  }

  Future<SchoolContext?> bootstrapCurrentSchoolContext() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('[SchoolContext] Bootstrap: user null, atlanıyor.');
      return null;
    }

    // Her zaman session yenilemeyi dene — token süresi dolmuş olabilir
    try {
      final refreshed = await _client.auth.refreshSession();
      if (refreshed.session != null) {
        debugPrint('[SchoolContext] Session basariyla yenilendi.');
      }
    } catch (e) {
      debugPrint('[SchoolContext] Session yenileme basarisiz (devam ediliyor): $e');
    }

    final token = _client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('[SchoolContext] Bootstrap: token bos, atlanıyor.');
      return null;
    }

    final metadata = _metadataOf(user);
    final schoolName = _stringValue(metadata['school_name']) ?? 'Okul Adi';

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.post<dynamic>(_bootstrapPath);
      final rawData = response.data;
      if (rawData is! Map) {
        _lastBootstrapError = 'Bootstrap endpoint gecersiz veri dondurdu.';
        return null;
      }
      final data = Map<String, dynamic>.from(rawData);

      final schoolId = _intValue(data['school_id']);
      if (schoolId == null) {
        _lastBootstrapError = 'Bootstrap endpoint school_id dondurmedi.';
        return null;
      }

      final role = _stringValue(data['role']) ?? 'admin';
      await _persistSchoolMetadata(
        schoolId: schoolId,
        schoolName: schoolName,
        role: role,
      );

      return SchoolContext(
        schoolId: schoolId,
        schoolName: schoolName,
        role: role,
      );
    } catch (e) {
      if (e is DioException) {
        _lastBootstrapError = _formatDioError(e);
        debugPrint('[SchoolContext] Bootstrap endpoint basarisiz: '
            'status=${e.response?.statusCode}, '
            'body=${e.response?.data}');
      } else {
        _lastBootstrapError = e.toString();
        debugPrint('[SchoolContext] Bootstrap endpoint basarisiz: $e');
      }
      return null;
    }
  }

  String _buildMissingContextMessage({
    String? bootstrapError,
    Object? membershipLookupError,
  }) {
    final details = <String>[
      if (bootstrapError != null && bootstrapError.isNotEmpty)
        'Bootstrap hatasi: $bootstrapError',
      if (membershipLookupError != null)
        'Supabase uyelik sorgusu hatasi: ${membershipLookupError.toString()}',
    ];

    final suffix = details.isEmpty ? '' : ' Detay: ${details.join(' | ')}';
    return 'Okul uyeligi otomatik olusturulamadi. '
        'Bu genelde backend school-memberships/bootstrap endpointi hata verdiginde '
        've kullanici icin mevcut bir school_id bulunamadiginda olur.'
        '$suffix';
  }

  String _formatDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (responseData is Map) {
      final detail =
          responseData['detail']?.toString() ??
          responseData['message']?.toString();
      if (detail != null && detail.isNotEmpty) {
        return 'HTTP $statusCode: $detail';
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return 'HTTP $statusCode: ${responseData.trim()}';
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return 'HTTP ${statusCode ?? '-'}: ${error.message!.trim()}';
    }

    return 'HTTP ${statusCode ?? '-'}: Bilinmeyen bootstrap hatasi';
  }

  Future<void> _persistSchoolMetadata({
    required int schoolId,
    required String schoolName,
    required String role,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    final currentData = _metadataOf(user);
    final nextData = <String, dynamic>{
      ...currentData,
      'school_id': schoolId,
      'school_name': schoolName,
      'school_role': role,
    };

    final unchanged =
        _intValue(currentData['school_id']) == schoolId &&
        _stringValue(currentData['school_name']) == schoolName &&
        _stringValue(currentData['school_role']) == role;
    if (unchanged) {
      return;
    }

    try {
      await _client.auth.updateUser(UserAttributes(data: nextData));
    } catch (_) {
      // Metadata guncellemesi basarisiz olsa da okul context'i kullanilabilir.
    }
  }

  Map<String, dynamic> _metadataOf(User user) {
    return Map<String, dynamic>.from(
      user.userMetadata ?? <String, dynamic>{},
    );
  }

  String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  int? _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
