// lib/presentation/pages/about_page.dart

import 'package:flutter/material.dart';

// Asumsi widget ini ada di path yang benar sesuai contoh Anda.
// import 'package:my_aplication/presentation/widgets/waving_flag.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final appColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      // Pastikan Anda meletakkan logo di path 'assets/icon/icon.png'
                      // dan mendaftarkannya di pubspec.yaml
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.space_dashboard_outlined,
                              size: 50,
                              color: appColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RSpace',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: appColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manajemen Pengetahuan & Tugas Pribadi Anda',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Deskripsi Aplikasi
            _buildSectionTitle(context, 'Tentang RSpace'),
            const SizedBox(height: 8),
            const Text(
              'RSpace adalah aplikasi manajemen konten dan tugas pribadi yang dirancang untuk membantu Anda mengatur materi pembelajaran, catatan, dan pengetahuan secara terstruktur. Dengan fitur utama Sistem Repetisi Berjangka (Spaced Repetition System), aplikasi ini sangat ideal untuk mahasiswa dan pembelajar seumur hidup. Dibuat dengan Flutter, RSpace memberikan solusi andal untuk mengelola informasi penting Anda langsung di perangkat, memberikan kontrol penuh atas data tanpa ketergantungan pada layanan cloud.',
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Fitur Utama
            _buildSectionTitle(context, 'Fitur Utama'),
            const SizedBox(height: 8),
            _FeatureTile(
              icon: Icons.account_tree_outlined,
              title: 'Struktur Konten Hirarkis',
              subtitle: 'Atur materi dalam Topik -> Subjek -> Diskusi -> Poin.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.school_outlined,
              title: 'Sistem Repetisi Berjangka',
              subtitle:
                  'Perkuat ingatan dengan metode Spaced Repetition yang terintegrasi.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.task_alt_outlined,
              title: 'Manajemen Tugas "My Tasks"',
              subtitle:
                  'Kelola daftar tugas harian dengan kategori, tanggal, dan progress.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.visibility_off_outlined,
              title: 'Sembunyikan & Tampilkan',
              subtitle:
                  'Fokus pada materi yang relevan dengan menyembunyikan item yang tidak lagi aktif.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.settings_suggest_outlined,
              title: 'Filter & Urutan Lanjutan',
              subtitle:
                  'Temukan informasi dengan cepat melalui fitur pencarian, filter, dan pengurutan yang komprehensif.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.folder_zip_outlined,
              title: 'Backup & Impor Lokal',
              subtitle:
                  'Amankan dan pulihkan seluruh data Anda dengan mudah melalui file ZIP.',
              appColor: appColor,
            ),
            _FeatureTile(
              icon: Icons.storage_outlined,
              title: 'Penyimpanan Kustom (Android)',
              subtitle:
                  'Pilih sendiri folder penyimpanan data aplikasi Anda untuk kontrol penuh.',
              appColor: appColor,
            ),
            const Divider(height: 48),

            // Informasi Pengembang
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: appColor,
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Dibuat oleh:', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Frendy Rikal Gerung, S.Kom.',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sarjana Komputer dari Universitas Negeri Manado',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Ganti WavingFlag dengan widget yang sesuai jika ada
                  // SizedBox(
                  //   width: 80,
                  //   height: 50,
                  //   child: WavingFlag(),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color appColor;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.appColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: appColor.withOpacity(0.8), size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}
