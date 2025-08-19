// lib/presentation/providers/time_log_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/log_task_preset_model.dart';
import '../../data/models/time_log_model.dart';
import '../../data/services/time_log_service.dart';

class TimeLogProvider with ChangeNotifier {
  final TimeLogService _timeLogService = TimeLogService();

  List<TimeLogEntry> _logs = [];
  List<TimeLogEntry> get logs => _logs;

  List<LogTaskPreset> _taskPresets = [];
  List<LogTaskPreset> get taskPresets => _taskPresets;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  TimeLogEntry? _todayLog;
  TimeLogEntry? get todayLog => _todayLog;

  TimeLogProvider() {
    fetchLogs();
  }

  Future<void> fetchLogs({bool fetchPresets = true}) async {
    _isLoading = true;
    notifyListeners();
    _logs = await _timeLogService.loadTimeLogs();
    if (fetchPresets) {
      _taskPresets = await _timeLogService.loadTaskPresets();
    }
    _findTodayLog();
    _isLoading = false;
    notifyListeners();
  }

  void _findTodayLog() {
    final todayDate = DateUtils.dateOnly(DateTime.now());
    try {
      _todayLog = _logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, todayDate),
      );
    } catch (e) {
      _todayLog = null;
    }
  }

  Future<void> _saveLogs() async {
    await _timeLogService.saveTimeLogs(_logs);
    notifyListeners();
  }

  Future<void> _savePresets() async {
    await _timeLogService.saveTaskPresets(_taskPresets);
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENAMBAHKAN SEMUA PRESET <==
  Future<int> addTasksFromPresets() async {
    final todayDate = DateUtils.dateOnly(DateTime.now());
    _findTodayLog();

    if (_todayLog == null) {
      _todayLog = TimeLogEntry(date: todayDate, tasks: []);
      _logs.insert(0, _todayLog!);
    }

    int tasksAdded = 0;
    final existingTaskNames = _todayLog!.tasks.map((t) => t.name).toSet();

    for (final preset in _taskPresets) {
      // Hanya tambahkan jika tugas dengan nama yang sama belum ada
      if (!existingTaskNames.contains(preset.name)) {
        final newId =
            (_todayLog!.tasks.isEmpty
                ? 0
                : _todayLog!.tasks
                      .map((t) => t.id)
                      .reduce((a, b) => a > b ? a : b)) +
            1;
        final newTask = LoggedTask(id: newId, name: preset.name);
        _todayLog!.tasks.add(newTask);
        existingTaskNames.add(
          preset.name,
        ); // Update set untuk pengecekan berikutnya
        tasksAdded++;
      }
    }

    if (tasksAdded > 0) {
      await _saveLogs();
    }
    return tasksAdded;
  }

  Future<void> addTask(String name, {String? category}) async {
    final todayDate = DateUtils.dateOnly(DateTime.now());
    _findTodayLog();

    if (_todayLog == null) {
      _todayLog = TimeLogEntry(date: todayDate, tasks: []);
      _logs.insert(0, _todayLog!);
    }

    // Cek duplikat sebelum menambahkan
    final taskExists = _todayLog!.tasks.any((task) => task.name == name);
    if (taskExists) {
      return; // Jangan tambahkan jika sudah ada
    }

    final newId =
        (_todayLog!.tasks.isEmpty
            ? 0
            : _todayLog!.tasks
                  .map((t) => t.id)
                  .reduce((a, b) => a > b ? a : b)) +
        1;
    final newTask = LoggedTask(id: newId, name: name, category: category);
    _todayLog!.tasks.add(newTask);

    await _saveLogs();
  }

  Future<void> deleteTask(LoggedTask task) async {
    _todayLog?.tasks.removeWhere((t) => t.id == task.id);
    await _saveLogs();
  }

  Future<void> updateTaskName(LoggedTask task, String newName) async {
    final taskToUpdate = _todayLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.name = newName;
      await _saveLogs();
    }
  }

  Future<void> updateDuration(LoggedTask task, int newDuration) async {
    final taskToUpdate = _todayLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.durationMinutes = newDuration < 0 ? 0 : newDuration;
      await _saveLogs();
    }
  }

  Future<void> incrementDuration(LoggedTask task) async {
    final taskToUpdate = _todayLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.durationMinutes += 30;
      await _saveLogs();
    }
  }

  // FUNGSI CRUD UNTUK PRESET
  Future<void> addPreset(String name) async {
    final newId =
        (_taskPresets.isEmpty
            ? 0
            : _taskPresets.map((p) => p.id).reduce((a, b) => a > b ? a : b)) +
        1;
    _taskPresets.add(LogTaskPreset(id: newId, name: name));
    await _savePresets();
  }

  Future<void> updatePreset(LogTaskPreset preset, String newName) async {
    final presetToUpdate = _taskPresets.firstWhere((p) => p.id == preset.id);
    presetToUpdate.name = newName;
    await _savePresets();
  }

  Future<void> deletePreset(LogTaskPreset preset) async {
    _taskPresets.removeWhere((p) => p.id == preset.id);
    await _savePresets();
  }
}
