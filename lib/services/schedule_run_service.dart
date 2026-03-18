import '../models/schedule_run_model.dart';
import 'schedule_module_api_client.dart';

class ScheduleRunService {
  final ScheduleModuleApiClient _apiClient;

  ScheduleRunService({required ScheduleModuleApiClient apiClient})
    : _apiClient = apiClient;

  List<dynamic> _asList(dynamic data) => List<dynamic>.from(data as List);

  Map<String, dynamic> _asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);

  Future<ScheduleRunCreateResult> createScheduleRun() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/schedule-runs/',
      );
      return ScheduleRunCreateResult.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<List<ScheduleRunModel>> getScheduleRuns() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/v1/schedule-runs/',
        queryParameters: {'skip': 0, 'limit': 100},
      );
      return _asList(response.data)
          .map(
            (item) => ScheduleRunModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }

  Future<ScheduleRunDetailModel> getScheduleRunDetail(int runId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/schedule-runs/$runId',
      );
      return ScheduleRunDetailModel.fromJson(_asMap(response.data));
    } catch (error) {
      throw _apiClient.toApiException(error);
    }
  }
}
