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
      appBar: AppBar(title: const Text('Diskusi Selesai (Online)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Fitur ini akan mengkompres semua diskusi yang telah selesai ke dalam satu file zip untuk diunggah ke server.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (provider.isExporting)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.compress),
                  label: const Text('Mulai Proses Kompresi'),
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
