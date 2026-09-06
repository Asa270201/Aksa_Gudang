import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0B1410),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9AD64D),
      onPrimary: Color(0xFF15210F),
      secondary: Color(0xFF50C878),
      tertiary: Color(0xFFE8B44F),
      surface: Color(0xFF15231A),
      surfaceContainerHighest: Color(0xFF203126),
      onSurface: Color(0xFFF2F5EC),
      onSurfaceVariant: Color(0xFFB7C5B6),
      outline: Color(0xFF34483A),
    ),
    textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFF2F5EC),
      displayColor: const Color(0xFFF2F5EC),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFF0B1410),
      foregroundColor: Color(0xFFF2F5EC),
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF15231A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF15231A),
      hintStyle: const TextStyle(color: Color(0xFF718473)),
      labelStyle: const TextStyle(color: Color(0xFFB7C5B6)),
      prefixIconColor: const Color(0xFF9AD64D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF34483A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF34483A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF9AD64D), width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2B3E31)),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF15231A),
      indicatorColor: Color(0xFF334D2D),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
