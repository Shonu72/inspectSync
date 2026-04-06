class ApiEndpoints {
  // static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'https://inspectsync-backend.onrender.com/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Tasks
  static const String tasks = '/tasks';
  
  // Sync
  static const String syncPush = '/sync/push';
  static const String syncPull = '/sync/pull';

  // Media
  static const String presignedUrl = '/media/presigned-url';
}
