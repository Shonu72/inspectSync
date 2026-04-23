import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class TaskRemoteDataSource {
  final ApiClient apiClient;

  TaskRemoteDataSource({required this.apiClient});

  /// Sends a batch of offline changes to the server for processing.
  /// Standardized format: { "device_id": "...", "last_synced_at": "...", "changes": [...] }
  Future<Map<String, dynamic>> syncBatch(Map<String, dynamic> payload) async {
    final response = await apiClient.post(ApiEndpoints.syncPush, data: payload);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
    }

    throw Exception('Failed to push sync batch: ${response.statusMessage}');
  }

  /// Pulls delta changes from the server.
  Future<Map<String, dynamic>> pullBatch(String? sinceTimestamp) async {
    final response = await apiClient.get(
      ApiEndpoints.syncPull,
      queryParameters: sinceTimestamp != null
          ? {'since': sinceTimestamp}
          : null,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data['data'] as Map<String, dynamic>;
      }
    }

    throw Exception('Failed to pull sync batch: ${response.statusMessage}');
  }

  Future<dynamic> fetchLatestServerTaskData(String taskId) async {
    final response = await apiClient.get('${ApiEndpoints.tasks}/$taskId');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return data['data'];
      }
    }
    return null;
  }
}
