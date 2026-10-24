import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/announcement_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/concern_provider.dart';
import 'providers/holiday_provider.dart';
import 'providers/payment_provider.dart';
import 'screens/login_screen.dart';

// Firebase has to start before the app uses Firestore or Auth
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BhoardMateApp());
}

class BhoardMateApp extends StatelessWidget {
  const BhoardMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => ConcernProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
      ],
      child: MaterialApp(
        title: 'BhoardMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.amber,
          textTheme: GoogleFonts.poppinsTextTheme(),
          // warm yellow app bars on every screen
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.amber.shade300,
            foregroundColor: Colors.black87,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
