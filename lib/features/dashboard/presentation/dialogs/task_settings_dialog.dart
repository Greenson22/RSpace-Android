// lib/features/dashboard/presentation/dialogs/task_settings_dialog.dart

import 'package:flutter/material.dart';
// ==> IMPORT SERVICE BARU <==
import 'package:my_aplication/features/settings/application/services/dashboard_settings_service.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_service.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';

void showTaskSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TaskSettingsDialog(),
  );
}

class TaskSettingsDialog extends StatefulWidget {
  const TaskSettingsDialog({super.key});

  @override
  State<TaskSettingsDialog> createState() => _TaskSettingsDialogState();
}

class _TaskSettingsDialogState extends State<TaskSettingsDialog> {
  // ==> GUNAKAN SERVICE BARU <==
  final DashboardSettingsService _settingsService = DashboardSettingsService();
  final MyTaskService _myTaskService = MyTaskService();

  bool _isLoading = true;
  List<TaskCategory> _allCategories = [];
  Set<String> _excludedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _myTaskService.loadMyTasks();
      // ==> CARA MEMUAT DATA DIPERBARUI <==
      final settings = await _settingsService.loadSettings();
      final excluded = settings['excludedTaskCategories'] ?? {};

      if (mounted) {
        setState(() {
          _allCategories = categories.where((c) => !c.isHidden).toList();
          _excludedCategoryIds = excluded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle error
      }
    }
  }

  void _onSelectionChanged(bool? value, String categoryName) {
    setState(() {
      if (value == true) {
        _excludedCategoryIds.remove(categoryName);
      } else {
        _excludedCategoryIds.add(categoryName);
      }
    });
  }

  Future<void> _saveSettings() async {
    // ==> CARA MENYIMPAN DATA DIPERBARUI <==
    final currentSettings = await _settingsService.loadSettings();
    await _settingsService.saveSettings(
      excludedSubjects: currentSettings['excludedSubjects'] ?? <String>{},
      excludedTaskCategories: _excludedCategoryIds,
    );
    if (mounted) {
      Navigator.of(context).pop(true); // Return true to indicate a change
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Hitungan Tugas'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Pilih kategori mana yang akan dihitung dalam statistik "Tugas Belum Selesai" di Dashboard.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  ..._allCategories.map((category) {
                    return CheckboxListTile(
                      title: Text(category.name),
                      value: !_excludedCategoryIds.contains(category.name),
                      onChanged: (value) =>
                          _onSelectionChanged(value, category.name),
                    );
                  }).toList(),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan')),
      ],
    );
  }
}
