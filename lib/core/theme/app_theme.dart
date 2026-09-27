import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talentmatch/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBlue,
          primary: kBlue,
          secondary: kCyan,
          surface: kBg,
          onSurface: kText,
        ),
        scaffoldBackgroundColor: kBg,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w800, color: kNavy,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800, color: kNavy,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: kNavy,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600, color: kText,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400, color: kText,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w400, color: kMuted,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, color: kWhite,
          ),
        ),
        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: kWhite,
          surfaceTintColor: kWhite,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: kLine,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 19, fontWeight: FontWeight.w800, color: kNavy,
          ),
          iconTheme: const IconThemeData(color: kNavy),
        ),
        // NavigationBar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kWhite,
          surfaceTintColor: kWhite,
          indicatorColor: const Color(0xFFE7EFFF),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return GoogleFonts.inter(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? kBlue : kMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final active = states.contains(WidgetState.selected);
            return IconThemeData(color: active ? kBlue : kMuted, size: 22);
          }),
        ),
        // FilledButton (botón principal)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: kWhite,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        // OutlinedButton (botón secundario)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kBlue,
            side: const BorderSide(color: kBlue),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        // TextField / InputDecoration
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kWhite,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: kMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: kBlue, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F4F8),
          labelStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF596579)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
        ),
        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kNavy,
          contentTextStyle: GoogleFonts.inter(fontSize: 13, color: kWhite),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dividerTheme: const DividerThemeData(color: kLine, thickness: 1),
        // InputDecoration overrides for SnackBar shape
      );
}
