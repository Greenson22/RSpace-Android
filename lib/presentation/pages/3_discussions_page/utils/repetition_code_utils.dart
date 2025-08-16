import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Daftar kode repetisi yang terpusat
const List<String> kRepetitionCodes = [
  'R0D',
  'R1D',
  'R3D',
  'R7D',
  'R7D2',
  'R7D3',
  'R30D',
  'Finish',
];

// Fungsi untuk mendapatkan indeks kode, berguna untuk perbandingan
int getRepetitionCodeIndex(String code) {
  final index = kRepetitionCodes.indexOf(code);
  return index == -1 ? 999 : index; // Beri nilai besar jika tidak ditemukan
}

Color getColorForRepetitionCode(String code) {
  switch (code) {
    case 'R0D':
      return Colors.orange.shade700;
    case 'R1D':
      return Colors.blue.shade600;
    case 'R3D':
      return Colors.teal.shade500;
    case 'R7D':
      return Colors.cyan.shade600;
    case 'R7D2':
      return Colors.purple.shade400;
    case 'R7D3':
      return Colors.indigo.shade500;
    case 'R30D':
      return Colors.brown.shade500;
    case 'Finish':
      return Colors.green.shade800;
    default:
      return Colors.grey.shade600;
  }
}

String getNewDateForRepetitionCode(String code) {
  final now = DateTime.now();
  int daysToAdd;
  switch (code) {
    case 'R1D':
      daysToAdd = 1;
      break;
    case 'R3D':
      daysToAdd = 3;
      break;
    // ==> PERUBAHAN DI SINI <==
    // R7D, R7D2, dan R7D3 sekarang semua menambahkan 7 hari.
    case 'R7D':
    case 'R7D2':
    case 'R7D3':
      daysToAdd = 7;
      break;
    // ==> AKHIR PERUBAHAN <==
    case 'R30D':
      daysToAdd = 30;
      break;
    default:
      daysToAdd = 0;
      break;
  }
  return DateFormat('yyyy-MM-dd').format(now.add(Duration(days: daysToAdd)));
}
