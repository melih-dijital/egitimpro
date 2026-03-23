/// Auth Service
/// Supabase authentication servisi

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'school_context_service.dart';

/// Supabase kimlik dogrulama servisi
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? schoolName,
  }) async {
    final redirectTo = _getRedirectUrl();

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: redirectTo,
      data: {
        if (displayName != null) 'display_name': displayName,
        if (schoolName != null) 'school_name': schoolName,
      },
    );

    if (response.session != null) {
      await _ensureSchoolMembership();
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _ensureSchoolMembership();
    return response;
  }

  Future<bool> signInWithGoogle() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getRedirectUrl(),
      );
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  Future<bool> signInWithGithub() async {
    try {
      return await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: _getRedirectUrl(),
      );
    } catch (e) {
      debugPrint('GitHub sign in error: $e');
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _getRedirectUrl(),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> _ensureSchoolMembership() async {
    try {
      await SchoolContextService().bootstrapCurrentSchoolContext();
    } catch (_) {
      // Kimlik doğrulama akışı üyelik bootstrap başarısız olsa da devam etsin.
    }
  }

  String? _getRedirectUrl() {
    if (!kIsWeb) {
      return null;
    }

    return Uri.base
        .replace(path: '/auth/callback', queryParameters: <String, String>{})
        .toString();
  }

  static String mapErrorToMessage(Object error) {
    if (error is AuthException) {
      final message = error.message;

      if (message.contains('email rate limit exceeded')) {
        return 'Cok fazla dogrulama e-postasi gonderildi. Bir sure bekleyip tekrar deneyin.';
      }

      if (message.contains('over_email_send_rate_limit')) {
        return 'E-posta gonderim limiti asildi. Biraz bekleyip yeniden deneyin.';
      }

      return message;
    }

    final message = error.toString();

    if (message.contains('Failed to fetch') ||
        message.contains('Failed host lookup') ||
        message.contains('ClientException')) {
      return 'Supabase sunucusuna ulasilamiyor. Proje URL\'si hatali olabilir veya DNS/ag erisimi kesilmis olabilir.';
    }

    if (message.contains('XMLHttpRequest error')) {
      return 'Tarayici istegi engelledi. Supabase proje adresini ve ag erisimini kontrol edin.';
    }

    if (message.contains('email rate limit exceeded') ||
        message.contains('over_email_send_rate_limit')) {
      return 'E-posta gonderim limiti asildi. Biraz bekleyip yeniden deneyin.';
    }

    return 'Bir hata olustu. Lutfen tekrar deneyin.';
  }
}
