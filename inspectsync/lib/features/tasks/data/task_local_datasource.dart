import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../core/db/app_database.dart';

class TaskLocalDataSource {
  final AppDatabase _db;

  TaskLocalDataSource(this._db);

  Stream<List<Task>> watchTasks() {
    return (_db.select(_db.tasks)
          ..orderBy(
            [(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)],
          ))
        .watch();
  }

  Future<Task?> getTaskById(String id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Task?> watchTaskById(String id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> updateTaskLocally(Task task) async {
    await _db.transaction(() async {
      final now = DateTime.now();
      final updatedTask = task.copyWith(updatedAt: now, isSynced: false);

      // 1. Update local DB
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id)))
          .write(updatedTask);

      // 2. Add to Sync Queue
      final payload = jsonEncode({
        'id': updatedTask.id,
        'title': updatedTask.title,
        'description': updatedTask.description,
        'status': updatedTask.status,
        'version': updatedTask.version,
        'updatedAt': updatedTask.updatedAt.toUtc().toIso8601String(),
        'lat': updatedTask.lat,
        'lng': updatedTask.lng,
        'images': updatedTask.images,
      });

      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            entityId: updatedTask.id,
            entityType: 'task',
            action: 'update',
            payload: payload,
            createdAt: now,
          ));
    });
  }

  Future<void> insertTaskLocally(Task task) async {
    await _db.transaction(() async {
      await _db.into(_db.tasks).insert(task.copyWith(isSynced: false));

      final payload = jsonEncode({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'status': task.status,
        'version': task.version,
        'createdAt': task.createdAt.toUtc().toIso8601String(),
        'updatedAt': task.updatedAt.toUtc().toIso8601String(),
        'lat': task.lat,
        'lng': task.lng,
        'images': task.images,
      });

      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            entityId: task.id,
            entityType: 'task',
            action: 'create',
            payload: payload,
            createdAt: DateTime.now(),
          ));
    });
  }

  // Update specific task state post-sync
  Future<void> markTaskSynced(String taskId, {int? newVersion}) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(taskId)))
        .write(TasksCompanion(
          isSynced: const Value(true),
          version: newVersion != null ? Value(newVersion) : const Value.absent(),
        ));
  }

  /// Forcefully apply server data to local DB (used in Pull Sync)
  Future<void> upsertTaskFromServer(Task task) async {
    await _db.into(_db.tasks).insertOnConflictUpdate(task);
  }

  /// Remove task from local DB (used in Pull Sync for deleted items)
  Future<void> deleteTaskLocally(String taskId) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
  }
}
