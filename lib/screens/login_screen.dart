// placeholder, real login form is #4
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  // skip the login screen if Firebase still has the account
  Future<void> _checkSession() async {
    final auth = context.read<AuthProvider>();
    await auth.loadSession();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      _goToMain();
    } else {
      setState(() => _checking = false);
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = context.watch<AuthProvider>().errorMessage;
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BHoardMate',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().loginBoarder(
                    'BH01-RM2',
                    '2222',
                  );
                  if (ok && mounted) _goToMain();
                },
                child: const Text('Demo: log in as boarder (BH01-RM2)'),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
