// file: lib/utils/theme_utils.dart
import 'package:flutter/material.dart';

class ThemeUtils {
  // Daftar warna yang akan digunakan untuk tema dinamis
  static final List<Color> themePalettes = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
    Colors.green,
  ];

  // Fungsi untuk mendapatkan warna berdasarkan teks (judul/nama)
  static Color getThemeColorFromTitle(String title) {
    if (title.isEmpty) return themePalettes[0]; // Warna default jika kosong

    int hash = title.hashCode;
    int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }
}
