// lib/features/settings/presentation/pages/settings_page.dart
import 'dart:io'; // Ditambahkan untuk pengecekan Platform (OS)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Dibutuhkan untuk kDebugMode
import 'package:file_picker/file_picker.dart'; // Diaktifkan untuk pemilih folder
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

  @override
  void initState() {
    super.initState();
    _loadCustomPath();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomPath() async {
    setState(() => _isLoading = true);
    final customPath = await _storageService.loadCustomStoragePath();

    setState(() {
      _currentPath = (customPath != null && customPath.isNotEmpty)
          ? customPath
          // Teks fallback default:
          : "Default (Penyimpanan Aplikasi: Android/data/com...)";
      _pathController.text = customPath ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCustomPath(String path) async {
    await _storageService.saveCustomStoragePath(path);
    await _loadCustomPath();

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
    await _loadCustomPath();
  }

  Future<void> _pickDirectory() async {
    // Menggunakan package 'file_picker' untuk memilih folder secara langsung lewat dialog OS
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

                // Peringatan otomatis muncul apabila aplikasi di-run via mode Debug
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
                  // Pengecekan OS: Jika Android, trailing diisi null (tidak ada tombol).
                  // Jika Desktop, tampilkan tombol reset dan pilih folder.
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

                // Tempatkan pengaturan lain di bawah sini
                const Center(
                  child: Text(
                    '(Tambahkan opsi pengaturan lain di sini)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}
