import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/schedule_builder_models.dart';

class SchoolContextService {
  static final SchoolContextService _instance = SchoolContextService._internal();
  factory SchoolContextService() => _instance;
  SchoolContextService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Future<SchoolContext> getCurrentSchoolContext() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ScheduleApiException('Oturum bulunamadı.');
    }

    final metadata = user.userMetadata ?? const {};
    final schoolName = _stringValue(metadata['school_name']) ?? 'Okul Adı';

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
      // Tablo erişilemiyorsa metadata fallback'i kullanılır.
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
      'Aktif school_id bulunamadı. Kullanıcının okul üyeliği tanımlı olmalı.',
    );
  }

  String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
