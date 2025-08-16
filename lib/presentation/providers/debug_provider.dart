// lib/presentation/providers/debug_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugProvider with ChangeNotifier {
  bool _allowPathChanges = false;
  bool get allowPathChanges => _allowPathChanges;

  void togglePathChanges() {
    if (kDebugMode) {
      _allowPathChanges = !_allowPathChanges;
      notifyListeners();
    }
  }
}
