// lib/features/my_tasks/application/my_task_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import '../domain/models/my_task_model.dart';
import 'my_task_service.dart';
import '../../time_management/application/services/time_log_service.dart';
import '../../time_management/domain/models/time_log_model.dart';

class MyTaskProvider with ChangeNotifier {
  final MyTaskService _myTaskService = MyTaskService();
  final TimeLogService _timeLogService = TimeLogService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isCategoryReorderEnabled = false;
  bool get isCategoryReorderEnabled => _isCategoryReorderEnabled;

  bool _showHiddenCategories = false;
  bool get showHiddenCategories => _showHiddenCategories;

  bool _isGridView = false;
  bool get isGridView => _isGridView;

  List<TaskCategory> _allCategories = [];
  List<TaskCategory> get categories {
    if (_showHiddenCategories) {
      return _allCategories;
    }
    return _allCategories.where((c) => !c.isHidden).toList();
  }

  final Map<String, Set<String>> _selectedTasks = {};
  Map<String, Set<String>> get selectedTasks => _selectedTasks;
  bool get isTaskSelectionMode =>
      _selectedTasks.values.any((s) => s.isNotEmpty);
  int get totalSelectedTasks =>
      _selectedTasks.values.fold(0, (sum, set) => sum + set.length);

  MyTaskProvider() {
    fetchTasks();
  }

  void toggleTaskSelection(TaskCategory category, MyTask task) {
    _selectedTasks.putIfAbsent(category.name, () => {});
    if (_selectedTasks[category.name]!.contains(task.id)) {
      _selectedTasks[category.name]!.remove(task.id);
    } else {
      _selectedTasks[category.name]!.add(task.id);
    }
    notifyListeners();
  }

  void selectAllTasksInCategory(TaskCategory category, bool select) {
    _selectedTasks.putIfAbsent(category.name, () => {});
    if (select) {
      final taskIds = category.tasks.map((t) => t.id).toSet();
      _selectedTasks[category.name]!.addAll(taskIds);
    } else {
      _selectedTasks[category.name]!.clear();
    }
    notifyListeners();
  }

  void clearTaskSelection() {
    _selectedTasks.clear();
    notifyListeners();
  }

  Future<void> moveSelectedTasks(String targetCategoryName) async {
    final targetCategoryIndex = _allCategories.indexWhere(
      (c) => c.name == targetCategoryName,
    );
    if (targetCategoryIndex == -1) return;

    final List<MyTask> tasksToMove = [];

    for (var entry in _selectedTasks.entries) {
      final sourceCategoryName = entry.key;
      final selectedIds = entry.value;
      if (selectedIds.isEmpty) continue;

      final sourceCategoryIndex = _allCategories.indexWhere(
        (c) => c.name == sourceCategoryName,
      );
      if (sourceCategoryIndex != -1) {
        final sourceCategory = _allCategories[sourceCategoryIndex];
        tasksToMove.addAll(
          sourceCategory.tasks.where((t) => selectedIds.contains(t.id)),
        );
        sourceCategory.tasks.removeWhere((t) => selectedIds.contains(t.id));
      }
    }

    _allCategories[targetCategoryIndex].tasks.addAll(tasksToMove);

    clearTaskSelection();
    await _saveTasks();
  }

  void toggleShowHidden() {
    _showHiddenCategories = !_showHiddenCategories;
    notifyListeners();
  }

  void toggleCategoryReorder() {
    _isCategoryReorderEnabled = !_isCategoryReorderEnabled;
    notifyListeners();
  }

  Future<void> toggleLayout() async {
    _isGridView = !_isGridView;
    await _prefsService.saveMyTasksLayoutPreference(_isGridView);
    notifyListeners();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allCategories = await _myTaskService.loadMyTasks();
      _isGridView = await _prefsService.loadMyTasksLayoutPreference();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    await _myTaskService.saveMyTasks(_allCategories);
    notifyListeners();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _allCategories.removeAt(oldIndex);
    _allCategories.insert(newIndex, item);
    await _saveTasks();
  }

  Future<void> addCategory(String name, {String icon = '📝'}) async {
    final newCategory = TaskCategory(
      name: name,
      icon: icon,
      tasks: [],
      isHidden: false,
    );
    _allCategories.add(newCategory);
    await _saveTasks();
  }

