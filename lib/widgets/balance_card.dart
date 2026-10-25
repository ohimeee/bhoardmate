import 'package:flutter/material.dart';

import '../app_theme.dart';

// big green card with the amount still to pay (Home + Payments)
class BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final String? subtitle;

  const BalanceCard({
    super.key,
    this.title = 'Outstanding balance',
    required this.amount,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              '₱ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}
