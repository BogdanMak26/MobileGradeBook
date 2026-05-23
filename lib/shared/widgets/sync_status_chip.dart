import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/local/offline_queue.dart';
import '../../core/network/network_monitor.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(offlineQueueProvider);

    // Використовуємо stream-провайдер, при loading — синхронне значення
    final networkStatus = ref.watch(networkStatusProvider);
    final isOnline = networkStatus.when(
      data: (s) => s == NetworkStatus.online,
      loading: () => ref.read(networkMonitorProvider).isOnline,
      error: (_, __) => true,
    );

    final hasPending = !isOnline && pendingCount > 0;

    final bgColor = isOnline
        ? const Color(0xFF16A34A)   // зелений
        : hasPending
            ? const Color(0xFFD97706) // помаранчевий — є зміни в черзі
            : const Color(0xFF64748B); // сірий — просто офлайн

    final icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final label = isOnline ? 'Онлайн' : 'Офлайн';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasPending) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
