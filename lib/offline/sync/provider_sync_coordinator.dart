import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/sync_coordinator.dart';
import '../services/sync_queue_manager.dart';

class ProviderSyncCoordinator implements SyncCoordinator {
  ProviderSyncCoordinator(this._queueManager);

  final SyncQueueManager _queueManager;
  final Set<String> _runningUsers = <String>{};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> triggerSync({required String userId, bool force = false}) async {
    if (!_initialized) {
      await initialize();
    }
    if (!force && _runningUsers.contains(userId)) {
      return;
    }

    _runningUsers.add(userId);
    try {
      await _queueManager.recoverExpiredLeases(DateTime.now());
      final operations = await _queueManager.loadRunnableOperations(
        userId: userId,
        now: DateTime.now(),
      );
      debugPrint(
        '[OFFLINE_FIRST] SyncCoordinator bootstrapped ${operations.length} runnable operations for $userId',
      );
    } finally {
      _runningUsers.remove(userId);
    }
  }

  @override
  Future<void> onConnectivityRestored(String userId) {
    return triggerSync(userId: userId);
  }

  @override
  Future<void> dispose() async {
    _runningUsers.clear();
  }
}
