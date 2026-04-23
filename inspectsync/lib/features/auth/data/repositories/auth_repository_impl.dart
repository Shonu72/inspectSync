import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  UserEntity? _currentUser;
  String? _token;

  AuthRepositoryImpl({required this.remoteDataSource, required this.storage});

  @override
  UserEntity? get currentUser => _currentUser;

  String? get token => _token;

  @override
  bool get isAuthenticated => _token != null;

  static const String _userKey = 'user';
  static const String _tokenKey = 'token';

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.login(email, password);
      await _saveAuthData(response.user, response.token);
      return Right(response.user);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      _currentUser = null;
      _token = null;
      await storage.delete(key: _userKey);
      await storage.delete(key: _tokenKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> restoreSession() async {
    try {
      final userJson = await storage.read(key: _userKey);
      final tokenValue = await storage.read(key: _tokenKey);

      if (userJson != null && tokenValue != null) {
        final userModel = UserModel.fromJson(jsonDecode(userJson));
        _currentUser = userModel;
        _token = tokenValue;
        return Right(_currentUser);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _saveAuthData(UserModel user, String token) async {
    _currentUser = user;
    _token = token;
    await storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    await storage.write(key: _tokenKey, value: token);
  }
}
