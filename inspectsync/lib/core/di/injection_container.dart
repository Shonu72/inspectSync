import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../api/api_client.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../db/app_database.dart';
import '../network/connectivity_service.dart';
import '../theme/theme_cubit.dart';
import '../security/security_cubit.dart';
import '../util/logger.dart';
import '../services/media_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/sync/sync_service.dart';
import '../../features/sync/sync_queue_manager.dart';
import '../../features/sync/conflict_resolver.dart';
import '../../features/sync/presentation/providers/sync_controller.dart';
import '../../features/tasks/data/task_local_datasource.dart';
import '../../features/tasks/data/task_remote_datasource.dart';
import '../../features/tasks/data/task_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  final talker = AppLogger.talker;
  sl.registerLazySingleton(() => talker);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  const storage = FlutterSecureStorage();
  sl.registerLazySingleton(() => storage);

  sl.registerLazySingleton(() => ThemeCubit(sl()));
  sl.registerLazySingleton(() => SecurityCubit(sl()));

  final dio = Dio();
  sl.registerLazySingleton(() => dio);

  sl.registerLazySingleton(() => AuthInterceptor(storage: sl()));
  sl.registerLazySingleton(
    () => ApiClient(dio: sl(), authInterceptor: sl(), talker: sl()),
  );

  sl.registerLazySingleton(() => AppDatabase());
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => MediaService(sl()));

  // Features - Auth
  // DataSources
  sl.registerLazySingleton<IAuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), storage: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      restoreSessionUseCase: sl(),
      syncService: sl(),
    ),
  );

  // Features - Sync & Tasks
  sl.registerLazySingleton(() => TaskLocalDataSource(sl()));
  sl.registerLazySingleton(() => TaskRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton(() => SyncQueueManager(sl()));
  sl.registerLazySingleton(() => ConflictResolver(sl()));

  sl.registerLazySingleton(
    () => SyncService(
      queueManager: sl(),
      remote: sl<TaskRemoteDataSource>(),
      local: sl<TaskLocalDataSource>(),
      conflictResolver: sl(),
      connectivityService: sl(),
      prefs: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => TaskRepository(
      local: sl<TaskLocalDataSource>(),
      remote: sl<TaskRemoteDataSource>(),
      syncService: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => SyncController(
      sl(),
      sl(),
      sl(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );
}
