class ScheduleApiConfig {
  const ScheduleApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'SCHEDULE_API_BASE_URL',
    defaultValue: 'https://api.dovizlens.online',
  );
}
