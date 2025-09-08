// lib/data/services/time_log_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart'; // Ditambahkan untuk DateUtils
import '../../domain/models/log_task_preset_model.dart';
import '../../domain/models/time_log_model.dart';
import '../../../../data/services/path_service.dart';

class TimeLogService {
  final PathService _pathService = PathService();

  // ======================================================================
  // == PERUBAHAN UTAMA: Logika pembuatan log harian dipindah ke sini ==
  // ======================================================================
  Future<List<TimeLogEntry>> loadTimeLogs() async {
    final filePath = await _pathService.timeLogPath;
    final file = File(filePath);
    List<TimeLogEntry> logs = [];
    bool needsSave = false;

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); // Buat array JSON kosong
    } else {
      final jsonString = await file.readAsString();
      if (jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        logs = jsonList.map((item) => TimeLogEntry.fromJson(item)).toList();
      }
    }

    final todayDate = DateUtils.dateOnly(DateTime.now());
    final hasTodayLog = logs.any(
      (log) => DateUtils.isSameDay(log.date, todayDate),
    );

    // Jika log untuk hari ini BELUM ADA dan sudah ada log sebelumnya
    if (!hasTodayLog && logs.isNotEmpty) {
      final lastLog = logs.first; // Asumsi sudah terurut dari baru ke lama
      final newTasksForToday = lastLog.tasks.map((task) {
        return LoggedTask(
          id: task.id,
          name: task.name,
          durationMinutes: 0, // Reset durasi untuk hari baru
          category: task.category,
          linkedTaskIds: List<String>.from(task.linkedTaskIds), // Wariskan link
        );
      }).toList();

      final newTodayLog = TimeLogEntry(
        date: todayDate,
        tasks: newTasksForToday,
      );
      logs.insert(0, newTodayLog); // Tambahkan log hari ini ke paling atas
      needsSave = true;

      // Hapus link dari semua hari SEBELUMNYA untuk mencegah duplikasi
      for (final log in logs) {
        if (!DateUtils.isSameDay(log.date, todayDate)) {
          for (final task in log.tasks) {
            if (task.linkedTaskIds.isNotEmpty) {
              task.linkedTaskIds.clear();
            }
          }
        }
      }
    }

    // Simpan hanya jika ada perubahan (log baru dibuat)
    if (needsSave) {
      await _saveTimeLogsWithoutNotify(file, logs);
    }

    return logs;
  }

  // Fungsi save privat tanpa notifyListeners
  Future<void> _saveTimeLogsWithoutNotify(
    File file,
    List<TimeLogEntry> logs,
  ) async {
    final listJson = logs.map((log) => log.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }

  // Fungsi save publik yang digunakan oleh provider
  Future<void> saveTimeLogs(List<TimeLogEntry> logs) async {
    final filePath = await _pathService.timeLogPath;
    final file = File(filePath);
    await _saveTimeLogsWithoutNotify(file, logs);
  }

  // ==> FUNGSI BARU UNTUK PRESET <==
  Future<List<LogTaskPreset>> loadTaskPresets() async {
    final filePath = await _pathService.logTaskPresetsPath;
    final file = File(filePath);
    if (!await file.exists()) {
      await file.writeAsString('[]');
      return [];
    }
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => LogTaskPreset.fromJson(item)).toList();
  }

  Future<void> saveTaskPresets(List<LogTaskPreset> presets) async {
    final filePath = await _pathService.logTaskPresetsPath;
    final file = File(filePath);
    final listJson = presets.map((preset) => preset.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
