// lib/presentation/providers/file_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../data/models/file_model.dart';

class FileProvider with ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<FileItem> _rspaceFiles = [];
  List<FileItem> get rspaceFiles => _rspaceFiles;

  List<FileItem> _perpuskuFiles = [];
  List<FileItem> get perpuskuFiles => _perpuskuFiles;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String _rspaceEndpoint = 'http://rikal.kecmobar.my.id/api/rspace/files';
  final String _perpuskuEndpoint =
      'http://rikal.kecmobar.my.id/api/perpusku/files';
  final String _apiKey = 'frendygerung1234567890';
  // Base URL untuk membangun link download
  final String _rspaceBaseUrl = 'http://rikal.kecmobar.my.id/rspace-files';
  final String _perpuskuBaseUrl = 'http://rikal.kecmobar.my.id/perpusku-files';

  FileProvider() {
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = {'x-api-key': _apiKey};

      // Menambahkan timeout untuk mencegah loading tanpa henti
      final rspaceResponse = await http
          .get(Uri.parse(_rspaceEndpoint), headers: headers)
          .timeout(const Duration(seconds: 15));

      final perpuskuResponse = await http
          .get(Uri.parse(_perpuskuEndpoint), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (rspaceResponse.statusCode == 200) {
        // PERBAIKAN: Langsung decode sebagai List, bukan Map
        final List<dynamic> rspaceData = json.decode(rspaceResponse.body);
        _rspaceFiles = rspaceData
            .map((item) => FileItem.fromJson(item, _rspaceBaseUrl))
            .toList();
      } else {
        throw HttpException(
          'Gagal memuat file RSpace: Status ${rspaceResponse.statusCode}',
        );
      }

      if (perpuskuResponse.statusCode == 200) {
        // PERBAIKAN: Langsung decode sebagai List, bukan Map
        final List<dynamic> perpuskuData = json.decode(perpuskuResponse.body);
        _perpuskuFiles = perpuskuData
            .map((item) => FileItem.fromJson(item, _perpuskuBaseUrl))
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
}
