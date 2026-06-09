// lib/features/content_management/presentation/discussions/dialogs/manage_point_presets_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../../../domain/models/point_preset_model.dart';

void showManagePointPresetsDialog(BuildContext context) {
  final provider = Provider.of<DiscussionProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const ManagePointPresetsDialog(),
    ),
  );
}

class ManagePointPresetsDialog extends StatelessWidget {
  const ManagePointPresetsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscussionProvider>(
      builder: (context, provider, child) {
        final presets = provider.pointPresets;
        return AlertDialog(
          title: const Text('Kelola Preset Poin'),
          content: SizedBox(
            width: double.maxFinite,
            child: presets.isEmpty
                ? const Center(child: Text('Belum ada preset.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      return ListTile(
                        title: Text(preset.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _showEditPresetDialog(context, preset),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  provider.deletePointPreset(preset),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showAddPresetDialog(context),
              child: const Text('Tambah Baru'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPresetDialog(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Preset Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Teks Preset'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addPointPreset(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, PointPreset preset) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final controller = TextEditingController(text: preset.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Teks Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Teks Baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.updatePointPreset(preset, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
