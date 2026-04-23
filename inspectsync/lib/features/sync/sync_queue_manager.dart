import 'package:drift/drift.dart' as drift;
import '../../../core/db/app_database.dart';

class SyncQueueManager {
  final AppDatabase _db;

  SyncQueueManager(this._db);

  Future<List<SyncQueueData>> getPendingQueue() async {
    return (_db.select(_db.syncQueue)
          ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
          ..orderBy([(q) => drift.OrderingTerm(expression: q.createdAt)]))
        .get();
  }

  Stream<List<SyncQueueData>> watchPendingQueue() {
    return (_db.select(_db.syncQueue)
          ..where((q) => q.status.equals('pending') | q.status.equals('failed'))
          ..orderBy([(q) => drift.OrderingTerm(expression: q.createdAt)]))
        .watch();
  }

  Future<void> markQueueSyncing(int id) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(id))).write(
      const SyncQueueCompanion(status: drift.Value('syncing')),
    );
  }

  Future<void> markQueueCompleted(int id) async {
    await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(id))).go();
  }

  Future<bool> markQueueFailed(int id, int currentRetries) async {
    try {
      await (_db.update(_db.syncQueue)..where((q) => q.id.equals(id))).write(
        SyncQueueCompanion(
          status: const drift.Value('failed'),
          retryCount: drift.Value(currentRetries + 1),
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPending(String entityId) async {
    final result = await (_db.select(
      _db.syncQueue,
    )..where((q) => q.entityId.equals(entityId))).get();
    return result.isNotEmpty;
  }
}
