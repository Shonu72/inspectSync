import 'package:dio/dio.dart';
import 'package:talker/talker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:inspectsync/core/api/api_client.dart';
import 'package:inspectsync/core/api/interceptors/auth_interceptor.dart';

import 'package:inspectsync/main.dart';
import 'package:inspectsync/features/auth/presentation/screens/login_screen.dart';
import 'package:inspectsync/features/dashboard/presentation/screens/main_screen.dart';
import 'package:inspectsync/features/sync/presentation/screens/sync_status_screen.dart';
import 'package:inspectsync/features/sync/presentation/screens/conflict_resolution_screen.dart';
import 'package:inspectsync/core/db/app_database.dart';
import 'package:inspectsync/features/sync/sync_queue_manager.dart';
import 'package:inspectsync/features/sync/conflict_resolver.dart';
import 'package:inspectsync/features/sync/sync_service.dart';
import 'package:inspectsync/features/sync/presentation/providers/sync_controller.dart';
import 'package:inspectsync/core/network/connectivity_service.dart';
import 'package:inspectsync/features/tasks/data/task_local_datasource.dart';
import 'package:inspectsync/features/tasks/data/task_remote_datasource.dart';
import 'package:inspectsync/features/tasks/data/task_repository.dart';

void main() {
  testWidgets('Offline architecture stub test', (WidgetTester tester) async {
    final db = AppDatabase();
    final localTaskDs = TaskLocalDataSource(db);
    
    // Fixed: Pass required api client dependency for tests
    final remoteTaskDs = TaskRemoteDataSource(
      apiClient: ApiClient(
        dio: Dio(), 
        authInterceptor: AuthInterceptor(storage: const FlutterSecureStorage()),
        talker: Talker(),
      ),
    );
    
    final queueManager = SyncQueueManager(db);
    final conflictResolver = ConflictResolver(db);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final connectivityService = ConnectivityService();
    final syncService = SyncService(
      queueManager: queueManager,
      remote: remoteTaskDs,
      local: localTaskDs,
      conflictResolver: conflictResolver,
      connectivityService: connectivityService,
      prefs: prefs,
    );
    final syncController = SyncController(
      syncService,
      queueManager,
      db,
      connectivityService: connectivityService,
    );

    final taskRepository = TaskRepository(
      local: localTaskDs,
      remote: remoteTaskDs,
      syncService: syncService,
    );

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/dashboard', builder: (context, state) => MainScreen(syncController: syncController)),
        GoRoute(path: '/sync', builder: (context, state) => SyncStatusScreen(controller: syncController)),
        GoRoute(path: '/sync/conflict/:id', builder: (context, state) => ConflictResolutionScreen(conflict: state.extra as Conflict, db: db)),
      ],
    );

    await tester.pumpWidget(MyApp(router: router, taskRepository: taskRepository));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
