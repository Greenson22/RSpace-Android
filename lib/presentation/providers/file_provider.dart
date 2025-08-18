// lib/presentation/providers/file_provider.dart

import 'dart:convert';
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

  FileProvider() {
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = {'x-api-key': _apiKey};

      final rspaceResponse = await http.get(
        Uri.parse(_rspaceEndpoint),
        headers: headers,
      );
      final perpuskuResponse = await http.get(
        Uri.parse(_perpuskuEndpoint),
        headers: headers,
      );

      if (rspaceResponse.statusCode == 200) {
        final List<dynamic> rspaceData = json.decode(rspaceResponse.body);
        _rspaceFiles = rspaceData
            .map((item) => FileItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Gagal memuat file RSpace');
      }

      if (perpuskuResponse.statusCode == 200) {
        final List<dynamic> perpuskuData = json.decode(perpuskuResponse.body);
        _perpuskuFiles = perpuskuData
            .map((item) => FileItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Gagal memuat file Perpusku');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
