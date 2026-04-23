import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<UserModel> register(String email, String name, String password);
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      return AuthResponseModel.fromJson(data);
    } else {
      throw Exception('Failed to login: ${response.data['message']}');
    }
  }

  @override
  Future<UserModel> register(String email, String name, String password) async {
    final response = await apiClient.post(
      ApiEndpoints.register,
      data: {'email': email, 'name': name, 'password': password},
    );

    if (response.statusCode == 201) {
      final data = response.data['data'];
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to register: ${response.data['message']}');
    }
  }
}
