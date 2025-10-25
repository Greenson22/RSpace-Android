// lib/features/my_tasks/presentation/dialogs/task_dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk input formatter
import 'package:intl/intl.dart';
import 'package:my_aplication/features/my_tasks/domain/models/my_task_model.dart';
import 'package:my_aplication/features/my_tasks/application/my_task_provider.dart';
import 'package:provider/provider.dart';
// Ganti import ini jika path berbeda
import '../../../content_management/presentation/topics/dialogs/topic_dialogs.dart'
    as cm_dialogs;

// Dialog Reorder Tasks
void showReorderTasksDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (dialogContext) => ChangeNotifierProvider.value(
      value: provider,
      child: _ReorderTasksDialog(category: category),
    ),
  );
}

class _ReorderTasksDialog extends StatefulWidget {
  final TaskCategory category;

  const _ReorderTasksDialog({required this.category});

  @override
  State<_ReorderTasksDialog> createState() => _ReorderTasksDialogState();
}

class _ReorderTasksDialogState extends State<_ReorderTasksDialog> {
  late List<MyTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List<MyTask>.from(widget.category.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyTaskProvider>(context, listen: false);

    return AlertDialog(
      title: Text('Urutkan Task di "${widget.category.name}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return Card(
              key: ValueKey(task.id),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(task.name),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _tasks.removeAt(oldIndex);
              _tasks.insert(newIndex, item);
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            provider.updateTasksOrder(widget.category, _tasks);
            Navigator.pop(context);
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

// Dialog Tambah Task
void showAddTaskDialog(BuildContext context, TaskCategory category) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: _AddTaskDialogContent(category: category),
    ),
  );
}

class _AddTaskDialogContent extends StatefulWidget {
  final TaskCategory category;
  const _AddTaskDialogContent({required this.category});

  @override
  State<_AddTaskDialogContent> createState() => _AddTaskDialogContentState();
}

class _AddTaskDialogContentState extends State<_AddTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController(
    text: '100',
  ); // Default target
  TaskType _selectedType = TaskType.simple;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final name = _nameController.text.trim();
    int targetCount = 1;
    if (_selectedType == TaskType.progress) {
      targetCount = int.tryParse(_targetController.text) ?? 100;
      if (targetCount <= 0) targetCount = 1; // Pastikan target > 0
    }

    provider.addTask(
      widget.category,
      name,
      type: _selectedType,
      targetCount: targetCount,
    );
    Navigator.pop(context);
    _showSnackBar(context, 'Task "$name" berhasil ditambahkan.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Task Baru di ${widget.category.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nama Task'),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              Text('Tipe Task:', style: Theme.of(context).textTheme.titleSmall),
              RadioListTile<TaskType>(
                title: const Text('Simple Count'),
                subtitle: const Text('Menghitung jumlah total.'),
                value: TaskType.simple,
                groupValue: _selectedType,
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              RadioListTile<TaskType>(
                title: const Text('Progress Percentage'),
                subtitle: const Text('Menampilkan progres 0-100%.'),
                value: TaskType.progress,
                groupValue: _selectedType,
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              // Tampilkan input target jika tipe progress
              if (_selectedType == TaskType.progress)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _targetController,
                    decoration: const InputDecoration(
                      labelText: 'Target untuk 100%',
                      hintText: 'Contoh: 100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Target wajib diisi';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Masukkan angka > 0';
                      return null;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveTask, child: const Text('Simpan')),
      ],
    );
  }
}

// Dialog Edit Task
void showEditTaskDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: _EditTaskDialogContent(category: category, task: task),
    ),
  );
}

class _EditTaskDialogContent extends StatefulWidget {
  final TaskCategory category;
  final MyTask task;
  const _EditTaskDialogContent({required this.category, required this.task});

  @override
  State<_EditTaskDialogContent> createState() => _EditTaskDialogContentState();
}

