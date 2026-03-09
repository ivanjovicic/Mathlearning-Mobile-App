abstract class SyncCoordinator {
  Future<void> initialize();

  Future<void> triggerSync({required String userId, bool force = false});

  Future<void> onConnectivityRestored(String userId);

  Future<void> dispose();
}
