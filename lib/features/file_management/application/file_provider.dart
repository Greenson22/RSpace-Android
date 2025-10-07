// lib/features/file_management/application/file_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:my_aplication/features/backup_management/presentation/utils/backup_actions.dart';
import '../../settings/application/services/api_config_service.dart';
import '../domain/models/file_model.dart';
import '../../../core/services/path_service.dart';
import '../../auth/application/auth_service.dart';
// ==> IMPORT DIALOG BARU <==
import '../presentation/dialogs/download_import_progress_dialog.dart';

// ==> ENUM BARU UNTUK STATUS PROGRES <==
enum SyncStepStatus { waiting, inProgress, success, failed }

// ==> CLASS BARU UNTUK MENYIMPAN STATE PROGRES <==
class SyncProgressState {
  SyncStepStatus rspaceDownloadStatus;
  SyncStepStatus rspaceImportStatus;
  SyncStepStatus perpuskuDownloadStatus;
  SyncStepStatus perpuskuImportStatus;
  String? errorMessage;

  SyncProgressState({
    this.rspaceDownloadStatus = SyncStepStatus.waiting,
    this.rspaceImportStatus = SyncStepStatus.waiting,
    this.perpuskuDownloadStatus = SyncStepStatus.waiting,
    this.perpuskuImportStatus = SyncStepStatus.waiting,
    this.errorMessage,
  });

  bool get isFinished =>
      rspaceDownloadStatus != SyncStepStatus.inProgress &&
      rspaceImportStatus != SyncStepStatus.inProgress &&
      perpuskuDownloadStatus != SyncStepStatus.inProgress &&
      perpuskuImportStatus != SyncStepStatus.inProgress;
}

class FileProvider with ChangeNotifier {
  final ApiConfigService _apiConfigService = ApiConfigService();
  final PathService _pathService = PathService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<FileItem> _rspaceFiles = [];
  List<FileItem> get rspaceFiles => _rspaceFiles;

  List<FileItem> _perpuskuFiles = [];
  List<FileItem> get perpuskuFiles => _perpuskuFiles;

  List<File> _downloadedRspaceFiles = [];
  List<File> get downloadedRspaceFiles => _downloadedRspaceFiles;

  List<File> _downloadedPerpuskuFiles = [];
  List<File> get downloadedPerpuskuFiles => _downloadedPerpuskuFiles;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Map<String, double> _downloadProgress = {};
  double getDownloadProgress(String uniqueName) =>
      _downloadProgress[uniqueName] ?? 0.0;

  final Map<String, double> _uploadProgress = {};
  double getUploadProgress(String fileName) => _uploadProgress[fileName] ?? 0.0;
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // ==> HAPUS isDownloading, GANTI DENGAN syncProgress <==
  SyncProgressState _syncProgress = SyncProgressState();
  SyncProgressState get syncProgress => _syncProgress;

  final Set<String> _selectedDownloadedFiles = {};
  Set<String> get selectedDownloadedFiles => _selectedDownloadedFiles;
  bool get isSelectionMode => _selectedDownloadedFiles.isNotEmpty;

  String? _apiDomain;
  String? get apiDomain => _apiDomain;

  String get _rspaceEndpoint => '$_apiDomain/api/rspace/files';
  String get _perpuskuEndpoint => '$_apiDomain/api/perpusku/files';
  String get _rspaceDownloadBaseUrl => '$_apiDomain/api/rspace/download/';
  String get _perpuskuDownloadBaseUrl => '$_apiDomain/api/perpusku/download/';
  String get _rspaceUploadEndpoint => '$_apiDomain/api/rspace/upload';
  String get _perpuskuUploadEndpoint => '$_apiDomain/api/perpusku/upload';
  String get _rspaceDeleteBaseUrl => '$_apiDomain/api/rspace/files/';
  String get _perpuskuDeleteBaseUrl => '$_apiDomain/api/perpusku/files/';

