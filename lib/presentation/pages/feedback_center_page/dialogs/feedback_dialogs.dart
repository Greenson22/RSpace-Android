// lib/presentation/pages/feedback_center_page/dialogs/feedback_dialogs.dart
import 'package:flutter/material.dart';
import '../../../../data/models/feedback_model.dart';
import '../../../providers/feedback_provider.dart';

// Dialog untuk menambah atau mengedit item
Future<void> showAddEditFeedbackDialog(
  BuildContext context, {
  FeedbackItem? item,
  required FeedbackProvider provider,
}) async {
  final isEditing = item != null;
  final _formKey = GlobalKey<FormState>();

  String _title = item?.title ?? '';
  String _description = item?.description ?? '';
  FeedbackType _type = item?.type ?? FeedbackType.idea;

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Catatan' : 'Tambah Catatan Baru'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pilihan Tipe
                    SegmentedButton<FeedbackType>(
                      segments: const [
                        ButtonSegment(
                          value: FeedbackType.idea,
                          icon: Text('💡 Ide'),
                        ),
                        ButtonSegment(
                          value: FeedbackType.bug,
                          icon: Text('🐞 Bug'),
                        ),
                        ButtonSegment(
                          value: FeedbackType.suggestion,
                          icon: Text('⭐ Saran'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (newSelection) {
                        setDialogState(() {
                          _type = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Judul
                    TextFormField(
                      initialValue: _title,
                      decoration: const InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong.';
                        }
                        return null;
                      },
                      onSaved: (value) => _title = value!,
                    ),
                    const SizedBox(height: 16),
                    // Deskripsi
                    TextFormField(
                      initialValue: _description,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (Opsional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      onSaved: (value) => _description = value!,
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
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (isEditing) {
                      item!.title = _title.trim();
                      item.description = _description.trim();
                      item.type = _type;
                      provider.updateItem(item);
                    } else {
                      provider.addItem(
                        _title.trim(),
                        _description.trim(),
                        _type,
                      );
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

// Dialog untuk mengubah status
Future<void> showChangeStatusDialog(
  BuildContext context,
  FeedbackItem item,
  FeedbackProvider provider,
) async {
  final newStatus = await showDialog<FeedbackStatus>(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: const Text('Ubah Status'),
        children: FeedbackStatus.values.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Text(status.toString().split('.').last),
          );
        }).toList(),
      );
    },
  );

  if (newStatus != null) {
    provider.updateStatus(item, newStatus);
  }
}
