// lib/features/finished_discussions/presentation/pages/finished_discussions_online_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussions_online_provider.dart';

class FinishedDiscussionsOnlinePage extends StatelessWidget {
  const FinishedDiscussionsOnlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinishedDiscussionsOnlineProvider(),
      child: const _FinishedDiscussionsOnlineView(),
    );
  }
}

class _FinishedDiscussionsOnlineView extends StatelessWidget {
  const _FinishedDiscussionsOnlineView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinishedDiscussionsOnlineProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Arsipkan Diskusi Selesai')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.archive_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Fitur ini akan mengumpulkan semua diskusi yang telah selesai dan menyalinnya ke dalam folder "finish_discussions" di penyimpanan utama Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (provider.isExporting)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Mulai Proses Arsip'),
                  onPressed: () async {
                    try {
                      final message = await provider
                          .exportFinishedDiscussionsOnline();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
