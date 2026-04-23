import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import '../../../sync/sync_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final SyncService syncService;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.restoreSessionUseCase,
    required this.syncService,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      emit(AuthAuthenticated(user));
      syncService.triggerImmediateSync();
    });
  }

  Future<void> logout() async {
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> checkStatus() async {
    final result = await restoreSessionUseCase(NoParams());

    result.fold((failure) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
        syncService.triggerImmediateSync();
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
}
