import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xff0F172A),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xff22C55E),
      secondary: Color(0xff38BDF8),
      surface: Color(0xff1E293B),
    ),

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xff0F172A),
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xff1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
