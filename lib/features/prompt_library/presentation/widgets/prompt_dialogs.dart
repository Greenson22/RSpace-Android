// lib/features/prompt_library/presentation/widgets/prompt_dialogs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../application/prompt_provider.dart';
import '../../domain/models/prompt_concept_model.dart';

// ... (KODE showAddCategoryDialog SAMA SEPERTI SEBELUMNYA) ...
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
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Contoh: Coding, Writing, Ide Bisnis',
            ),
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

// ... (KODE showAddPromptDialog SAMA SEPERTI SEBELUMNYA) ...
Future<void> showAddPromptDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final contentController = TextEditingController();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      final provider = Provider.of<PromptProvider>(context, listen: false);

      return AlertDialog(
        title: const Text('Tambah Prompt Baru'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Prompt',
                      hintText: 'Misal: Asisten Coding Flutter',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Singkat',
                      hintText: 'Kegunaan prompt ini...',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Deskripsi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Isi Prompt',
                      hintText: 'Tulis prompt lengkap di sini...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10,
                    minLines: 5,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Isi prompt tidak boleh kosong'
                        : null,
                  ),
                ],
              ),
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
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  content: contentController.text.trim(),
                  fileName: '',
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
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}

// ... (KODE showEditPromptDialog SAMA SEPERTI SEBELUMNYA) ...
Future<void> showEditPromptDialog(
  BuildContext context,
  PromptConcept existingPrompt,
) {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: existingPrompt.title);
  final descriptionController = TextEditingController(
    text: existingPrompt.description,
  );
  final contentController = TextEditingController(text: existingPrompt.content);

  return showDialog(
    context: context,
    builder: (dialogContext) {
      final provider = Provider.of<PromptProvider>(context, listen: false);

      return AlertDialog(
        title: const Text('Edit Prompt'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Prompt',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Judul tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Singkat',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Deskripsi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Isi Prompt (Markdown Supported)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 10,
                    minLines: 5,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Isi prompt tidak boleh kosong'
                        : null,
                  ),
                ],
              ),
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
                final updatedPrompt = PromptConcept(
                  idPrompt: existingPrompt.idPrompt,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  content: contentController.text.trim(),
                  fileName: existingPrompt.fileName,
                );

                try {
                  await provider.updatePrompt(
                    provider.selectedCategory!,
                    existingPrompt,
                    updatedPrompt,
                  );
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prompt berhasil diperbarui.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error update: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}

// === BARU: Dialog Memilih Topik/Kategori ===
Future<String?> showSelectTopicDialog(
  BuildContext context,
  List<String> categories, {
  String? currentCategory,
  String title = 'Pilih Topik',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final availableCategories = categories
          .where((c) => c != currentCategory)
          .toList();

      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: availableCategories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Tidak ada topik lain tersedia.",
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableCategories.length,
                  itemBuilder: (context, index) {
                    final category = availableCategories[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.folder_open,
                        color: Colors.amber,
                      ),
                      title: Text(category),
                      onTap: () {
                        Navigator.pop(context, category);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      );
    },
  );
}
