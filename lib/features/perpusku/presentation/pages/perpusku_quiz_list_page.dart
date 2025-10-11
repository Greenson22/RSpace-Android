// lib/features/perpusku/presentation/pages/perpusku_quiz_list_page.dart

import 'package:flutter/material.dart';
import '../../domain/models/perpusku_models.dart';

class PerpuskuQuizListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const PerpuskuQuizListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    // Logika untuk memuat dan menampilkan file kuis .json akan ditambahkan di sini.
    // Untuk saat ini, kita akan menampilkan pesan placeholder.

    return Scaffold(
      appBar: AppBar(title: Text('Kuis: ${subject.name}')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Fitur Kuis Perpusku sedang dalam pengembangan.\n\nDi sini Anda akan dapat melihat, membuat, dan memulai kuis yang tersimpan sebagai file .json di dalam folder subjek ini.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement dialog untuk membuat file kuis JSON baru
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur tambah kuis belum tersedia.')),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Buat Kuis Baru',
      ),
    );
  }
}
