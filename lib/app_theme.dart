import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Sprout palette, see docs/design/bhoardmate-palette.svg
class AppColors {
  static const background = Color(0xFFFAF6EE);
  static const primary = Color(0xFF2E6B4F);
  static const text = Color(0xFF1F2328);
  static const textLight = Color(0xFF6B7280);
  static const icon = Color(0xFF5B5BD6);

  // status pills: background + text
  static const paid = Color(0xFFD8F0E0);
  static const paidText = Color(0xFF1E5E3F);
  static const unpaid = Color(0xFFFBE3E1);
  static const unpaidText = Color(0xFFD9534F);
  static const pending = Color(0xFFFDF0D5);
  static const pendingText = Color(0xFFB7791F);

  // each feature has a tile color (Home + app bar) and a darker
  // shade for the app bar title, so users know which screen they are on
  static const payments = Color(0xFFDDF1E4);
  static const paymentsDark = Color(0xFF1E5E3F);
  static const announcements = Color(0xFFDCEBFA);
  static const announcementsDark = Color(0xFF2F5D8A);
  static const members = Color(0xFFFDE7D3);
  static const membersDark = Color(0xFF9A5A1F);
  static const concerns = Color(0xFFFADCDC);
  static const concernsDark = Color(0xFFA0435A);
  static const rooms = Color(0xFFE7E2F8);
  static const roomsDark = Color(0xFF5B4B9A);
}

// one theme for the whole app, buttons and FABs are always green
ThemeData appTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
