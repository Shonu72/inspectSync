import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

import '../../core/db/app_database.dart';
import '../../features/tasks/data/task_local_datasource.dart';
import '../../features/tasks/data/task_remote_datasource.dart';
import '../../core/network/connectivity_service.dart';
import 'conflict_resolver.dart';
import 'sync_queue_manager.dart';

class SyncProgress {
  final int totalItems;
  final int completedItems;
  final String currentItemDescription;
  final bool isSyncing;

  SyncProgress({
    required this.totalItems,
    required this.completedItems,
    required this.currentItemDescription,
    required this.isSyncing,
  });

  double get progress => totalItems == 0 ? 0 : completedItems / totalItems;
}

class SyncService {
  final SyncQueueManager queueManager;
  final TaskRemoteDataSource remote;
  final TaskLocalDataSource local;
  final ConflictResolver conflictResolver;
  final ConnectivityService connectivityService;

  bool _isSyncing = false;
  String? _lastSyncedAt;

  final SharedPreferences _prefs;
  static const String _lastSyncKey = 'last_successful_sync';
  
  DateTime? _lastSuccessfulSync;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  final _progressController = StreamController<SyncProgress>.broadcast();

  Stream<SyncProgress> get progressStream => _progressController.stream;

  SyncService({
    required this.queueManager,
    required this.remote,
    required this.local,
    required this.conflictResolver,
    required this.connectivityService,
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _loadLastSyncTime();
  }

  void _loadLastSyncTime() {
    final timestamp = _prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      _lastSuccessfulSync = DateTime.parse(timestamp);
    }
  }

  /// Triggered whenever a user makes a change or background worker wakes up
  void triggerImmediateSync() {
    if (_isSyncing) return;
    _runSyncRoutine();
  }

