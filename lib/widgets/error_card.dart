import 'package:flutter/material.dart';

import '../app_theme.dart';

// coral card with the error and a Retry button, shown above old data
// when a refresh fails (Home + Payments)
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.unpaid,
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: AppColors.unpaidText),
        title: Text(
          message,
          style: const TextStyle(color: AppColors.unpaidText),
        ),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}
