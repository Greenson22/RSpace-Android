// lib/presentation/providers/sync_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/services/path_service.dart';
import '../../core/services/storage_service.dart';

class SyncProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final PathService _pathService = PathService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String _syncStatusMessage = '';
  String get syncStatusMessage => _syncStatusMessage;

  String _finalMessage = '';
  bool _hasError = false;

  Future<void> performBackupAndUpload() async {
    _isSyncing = true;
    _hasError = false;
    _syncStatusMessage = 'Memulai proses...';
    notifyListeners();

    try {
      // Langkah 1: Backup & Upload RSpace
      _updateStatus('Membuat backup RSpace...');
      final rspaceFile = await _backupRspace();

      _updateStatus('Mengunggah backup RSpace...');
      await _uploadFile(rspaceFile, 'RSpace');

      // Langkah 2: Backup & Upload PerpusKu (jika path diatur)
      final perpuskuDataPath = await _prefsService.loadPerpuskuDataPath();
      if (perpuskuDataPath != null && perpuskuDataPath.isNotEmpty) {
        _updateStatus('Membuat backup PerpusKu...');
        final perpuskuFile = await _backupPerpusku();

        _updateStatus('Mengunggah backup PerpusKu...');
        await _uploadFile(perpuskuFile, 'PerpusKu');
      } else {
        _updateStatus('Melewati backup PerpusKu (path tidak diatur)...');
      }

      _finalMessage = 'Proses Backup & Sync berhasil diselesaikan!';
      _hasError = false;
    } catch (e) {
      _finalMessage = 'Terjadi kesalahan: ${e.toString()}';
      _hasError = true;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void showResultDialog(BuildContext context) {
    if (_finalMessage.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_hasError ? 'Proses Gagal' : 'Proses Selesai'),
        content: Text(_finalMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
    _finalMessage = ''; // Reset pesan setelah ditampilkan
  }

  void _updateStatus(String message) {
    _syncStatusMessage = message;
    notifyListeners();
  }

  Future<File> _backupRspace() async {
    final destinationPath = await _pathService.rspaceBackupPath;
    final contentsPath = await _pathService.contentsPath;
    final sourceDir = Directory(contentsPath);
    if (!await sourceDir.exists())
      throw Exception('Direktori "contents" RSpace tidak ditemukan.');

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final zipFileName = 'backup-topics-$timestamp.zip';
    final zipFilePath = path.join(destinationPath, zipFileName);

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    await encoder.addDirectory(sourceDir, includeDirName: false);
    encoder.close();
    return File(zipFilePath);
  }

  Future<File> _backupPerpusku() async {
    final destinationPath = await _pathService.perpuskuBackupPath;
    final perpuskuDataPath = await _pathService.perpuskuDataPath;
    final sourceDir = Directory(perpuskuDataPath);
    if (!await sourceDir.exists())
      throw Exception('Folder sumber data PerpusKu tidak ditemukan.');

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final zipFileName = 'backup-perpusku-$timestamp.zip';
    final zipFilePath = path.join(destinationPath, zipFileName);

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    await encoder.addDirectory(sourceDir, includeDirName: false);
    encoder.close();
    return File(zipFilePath);
  }

  Future<void> _uploadFile(File file, String type) async {
    final apiConfig = await _prefsService.loadApiConfig();
    final apiDomain = apiConfig['domain'];
    final apiKey = apiConfig['apiKey'];

    if (apiDomain == null || apiKey == null)
      throw Exception('Konfigurasi API (domain/key) tidak ditemukan.');

    final url = type == 'RSpace'
        ? '$apiDomain/api/rspace/upload'
        : '$apiDomain/api/perpusku/upload';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['x-api-key'] = apiKey;
    request.files.add(await http.MultipartFile.fromPath('zipfile', file.path));

    final response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      String errorMessage = 'Error tidak diketahui';
      try {
        final decodedBody = json.decode(responseBody);
        errorMessage = decodedBody is Map && decodedBody.containsKey('message')
            ? decodedBody['message']
            : responseBody;
      } catch (_) {
        errorMessage = responseBody;
      }
      throw HttpException(
        'Gagal mengunggah file: $errorMessage (Status ${response.statusCode})',
      );
    }
  }
}
