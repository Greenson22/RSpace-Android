// lib/presentation/pages/dashboard_page.dart
import 'dart:async'; // DITAMBAHKAN: untuk Stream
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // DITAMBAHKAN: untuk format tanggal/waktu
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/theme_provider.dart'; // DIIMPOR
import '../providers/topic_provider.dart';
import '1_topics_page.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'my_tasks_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBackingUp = false;
  late Stream<DateTime> _clockStream; // DITAMBAHKAN

  // DITAMBAHKAN: initState untuk memulai stream jam
  @override
  void initState() {
    super.initState();
    // Membuat stream yang menghasilkan DateTime.now() setiap detik
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  Future<void> _backupContents(BuildContext context) async {
    String? destinationPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Backup',
    );

    if (destinationPath == null) {
      if (mounted) showAppSnackBar(context, 'Backup dibatalkan.');
      return;
    }

    final topicProvider = TopicProvider();

    setState(() {
      _isBackingUp = true;
    });

    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await topicProvider.backupContents(
        destinationPath: destinationPath,
      );
      showAppSnackBar(context, message);
    } catch (e) {
      String errorMessage = 'Terjadi error saat backup: $e';
      if (e is FileSystemException) {
        errorMessage = 'Error: Gagal menulis file. Periksa izin aplikasi.';
      }
      showAppSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _showStoragePathDialog(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Utama',
    );

    if (selectedDirectory != null) {
      final prefsService = SharedPreferencesService();
      await prefsService.saveCustomStoragePath(selectedDirectory);
      if (mounted) {
        showAppSnackBar(
          context,
          'Lokasi disimpan. Mohon restart aplikasi untuk menerapkan.',
        );
      }
    } else {
      if (mounted) {
        showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () {
              themeProvider.darkTheme = !themeProvider.darkTheme;
            },
            tooltip: 'Ganti Tema',
          ),
        ],
      ),
      // DIUBAH: Menggunakan Column untuk menampung jam dan GridView
      body: Column(
        children: [
          // DITAMBAHKAN: Widget untuk menampilkan tanggal dan jam
          _buildClock(),
          // Expanded untuk memastikan GridView mengisi sisa ruang
          Expanded(
            child: Center(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                children: <Widget>[
                  _buildDashboardItem(
                    context,
                    icon: Icons.topic_outlined,
                    label: 'Topics',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopicsPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.task_alt,
                    label: 'My Tasks',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyTasksPage(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardItem(
                    context,
                    icon: Icons.backup_outlined,
                    label: 'Backup',
                    onTap: () => _backupContents(context),
                    child: _isBackingUp
                        ? const CircularProgressIndicator()
                        : null,
                  ),
                  if (Platform.isAndroid)
                    _buildDashboardItem(
                      context,
                      icon: Icons.folder_open_rounded,
                      label: 'Penyimpanan',
                      onTap: () => _showStoragePathDialog(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DITAMBAHKAN: Widget baru untuk membangun tampilan jam
  Widget _buildClock() {
    return StreamBuilder<DateTime>(
      stream: _clockStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final now = snapshot.data!;
          // Format: Rabu, 13 Agustus 2025
          final dateFormatter = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
          // Format: 13:03:45
          final timeFormatter = DateFormat('HH:mm:ss');
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Text(
                  dateFormatter.format(now),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  timeFormatter.format(now),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          );
        }
        // Tampilkan placeholder jika stream belum menghasilkan data
        return const SizedBox(height: 80);
      },
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child:
            child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 50, color: Theme.of(context).primaryColor),
                const SizedBox(height: 10),
                Text(label, style: const TextStyle(fontSize: 18)),
              ],
            ),
      ),
    );
  }
}
