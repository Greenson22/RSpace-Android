// lib/features/notes/presentation/dialogs/note_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import 'package:provider/provider.dart';

void showNoteSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const NoteSettingsDialog(),
  );
}

class NoteSettingsDialog extends StatelessWidget {
  const NoteSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AlertDialog(
          title: const Text('Pengaturan Catatan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text(
                  themeProvider.defaultNoteIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: const Text('Ikon Default Catatan Baru'),
                subtitle: const Text('Ketuk untuk mengubah ikon default.'),
                onTap: () async {
                  await showIconPickerDialog(
                    context: context,
                    name: 'Catatan',
                    onIconSelected: (newIcon) {
                      themeProvider.updateDefaultNoteIcon(newIcon);
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
