import 'package:flutter/material.dart';

import '../app_theme.dart';

// colored pill for 'paid', 'unpaid', 'pending' or 'done'
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.pending;
    Color textColor = AppColors.pendingText;
    if (status == 'paid' || status == 'done') {
      background = AppColors.paid;
      textColor = AppColors.paidText;
    } else if (status == 'unpaid') {
      background = AppColors.unpaid;
      textColor = AppColors.unpaidText;
    }
    // 'done' -> 'Done'
    final label = status[0].toUpperCase() + status.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
