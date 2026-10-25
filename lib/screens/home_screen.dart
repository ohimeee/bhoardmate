import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/payment.dart';
import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/error_card.dart';
import '../widgets/feature_button.dart';
import 'announcements_screen.dart';
import 'concerns_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';
import 'rooms_screen.dart';

// greeting, balance, owner's rent summary, latest news and the feature tiles
class HomeScreen extends StatefulWidget {
  // MainScreen passes this so Payments and See all switch tabs
  // instead of opening a second copy of the same screen
  final void Function(int index)? onOpenTab;

  const HomeScreen({super.key, this.onOpenTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // month picked in the owner's rent summary, null = this month
  String? _selectedMonth;

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // tabs in MainScreen: 1 = Pay, 2 = News
  void _openTab(int index, Widget screen) {
    if (widget.onOpenTab != null) {
      widget.onOpenTab!(index);
    } else {
      _open(screen);
    }
  }

  void _reloadPayments() {
    final auth = context.read<AuthProvider>();
    context.read<PaymentProvider>().loadPayments(
      roomId: auth.isOwner ? null : auth.currentRoomId,
    );
  }

  // boarder's name, or the room ID if the room has no name yet
  String _name(AuthProvider auth) {
    if (auth.isOwner) return auth.owner?.name ?? 'Owner';
    final room = auth.rooms
        .where((r) => r.id == auth.currentRoomId)
        .firstOrNull;
    final name = room?.boarderName ?? '';
    return name.isEmpty ? auth.currentRoomId ?? '' : name;
  }

  Widget _balanceSection(AuthProvider auth, PaymentProvider payments) {
    if (payments.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = payments.errorMessage;
    // nothing loaded at all: only the error, not a fake ₱ 0.00
    if (error != null && payments.payments.isEmpty) {
      return ErrorCard(message: error, onRetry: _reloadPayments);
    }
    final nextDue = payments.nextDueDate;
    return Column(
      children: [
        BalanceCard(
          title: auth.isOwner
              ? 'Unpaid total (all rooms)'
              : 'Outstanding balance',
          amount: payments.outstandingBalance,
          subtitle: nextDue == null ? 'All paid' : 'Next due: $nextDue',
        ),
        // a failed refresh keeps the old bills, so say they may be old
        if (error != null) ...[
          const SizedBox(height: 12),
          ErrorCard(message: error, onRetry: _reloadPayments),
        ],
      ],
    );
  }

  // owner only: room rent of the paid bills of one billing month
  Widget _rentSummary(PaymentProvider payments) {
    final months = payments.months;
    if (payments.isLoading || months.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    String month;
    if (months.contains(_selectedMonth)) {
      month = _selectedMonth!;
    } else if (months.contains(thisMonth)) {
      month = thisMonth;
    } else {
      month = months.first;
    }
    final bills = payments.billsForMonth(month);
    final paid = bills.where((p) => p.isPaid).length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Rent collected',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<String>(
                  value: month,
                  underline: const SizedBox(),
                  items: [
                    for (final m in months)
                      DropdownMenuItem(
                        value: m,
                        child: Text(Payment.monthName(m)),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ],
            ),
            Text(
              '₱ ${payments.rentCollected(month).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$paid of ${bills.length} bills paid',
              style: const TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    ); // Card
  }

  // latest 2 announcements, the rest are on the News tab
  Widget _newsSection(AnnouncementProvider news) {
    final latest = news.announcements.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latest announcements',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => _openTab(2, const AnnouncementsScreen()),
              child: const Text('See all'),
            ),
          ],
        ),
        if (news.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (news.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ErrorCard(
                message: news.errorMessage!,
                onRetry: () =>
                    context.read<AnnouncementProvider>().loadAnnouncements(),
              ),
            ),
          if (latest.isEmpty && news.errorMessage == null)
            const Text(
              'No announcements yet.',
              style: TextStyle(color: AppColors.textLight),
            ),
          for (final announcement in latest)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.announcements,
                  child: Icon(
                    Icons.campaign_outlined,
                    color: AppColors.announcementsDark,
                  ),
                ),
                title: Text(
                  announcement.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // long messages cut off, full text on the News tab
                subtitle: Text(
                  announcement.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openTab(2, const AnnouncementsScreen()),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final payments = context.watch<PaymentProvider>();
    final news = context.watch<AnnouncementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${_name(auth)}', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            // MainScreen opens the login screen after logout
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            auth.isOwner ? 'Owner' : 'Room ${auth.currentRoomId}',
            style: const TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          _balanceSection(auth, payments),
          if (auth.isOwner) ...[
            const SizedBox(height: 12),
            _rentSummary(payments),
          ],
          const SizedBox(height: 20),
          _newsSection(news),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              FeatureButton(
                label: 'Payments',
                icon: Icons.payments_outlined,
                color: AppColors.payments,
                onTap: () => _openTab(1, const PaymentsScreen()),
              ),
              FeatureButton(
                label: 'Announcements',
                icon: Icons.campaign_outlined,
                color: AppColors.announcements,
                onTap: () => _openTab(2, const AnnouncementsScreen()),
              ),
              FeatureButton(
                label: 'Members',
                icon: Icons.people_outline,
                color: AppColors.members,
                onTap: () => _open(const MembersScreen()),
              ),
              FeatureButton(
                label: 'Concerns',
                icon: Icons.chat_bubble_outline,
                color: AppColors.concerns,
                onTap: () => _open(const ConcernsScreen()),
              ),
              // owner only
              if (auth.isOwner)
                FeatureButton(
                  label: 'Rooms',
                  icon: Icons.meeting_room_outlined,
                  color: AppColors.rooms,
                  onTap: () => _open(const RoomsScreen()),
                ),
            ],
          ),
        ],
      ),
    ); // Scaffold
  }
}
