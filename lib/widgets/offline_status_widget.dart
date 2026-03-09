import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../services/offline_manager.dart';
import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';
import '../utils/overlay_safety.dart';

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
    final spacing = context.spacing;

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
              margin: EdgeInsets.all(spacing.s),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.s + spacing.xs,
                vertical: spacing.s,
              ),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(context.radius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pendingCount == 0
                        ? Icons.cloud_done
                        : (isOnline ? Icons.cloud_sync : Icons.cloud_off),
                    color: pendingCount == 0
                        ? context.status.success
                        : statusFg,
                    size: AppScale.icon(16, min: 14, max: 20),
                  ),
                  SizedBox(width: spacing.xs + spacing.xs / 2),
                  Text(
                    pendingCount == 0
                        ? 'All synced'
                        : (isOnline
                            ? 'Pending: $pendingCount'
                            : 'Offline pending: $pendingCount'),
                    style: TextStyle(
                      color: statusFg,
                      fontSize: AppScale.font(13, min: 12, max: 18),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOnline && pendingCount > 0) ...[
                    SizedBox(width: spacing.xs),
                    IconButton(
                      onPressed: () => _syncNow(context),
                      tooltip: context.safeTooltip('Sinhronizuj'),
                      icon: Icon(
                        Icons.sync,
                        color: statusFg,
                        size: AppScale.icon(18, min: 16, max: 22),
                      ),
                      constraints: BoxConstraints(
                        minWidth: AppScale.s(40),
                        minHeight: AppScale.s(40),
                      ),
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
