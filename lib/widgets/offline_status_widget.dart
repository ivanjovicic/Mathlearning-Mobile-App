import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/offline_manager.dart';

class OfflineStatusWidget extends StatelessWidget {
  const OfflineStatusWidget({super.key});

  Future<void> _syncNow(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sinhronizujem offline podatke...'),
        backgroundColor: colorScheme.primary,
      ),
    );

    await OfflineManager.instance.manualSync();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sinhronizacija zavrsena!'),
        backgroundColor: colorScheme.tertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService.instance;
    final offlineManager = OfflineManager.instance;

    return StreamBuilder<bool>(
      stream: connectivity.onConnectivityChanged,
      initialData: connectivity.isOnline,
      builder: (context, onlineSnapshot) {
        final isOnline = onlineSnapshot.data ?? true;

        return StreamBuilder<int>(
          stream: offlineManager.pendingCountStream,
          initialData: 0,
          builder: (context, pendingSnapshot) {
            final pendingCount = pendingSnapshot.data ?? 0;
            if (isOnline && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            final colorScheme = Theme.of(context).colorScheme;
            final statusBg = isOnline
                ? colorScheme.secondaryContainer
                : colorScheme.errorContainer;
            final statusFg = isOnline
                ? colorScheme.onSecondaryContainer
                : colorScheme.onErrorContainer;

            return Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pendingCount == 0
                        ? Icons.cloud_done
                        : (isOnline ? Icons.cloud_sync : Icons.cloud_off),
                    color: pendingCount == 0 ? Colors.green : statusFg,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    pendingCount == 0
                        ? 'All synced'
                        : (isOnline
                            ? 'Pending: $pendingCount'
                            : 'Offline pending: $pendingCount'),
                    style: TextStyle(
                      color: statusFg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOnline && pendingCount > 0) ...[
                    IconButton(
                      onPressed: () => _syncNow(context),
                      tooltip: 'Sinhronizuj',
                      icon: Icon(Icons.sync, color: statusFg, size: 18),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
