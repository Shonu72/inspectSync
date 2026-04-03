import 'package:dio/dio.dart';
import 'failure.dart';

class ErrorHandler {
  static Failure handle(dynamic exception) {
    if (exception is DioException) {
      return _handleDioError(exception);
    } else if (exception is Failure) {
      return exception;
    } else {
      return ServerFailure(exception.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timed out. Please check your internet.');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'];
        
        switch (statusCode) {
          case 401:
            return AuthFailure(message ?? 'Incorrect email or password.');
          case 403:
            return const AuthFailure('You do not have permission to perform this action.');
          case 404:
            return const ServerFailure('Requested resource not found.');
          case 500:
            return const ServerFailure('Server is currently under maintenance. Please try again later.');
          default:
            return ServerFailure(message ?? 'An unexpected server error occurred ($statusCode).');
        }
        
      case DioExceptionType.cancel:
        return const ServerFailure('Request was cancelled.');
        
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection. Please check your data or Wi-Fi.');
        
      case DioExceptionType.unknown:
      default:
        return const ServerFailure('An unknown error occurred. Please try again.');
    }
  }
}
