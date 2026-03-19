class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qsjodipcbdwjorvmbwbt.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzam9kaXBjYmR3am9ydm1id2J0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMzUzMDcsImV4cCI6MjA4NjgxMTMwN30.DTlxylsjWSljuHw6zhUYRpCtVk-pt7B_Gh-YCzEJNU8',
  );

  static bool get hasValidShape {
    return url.startsWith('https://') &&
        url.contains('.supabase.co') &&
        anonKey.isNotEmpty;
  }
}
