import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/holiday.dart';
import '../providers/holiday_provider.dart';
import 'error_card.dart';

// "Upcoming PH holidays" card on the News tab, data from Nager.Date.
// Shows loading, error + Retry, and a note when the list is the saved one
class HolidaySection extends StatefulWidget {
  const HolidaySection({super.key});

  @override
  State<HolidaySection> createState() => _HolidaySectionState();
}

class _HolidaySectionState extends State<HolidaySection> {
  // only the next 3 until the user taps "Show all"
  bool _showAll = false;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _retry() {
    context.read<HolidayProvider>().loadHolidays();
  }

  Widget _holidayTile(Holiday holiday) {
    final date = holiday.date;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // small calendar box: month on top, day below
      leading: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.announcements,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _months[date.month - 1],
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.announcementsDark,
              ),
            ),
            Text(
              '${date.day}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.announcementsDark,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        holiday.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // weekday matters: a holiday on a weekday moves the rent due date
        holiday.localName == holiday.name
            ? '${_days[date.weekday - 1]}, ${date.year}'
            : '${_days[date.weekday - 1]}, ${date.year} · ${holiday.localName}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HolidayProvider>();

    // nothing loaded and nothing saved: only the error
    if (!provider.isLoading && provider.errorMessage != null) {
      return ErrorCard(message: provider.errorMessage!, onRetry: _retry);
    }

    final upcoming = provider.upcomingHolidays;
    final shown = _showAll ? upcoming : upcoming.take(3).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_outlined, color: AppColors.announcementsDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upcoming PH holidays',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // API failed but we have the list from last time
              if (provider.isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: AppColors.pending,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 18,
                        color: AppColors.pendingText,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Offline: showing the saved list.',
                          style: TextStyle(color: AppColors.pendingText),
                        ),
                      ),
                      TextButton(onPressed: _retry, child: const Text('Retry')),
                    ],
                  ),
                ),
              if (upcoming.isEmpty)
                const Text(
                  'No upcoming holidays.',
                  style: TextStyle(color: AppColors.textLight),
                ),
              for (final holiday in shown) _holidayTile(holiday),
              if (upcoming.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  child: Text(
                    _showAll ? 'Show less' : 'Show all (${upcoming.length})',
                  ),
                ),
              const Text(
                'Source: Nager.Date',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ],
        ),
      ),
    ); // Card
  }
}
