import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/usecases/usecase.dart';

enum AuthStatus { authenticated, unauthenticated, authenticating, error }

class AuthProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthStatus _status = AuthStatus.unauthenticated;
  UserEntity? _currentUser;
  String? _errorMessage;

  AuthProvider({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase {
    _init();
  }

  AuthStatus get status => _status;
  UserEntity? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  Future<void> _init() async {
    // Session restoration Is handled by the repository internally or a specific UseCase
    // For now, we'll let the LoginUseCase/Repository handle the initial state
    // In a full implementation, we'd have a RestoreSessionUseCase
    _status = AuthStatus.unauthenticated; 
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _loginUseCase(LoginParams(email: email, password: password));

    return result.fold(
      (failure) {
        _status = AuthStatus.error;
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (user) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> logout() async {
    final result = await _logoutUseCase(const NoParams());
    
    result.fold(
      (failure) {
        // Optional: handle logout error
      },
      (_) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
      },
    );
  }
}