  FileProvider() {
    _initialize();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  // ==> FUNGSI INI DIPERBARUI TOTAL <==
  Future<void> downloadAndImportAll(BuildContext context) async {
    // Tampilkan dialog progres SEBELUM memulai proses
    showDownloadImportProgressDialog(context);

    // Reset state progres
    _syncProgress = SyncProgressState();
    notifyListeners();

    File? rspaceFile;
    File? perpuskuFile;

    try {
      // --- RSPACE ---
      final rspaceItem = _rspaceFiles.isNotEmpty ? _rspaceFiles.first : null;
      if (rspaceItem != null) {
        // Step 1: Download RSpace
        _syncProgress.rspaceDownloadStatus = SyncStepStatus.inProgress;
        notifyListeners();
        try {
          rspaceFile = await _downloadSingleFile(rspaceItem, true);
          _syncProgress.rspaceDownloadStatus = SyncStepStatus.success;
        } catch (e) {
          _syncProgress.rspaceDownloadStatus = SyncStepStatus.failed;
          throw Exception("Gagal download RSpace: $e");
        } finally {
          notifyListeners();
        }

        // Step 2: Import RSpace
        _syncProgress.rspaceImportStatus = SyncStepStatus.inProgress;
        notifyListeners();
        try {
          await importSpecificFile(
            context,
            rspaceFile,
            'RSpace',
            showConfirmation: false,
          );
          _syncProgress.rspaceImportStatus = SyncStepStatus.success;
        } catch (e) {
          _syncProgress.rspaceImportStatus = SyncStepStatus.failed;
          throw Exception("Gagal import RSpace: $e");
        } finally {
          notifyListeners();
        }
      } else {
        _syncProgress.rspaceDownloadStatus = SyncStepStatus.success;
        _syncProgress.rspaceImportStatus = SyncStepStatus.success;
      }

      // --- PERPUSKU ---
      final perpuskuItem = _perpuskuFiles.isNotEmpty
          ? _perpuskuFiles.first
          : null;
      if (perpuskuItem != null) {
        // Step 3: Download PerpusKu
        _syncProgress.perpuskuDownloadStatus = SyncStepStatus.inProgress;
        notifyListeners();
        try {
          perpuskuFile = await _downloadSingleFile(perpuskuItem, false);
          _syncProgress.perpuskuDownloadStatus = SyncStepStatus.success;
        } catch (e) {
          _syncProgress.perpuskuDownloadStatus = SyncStepStatus.failed;
          throw Exception("Gagal download PerpusKu: $e");
        } finally {
          notifyListeners();
        }

        // Step 4: Import PerpusKu
        _syncProgress.perpuskuImportStatus = SyncStepStatus.inProgress;
        notifyListeners();
        try {
          await importSpecificFile(
            context,
            perpuskuFile,
            'PerpusKu',
            showConfirmation: false,
          );
          _syncProgress.perpuskuImportStatus = SyncStepStatus.success;
        } catch (e) {
          _syncProgress.perpuskuImportStatus = SyncStepStatus.failed;
          throw Exception("Gagal import PerpusKu: $e");
        } finally {
          notifyListeners();
        }
      } else {
        _syncProgress.perpuskuDownloadStatus = SyncStepStatus.success;
        _syncProgress.perpuskuImportStatus = SyncStepStatus.success;
      }
    } catch (e) {
      _syncProgress.errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  // Sisa kode di bawah ini tidak berubah secara signifikan
  // ...
  void toggleDownloadedFileSelection(File file) {
    if (_selectedDownloadedFiles.contains(file.path)) {
      _selectedDownloadedFiles.remove(file.path);
    } else {
      _selectedDownloadedFiles.add(file.path);
    }
    notifyListeners();
  }

  void selectAllDownloaded() {
    _selectedDownloadedFiles.addAll(_downloadedRspaceFiles.map((f) => f.path));
    _selectedDownloadedFiles.addAll(
      _downloadedPerpuskuFiles.map((f) => f.path),
    );
    notifyListeners();
  }

  void clearSelection() {
    _selectedDownloadedFiles.clear();
    notifyListeners();
  }

  Future<String> deleteSelectedDownloadedFiles() async {
    final count = _selectedDownloadedFiles.length;
    for (String path in _selectedDownloadedFiles) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Abaikan error
      }
    }
    _selectedDownloadedFiles.clear();
    await _scanDownloadedFiles();
    return '$count file berhasil dihapus.';
  }

  Future<void> _initialize() async {
    await _loadApiConfig();
    if (_apiDomain != null) {
      await Future.wait([fetchFiles(), _scanDownloadedFiles()]);
    } else {
      _isLoading = false;
      _errorMessage =
          'Konfigurasi Server API belum diatur. Silakan atur domain terlebih dahulu.';
      notifyListeners();
    }
  }

  Future<void> _loadApiConfig() async {
    final config = await _apiConfigService.loadConfig();
    _apiDomain = config['domain'];
    notifyListeners();
  }

  Future<void> saveApiConfig(String domain, String apiKey) async {
    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }
    await _apiConfigService.saveConfig(domain, apiKey);
    _apiDomain = domain;
    notifyListeners();
    await fetchFiles();
  }

