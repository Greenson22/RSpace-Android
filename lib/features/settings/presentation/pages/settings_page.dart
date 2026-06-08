// lib/features/settings/presentation/pages/settings_page.dart
import 'dart:io'; // Ditambahkan untuk pengecekan Platform (OS)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Dibutuhkan untuk kDebugMode
import 'package:file_picker/file_picker.dart'; // Diaktifkan untuk pemilih folder
import 'package:shared_preferences/shared_preferences.dart'; // Tambahkan ini untuk menyimpan preferensi web
import '../../../../core/services/storage_service.dart';

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
  bool _useInternalWeb =
      true; // State baru untuk preferensi web (default: true)

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Mengubah nama fungsi agar mencakup semua pemuatan data
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  // Fungsi gabungan untuk memuat custom path dan preferensi web
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    // 1. Muat data custom path
    final customPath = await _storageService.loadCustomStoragePath();

    // 2. Muat data preferensi web (jika belum ada, default-nya true)
    final prefs = await SharedPreferences.getInstance();
    final useInternal = prefs.getBool('use_internal_web') ?? true;

    setState(() {
      _currentPath = (customPath != null && customPath.isNotEmpty)
          ? customPath
          : "Default (Penyimpanan Aplikasi: Android/data/com...)";
      _pathController.text = customPath ?? '';
      _useInternalWeb = useInternal;
      _isLoading = false;
    });
  }

  Future<void> _saveCustomPath(String path) async {
    await _storageService.saveCustomStoragePath(path);
    await _loadSettings(); // Segarkan pengaturan setelah menyimpan

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
    await _storageService.saveCustomStoragePath('');
    await _loadSettings();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Penyimpanan & Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mode Debug Aktif: Perubahan folder yang dilakukan di sini menggunakan kunci terpisah dan tidak akan memengaruhi versi Release.',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lokasi Folder RSpace & Perpusku'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _currentPath,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  trailing: Platform.isAndroid
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentPath !=
                                "Default (Penyimpanan Aplikasi: data/com...)")
                              IconButton(
                                icon: const Icon(Icons.restore),
                                tooltip: 'Kembalikan ke Default',
                                onPressed: _resetPath,
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.folder_open,
                                color: Colors.blue,
                              ),
                              tooltip: 'Pilih Folder',
                              onPressed: _pickDirectory,
                            ),
                          ],
                        ),
                ),
                const Divider(height: 32),

                // ========================================================
                // BAGIAN BARU: Pengaturan Tautan & Web
                // ========================================================
                const Text(
                  'Preferensi Tautan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Buka Web di Dalam Aplikasi'),
                  subtitle: const Text(
                    'Aktifkan untuk membuka tautan discussion via web internal (WebView). Matikan jika ingin menggunakan browser eksternal HP Anda.',
                  ),
                  value: _useInternalWeb,
                  activeColor: Colors.blue,
                  onChanged: (bool value) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('use_internal_web', value);

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
                const Divider(height: 32),
              ],
            ),
    );
  }
}
