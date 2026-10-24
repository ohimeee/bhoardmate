// placeholder, real Home is #6
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import 'announcements_screen.dart';
import 'concerns_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';
import 'rooms_screen.dart';

class HomeScreen extends StatelessWidget {
  // Edit each Home card's background color here.
  static const cardColors = <String, Color>{
    'Payments': Colors.white,
    'Announcements': Color(0xFFDCEBFA),
    'Members': Color(0xFFFDE7D3),
    'Concerns': Color(0xFFFADCDC),
    'Rooms': Color(0xFFE7E2F8),
  };

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final balance = context.watch<PaymentProvider>().outstandingBalance;

    final buttons = <String, Widget>{
      'Payments': const PaymentsScreen(),
      'Announcements': const AnnouncementsScreen(),
      'Members': const MembersScreen(),
      'Concerns': const ConcernsScreen(),
      // owner only
      if (auth.isOwner) 'Rooms': const RoomsScreen(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // MainScreen opens the login screen after logout
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as: ${auth.isOwner ? 'Owner' : auth.currentRoomId}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Outstanding balance: PHP ${balance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: buttons.entries.map((entry) {
                  return Card(
                    color: cardColors[entry.key],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => entry.value),
                        );
                      },
                      child: Center(child: Text(entry.key)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