  Future<void> _scanDownloadedFiles() async {
    final downloadPath = await _pathService.downloadsPath;
    try {
      final rspaceDir = Directory(path.join(downloadPath, 'rspace_download'));
      if (await rspaceDir.exists()) {
        _downloadedRspaceFiles = rspaceDir
            .listSync()
            .whereType<File>()
            .toList();
      } else {
        _downloadedRspaceFiles = [];
      }
      final perpuskuDir = Directory(
        path.join(downloadPath, 'perpusku_download'),
      );
      if (await perpuskuDir.exists()) {
        _downloadedPerpuskuFiles = perpuskuDir
            .listSync()
            .whereType<File>()
            .toList();
      } else {
        _downloadedPerpuskuFiles = [];
      }
    } catch (e) {
      _errorMessage = 'Gagal memindai file lokal: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchFiles() async {
    if (_apiDomain == null || _apiDomain!.isEmpty) {
      _errorMessage =
          'Konfigurasi Server API belum diatur. Silakan atur domain terlebih dahulu.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final headers = await _getAuthHeaders();
      final rspaceResponse = await http
          .get(Uri.parse(_rspaceEndpoint), headers: headers)
          .timeout(const Duration(seconds: 15));
      final perpuskuResponse = await http
          .get(Uri.parse(_perpuskuEndpoint), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (rspaceResponse.statusCode == 200) {
        final List<dynamic> rspaceData = json.decode(rspaceResponse.body);
        _rspaceFiles = rspaceData
            .map((item) => FileItem.fromJson(item, _rspaceDownloadBaseUrl))
            .toList();
      } else {
        throw HttpException(
          'Gagal memuat file RSpace: Status ${rspaceResponse.statusCode}',
        );
      }
      if (perpuskuResponse.statusCode == 200) {
        final List<dynamic> perpuskuData = json.decode(perpuskuResponse.body);
        _perpuskuFiles = perpuskuData
            .map((item) => FileItem.fromJson(item, _perpuskuDownloadBaseUrl))
            .toList();
      } else {
        throw HttpException(
          'Gagal memuat file Perpusku: Status ${perpuskuResponse.statusCode}',
        );
      }
    } on SocketException {
      _errorMessage =
          'Tidak dapat terhubung ke server. Periksa koneksi internet dan pastikan domain benar.';
    } on TimeoutException {
      _errorMessage = 'Waktu koneksi habis. Server mungkin sedang tidak aktif.';
    } on HttpException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> deleteFile(FileItem file, bool isRspaceFile) async {
    final url = isRspaceFile
        ? '$_rspaceDeleteBaseUrl${file.uniqueName}'
        : '$_perpuskuDeleteBaseUrl${file.uniqueName}';
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await fetchFiles();
        return 'File "${file.originalName}" berhasil dihapus.';
      } else {
        final responseBody = json.decode(response.body);
        throw HttpException(
          'Gagal menghapus file: ${responseBody['message'] ?? 'Error tidak diketahui'} (Status ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> deleteDownloadedFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _scanDownloadedFiles();
        return 'File "${path.basename(file.path)}" berhasil dihapus dari perangkat.';
      }
      return 'File tidak ditemukan.';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadFile(PlatformFile file, bool isRspaceFile) async {
    _isUploading = true;
    final fileName = file.name;
    _uploadProgress[fileName] = 0.01;
    notifyListeners();
    try {
      final url = isRspaceFile
          ? _rspaceUploadEndpoint
          : _perpuskuUploadEndpoint;
      var request = http.MultipartRequest('POST', Uri.parse(url));
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath(
          'zipfile',
          file.path!,
          filename: fileName,
        ),
      );
      final response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchFiles();
        return 'File "$fileName" berhasil diunggah.';
      } else {
        final responseBody = await response.stream.bytesToString();
        throw HttpException(
          'Gagal mengunggah file: Status ${response.statusCode}, Body: $responseBody',
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      _isUploading = false;
      _uploadProgress.remove(fileName);
      notifyListeners();
    }
  }

  Future<File> _downloadSingleFile(FileItem file, bool isRspaceFile) async {
    final downloadPath = await _pathService.downloadsPath;
    final subfolder = isRspaceFile ? 'rspace_download' : 'perpusku_download';
    final downloadsDir = Directory(path.join(downloadPath, subfolder));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final String savePath = path.join(downloadsDir.path, file.originalName);
    final request = http.Request('GET', Uri.parse(file.downloadUrl));
    request.headers.addAll(await _getAuthHeaders());
    final http.StreamedResponse response = await request.send();
    if (response.statusCode != 200) {
      throw HttpException('Gagal mengunduh: Status ${response.statusCode}');
    }
    final List<int> bytes = await response.stream.toBytes();
    final downloadedFile = File(savePath);
    await downloadedFile.writeAsBytes(bytes);
    await _scanDownloadedFiles();
    return downloadedFile;
  }

  Future<String> downloadFile(FileItem file, bool isRspaceFile) async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('Izin penyimpanan ditolak.');
      }
    }
    final downloadPath = await _pathService.downloadsPath;
    final subfolder = isRspaceFile ? 'rspace_download' : 'perpusku_download';
    final downloadsDir = Directory(path.join(downloadPath, subfolder));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final String savePath = path.join(downloadsDir.path, file.originalName);
    try {
      _downloadProgress[file.uniqueName] = 0.01;
      notifyListeners();
      final request = http.Request('GET', Uri.parse(file.downloadUrl));
      request.headers.addAll(await _getAuthHeaders());
      final http.StreamedResponse response = await request.send();
      if (response.statusCode != 200) {
        throw HttpException('Gagal mengunduh: Status ${response.statusCode}');
      }
      final contentLength = response.contentLength;
      List<int> bytes = [];
      response.stream.listen(
        (List<int> newBytes) {
          bytes.addAll(newBytes);
          if (contentLength != null) {
            _downloadProgress[file.uniqueName] = bytes.length / contentLength;
            notifyListeners();
          }
        },
        onDone: () async {
          final downloadedFile = File(savePath);
          await downloadedFile.writeAsBytes(bytes);
          _downloadProgress.remove(file.uniqueName);
          await _scanDownloadedFiles();
          notifyListeners();
          await OpenFile.open(savePath);
        },
        onError: (e) {
          _downloadProgress.remove(file.uniqueName);
          notifyListeners();
          throw e;
        },
        cancelOnError: true,
      );
      return 'Mengunduh ${file.originalName}...';
    } catch (e) {
      _downloadProgress.remove(file.uniqueName);
      notifyListeners();
      rethrow;
    }
  }
}
