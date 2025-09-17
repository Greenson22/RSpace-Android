// lib/features/settings/presentation/dialogs/gemini_model_management_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';
import 'package:uuid/uuid.dart';

// Fungsi untuk menampilkan dialog
Future<List<GeminiModelInfo>?> showGeminiModelManagementDialog(
  BuildContext context, {
  required List<GeminiModelInfo> currentModels,
}) {
  return showDialog<List<GeminiModelInfo>>(
    context: context,
    builder: (context) =>
        GeminiModelManagementDialog(initialModels: currentModels),
  );
}

// Widget utama dialog
class GeminiModelManagementDialog extends StatefulWidget {
  final List<GeminiModelInfo> initialModels;
  const GeminiModelManagementDialog({super.key, required this.initialModels});

  @override
  State<GeminiModelManagementDialog> createState() =>
      _GeminiModelManagementDialogState();
}

class _GeminiModelManagementDialogState
    extends State<GeminiModelManagementDialog> {
  late List<GeminiModelInfo> _models;

  @override
  void initState() {
    super.initState();
    _models = List.from(widget.initialModels);
  }

  Future<void> _addNewOrEditModel({GeminiModelInfo? existingModel}) async {
    final result = await _showAddOrEditModelDialog(
      existingModel: existingModel,
    );
    if (result != null) {
      setState(() {
        if (existingModel != null) {
          final index = _models.indexWhere((m) => m.id == result.id);
          if (index != -1) _models[index] = result;
        } else {
          _models.add(result);
        }
      });
    }
  }

  void _deleteModel(GeminiModelInfo modelToDelete) {
    if (modelToDelete.isDefault) return;
    setState(() {
      _models.removeWhere((m) => m.id == modelToDelete.id);
    });
  }

  Future<GeminiModelInfo?> _showAddOrEditModelDialog({
    GeminiModelInfo? existingModel,
  }) {
    final isEditing = existingModel != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingModel?.name ?? '',
    );
    final idController = TextEditingController(
      text: existingModel?.modelId ?? '',
    );

    return showDialog<GeminiModelInfo>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Ubah Model AI' : 'Tambah Model AI Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Tampilan Model',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'ID Model (contoh: gemini-1.5-pro)',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'ID Model tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  GeminiModelInfo(
                    id: existingModel?.id,
                    name: nameController.text.trim(),
                    modelId: idController.text.trim(),
                    isDefault: existingModel?.isDefault ?? false,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Kelola Model AI'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addNewOrEditModel,
            tooltip: 'Tambah Model Baru',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _models.length,
          itemBuilder: (context, index) {
            final model = _models[index];
            return ListTile(
              title: Text(model.name),
              subtitle: Text(model.modelId),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Model',
                    onPressed: () => _addNewOrEditModel(existingModel: model),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: model.isDefault ? Colors.grey : Colors.red,
                      size: 20,
                    ),
                    tooltip: model.isDefault
                        ? 'Model default tidak bisa dihapus'
                        : 'Hapus Model',
                    onPressed: model.isDefault
                        ? null
                        : () => _deleteModel(model),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_models),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}
