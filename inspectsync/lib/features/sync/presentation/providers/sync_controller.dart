import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../sync_queue_manager.dart';
import '../../sync_service.dart';

class SyncController extends ChangeNotifier {
  final SyncService _syncService;
  final SyncQueueManager _queueManager;
  final AppDatabase _db;
  final ConnectivityService connectivityService;

  SyncProgress? _currentProgress;
  List<SyncQueueData> _pendingItems = [];
  Map<String, Conflict> _conflicts = {};
  String _storageSize = '0 KB';
  StreamSubscription? _queueSubscription;

  SyncController(
    this._syncService,
    this._queueManager,
    this._db, {
    required this.connectivityService,
  }) {
    _syncService.progressStream.listen((progress) {
      _currentProgress = progress;
      loadData();
      if (!progress.isSyncing) {
        calculateStorageSize(); // Re-calculate after sync completes
      }
      notifyListeners();
    });

    // React to connectivity changes
    connectivityService.addListener(_onConnectivityChanged);

    // React to queue changes automatically
    _queueSubscription = _queueManager.watchPendingQueue().listen((items) {
      _pendingItems = items;
      notifyListeners();
    });

    loadData();
    calculateStorageSize();
  }

  SyncProgress? get progress => _currentProgress;
  bool get isSyncing => _currentProgress?.isSyncing ?? false;
  List<SyncQueueData> get pendingItems => _pendingItems;
  bool get isOnline => connectivityService.isOnline;
  bool get isOffline => connectivityService.isOffline;
  bool get isManualOffline => connectivityService.isManualOffline;
  ConnectivityStatus get connectivityStatus => connectivityService.status;
  DateTime? get lastSyncedAt => _syncService.lastSuccessfulSync;
  String get storageSize => _storageSize;

  void setManualOffline(bool value) {
    connectivityService.setManualOffline(value);
  }

  void _onConnectivityChanged() {
    // When we come back online, auto-trigger a sync if there are pending items
    if (connectivityService.isOnline && _pendingItems.isNotEmpty && !isSyncing) {
      debugPrint('SyncController: Back online with ${_pendingItems.length} pending → auto-syncing');
      syncNow();
    }
    notifyListeners();
  }

  Future<void> loadData() async {
    _pendingItems = await _queueManager.getPendingQueue();
    final unresolved = await getUnresolvedConflicts();
    _conflicts = {for (var c in unresolved) c.entityId: c};
    notifyListeners();
  }

  Conflict? getConflictForEntity(String entityId) => _conflicts[entityId];

  void syncNow() {
    if (!isSyncing && isOnline) {
      _syncService.triggerImmediateSync();
    } else if (isOffline) {
      debugPrint('SyncController: Cannot sync — device is offline');
    }
  }

  /// Force a connectivity recheck (e.g. user pulls to refresh)
  Future<bool> recheckConnectivity() async {
    return connectivityService.checkNow();
  }

  Future<void> calculateStorageSize() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      
      if (await file.exists()) {
        final bytes = await file.length();
        if (bytes < 1024) {
          _storageSize = '$bytes B';
        } else if (bytes < 1024 * 1024) {
          _storageSize = '${(bytes / 1024).toStringAsFixed(1)} KB';
        } else if (bytes < 1024 * 1024 * 1024) {
          _storageSize = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else {
          _storageSize = '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('SyncController: Error calculating storage size: $e');
    }
  }

  Future<List<Conflict>> getUnresolvedConflicts() async {
    return (_db.select(
      _db.conflicts,
    )..where((c) => c.status.equals('unresolved'))).get();
  }

  @override
  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    _queueSubscription?.cancel();
    super.dispose();
  }
}
