// lib/presentation/providers/file_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path; // ==> IMPORT DITAMBAHKAN
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/file_model.dart';
// ==> IMPORT DITAMBAHKAN
import '../../data/services/shared_preferences_service.dart';

class FileProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<FileItem> _rspaceFiles = [];
  List<FileItem> get rspaceFiles => _rspaceFiles;

  List<FileItem> _perpuskuFiles = [];
  List<FileItem> get perpuskuFiles => _perpuskuFiles;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==> STATE BARU UNTUK PATH DOWNLOAD <==
  String? _downloadPath;
  String? get downloadPath => _downloadPath;

  final Map<String, double> _downloadProgress = {};
  double getDownloadProgress(String uniqueName) =>
      _downloadProgress[uniqueName] ?? 0.0;

  final String _rspaceEndpoint = 'http://rikal.kecmobar.my.id/api/rspace/files';
  final String _perpuskuEndpoint =
      'http://rikal.kecmobar.my.id/api/perpusku/files';
  final String _rspaceDownloadBaseUrl =
      'http://rikal.kecmobar.my.id/api/rspace/download/';
  final String _perpuskuDownloadBaseUrl =
      'http://rikal.kecmobar.my.id/api/perpusku/download/';
  final String _apiKey = 'frendygerung1234567890';

  FileProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadDownloadPath();
    await fetchFiles();
  }

  Future<void> _loadDownloadPath() async {
    _downloadPath = await _prefsService.loadCustomDownloadPath();
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGATUR PATH DOWNLOAD <==
  Future<void> setDownloadPath(String newPath) async {
    await _prefsService.saveCustomDownloadPath(newPath);
    _downloadPath = newPath;
    notifyListeners();
  }

  Future<void> fetchFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = {'x-api-key': _apiKey};
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
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
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

  // ==> FUNGSI DOWNLOAD DIPERBARUI TOTAL <==
  Future<String> downloadFile(FileItem file, bool isRspaceFile) async {
    if (_downloadPath == null || _downloadPath!.isEmpty) {
      throw Exception('Folder tujuan download belum ditentukan.');
    }

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
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
      request.headers['x-api-key'] = _apiKey;
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
