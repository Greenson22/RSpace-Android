// lib/features/archive/presentation/pages/archive_hub_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/archive/presentation/pages/archive_topic_page.dart'; // IMPORT BARU
import '../../../finished_discussions/presentation/pages/finished_discussions_online_page.dart';

class ArchiveHubPage extends StatelessWidget {
  const ArchiveHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arsip & Ekspor')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Lihat Arsip',
            subtitle:
                'Jelajahi konten diskusi selesai yang telah Anda arsipkan.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ArchiveTopicPage(),
              ), // UBAH DI SINI
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context,
            icon: Icons.archive_outlined,
            title: 'Arsipkan Diskusi Selesai',
            subtitle: 'Salin semua diskusi yang telah selesai ke folder arsip.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FinishedDiscussionsOnlinePage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
