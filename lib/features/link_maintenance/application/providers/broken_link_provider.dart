// lib/presentation/providers/broken_link_provider.dart

import 'package:flutter/material.dart';
import '../../domain/models/broken_link_model.dart';
import '../services/broken_link_service.dart';

class BrokenLinkProvider with ChangeNotifier {
  final BrokenLinkService _service = BrokenLinkService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<BrokenLink> _brokenLinks = [];
  List<BrokenLink> get brokenLinks => _brokenLinks;

  BrokenLinkProvider() {
    fetchBrokenLinks();
  }

  Future<void> fetchBrokenLinks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _brokenLinks = await _service.findBrokenLinks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
