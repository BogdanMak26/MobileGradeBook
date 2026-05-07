import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/local/offline_queue.dart';
import '../theme/app_theme.dart';

class SyncStatusChip extends ConsumerWidget {
  final bool isOnline;
  const SyncStatusChip({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(offlineQueueProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline
                  ? Colors.green.shade200
                  : Colors.grey.shade300,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'Онлайн' : 'Офлайн',
              style: TextStyle(
                color: isOnline
                    ? Colors.green.shade200
                    : Colors.grey.shade300,
                fontSize: 11,
              ),
            ),
            if (!isOnline && pendingCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
