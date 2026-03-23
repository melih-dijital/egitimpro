import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_builder_models.dart';

class SchoolContextService {
  static final SchoolContextService _instance = SchoolContextService._internal();

  factory SchoolContextService() => _instance;

  SchoolContextService._internal();

  static const String _baseUrl = 'https://api.dovizlens.online';
  static const String _bootstrapPath = '/api/v1/school-memberships/bootstrap';

  SupabaseClient get _client => Supabase.instance.client;

  Future<SchoolContext> getCurrentSchoolContext() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ScheduleApiException('Oturum bulunamadi.');
    }

    final metadata = _metadataOf(user);
    final schoolName = _stringValue(metadata['school_name']) ?? 'Okul Adi';

    final bootstrappedContext = await bootstrapCurrentSchoolContext();
    if (bootstrappedContext != null) {
      return bootstrappedContext;
    }

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
    } catch (_) {
      // Supabase tarafinda tablo yoksa metadata fallback'i kullanilir.
    }

    final fallbackSchoolId = _intValue(metadata['school_id']);
    if (fallbackSchoolId != null) {
      return SchoolContext(
        schoolId: fallbackSchoolId,
        schoolName: schoolName,
        role: _stringValue(metadata['school_role']) ?? 'admin',
      );
    }

    throw const ScheduleApiException(
      'Okul uyeligi otomatik olusturulamadi. Lutfen tekrar deneyin.',
    );
  }

  Future<SchoolContext?> bootstrapCurrentSchoolContext() async {
    final user = _client.auth.currentUser;
    final token = _client.auth.currentSession?.accessToken;
    if (user == null || token == null || token.isEmpty) {
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
        return null;
      }
      final data = Map<String, dynamic>.from(rawData);

      final schoolId = _intValue(data['school_id']);
      if (schoolId == null) {
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
    } catch (_) {
      return null;
    }
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
