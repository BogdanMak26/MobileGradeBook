import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/local/offline_queue.dart';
import '../../core/network/network_monitor.dart';
import '../../core/sync/sync_service.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(offlineQueueProvider);

    final networkStatus = ref.watch(networkStatusProvider);
    final isOnline = networkStatus.when(
      data: (s) => s == NetworkStatus.online,
      loading: () => ref.read(networkMonitorProvider).isOnline,
      error: (_, __) => true,
    );

    final hasPending = !isOnline && pendingCount > 0;

    final bgColor = isOnline
        ? const Color(0xFF16A34A)
        : hasPending
            ? const Color(0xFFD97706)
            : const Color(0xFF64748B);

    final icon = isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded;
    final label = isOnline ? 'Онлайн' : 'Офлайн';

    final chip = Container(
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

    if (!hasPending) return chip;

    return GestureDetector(
      onTap: () => _showQueueSheet(context, ref, isOnline),
      child: chip,
    );
  }

  Future<void> _showQueueSheet(BuildContext context, WidgetRef ref, bool isOnline) async {
    final ops = await ref.read(offlineQueueProvider.notifier).getAll();
    final syncNow = isOnline ? () => ref.read(syncServiceProvider).syncNow() : null;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QueueBottomSheet(ops: ops, isOnline: isOnline, onSyncNow: syncNow),
    );
  }
}

// ─── Bottom sheet ────────────────────────────────────────────────────────────

class _QueueBottomSheet extends StatelessWidget {
  final List<PendingOp> ops;
  final bool isOnline;
  final VoidCallback? onSyncNow;

  const _QueueBottomSheet({
    required this.ops,
    required this.isOnline,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + 28;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Черга змін (${ops.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Дані буде надіслано на сервер при появі мережі',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: ops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _OpTile(op: ops[i]),
            ),
          ),
          if (onSyncNow != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Синхронізувати зараз'),
                onPressed: () {
                  Navigator.pop(context);
                  onSyncNow!();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OpTile extends StatelessWidget {
  final PendingOp op;
  const _OpTile({required this.op});

  static const _methodColors = {
    'POST':   Color(0xFF16A34A),
    'PUT':    Color(0xFF2563EB),
    'PATCH':  Color(0xFFD97706),
    'DELETE': Color(0xFFDC2626),
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'щойно';
    if (diff.inMinutes < 60) return '${diff.inMinutes} хв.';
    if (diff.inHours < 24) return '${diff.inHours} год.';
    return '${diff.inDays} дн.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _methodColors[op.method] ?? Colors.grey;
    final theme = Theme.of(context);
    final title = op.label ?? op.path;
    final sub = op.subtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              op.method,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(op.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
