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
import '../domain/models/file_model.dart';
import '../../../core/services/storage_service.dart';

class FileProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
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

  String? _downloadPath;
  String? get downloadPath => _downloadPath;

  final Map<String, double> _downloadProgress = {};
  double getDownloadProgress(String uniqueName) =>
      _downloadProgress[uniqueName] ?? 0.0;

  final Map<String, double> _uploadProgress = {};
  double getUploadProgress(String fileName) => _uploadProgress[fileName] ?? 0.0;
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  // ==> STATE BARU UNTUK SELEKSI FILE <==
  final Set<String> _selectedDownloadedFiles = {};
  Set<String> get selectedDownloadedFiles => _selectedDownloadedFiles;
  bool get isSelectionMode => _selectedDownloadedFiles.isNotEmpty;

  String? _apiDomain;
  String? _apiKey;
  String? get apiDomain => _apiDomain;
  String? get apiKey => _apiKey;

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

  // ==> FUNGSI BARU UNTUK MENGELOLA SELEKSI <==
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
        // Abaikan error jika file tidak dapat dihapus
      }
    }
    _selectedDownloadedFiles.clear();
    await _scanDownloadedFiles(); // Muat ulang daftar file
    return '$count file berhasil dihapus.';
  }
  // --- AKHIR FUNGSI BARU ---

  Future<void> _initialize() async {
    await _loadApiConfig();
    await _loadDownloadPath();
    if (_apiDomain != null && _apiKey != null) {
      await Future.wait([fetchFiles(), _scanDownloadedFiles()]);
    } else {
      _isLoading = false;
      _errorMessage =
          'Konfigurasi Server API belum diatur. Silakan atur domain dan API key terlebih dahulu.';
      notifyListeners();
    }
  }

  Future<void> _loadApiConfig() async {
    final config = await _prefsService.loadApiConfig();
    _apiDomain = config['domain'];
    _apiKey = config['apiKey'];
    notifyListeners();
  }

  Future<void> saveApiConfig(String domain, String apiKey) async {
    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }
    await _prefsService.saveApiConfig(domain, apiKey);
    _apiDomain = domain;
    _apiKey = apiKey;
    notifyListeners();
    await fetchFiles();
  }

  Future<void> _loadDownloadPath() async {
    _downloadPath = await _prefsService.loadCustomDownloadPath();
    notifyListeners();
  }

  Future<void> setDownloadPath(String newPath) async {
    await _prefsService.saveCustomDownloadPath(newPath);
    _downloadPath = newPath;
    await _scanDownloadedFiles();
    notifyListeners();
  }

  Future<void> _scanDownloadedFiles() async {
    if (_downloadPath == null || _downloadPath!.isEmpty) {
      _downloadedRspaceFiles = [];
      _downloadedPerpuskuFiles = [];
      notifyListeners();
      return;
    }

    try {
      final rspaceDir = Directory(path.join(_downloadPath!, 'rspace_download'));
      if (await rspaceDir.exists()) {
        _downloadedRspaceFiles = rspaceDir
            .listSync()
            .whereType<File>()
            .toList();
      } else {
        _downloadedRspaceFiles = [];
      }

      final perpuskuDir = Directory(
        path.join(_downloadPath!, 'perpusku_download'),
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
    if (_apiDomain == null ||
        _apiKey == null ||
        _apiDomain!.isEmpty ||
        _apiKey!.isEmpty) {
      _errorMessage =
          'Konfigurasi Server API belum diatur. Silakan atur domain dan API key terlebih dahulu.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = {'x-api-key': _apiKey!};
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
      _errorMessage = 'Terjadi kesalahan tidak terduga: ${e.toString()}';
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
      final response = await http.delete(
        Uri.parse(url),
        headers: {'x-api-key': _apiKey!},
      );

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
      request.headers['x-api-key'] = _apiKey!;

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

  Future<void> downloadAndImportAll(BuildContext context) async {
    if (_downloadPath == null || _downloadPath!.isEmpty) {
      throw Exception('Folder tujuan download belum ditentukan.');
    }

    _isDownloading = true;
    notifyListeners();

    try {
      final rspaceFile = _rspaceFiles.isNotEmpty ? _rspaceFiles.first : null;
      final perpuskuFile = _perpuskuFiles.isNotEmpty
          ? _perpuskuFiles.first
          : null;

      if (rspaceFile == null && perpuskuFile == null) {
        throw Exception('Tidak ada file yang tersedia untuk diunduh.');
      }

      List<File> downloadedFiles = [];

      if (rspaceFile != null) {
        final downloaded = await _downloadSingleFile(rspaceFile, true);
        downloadedFiles.add(downloaded);
      }
      if (perpuskuFile != null) {
        final downloaded = await _downloadSingleFile(perpuskuFile, false);
        downloadedFiles.add(downloaded);
      }

      if (context.mounted) {
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Konfirmasi Import'),
                content: Text(
                  'Download selesai. Lanjutkan untuk mengimpor ${downloadedFiles.length} file? Ini akan menimpa data yang ada.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Lanjutkan'),
                  ),
                ],
              ),
            ) ??
            false;

        if (confirmed && context.mounted) {
          if (rspaceFile != null) {
            await importSpecificFile(
              context,
              downloadedFiles.firstWhere(
                (f) => path.basename(f.path) == rspaceFile.originalName,
              ),
              'RSpace',
            );
          }
          if (perpuskuFile != null) {
            await importSpecificFile(
              context,
              downloadedFiles.firstWhere(
                (f) => path.basename(f.path) == perpuskuFile.originalName,
              ),
              'PerpusKu',
            );
          }
        }
      }
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<File> _downloadSingleFile(FileItem file, bool isRspaceFile) async {
    final subfolder = isRspaceFile ? 'rspace_download' : 'perpusku_download';
    final downloadsDir = Directory(path.join(_downloadPath!, subfolder));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final String savePath = path.join(downloadsDir.path, file.originalName);

    final request = http.Request('GET', Uri.parse(file.downloadUrl));
    request.headers['x-api-key'] = _apiKey!;
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
    if (_downloadPath == null || _downloadPath!.isEmpty) {
      throw Exception('Folder tujuan download belum ditentukan.');
    }

    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        throw Exception('Izin penyimpanan ditolak.');
      }
    }

    final subfolder = isRspaceFile ? 'rspace_download' : 'perpusku_download';
    final downloadsDir = Directory(path.join(_downloadPath!, subfolder));

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final String savePath = path.join(downloadsDir.path, file.originalName);

    try {
      _downloadProgress[file.uniqueName] = 0.01;
      notifyListeners();

      final request = http.Request('GET', Uri.parse(file.downloadUrl));
      request.headers['x-api-key'] = _apiKey!;
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
