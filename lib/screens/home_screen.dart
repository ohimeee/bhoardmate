// placeholder, real Home is #6
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/feature_button.dart';
import 'announcements_screen.dart';
import 'concerns_screen.dart';
import 'login_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';
import 'rooms_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final balance = context.watch<PaymentProvider>().outstandingBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // wait for Firebase sign out, or the login screen
              // would find the old account and log back in
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Logged in as: ${auth.isOwner ? 'Owner' : auth.currentRoomId}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          BalanceCard(amount: balance),
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
                onTap: () => _open(context, const PaymentsScreen()),
              ),
              FeatureButton(
                label: 'Announcements',
                icon: Icons.campaign_outlined,
                color: AppColors.announcements,
                onTap: () => _open(context, const AnnouncementsScreen()),
              ),
              FeatureButton(
                label: 'Members',
                icon: Icons.people_outline,
                color: AppColors.members,
                onTap: () => _open(context, const MembersScreen()),
              ),
              FeatureButton(
                label: 'Concerns',
                icon: Icons.chat_bubble_outline,
                color: AppColors.concerns,
                onTap: () => _open(context, const ConcernsScreen()),
              ),
              // owner only
              if (auth.isOwner)
                FeatureButton(
                  label: 'Rooms',
                  icon: Icons.meeting_room_outlined,
                  color: AppColors.rooms,
                  onTap: () => _open(context, const RoomsScreen()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
