import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  final Dio dio;
  static const String baseUrl = ApiEndpoints.baseUrl;

  ApiClient({
    required this.dio,
    required AuthInterceptor authInterceptor,
  }) {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.addAll([
      authInterceptor,
      TalkerDioLogger(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }
}
