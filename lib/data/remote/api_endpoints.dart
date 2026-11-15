/// All API routes used by the parent mobile app (mirrors the portal client).
class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/api/auth/login';

  static const String pairingCodes = '/api/parent/pairing-codes';
  static String pairingCode(int id) => '/api/parent/pairing-codes/$id';

  static const String children = '/api/parent/children';
  static String child(int id) => '/api/parent/children/$id';
  static String childLocations(int id, {int limit = 100}) =>
      '/api/parent/children/$id/locations?limit=$limit';
  static String childApps(int id) => '/api/parent/children/$id/apps';
  static String childAppPolicy(int id) =>
      '/api/parent/children/$id/apps/policy';
  static String childUsage(int id, {int days = 7}) =>
      '/api/parent/children/$id/usage?days=$days';
  static String childTracking(int id) => '/api/parent/children/$id/tracking';
  static String childProtection(int id) =>
      '/api/parent/children/$id/protection';
  static String childDeviceLock(int id) =>
      '/api/parent/children/$id/device-lock';
  static String childParentLock(int id) =>
      '/api/parent/children/$id/parent-lock';

  static const String sosEvents = '/api/parent/sos-events';
  static String resolveSos(int id) => '/api/parent/sos/$id/resolve';
}
