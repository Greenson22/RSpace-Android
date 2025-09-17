// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ==> DAFTAR WARNA PRIMER YANG BISA DIPILIH <==
  static final List<Color> selectableColors = [
    Colors.purple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.red,
    Colors.green,
  ];

  // Palet Warna gradasi untuk dashboard
  static const List<Color> gradientColors1 = [
    Color(0xFF6A11CB),
    Color(0xFF2575FC),
  ];
  static const List<Color> gradientColors2 = [
    Color(0xFF00B09B),
    Color(0xFF96C93D),
  ];
  static const List<Color> gradientColors3 = [
    Color(0xFFFF8008),
    Color(0xFFFFC837),
  ];
  static const List<Color> gradientColors4 = [
    Color(0xFFE53935),
    Color(0xFFE35D5B),
  ];
  static const List<Color> gradientColors5 = [
    Color(0xFF8E2DE2),
    Color(0xFF4A00E0),
  ];
  // ==> TAMBAHKAN GRADIENT BARU <==
  static const List<Color> gradientColors6 = [
    Color(0xFF004D40),
    Color(0xFF009688),
  ];
  static const List<Color> gradientColors7 = [
    Color(0xFFD32F2F),
    Color(0xFFF44336),
  ];
  static const List<Color> gradientColors8 = [
    Color(0xFF1E3A8A),
    Color(0xFF3B82F6),
  ];
  static const List<Color> gradientColors9 = [
    Color(0xFFF59E0B),
    Color(0xFFFBBF24),
  ];
  static const List<Color> gradientHero = [
    Color(0xFF434343),
    Color(0xFF000000),
  ];

  // ==> FUNGSI BARU UNTUK MEMBUAT THEME SECARA DINAMIS <==
  static ThemeData getTheme(Color primaryColor, bool isDark) {
    if (isDark) {
      return _darkTheme(primaryColor);
    }
    return _lightTheme(primaryColor);
  }

  // ==> TEMA SPESIAL NATAL <==
  static ThemeData getChristmasTheme(bool isDark) {
    // Palet Warna Natal
    const Color christmasRed = Color(0xFFC62828); // Merah tua
    const Color christmasGreen = Color(0xFF2E7D32); // Hijau tua
    const Color offWhite = Color(0xFFF5F5DC); // Krem/Putih Gading

    if (isDark) {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: christmasRed,
        scaffoldBackgroundColor: const Color(0xFF1A2B27), // Hijau sangat gelap
        colorScheme: ColorScheme.dark(
          primary: christmasRed,
          secondary: christmasGreen,
          surface: Colors.grey[850]!,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: offWhite,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2C3E3A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: christmasRed,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: christmasRed,
        scaffoldBackgroundColor: offWhite,
        colorScheme: const ColorScheme.light(
          primary: christmasRed,
          secondary: christmasGreen,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: christmasRed,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: christmasRed,
          foregroundColor: Colors.white,
        ),
      );
    }
  }

  // ==> TEMA SPESIAL BAWAH AIR <==
  static ThemeData getUnderwaterTheme(bool isDark) {
    // Palet Warna Bawah Air
    const Color deepBlue = Color(0xFF003973);
    const Color lightBlue = Color(0xFF33A1FD);
    const Color sandColor = Color(0xFFE5DDCB);

    if (isDark) {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: lightBlue,
        scaffoldBackgroundColor: const Color(0xFF001f3f), // Biru sangat gelap
        colorScheme: ColorScheme.dark(
          primary: lightBlue,
          secondary: Colors.cyan,
          surface: const Color(0xFF002a54),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: sandColor,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF002a54).withOpacity(0.8),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: lightBlue,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      // Tema terang untuk bawah air mungkin tidak terlalu masuk akal,
      // jadi kita buat variasi yang lebih cerah saja.
      return _lightTheme(lightBlue);
    }
  }

  static ThemeData _lightTheme(Color primaryColor) => ThemeData(
    primarySwatch: _createMaterialColor(primaryColor),
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.grey[100],
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    // ==> AWAL PERBAIKAN <==
    tabBarTheme: const TabBarThemeData(
      // DIUBAH DARI TabBarTheme
      labelColor: Colors.white, // Warna teks tab yang aktif
      unselectedLabelColor: Colors.white70, // Warna teks tab yang tidak aktif
      indicatorColor: Colors.white, // Warna garis indikator
    ),
    // ==> AKHIR PERBAIKAN <==
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: _createMaterialColor(primaryColor),
      brightness: Brightness.light,
    ).copyWith(secondary: primaryColor),
  );

  static ThemeData _darkTheme(Color primaryColor) => ThemeData(
    primarySwatch: _createMaterialColor(primaryColor),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    // ==> AWAL PERBAIKAN <==
    tabBarTheme: TabBarThemeData(
      // DIUBAH DARI TabBarTheme
      labelColor: primaryColor, // Warna teks tab yang aktif
      unselectedLabelColor: Colors.grey[400], // Warna teks tab yang tidak aktif
      indicatorColor: primaryColor, // Warna garis indikator
    ),
    // ==> AKHIR PERBAIKAN <==
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[850],
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: _createMaterialColor(primaryColor),
      brightness: Brightness.dark,
    ).copyWith(secondary: primaryColor),
  );

  // Helper untuk membuat MaterialColor dari satu Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
