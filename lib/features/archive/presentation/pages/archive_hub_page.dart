// lib/features/archive/presentation/pages/archive_hub_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/archive/presentation/pages/archive_topic_page.dart';
import 'package:my_aplication/features/finished_discussions/presentation/pages/finished_discussions_online_page.dart';
// ==> 1. IMPORT AUTH PROVIDER DAN HALAMAN PROFIL <==
import 'package:my_aplication/features/auth/application/auth_provider.dart';
import 'package:my_aplication/features/auth/presentation/profile_page.dart';

class ArchiveHubPage extends StatelessWidget {
  const ArchiveHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ==> 2. GUNAKAN CONSUMER UNTUK MENDAPATKAN STATUS LOGIN <==
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final bool isLoggedIn = auth.authState == AuthState.authenticated;

        return Scaffold(
          appBar: AppBar(title: const Text('Arsip & Ekspor')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMenuCard(
                context,
                icon: Icons.inventory_2_outlined,
                title: 'Lihat Arsip Online',
                subtitle:
                    'Jelajahi konten diskusi yang telah Anda arsipkan di server.',
                // ==> 3. UBAH LOGIKA onTap <==
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArchiveTopicPage(),
                      ),
                    );
                  } else {
                    _showLoginRequiredDialog(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                icon: Icons.archive_outlined,
                title: 'Arsipkan Diskusi Selesai',
                subtitle:
                    'Unggah semua diskusi yang telah selesai ke arsip online Anda.',
                // ==> 4. UBAH LOGIKA onTap <==
                onTap: () {
                  if (isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinishedDiscussionsOnlinePage(),
                      ),
                    );
                  } else {
                    _showLoginRequiredDialog(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==> 5. BUAT FUNGSI UNTUK MENAMPILKAN DIALOG <==
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Diperlukan'),
        content: const Text(
          'Anda harus login untuk menggunakan fitur arsip online. Ingin login atau membuat akun sekarang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
            child: const Text('Login / Daftar'),
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
