// lib/features/prompt_library/presentation/widgets/prompt_dialogs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/prompt_provider.dart';

Future<void> showAddCategoryDialog(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    builder: (dialogContext) {
      // Menggunakan konteks dari halaman utama yang memiliki provider
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
              // Validasi dasar untuk karakter yang tidak valid dalam nama folder
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
                    // Jangan tutup dialog jika ada error, agar pengguna bisa lihat pesannya
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
