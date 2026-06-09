// lib/features/settings/presentation/pages/settings_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_theme.dart';
// Import halaman Perpusku yang dipindahkan ke sini
import '../../../perpusku/presentation/pages/perpusku_topic_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SharedPreferencesService _storageService = SharedPreferencesService();
  final TextEditingController _pathController = TextEditingController();

  String _currentPath = "Memuat...";
  bool _isLoading = true;
  bool _useInternalWeb = true;

  String get _webPreferenceKey =>
      Platform.isAndroid ? 'use_internal_web_android' : 'use_internal_web';

  bool get _defaultWebPreferenceValue => Platform.isAndroid ? false : true;

  String _getDefaultPathDescription() {
    if (Platform.isAndroid) {
      return "Default (Internal: Android/data/${Platform.localeName}/files)";
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '~';
      return "Default (Direktori Rumah: $home/.local/share)";
    } else if (Platform.isWindows) {
      final appData =
          Platform.environment['APPDATA'] ?? 'C:\\Users\\...\\AppData\\Roaming';
      return "Default (Direktori Dokumen / AppData: $appData)";
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '~';
      return "Default (Library Support: $home/Library/Application Support)";
    }
    return "Default (Penyimpanan Internal Aplikasi)";
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final customPath = await _storageService.loadCustomStoragePath();
    final prefs = await SharedPreferences.getInstance();
    final useInternal =
        prefs.getBool(_webPreferenceKey) ?? _defaultWebPreferenceValue;

    setState(() {
      _currentPath = (customPath != null && customPath.isNotEmpty)
          ? customPath
          : _getDefaultPathDescription();
      _pathController.text = customPath ?? '';
      _useInternalWeb = useInternal;
      _isLoading = false;
    });
  }

  Future<void> _saveCustomPath(String path) async {
    await _storageService.saveCustomStoragePath(path);
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jalur penyimpanan berhasil diperbarui. Muat ulang (restart) aplikasi agar efeknya berjalan sempurna.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _resetPath() async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            final double textScaleFactor = MediaQuery.of(
              context,
            ).textScaleFactor;
            return AlertDialog(
              title: Text(
                'Konfirmasi Reset',
                style: TextStyle(
                  fontSize: 16.0 * textScaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Apakah Anda yakin ingin mengembalikan lokasi folder penyimpanan ke pengaturan default?',
                style: TextStyle(fontSize: 14.0 * textScaleFactor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Batal',
                    style: TextStyle(fontSize: 14.0 * textScaleFactor),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 14.0 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      setState(() => _isLoading = true);
      await _storageService.saveCustomStoragePath('');
      await _loadSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi folder berhasil dikembalikan ke default.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Utama',
    );

    if (selectedDirectory != null) {
      _saveCustomPath(selectedDirectory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final List<Color> appBarGradient = AppTheme.getGradientForTitle(
      'Pengaturan',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 18.0 * textScaleFactor,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: appBarGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0 * textScaleFactor,
              ),
              children: [
                // ========================================================
                // SEKSI MODUL & KONTEN (BARU)
                // ========================================================
                Text(
                  'Modul Aplikasi',
                  style: TextStyle(
                    fontSize: 14.0 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 2.0 * textScaleFactor,
                  ),
                  leading: Icon(
                    Icons.local_library_outlined,
                    color: appBarGradient.first,
                    size: 22.0 * textScaleFactor,
                  ),
                  title: Text(
                    'Perpusku',
                    style: TextStyle(
                      fontSize: 14.0 * textScaleFactor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Buka dan kelola manajemen materi pustaka referensi Anda.',
                    style: TextStyle(fontSize: 11.0 * textScaleFactor),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14.0 * textScaleFactor,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PerpuskuTopicPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32, thickness: 1.0),

                // ========================================================
                // SEKSI PENYIMPANAN
                // ========================================================
                Text(
                  'Penyimpanan & Data',
                  style: TextStyle(
                    fontSize: 14.0 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18.0 * textScaleFactor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mode Debug Aktif: Perubahan folder yang dilakukan di sini menggunakan kunci terpisah dan tidak akan memengaruhi versi Release.',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 13.0 * textScaleFactor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 2.0 * textScaleFactor,
                  ),
                  title: Text(
                    'Lokasi Folder RSpace & Perpusku',
                    style: TextStyle(fontSize: 14.0 * textScaleFactor),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _currentPath,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 10.0 * textScaleFactor,
                      ),
                    ),
                  ),
                  trailing: Platform.isAndroid
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_currentPath.startsWith("Default"))
                              IconButton(
                                icon: Icon(
                                  Icons.restore,
                                  size: 18.0 * textScaleFactor,
                                ),
                                tooltip: 'Kembalikan ke Default',
                                onPressed: _resetPath,
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.folder_open,
                                color: appBarGradient.last,
                                size: 20.0 * textScaleFactor,
                              ),
                              tooltip: 'Pilih Folder',
                              onPressed: _pickDirectory,
                            ),
                          ],
                        ),
                ),
                const Divider(height: 32, thickness: 1.0),

                // ========================================================
                // SEKSI PREFERENSI TAUTAN
                // ========================================================
                Text(
                  'Preferensi Tautan',
                  style: TextStyle(
                    fontSize: 14.0 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 2.0 * textScaleFactor,
                  ),
                  title: Text(
                    Platform.isAndroid
                        ? 'Buka Web di Dalam Aplikasi (Android)'
                        : 'Buka Web di Dalam Aplikasi (Desktop)',
                    style: TextStyle(fontSize: 14.0 * textScaleFactor),
                  ),
                  subtitle: Text(
                    Platform.isAndroid
                        ? 'Aktifkan untuk membuka diskusi via WebView internal Android. (Default: mati/menggunakan browser bawaan HP).'
                        : 'Aktifkan untuk membuka diskusi via web internal aplikasi.',
                    style: TextStyle(fontSize: 11.0 * textScaleFactor),
                  ),
                  trailing: Transform.scale(
                    scale: textScaleFactor,
                    child: Switch(
                      value: _useInternalWeb,
                      activeColor: appBarGradient.first,
                      onChanged: (bool value) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(_webPreferenceKey, value);

                        setState(() {
                          _useInternalWeb = value;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'Tautan sekarang akan dibuka via Web Internal.'
                                    : 'Tautan sekarang akan dibuka via Browser Eksternal.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const Divider(height: 32, thickness: 1.0),
              ],
            ),
    );
  }
}
