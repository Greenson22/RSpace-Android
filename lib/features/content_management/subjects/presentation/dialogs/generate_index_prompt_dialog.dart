// lib/features/content_management/presentation/subjects/dialogs/generate_index_prompt_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';

// Fungsi untuk menampilkan dialog utama
Future<void> showGenerateIndexPromptDialog(
  BuildContext context,
  Subject subject,
) async {
  // Tampilkan dialog input tema terlebih dahulu
  final themeDescription = await showDialog<String>(
    context: context,
    builder: (context) => _ThemeInputDialog(subjectName: subject.name),
  );

  if (themeDescription != null &&
      themeDescription.isNotEmpty &&
      context.mounted) {
    // ==> LANGSUNG BUAT PROMPT DI SINI, TIDAK PERLU SERVICE
    final prompt =
        '''
    Buatkan saya sebuah template HTML5 lengkap dengan tema "$themeDescription".

    ATURAN SANGAT PENTING:
    1.  Gunakan HANYA inline CSS untuk semua styling. JANGAN gunakan tag `<style>` atau file CSS eksternal.
    2.  Di dalam `<body>`, WAJIB ada sebuah `<div>` kosong dengan id `main-container`. Contoh: `<div id="main-container"></div>`. Ini adalah tempat konten akan dimasukkan nanti.
    3.  Pastikan outputnya adalah HANYA kode HTML mentah, tanpa penjelasan tambahan, tanpa ```html, dan tanpa markdown formatting.
    ''';

    showDialog(
      context: context,
      builder: (context) => _PromptDisplayDialog(prompt: prompt),
    );
  }
}

// ... (sisa kode _ThemeInputDialog dan _PromptDisplayDialog tidak berubah)
class _ThemeInputDialog extends StatelessWidget {
  final String subjectName;
  const _ThemeInputDialog({required this.subjectName});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Generate Prompt Template'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deskripsikan tampilan template yang Anda inginkan untuk Subject "$subjectName".',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Tema',
                hintText: 'Contoh: tema luar angkasa gelap, desain vintage...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: const Text('Buat Prompt'),
        ),
      ],
    );
  }
}

class _PromptDisplayDialog extends StatelessWidget {
  final String prompt;
  const _PromptDisplayDialog({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Salin Prompt Ini'),
      content: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(prompt),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Salin'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: prompt));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prompt disalin ke clipboard!')),
            );
          },
        ),
      ],
    );
  }
}
