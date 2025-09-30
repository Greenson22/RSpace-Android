// lib/features/backup_management/application/sync_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/path_service.dart';
import '../../settings/application/services/api_config_service.dart';
// ==> 1. IMPORT AUTH SERVICE <==
import '../../auth/application/auth_service.dart';

/// Kelas untuk menampung hasil detail dari proses sinkronisasi.
class SyncResult {
  final bool rspaceBackupSuccess;
  final bool rspaceUploadSuccess;
  final bool perpuskuBackupSuccess;
  final bool perpuskuUploadSuccess;
  final String? errorMessage;
  final String? rspaceBackupPath;
  final String? perpuskuBackupPath;

  SyncResult({
    this.rspaceBackupSuccess = false,
    this.rspaceUploadSuccess = false,
    this.perpuskuBackupSuccess = false,
    this.perpuskuUploadSuccess = false,
    this.errorMessage,
    this.rspaceBackupPath,
    this.perpuskuBackupPath,
  });

  bool get overallSuccess =>
      rspaceBackupSuccess &&
      rspaceUploadSuccess &&
      perpuskuBackupSuccess &&
      perpuskuUploadSuccess &&
      errorMessage == null;
}

class SyncProvider with ChangeNotifier {
  final ApiConfigService _apiConfigService = ApiConfigService();
  final PathService _pathService = PathService();
  // ==> 2. BUAT INSTANCE DARI AUTH SERVICE <==
  final AuthService _authService = AuthService();

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

      // Langkah 2: Backup & Upload PerpusKu (Selalu dijalankan)
      _updateStatus('Membuat backup PerpusKu...');
      final perpuskuFile = await _backupPerpusku();
      perpuskuPath = perpuskuFile.path;
      perpuskuBSuccess = true;

      _updateStatus('Mengunggah backup PerpusKu...');
      await _uploadFile(perpuskuFile, 'PerpusKu');
      perpuskuUSuccess = true;
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
    // ... (fungsi ini tidak berubah)
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
    // ... (fungsi ini tidak berubah)
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

  // ==> 3. PERBARUI FUNGSI UPLOAD SECARA TOTAL <==
  Future<void> _uploadFile(File file, String type) async {
    // Dapatkan konfigurasi domain
    final apiConfig = await _apiConfigService.loadConfig();
    final apiDomain = apiConfig['domain'];
    if (apiDomain == null) {
      throw Exception('Konfigurasi domain API tidak ditemukan.');
    }

    // Dapatkan token dari AuthService
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception(
        'Akses ditolak. Silakan login terlebih dahulu untuk melakukan sinkronisasi.',
      );
    }

    // Tentukan URL tujuan
    final url = type == 'RSpace'
        ? '$apiDomain/api/rspace/upload'
        : '$apiDomain/api/perpusku/upload';

    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Tambahkan header otorisasi dengan token JWT
    request.headers['Authorization'] = 'Bearer $token';

    // Tambahkan file ke request
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
