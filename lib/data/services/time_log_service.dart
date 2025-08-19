// lib/data/services/time_log_service.dart

import 'dart:convert';
import 'dart:io';
import '../models/time_log_model.dart';
import 'path_service.dart';

class TimeLogService {
  final PathService _pathService = PathService();

  Future<List<TimeLogEntry>> loadTimeLogs() async {
    final filePath = await _pathService.timeLogPath;
    final file = File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); // Buat array JSON kosong
      return [];
    }

    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => TimeLogEntry.fromJson(item)).toList();
  }

  Future<void> saveTimeLogs(List<TimeLogEntry> logs) async {
    final filePath = await _pathService.timeLogPath;
    final file = File(filePath);
    final listJson = logs.map((log) => log.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
