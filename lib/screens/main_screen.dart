import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/concern_provider.dart';
import '../providers/holiday_provider.dart';
import '../providers/payment_provider.dart';
import 'announcements_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
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
    MembersScreen(showOwnProfile: true),
  ];

  @override
  void initState() {
    super.initState();
    // load data once after login
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

  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    // logout button or the owner reset this boarder's code:
    // go back to login and remove every screen behind it
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    if (!loggedIn && !_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // forget the old user's data before the next login
        context.read<PaymentProvider>().clear();
        context.read<AnnouncementProvider>().clear();
        context.read<ConcernProvider>().clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
    }

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
