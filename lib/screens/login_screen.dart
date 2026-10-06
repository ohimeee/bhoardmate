// placeholder, real login form is #4
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToMain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BhoardMate',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().loginBoarder(
                    'BH01-RM2',
                    '2222',
                  );
                  if (ok && context.mounted) _goToMain(context);
                },
                child: const Text('Demo: log in as boarder (BH01-RM2)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().loginOwner(
                    'owner',
                    'admin123',
                  );
                  if (ok && context.mounted) _goToMain(context);
                },
                child: const Text('Demo: log in as owner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
