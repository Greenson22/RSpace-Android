// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '../theme/app_theme.dart';
import '1_topics_page.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'about_page.dart';
import 'my_tasks_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBackingUp = false;
  bool _isImporting = false;

  Future<void> _backupContents(BuildContext context) async {
    String? destinationPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Tujuan Backup',
    );

    if (destinationPath == null) {
      if (mounted) showAppSnackBar(context, 'Backup dibatalkan.');
      return;
    }

    final topicProvider = Provider.of<TopicProvider>(context, listen: false);

    setState(() => _isBackingUp = true);
    showAppSnackBar(context, 'Memulai proses backup...');
    try {
      final message = await topicProvider.backupContents(
        destinationPath: destinationPath,
      );
      if (mounted) showAppSnackBar(context, message);
    } catch (e) {
      String errorMessage = 'Terjadi error saat backup: $e';
      if (e is FileSystemException) {
        errorMessage = 'Error: Gagal menulis file. Periksa izin aplikasi.';
      }
      if (mounted) showAppSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _importContents(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      if (mounted) showAppSnackBar(context, 'Import dibatalkan.');
      return;
    }

    final confirmed = await _showImportConfirmationDialog(context);
    if (!confirmed) {
      if (mounted) showAppSnackBar(context, 'Import dibatalkan oleh pengguna.');
      return;
    }

    setState(() => _isImporting = true);
    showAppSnackBar(context, 'Memulai proses import...');

    try {
      final zipFile = File(result.files.single.path!);
      final topicProvider = Provider.of<TopicProvider>(context, listen: false);
      await topicProvider.importContents(zipFile);
      if (mounted) {
        showAppSnackBar(
          context,
          'Import berhasil. Mohon restart aplikasi untuk menerapkan perubahan.',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Terjadi error saat import: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<bool> _showImportConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Import'),
            content: const Text(
              'PERINGATAN: Tindakan ini akan menghapus semua data "topics" dan "my_tasks.json" saat ini, lalu menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?',
            ),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Lanjutkan'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
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
      if (mounted) showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () => themeProvider.darkTheme = !themeProvider.darkTheme,
            tooltip: 'Ganti Tema',
          ),
          // ==> TOMBOL TENTANG DIPINDAHKAN KE SINI <==
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
            tooltip: 'Tentang Aplikasi',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const _DashboardHeader(),
            const SizedBox(height: 20),
            _buildGridView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        _DashboardItem(
          icon: Icons.topic_outlined,
          label: 'Topics',
          gradientColors: AppTheme.gradientColors1,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TopicsPage()),
          ),
        ),
        _DashboardItem(
          icon: Icons.task_alt,
          label: 'My Tasks',
          gradientColors: AppTheme.gradientColors2,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyTasksPage()),
          ),
        ),
        _DashboardItem(
          icon: Icons.backup_outlined,
          label: 'Backup',
          gradientColors: AppTheme.gradientColors3,
          onTap: () => _backupContents(context),
          child: _isBackingUp
              ? const CircularProgressIndicator(color: Colors.white)
              : null,
        ),
        _DashboardItem(
          icon: Icons.restore,
          label: 'Import',
          gradientColors: AppTheme.gradientColors4,
          onTap: () => _importContents(context),
          child: _isImporting
              ? const CircularProgressIndicator(color: Colors.white)
              : null,
        ),
        if (Platform.isAndroid)
          _DashboardItem(
            icon: Icons.folder_open_rounded,
            label: 'Penyimpanan',
            gradientColors: AppTheme.gradientColors5,
            onTap: () => _showStoragePathDialog(context),
          ),
        // ==> TOMBOL TENTANG DIHAPUS DARI GRID <==
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            ),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
              final time = DateFormat('HH:mm:ss').format(now);
              return Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(date, style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Widget? child;

  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradientColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              child ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
