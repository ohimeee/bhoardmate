import 'package:flutter/material.dart';

import '../app_theme.dart';

// white card with label/value rows, e.g. {'Contact': '0917 ...'}
class InfoCard extends StatelessWidget {
  final String? title;
  final Map<String, String> rows;

  const InfoCard({super.key, this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (final row in rows.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.key,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    Text(row.value, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
