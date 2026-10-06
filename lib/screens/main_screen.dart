import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/concern_provider.dart';
import '../providers/holiday_provider.dart';
import '../providers/payment_provider.dart';
import 'announcements_screen.dart';
import 'home_screen.dart';
import 'members_screen.dart';
import 'payments_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PaymentsScreen(),
    AnnouncementsScreen(),
    MembersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // load sample data once after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      // owner sees every room, boarder only their own
      final roomId = auth.isOwner ? null : auth.currentRoomId;
      context.read<PaymentProvider>().loadPayments(roomId: roomId);
      context.read<AnnouncementProvider>().loadAnnouncements();
      context.read<ConcernProvider>().loadConcerns(roomId: roomId);
      context.read<HolidayProvider>().loadHolidays();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Pay'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}
