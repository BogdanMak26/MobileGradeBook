// lib/shared/widgets/sync_status_chip.dart
import 'package:flutter/material.dart';

class SyncStatusChip extends StatelessWidget {
  final bool isOnline;
  const SyncStatusChip({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green.shade200 : Colors.grey.shade300, size: 14),
            const SizedBox(width: 4),
            Text(isOnline ? 'Онлайн' : 'Офлайн',
                style: TextStyle(
                    color: isOnline ? Colors.green.shade200 : Colors.grey.shade300,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