class _EditTaskDialogContentState extends State<_EditTaskDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _countController;
  late TextEditingController _targetController;
  late TextEditingController _targetTodayController;
  late DateTime _selectedDate;
  late TaskType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _countController = TextEditingController(
      text: widget.task.count.toString(),
    );
    _targetController = TextEditingController(
      text: widget.task.targetCount.toString(),
    );
    _targetTodayController = TextEditingController(
      text: widget.task.targetCountToday.toString(),
    );
    _selectedDate = DateTime.tryParse(widget.task.date) ?? DateTime.now();
    _selectedType = widget.task.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _targetController.dispose();
    _targetTodayController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<MyTaskProvider>(context, listen: false);
    final newName = _nameController.text.trim();
    final newCount = int.tryParse(_countController.text) ?? widget.task.count;
    int newTargetCount = widget.task.targetCount;
    int newTargetToday =
        int.tryParse(_targetTodayController.text) ??
        widget.task.targetCountToday;
    if (newTargetToday < 0) newTargetToday = 0; // Pastikan tidak negatif

    if (_selectedType == TaskType.progress) {
      newTargetCount = int.tryParse(_targetController.text) ?? 100;
      if (newTargetCount <= 0) newTargetCount = 1;
    }

    provider.editTask(
      widget.category,
      widget.task,
      newName: newName,
      newType: _selectedType,
      newCount: newCount,
      newTargetCount: newTargetCount,
      newDate: _selectedDate,
      newTargetToday: newTargetToday,
    );
    Navigator.pop(context);
    _showSnackBar(context, 'Task "$newName" berhasil diperbarui.');
  }

  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Task: ${widget.task.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Task'),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tipe Task'),
                subtitle: Text(
                  _selectedType == TaskType.progress
                      ? 'Progress Percentage'
                      : 'Simple Count',
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
                leading: Icon(
                  _selectedType == TaskType.progress
                      ? Icons.show_chart
                      : Icons.format_list_numbered,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                decoration: InputDecoration(
                  labelText: _selectedType == TaskType.progress
                      ? 'Progress Saat Ini'
                      : 'Jumlah Total Saat Ini',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final val = int.tryParse(v);
                  if (val == null || val < 0) return 'Masukkan angka >= 0';
                  // Validasi tambahan untuk progress (jika count TIDAK BOLEH > target)
                  // if (_selectedType == TaskType.progress) {
                  //   final target = int.tryParse(_targetController.text) ?? 0;
                  //   if (target > 0 && val > target) {
                  //     return 'Progress tidak boleh > target';
                  //   }
                  // }
                  return null;
                },
              ),
              if (_selectedType == TaskType.progress)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _targetController,
                    decoration: const InputDecoration(
                      labelText: 'Target untuk 100%',
                      hintText: 'Contoh: 100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Target wajib diisi';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Masukkan angka > 0';
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetTodayController,
                decoration: const InputDecoration(
                  labelText: 'Target Harian (0 = tanpa target)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Target harian wajib diisi';
                  final val = int.tryParse(v);
                  if (val == null || val < 0) return 'Masukkan angka >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text("Tanggal Jatuh Tempo"),
                subtitle: Text(
                  DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_selectedDate),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}

// Dialog Delete Task
void showDeleteTaskDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus Task'),
      content: Text('Anda yakin ingin menghapus task "${task.name}"?'),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text('Hapus'),
          onPressed: () {
            provider.deleteTask(category, task);
            Navigator.pop(context);
            _showSnackBar(context, 'Task "${task.name}" berhasil dihapus.');
          },
        ),
      ],
    ),
  );
}

// Dialog Tambah Progress (untuk tipe progress)
void showAddProgressCountDialog(
  BuildContext context,
  TaskCategory category,
  MyTask task,
) {
  final provider = Provider.of<MyTaskProvider>(context, listen: false);
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Tambah Progress: ${task.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Jumlah Progress Ditambah',
            hintText: 'Target: ${task.targetCount}, Saat ini: ${task.count}',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final amountToAdd = int.tryParse(controller.text);
              if (amountToAdd != null && amountToAdd > 0) {
                provider.addProgressCount(category, task, amountToAdd);
                Navigator.pop(context);
                _showSnackBar(context, 'Progress ditambahkan.');
              } else {
                _showSnackBar(
                  context,
                  'Masukkan jumlah yang valid (> 0).',
                  isError: true,
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      );
    },
  );
}

// Dialog Konfirmasi Increment Count (untuk tipe simple)
Future<bool?> showIncrementCountConfirmationDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi'),
      content: const Text(
        'Tambah hitungan total dan hitungan hari ini sebanyak 1? Tanggal "due" juga akan diperbarui.',
      ),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: const Text('Ya, Tambah'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}

// Dialog Konfirmasi Tambah 1 Progress (untuk tipe progress)
Future<bool?> showAddOneProgressConfirmationDialog(
  BuildContext context,
  String taskName,
) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi Tambah Progress'),
      content: Text('Tambah 1 progress ke task "$taskName"?'),
      actions: [
        TextButton(
          child: const Text('Batal'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: const Text('Ya, Tambah 1'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
}

// Fungsi _showSnackBar
void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ),
  );
}
