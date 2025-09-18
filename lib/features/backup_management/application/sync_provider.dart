// lib/features/backup_management/application/sync_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/path_service.dart';
// ==> IMPORT SERVICE BARU & HAPUS STORAGE_SERVICE <==
import '../../settings/application/services/api_config_service.dart';

/// Kelas untuk menampung hasil detail dari proses sinkronisasi.
class SyncResult {
  final bool rspaceBackupSuccess;
  final bool rspaceUploadSuccess;
  final bool perpuskuBackupSuccess;
  final bool perpuskuUploadSuccess;
  final bool isPerpuskuSkipped;
  final String? errorMessage;
  final String? rspaceBackupPath;
  final String? perpuskuBackupPath;

  SyncResult({
    this.rspaceBackupSuccess = false,
    this.rspaceUploadSuccess = false,
    this.perpuskuBackupSuccess = false,
    this.perpuskuUploadSuccess = false,
    this.isPerpuskuSkipped = false,
    this.errorMessage,
    this.rspaceBackupPath,
    this.perpuskuBackupPath,
  });

  bool get overallSuccess =>
      rspaceBackupSuccess &&
      rspaceUploadSuccess &&
      (isPerpuskuSkipped || (perpuskuBackupSuccess && perpuskuUploadSuccess)) &&
      errorMessage == null;
}

class SyncProvider with ChangeNotifier {
  // ==> GUNAKAN SERVICE BARU <==
  final ApiConfigService _apiConfigService = ApiConfigService();
  final PathService _pathService = PathService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String _syncStatusMessage = '';
  String get syncStatusMessage => _syncStatusMessage;

  Future<SyncResult> performBackupAndUpload() async {
    _isSyncing = true;
    _syncStatusMessage = 'Memulai proses...';
    notifyListeners();

    bool rspaceBSuccess = false;
    bool rspaceUSuccess = false;
    bool perpuskuBSuccess = false;
    bool perpuskuUSuccess = false;
    bool perpuskuSkipped = false;
    String? errorMsg;
    String? rspacePath;
    String? perpuskuPath;

    try {
      // Langkah 1: Backup & Upload RSpace
      _updateStatus('Membuat backup RSpace...');
      final rspaceFile = await _backupRspace();
      rspacePath = rspaceFile.path;
      rspaceBSuccess = true;

      _updateStatus('Mengunggah backup RSpace...');
      await _uploadFile(rspaceFile, 'RSpace');
      rspaceUSuccess = true;

      // Langkah 2: Backup & Upload PerpusKu (jika path diatur)
      final perpuskuDataPath = await _pathService.loadPerpuskuDataPath();
      if (perpuskuDataPath != null && perpuskuDataPath.isNotEmpty) {
        _updateStatus('Membuat backup PerpusKu...');
        final perpuskuFile = await _backupPerpusku();
        perpuskuPath = perpuskuFile.path;
        perpuskuBSuccess = true;

        _updateStatus('Mengunggah backup PerpusKu...');
        await _uploadFile(perpuskuFile, 'PerpusKu');
        perpuskuUSuccess = true;
      } else {
        _updateStatus('Melewati backup PerpusKu (path tidak diatur)...');
        perpuskuSkipped = true;
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return SyncResult(
      rspaceBackupSuccess: rspaceBSuccess,
      rspaceUploadSuccess: rspaceUSuccess,
      perpuskuBackupSuccess: perpuskuBSuccess,
      perpuskuUploadSuccess: perpuskuUSuccess,
      isPerpuskuSkipped: perpuskuSkipped,
      errorMessage: errorMsg,
      rspaceBackupPath: rspacePath,
      perpuskuBackupPath: perpuskuPath,
    );
  }

  void _updateStatus(String message) {
    _syncStatusMessage = message;
    notifyListeners();
  }

  Future<File> _backupRspace() async {
    final destinationPath = await _pathService.rspaceBackupPath;
    final contentsPath = await _pathService.contentsPath;
    final sourceDir = Directory(contentsPath);
    if (!await sourceDir.exists()) {
      throw Exception('Direktori "contents" RSpace tidak ditemukan.');
    }

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
    if (!await sourceDir.exists()) {
      throw Exception('Folder sumber data PerpusKu tidak ditemukan.');
    }

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final zipFileName = 'backup-perpusku-$timestamp.zip';
    final zipFilePath = path.join(destinationPath, zipFileName);

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    await encoder.addDirectory(sourceDir, includeDirName: false);
    encoder.close();
    return File(zipFilePath);
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> _uploadFile(File file, String type) async {
    final apiConfig = await _apiConfigService.loadConfig();
    final apiDomain = apiConfig['domain'];
    final apiKey = apiConfig['apiKey'];

    if (apiDomain == null || apiKey == null) {
      throw Exception('Konfigurasi API (domain/key) tidak ditemukan.');
    }

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