  Future<void> _runSyncRoutine() async {
    if (_isSyncing) return;
    
    // Check connectivity before starting
    if (connectivityService.isOffline) {
      debugPrint('SyncService: Skipping sync routine — device is offline');
      return;
    }

    _isSyncing = true;

    try {
      // --- PHASE 1: PUSH CHANGES ---
      final queueItems = await queueManager.getPendingQueue();
      final pushTotal = queueItems.length;

      if (pushTotal > 0) {
        _progressController.add(SyncProgress(
          totalItems: pushTotal,
          completedItems: 0,
          currentItemDescription: 'Uploading local changes...',
          isSyncing: true,
        ));

        final List<Map<String, dynamic>> changes = [];
        for (final item in queueItems) {
          final payloadMap = Map<String, dynamic>.from(jsonDecode(item.payload));
          
          // Map internal priority int to backend enum strings
          if (payloadMap.containsKey('priority')) {
            final pInt = payloadMap['priority'] as int;
            final pStr = pInt == 0 ? 'HIGH' : (pInt == 2 ? 'LOW' : 'MED');
            payloadMap['priority'] = pStr;
          }

          changes.add({
            'entityId': item.entityId,
            'entityType': item.entityType,
            'operation': item.action,
            'payload': payloadMap,
            'idempotencyKey': 'sync-${item.id}-${item.createdAt.millisecondsSinceEpoch}',
            'clientVersion': payloadMap['version'] ?? 1,
          });
        }

        final deviceId = await _getDeviceId();
        final batchPayload = {
          'device_id': deviceId,
          'last_synced_at': _lastSyncedAt,
          'changes': changes,
        };

        final result = await remote.syncBatch(batchPayload);

        // Process Push Successes
        final List<dynamic> syncedResults = result['synced'] ?? [];
        for (final success in syncedResults) {
          final entityId = success['entityId'];
          final queueItem = queueItems.firstWhere((i) => i.entityId == entityId);
          await queueManager.markQueueCompleted(queueItem.id);
          await local.markTaskSynced(entityId, newVersion: success['version']);
        }

        // Process Push Conflicts
        final List<dynamic> conflictResults = result['conflicts'] ?? [];
        for (final conflict in conflictResults) {
          await conflictResolver.detectAndHandleConflict(
            conflict['entityId'],
            conflict['clientData'],
            conflict['serverData'],
          );
          final queueItem = queueItems.firstWhere((i) => i.entityId == conflict['entityId']);
          await queueManager.markQueueFailed(queueItem.id, queueItem.retryCount);
        }

        // Process Push Failures
        final List<dynamic> failedResults = result['failed'] ?? [];
        for (final failure in failedResults) {
          final queueItem = queueItems.firstWhere((i) => i.entityId == failure['entityId']);
          await queueManager.markQueueFailed(queueItem.id, queueItem.retryCount);
        }
      }

      // Re-verify connectivity before Pull phase
      if (connectivityService.isOffline) {
        debugPrint('SyncService: Skipping pull phase — device went offline');
        _progressController.add(SyncProgress(
          totalItems: 1,
          completedItems: 1,
          currentItemDescription: 'Push completed, Pull skipped (Offline)',
          isSyncing: false,
        ));
        return;
      }

      // --- PHASE 2: PULL CHANGES ---
      _progressController.add(SyncProgress(
        totalItems: 1,
        completedItems: 0,
        currentItemDescription: 'Checking for remote updates...',
        isSyncing: true,
      ));

      final pullResult = await remote.pullBatch(_lastSyncedAt);
      
      // Update/Insert Remote Tasks
      final List<dynamic> remoteTasks = pullResult['tasks'] ?? [];
      for (final rawTask in remoteTasks) {
        final String taskId = rawTask['id'];
        
        // Safety: Don't overwrite if we have pending local changes for this task
        if (await queueManager.hasPending(taskId)) {
          debugPrint('SyncService: Skipping pull-update for $taskId - local changes pending');
          continue;
        }

        // Map backend enum string back to internal int
        final pStr = rawTask['priority']?.toString().toUpperCase() ?? 'MED';
        final pInt = pStr == 'HIGH' ? 0 : (pStr == 'LOW' ? 2 : 1);

        // Map backend JSON to Drift Task
        final task = Task(
          id: taskId,
          title: rawTask['title'],
          description: rawTask['description'],
          lat: (rawTask['lat']?.toDouble()),
          lng: (rawTask['lng']?.toDouble()),
          status: rawTask['status'] ?? 'pending',
          priority: pInt,
          version: rawTask['version'] ?? 1,
          isSynced: true,
          updatedAt: DateTime.parse(rawTask['updatedAt']),
          createdAt: DateTime.parse(rawTask['createdAt']),
        );
        await local.upsertTaskFromServer(task);
      }

      // Process Remote Deletions
      final List<dynamic> deletedIds = pullResult['deletedIds'] ?? [];
      for (final id in deletedIds) {
        final String taskId = id.toString();
        if (await queueManager.hasPending(taskId)) {
          debugPrint('SyncService: Skipping pull-delete for $taskId - local changes pending');
          continue;
        }
        await local.deleteTaskLocally(taskId);
      }

      // 3. Finalize
      _lastSyncedAt = pullResult['serverTime'];
      _lastSuccessfulSync = DateTime.now();
      await _prefs.setString(_lastSyncKey, _lastSuccessfulSync!.toIso8601String());
      
      _progressController.add(SyncProgress(
        totalItems: 1,
        completedItems: 1,
        currentItemDescription: 'Synchronization successful',
        isSyncing: false,
      ));
    } catch (e) {
      debugPrint('Sync Routine Failed: $e');
      _progressController.add(SyncProgress(
        totalItems: 0,
        completedItems: 0,
        currentItemDescription: 'Sync error: $e',
        isSyncing: false,
      ));
    } finally {
      _isSyncing = false;
    }
  }

  Future<String> _getDeviceId() async {
    return 'device-flutter-v1';
  }

  void dispose() {
    _progressController.close();
  }
}
