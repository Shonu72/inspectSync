import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inspectsync/features/sync/sync_service.dart';
import 'package:inspectsync/features/sync/sync_queue_manager.dart';
import 'package:inspectsync/features/sync/conflict_resolver.dart';
import 'package:inspectsync/features/tasks/data/task_remote_datasource.dart';
import 'package:inspectsync/features/tasks/data/task_local_datasource.dart';
import 'package:inspectsync/core/network/connectivity_service.dart';
import 'package:inspectsync/core/db/app_database.dart';

// Mocks
class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

class MockConflictResolver extends Mock implements ConflictResolver {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SyncService syncService;
  late MockSyncQueueManager mockQueueManager;
  late MockTaskRemoteDataSource mockRemote;
  late MockTaskLocalDataSource mockLocal;
  late MockConflictResolver mockConflictResolver;
  late MockConnectivityService mockConnectivityService;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockQueueManager = MockSyncQueueManager();
    mockRemote = MockTaskRemoteDataSource();
    mockLocal = MockTaskLocalDataSource();
    mockConflictResolver = MockConflictResolver();
    mockConnectivityService = MockConnectivityService();
    mockPrefs = MockSharedPreferences();

    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockConnectivityService.isOffline).thenReturn(false);
    when(
      () => mockQueueManager.hasPending(any()),
    ).thenAnswer((_) async => false);

    syncService = SyncService(
      queueManager: mockQueueManager,
      remote: mockRemote,
      local: mockLocal,
      conflictResolver: mockConflictResolver,
      connectivityService: mockConnectivityService,
      prefs: mockPrefs,
    );
  });

  group('SyncService - Push Phase', () {
    test('Successful push should mark items as completed', () async {
      // Arrange
      final mockItem = SyncQueueData(
        id: 1,
        entityId: 'task-123',
        entityType: 'task',
        action: 'update',
        payload: jsonEncode({'title': 'Updated Task', 'version': 1}),
        status: 'pending',
        retryCount: 0,
        createdAt: DateTime.now(),
      );

      when(
        () => mockQueueManager.getPendingQueue(),
      ).thenAnswer((_) async => [mockItem]);
      when(() => mockRemote.syncBatch(any())).thenAnswer(
        (_) async => {
          'synced': [
            {'entityId': 'task-123', 'version': 2},
          ],
          'conflicts': [],
          'failed': [],
        },
      );
      when(
        () => mockQueueManager.markQueueCompleted(any()),
      ).thenAnswer((_) async => Future.value());
      when(
        () => mockLocal.markTaskSynced(
          any(),
          newVersion: any(named: 'newVersion'),
        ),
      ).thenAnswer((_) async => Future.value());
      when(() => mockRemote.pullBatch(any())).thenAnswer(
        (_) async => {
          'tasks': [],
          'deletedIds': [],
          'serverTime': '2024-01-01T00:00:00Z',
        },
      );

      // Act
      await syncService.triggerImmediateSync();

      // Assert
      verify(() => mockQueueManager.markQueueCompleted(1)).called(1);
      verify(
        () => mockLocal.markTaskSynced('task-123', newVersion: 2),
      ).called(1);
    });

    test('Conflict in push should trigger conflict resolution', () async {
      // Arrange
      final mockItem = SyncQueueData(
        id: 1,
        entityId: 'task-456',
        entityType: 'task',
        action: 'update',
        payload: jsonEncode({'title': 'Conflicting Task', 'version': 1}),
        status: 'pending',
        retryCount: 0,
        createdAt: DateTime.now(),
      );

      when(
        () => mockQueueManager.getPendingQueue(),
      ).thenAnswer((_) async => [mockItem]);
      when(() => mockRemote.syncBatch(any())).thenAnswer(
        (_) async => {
          'synced': [],
          'conflicts': [
            {
              'entityId': 'task-456',
              'clientData': {'title': 'Conflicting Task'},
              'serverData': {'title': 'Server Task'},
            },
          ],
          'failed': [],
        },
      );
      when(
        () => mockConflictResolver.detectAndHandleConflict(any(), any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockQueueManager.markQueueFailed(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockRemote.pullBatch(any())).thenAnswer(
        (_) async => {
          'tasks': [],
          'deletedIds': [],
          'serverTime': '2024-01-01T00:00:00Z',
        },
      );

      // Act
      await syncService.triggerImmediateSync();

      // Assert
      verify(
        () => mockConflictResolver.detectAndHandleConflict(
          'task-456',
          {'title': 'Conflicting Task'},
          {'title': 'Server Task'},
        ),
      ).called(1);
      verify(() => mockQueueManager.markQueueFailed(1, 0)).called(1);
    });
  });

  group('SyncService - Connectivity', () {
    test('Should skip sync when offline', () async {
      // Arrange
      when(() => mockConnectivityService.isOffline).thenReturn(true);

      // Act
      await syncService.triggerImmediateSync();

      // Assert
      verifyNever(() => mockQueueManager.getPendingQueue());
    });
  });
}
