import 'package:uuid/uuid.dart';
import '../../../core/db/app_database.dart';
import '../../sync/sync_service.dart';
import 'task_local_datasource.dart';
import 'task_remote_datasource.dart';

class TaskRepository {
  final TaskLocalDataSource local;
  final TaskRemoteDataSource remote;
  final SyncService syncService;

  TaskRepository({
    required this.local,
    required this.remote,
    required this.syncService,
  });

  /// Get a stream of all tasks for reactive UI
  Stream<List<Task>> watchTasks() {
    return local.watchTasks();
  }

  /// Fetch a single task by ID
  Future<Task?> getTaskById(String id) {
    return local.getTaskById(id);
  }

  /// Create a new task offline-first
  Future<void> createTask({
    required String title,
    String? description,
    double? lat,
    double? lng,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(), // Proper GUID for offline sync
      title: title,
      description: description,
      lat: lat,
      lng: lng,
      status: 'pending',
      version: 1,
      isSynced: false,
      updatedAt: now,
      createdAt: now,
    );

    await local.insertTaskLocally(task);
    
    // Trigger sync in background
    syncService.triggerImmediateSync();
  }

  /// Update an existing task offline-first
  Future<void> updateTask(Task task) async {
    await local.updateTaskLocally(task);
    
    // Trigger sync in background
    syncService.triggerImmediateSync();
  }

  /// Fetch latest tasks from server (Optional: used for manual refresh)
  Future<void> refreshTasks() async {
    // This would call pullChanges on the sync service logic
    // For now, we rely on the sync engine's triggers.
    syncService.triggerImmediateSync();
  }
}
