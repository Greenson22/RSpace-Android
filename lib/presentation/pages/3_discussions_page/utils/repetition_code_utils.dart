import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    case 'R7D':
      daysToAdd = 7;
      break;
    case 'R7D2':
      daysToAdd = 14;
      break;
    case 'R7D3':
      daysToAdd = 21;
      break;
    case 'R30D':
      daysToAdd = 30;
      break;
    default:
      daysToAdd = 0;
      break;
  }
  return DateFormat('yyyy-MM-dd').format(now.add(Duration(days: daysToAdd)));
}
