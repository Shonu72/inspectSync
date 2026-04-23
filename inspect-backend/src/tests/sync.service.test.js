const syncService = require('../services/sync.service');
const prisma = require('../config/db');
const { isDuplicate } = require('../utils/idempotency');
const { addSyncJob } = require('../queues/sync-jobs.queue');

// Mocks
jest.mock('../config/db', () => ({
  task: {
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    findUnique: jest.fn(),
  },
  syncLog: {
    findUnique: jest.fn(),
    create: jest.fn(),
  },
  device: {
    upsert: jest.fn(),
  },
  conflict: {
    create: jest.fn(),
  },
  $transaction: jest.fn((callback) => callback(require('../config/db'))),
}));

jest.mock('../services/s3.service', () => ({
  generateViewUrl: jest.fn((url) => Promise.resolve(`presigned-${url}`)),
}));

jest.mock('../utils/idempotency', () => ({
  isDuplicate: jest.fn(),
}));

jest.mock('../queues/sync-jobs.queue', () => ({
  addSyncJob: jest.fn().mockResolvedValue({}),
}));

describe('SyncService (Backend)', () => {
  const userId = 'user-1';

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('pullChanges', () => {
    it('should fetch tasks and presign images', async () => {
      const mockTasks = [
        { id: 'task-1', title: 'Task 1', images: 'img1.jpg,img2.jpg', updatedAt: new Date() },
      ];
      prisma.task.findMany.mockResolvedValueOnce(mockTasks);
      prisma.task.findMany.mockResolvedValueOnce([]); // deletedTasks

      const result = await syncService.pullChanges(null, userId);

      expect(result.tasks).toHaveLength(1);
      expect(result.tasks[0].images).toContain('presigned-img1.jpg');
      expect(result.tasks[0].images).toContain('presigned-img2.jpg');
      expect(result.deletedIds).toEqual([]);
    });
  });

  describe('pushChanges', () => {
    const device_id = 'device-1';

    it('should create a new task and log the sync', async () => {
      const changes = [{
        entityId: 'new-task-1',
        entityType: 'task',
        operation: 'create',
        payload: { title: 'New Task' },
        idempotencyKey: 'ikey-1',
        clientVersion: 1
      }];

      isDuplicate.mockResolvedValue(false);
      prisma.syncLog.findUnique.mockResolvedValue(null);
      prisma.task.create.mockResolvedValue({ id: 'new-task-1', version: 1 });
      prisma.syncLog.create.mockResolvedValue({});
      prisma.device.upsert.mockResolvedValue({});

      const result = await syncService.pushChanges({ device_id, changes }, userId);

      expect(result.synced).toHaveLength(1);
      expect(result.synced[0].entityId).toBe('new-task-1');
      expect(prisma.task.create).toHaveBeenCalled();
      expect(addSyncJob).toHaveBeenCalledWith('send-notifications', expect.anything());
    });

    it('should skip duplicate changes based on idempotency key', async () => {
      const changes = [{
        entityId: 'task-1',
        idempotencyKey: 'ikey-dup'
      }];

      isDuplicate.mockResolvedValue(true);

      const result = await syncService.pushChanges({ device_id, changes }, userId);

      expect(result.synced).toHaveLength(1);
      expect(result.synced[0].note).toContain('already processed');
      expect(prisma.task.create).not.toHaveBeenCalled();
    });
  });
});
