// lib/presentation/providers/time_log_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/log_task_preset_model.dart';
import '../../data/models/time_log_model.dart';
import '../../data/services/time_log_service.dart';
// ==> 1. IMPORT SERVICE DAN MODEL MY TASK
import '../../data/services/my_task_service.dart';
import '../../data/models/my_task_model.dart';

class TimeLogProvider with ChangeNotifier {
  final TimeLogService _timeLogService = TimeLogService();
  // ==> 2. BUAT INSTANCE BARU DARI MYTASKSERVICE
  final MyTaskService _myTaskService = MyTaskService();

  List<TimeLogEntry> _logs = [];
  List<TimeLogEntry> get logs => _logs;

  List<LogTaskPreset> _taskPresets = [];
  List<LogTaskPreset> get taskPresets => _taskPresets;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  TimeLogEntry? _todayLog;
  TimeLogEntry? get todayLog => _todayLog;

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
    await _findTodayLogAndSetEditable(); // Diubah menjadi async
    _isLoading = false;
    notifyListeners();
  }

  void setEditableLog(TimeLogEntry? log) {
    if (_editableLog == log) {
      _editableLog = _todayLog;
    } else {
      _editableLog = log;
    }
    notifyListeners();
  }

  // ==> FUNGSI INI DIMODIFIKASI SECARA SIGNIFIKAN <==
  Future<void> _findTodayLogAndSetEditable() async {
    final todayDate = DateUtils.dateOnly(DateTime.now());

    try {
      // Coba cari log untuk hari ini. Jika sudah ada, tidak ada aksi terkait link.
      _todayLog = _logs.firstWhere(
        (log) => DateUtils.isSameDay(log.date, todayDate),
      );
    } catch (e) {
      // Jika log hari ini TIDAK DITEMUKAN (artinya, ini pertama kali aplikasi dibuka di hari baru)
      if (_logs.isNotEmpty) {
        // Ambil log terakhir sebagai referensi (asumsi sudah terurut dari baru ke lama)
        final lastLog = _logs.first;

        // Buat daftar tugas baru untuk hari ini, wariskan nama dan link-nya
        final newTasks = lastLog.tasks.map((task) {
          return LoggedTask(
            id: task.id,
            name: task.name,
            durationMinutes: 0, // Selalu reset durasi menjadi 0
            category: task.category,
            // Salin (wariskan) link dari tugas di hari sebelumnya
            linkedTaskIds: List<String>.from(task.linkedTaskIds),
          );
        }).toList();

        // Buat entri log baru untuk hari ini
        final newTodayLog = TimeLogEntry(date: todayDate, tasks: newTasks);
        _logs.insert(0, newTodayLog); // Tambahkan ke paling atas
        _todayLog = newTodayLog;

        // ## LOGIKA BARU: Hapus Link dari Semua Hari SEBELUMNYA ##
        // Iterasi semua log, dan jika BUKAN log hari ini, hapus linknya.
        bool needsSave = false;
        for (final log in _logs) {
          if (!DateUtils.isSameDay(log.date, todayDate)) {
            for (final task in log.tasks) {
              if (task.linkedTaskIds.isNotEmpty) {
                task.linkedTaskIds.clear();
                needsSave = true;
              }
            }
          }
        }

        // Simpan hanya jika ada perubahan (log baru dibuat atau link lama dihapus)
        if (needsSave || _logs.length == 1) {
          await _saveLogs();
        }
      } else {
        // Kondisi jika ini adalah log pertama kali, tidak ada yang perlu dilakukan.
        _todayLog = null;
      }
    }

    // Selalu set log yang bisa diedit ke log hari ini.
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
    if (_editableLog == null) {
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

    _editableLog = targetLog;

    await _saveLogs();
  }

  // FUNGSI BARU UNTUK MENGHAPUS SATU LOG HARIAN
  Future<void> deleteLog(TimeLogEntry log) async {
    _logs.removeWhere((l) => l.date == log.date);
    // Jika log yang dihapus adalah log yang sedang diedit,
    // kembalikan editable log ke log hari ini.
    if (_editableLog == log) {
      _editableLog = _todayLog;
    }
    await _saveLogs();
  }

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

  // ==> 3. FUNGSI BARU UNTUK MENGUPDATE TUGAS TERHUBUNG
  Future<void> updateLinkedTasks(
    LoggedTask task,
    List<String> newLinkedIds,
  ) async {
    // Cari log yang berisi tugas ini
    final log = _logs.firstWhere((l) => l.tasks.contains(task));
    // Cari tugas yang spesifik di dalam log tersebut
    final taskToUpdate = log.tasks.firstWhere((t) => t.id == task.id);

    taskToUpdate.linkedTaskIds = newLinkedIds;
    await _saveLogs();
  }

  // ==> 4. MODIFIKASI FUNGSI incrementDuration
  Future<void> incrementDuration(
    LoggedTask task, {
    bool updateLinkedTasks = false,
  }) async {
    final taskToUpdate = _editableLog?.tasks.firstWhere((t) => t.id == task.id);
    if (taskToUpdate != null) {
      taskToUpdate.durationMinutes += 30;

      // Jika tombol "Tambah 30 Menit & Update" ditekan dan ada task terhubung
      if (updateLinkedTasks && taskToUpdate.linkedTaskIds.isNotEmpty) {
        await _updateMyTasks(taskToUpdate.linkedTaskIds);
      }

      await _saveLogs();
    }
  }

  // ==> 5. FUNGSI HELPER BARU UNTUK MENGUPDATE MY TASKS
  Future<void> _updateMyTasks(List<String> linkedIds) async {
    // Muat semua kategori dan tugas dari My Tasks
    List<TaskCategory> allCategories = await _myTaskService.loadMyTasks();
    bool changed = false;

    // Iterasi melalui semua kategori dan tugas
    for (var category in allCategories) {
      for (var myTask in category.tasks) {
        // Jika ID tugas cocok dengan yang terhubung
        if (linkedIds.contains(myTask.id)) {
          myTask.checked = true; // Tandai sebagai selesai
          myTask.count++; // Tambah jumlahnya
          myTask.date = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now()); // Update tanggal
          changed = true;
        }
      }
    }

    // Simpan perubahan jika ada
    if (changed) {
      await _myTaskService.saveMyTasks(allCategories);
    }
  }

  // --- Preset Management ---
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
