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

  // ==> STATE BARU UNTUK MENGELOLA LOG YANG SEDANG DIEDIT <==
  TimeLogEntry? _editableLog;
  TimeLogEntry? get editableLog => _editableLog;

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
    _findTodayLogAndSetEditable(); // Diubah
    _isLoading = false;
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGATUR LOG MANA YANG AKTIF <==
  void setEditableLog(TimeLogEntry? log) {
    _editableLog = log;
    notifyListeners();
  }

  void _findTodayLogAndSetEditable() {
    final todayDate = DateUtils.dateOnly(DateTime.now());
    try {
      _todayLog = _logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, todayDate),
      );
    } catch (e) {
      _todayLog = null;
    }
    // Secara default, log yang bisa diedit adalah log hari ini
    _editableLog = _todayLog;
  }

  Future<void> _saveLogs() async {
    await _timeLogService.saveTimeLogs(_logs);
    notifyListeners();
  }

  Future<void> _savePresets() async {
    await _timeLogService.saveTaskPresets(_taskPresets);
    notifyListeners();
  }

  Future<int> addTasksFromPresets() async {
    // Operasi ini sekarang berlaku pada log yang sedang aktif
    if (_editableLog == null) {
      // Jika log aktif (misal hari ini) belum ada, buat dulu
      final date = DateUtils.dateOnly(DateTime.now());
      _editableLog = TimeLogEntry(date: date, tasks: []);
      _logs.insert(0, _editableLog!);
      if (DateUtils.isSameDay(date, DateTime.now())) {
        _todayLog = _editableLog;
      }
    }

    final List<LoggedTask> tasksToAdd = [];
    final existingTaskNames = _editableLog!.tasks.map((t) => t.name).toSet();

    int latestId = _editableLog!.tasks.isEmpty
        ? 0
        : _editableLog!.tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b);

    for (final preset in _taskPresets) {
      if (!existingTaskNames.contains(preset.name)) {
        latestId++;
        tasksToAdd.add(LoggedTask(id: latestId, name: preset.name));
        existingTaskNames.add(preset.name);
      }
    }

    if (tasksToAdd.isNotEmpty) {
      _editableLog!.tasks.addAll(tasksToAdd);
      await _saveLogs();
    }

    return tasksToAdd.length;
  }

  // ==> Diperbarui untuk menerima tanggal spesifik <==
  Future<void> addTask(String name, {DateTime? date}) async {
    final targetDate = DateUtils.dateOnly(
      date ?? _editableLog?.date ?? DateTime.now(),
    );

    TimeLogEntry? targetLog;
    try {
      targetLog = _logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, targetDate),
      );
    } catch (e) {
      targetLog = null;
    }

    if (targetLog == null) {
      targetLog = TimeLogEntry(date: targetDate, tasks: []);
      _logs.insert(0, targetLog);
      // Urutkan kembali log setelah menambahkan entri baru
      _logs.sort((a, b) => b.date.compareTo(a.date));
    }

    final taskExists = targetLog.tasks.any((task) => task.name == name);
    if (taskExists) {
      return;
    }

    final newId =
        (targetLog.tasks.isEmpty
            ? 0
            : targetLog.tasks
                  .map((t) => t.id)
                  .reduce((a, b) => a > b ? a : b)) +
        1;
    final newTask = LoggedTask(id: newId, name: name);
    targetLog.tasks.add(newTask);

    // Pastikan log yang diedit tetap menjadi log yang aktif
    _editableLog = targetLog;

    await _saveLogs();
  }

  // ==> Semua fungsi di bawah ini sekarang beroperasi pada _editableLog <==
  Future<void> deleteTask(LoggedTask task) async {
    _editableLog?.tasks.removeWhere((t) => t.id == task.id);
    await _saveLogs();
  }

  Future<void> updateTaskName(LoggedTask task, String newName) async {
    final taskToUpdate = _editableLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.name = newName;
      await _saveLogs();
    }
  }

  Future<void> updateDuration(LoggedTask task, int newDuration) async {
    final taskToUpdate = _editableLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.durationMinutes = newDuration < 0 ? 0 : newDuration;
      await _saveLogs();
    }
  }

  Future<void> incrementDuration(LoggedTask task) async {
    final taskToUpdate = _editableLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.durationMinutes += 30;
      await _saveLogs();
    }
  }

  // FUNGSI CRUD UNTUK PRESET (TIDAK BERUBAH)
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
