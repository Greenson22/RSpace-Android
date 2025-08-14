import 'package:flutter/material.dart';

class AppTheme {
  // Palet Warna gradasi untuk dashboard
  static const List<Color> gradientColors1 = [
    Color(0xFF64B5F6),
    Color(0xFF2196F3),
  ];
  static const List<Color> gradientColors2 = [
    Color(0xFF81C784),
    Color(0xFF4CAF50),
  ];
  static const List<Color> gradientColors3 = [
    Color(0xFFFFA726),
    Color(0xFFFF9800),
  ];
  static const List<Color> gradientColors4 = [
    Color(0xFFF06292),
    Color(0xFFE91E63),
  ];
  static const List<Color> gradientColors5 = [
    Color(0xFFBA68C8),
    Color(0xFF9C27B0),
  ];

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.purple, // DIUBAH
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100], // Latar belakang lebih lembut
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple, // DIUBAH
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ), // Kartu lebih bulat
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.purple[600], // DIUBAH
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.purple,
    ).copyWith(secondary: Colors.purpleAccent),
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.purple, // DIUBAH
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(
      0xFF121212,
    ), // Latar belakang gelap standar
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 4, // Shadow lebih terlihat di tema gelap
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.purple[300], // DIUBAH
      foregroundColor: Colors.black,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.purple,
      brightness: Brightness.dark,
    ).copyWith(secondary: Colors.purpleAccent),
  );
}
