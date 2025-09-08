// lib/features/prompt_library/presentation/widgets/prompt_dialogs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/prompt_provider.dart';
import '../../domain/models/prompt_concept_model.dart';
import '../../domain/models/prompt_variation_model.dart';

// Dialog untuk menambah kategori baru
Future<void> showAddCategoryDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      final provider = Provider.of<PromptProvider>(context, listen: false);

      return AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Kategori'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama kategori tidak boleh kosong.';
              }
              if (RegExp(r'[<>:"/\\|?*]').hasMatch(value)) {
                return 'Nama mengandung karakter tidak valid.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final categoryName = controller.text.trim();
                try {
                  await provider.addCategory(categoryName);
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Kategori "$categoryName" berhasil ditambahkan.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

// Dialog untuk menambah konsep prompt baru
Future<void> showAddPromptDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final judulController = TextEditingController();
  final deskripsiUtamaController = TextEditingController();
  final namaVariasiController = TextEditingController();
  final isiPromptController = TextEditingController();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      final provider = Provider.of<PromptProvider>(context, listen: false);

      return AlertDialog(
        title: const Text('Tambah Konsep Prompt Baru'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Utama Prompt',
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: deskripsiUtamaController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Utama Prompt',
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const Divider(height: 32),
                Text(
                  'Variasi Awal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: namaVariasiController,
                  decoration: const InputDecoration(labelText: 'Nama Variasi'),
                  validator: (v) => v!.trim().isEmpty
                      ? 'Nama variasi tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: isiPromptController,
                  decoration: const InputDecoration(
                    labelText: 'Isi Prompt',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                  validator: (v) => v!.trim().isEmpty
                      ? 'Isi prompt tidak boleh kosong'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPrompt = PromptConcept(
                  idPrompt:
                      '${provider.selectedCategory!.toUpperCase()}-${const Uuid().v4().substring(0, 4)}',
                  judulUtama: judulController.text.trim(),
                  deskripsiUtama: deskripsiUtamaController.text.trim(),
                  fileName: '', // Akan dibuat oleh provider
                  variasiPrompt: [
                    PromptVariation(
                      nama: namaVariasiController.text.trim(),
                      versi: '1.0',
                      deskripsi: 'Versi awal.',
                      targetModelAi: ['General'],
                      isiPrompt: isiPromptController.text.trim(),
                    ),
                  ],
                );

                try {
                  await provider.addPrompt(
                    provider.selectedCategory!,
                    newPrompt,
                  );
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prompt baru berhasil disimpan.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan Prompt'),
          ),
        ],
      );
    },
  );
}