  Future<void> renameCategory(TaskCategory category, String newName) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      _allCategories[index] = TaskCategory(
        name: newName,
        icon: category.icon,
        tasks: category.tasks,
        isHidden: category.isHidden,
      );
      await _saveTasks();
    }
  }

  Future<void> deleteCategory(TaskCategory category) async {
    _allCategories.removeWhere((c) => c.name == category.name);
    await _saveTasks();
  }

  Future<void> updateCategoryIcon(TaskCategory category, String newIcon) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      _allCategories[index] = TaskCategory(
        name: category.name,
        icon: newIcon,
        tasks: category.tasks,
        isHidden: category.isHidden,
      );
      await _saveTasks();
    }
  }

  Future<void> toggleCategoryVisibility(TaskCategory category) async {
    final index = _allCategories.indexWhere((c) => c.name == category.name);
    if (index != -1) {
      _allCategories[index] = TaskCategory(
        name: category.name,
        icon: category.icon,
        tasks: category.tasks,
        isHidden: !category.isHidden,
      );
      await _saveTasks();
    }
  }

  Future<void> updateTasksOrder(
    TaskCategory category,
    List<MyTask> newOrderedTasks,
  ) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      _allCategories[categoryIndex] = TaskCategory(
        name: category.name,
        icon: category.icon,
        tasks: newOrderedTasks,
        isHidden: category.isHidden,
      );
      await _saveTasks();
    }
  }

  Future<void> addTask(TaskCategory category, String taskName) async {
    final newTask = MyTask(
      name: taskName,
      count: 0,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      checked: false,
    );
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      _allCategories[categoryIndex].tasks.add(newTask);
      await _saveTasks();
    }
  }

  Future<void> renameTask(
    TaskCategory category,
    MyTask task,
    String newName,
  ) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexWhere(
        (t) => t.id == task.id,
      );
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].name = newName;
        await _saveTasks();
      }
    }
  }

  Future<void> deleteTask(TaskCategory category, MyTask task) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      _allCategories[categoryIndex].tasks.removeWhere((t) => t.id == task.id);
      await _saveTasks();
    }
  }

  Future<void> incrementTaskCount(TaskCategory category, MyTask task) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexWhere(
        (t) => t.id == task.id,
      );
      if (taskIndex != -1) {
        final currentTask = _allCategories[categoryIndex].tasks[taskIndex];
        currentTask.count++;
        currentTask.countToday++;
        currentTask.date = DateFormat('yyyy-MM-dd').format(DateTime.now());
        currentTask.lastUpdated = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now());
        await _updateTimeLogForTask(currentTask.id);
        await _saveTasks();
      }
    }
  }

  Future<void> _updateTimeLogForTask(String myTaskId) async {
    List<TimeLogEntry> allLogs = await _timeLogService.loadTimeLogs();
    bool logChanged = false;

    for (var logEntry in allLogs) {
      for (var loggedTask in logEntry.tasks) {
        if (loggedTask.linkedTaskIds.contains(myTaskId)) {
          loggedTask.durationMinutes += 30;
          logChanged = true;
        }
      }
    }

    if (logChanged) {
      await _timeLogService.saveTimeLogs(allLogs);
    }
  }

  Future<void> updateTaskDate(
    TaskCategory category,
    MyTask task,
    DateTime newDate,
  ) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexWhere(
        (t) => t.id == task.id,
      );
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].date = DateFormat(
          'yyyy-MM-dd',
        ).format(newDate);
        await _saveTasks();
      }
    }
  }

  Future<void> updateTaskCount(
    TaskCategory category,
    MyTask task,
    int newCount,
  ) async {
    final categoryIndex = _allCategories.indexWhere(
      (c) => c.name == category.name,
    );
    if (categoryIndex != -1) {
      final taskIndex = _allCategories[categoryIndex].tasks.indexWhere(
        (t) => t.id == task.id,
      );
      if (taskIndex != -1) {
        _allCategories[categoryIndex].tasks[taskIndex].count = newCount;
        await _saveTasks();
      }
    }
  }

  // ==> PERUBAHAN DI SINI: FUNGSI UNCHECK ALL DIHAPUS <==
}
