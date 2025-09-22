// lib/features/link_maintenance/application/providers/file_path_correction_provider.dart

import 'package:flutter/material.dart';
import '../services/file_path_correction_service.dart';

class FilePathCorrectionProvider with ChangeNotifier {
  final FilePathCorrectionService _service = FilePathCorrectionService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFinished = false;
  bool get isFinished => _isFinished;

  String? _error;
  String? get error => _error;

  Map<String, int> _results = {};
  Map<String, int> get results => _results;

  Future<void> runCorrection() async {
    _isLoading = true;
    _isFinished = false;
    _error = null;
    notifyListeners();

    try {
      _results = await _service.correctAllFilePaths();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isFinished = true;
      notifyListeners();
    }
  }
}
