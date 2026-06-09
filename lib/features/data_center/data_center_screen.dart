// lib/features/data_center/presentation/screens/data_center_screen.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/data_center/backup/backup_tab.dart';
import 'package:my_aplication/features/data_center/local_sharing/local_sharing_tab.dart';
import '../../core/theme/app_theme.dart';

class DataCenterScreen extends StatelessWidget {
  const DataCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final theme = Theme.of(context);

    // WARNA TEMA DATA CENTER: Kombinasi Biru Tua Komputer / Server & Cyan Neon Nirkabel
    // Ini menjamin tulisan putih (Colors.white) di atasnya akan terlihat sangat kontras dan jelas.
    const List<Color> dataCenterGradient = [
      Color(0xFF0F2027), // Deep Navy / Dark Server Blue
      Color(0xFF203A43), // Slate Tech Cyan
      Color(0xFF2C5364), // Metallic Steel Blue
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Data Center',
            style: TextStyle(
              fontSize: 18.0 * textScaleFactor,
              fontWeight: FontWeight
                  .bold, // Dibuat bold agar lebih tegas dan terbaca jelas
              color: Colors.white,
              letterSpacing:
                  0.8, // Menambah ruang antar huruf agar teks lebih terbaca
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: dataCenterGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 4,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ), // Menjaga panah 'Back' tetap putih bersih
          bottom: TabBar(
            indicatorWeight:
                4, // Dipertebal sedikit agar garis indikator lebih mencolok
            indicatorColor: Colors
                .cyanAccent, // Menggunakan warna cyan terang untuk indikator agar kontras di atas warna gelap
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            labelColor: Colors
                .white, // Mengharuskan warna teks Tab aktif berwarna putih terang
            unselectedLabelColor: Colors
                .white70, // Tab mati berwarna putih buram agar kontras terlihat jelas
            tabs: const [
              Tab(icon: Icon(Icons.backup_outlined), text: 'Backup'),
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        body: const TabBarView(children: [BackupTab(), LocalSharingTab()]),
      ),
    );
  }
}
