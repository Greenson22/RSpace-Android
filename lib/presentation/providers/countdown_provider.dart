// lib/presentation/providers/countdown_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/countdown_model.dart';
import '../../data/services/countdown_service.dart';

class CountdownProvider with ChangeNotifier {
  final CountdownService _service = CountdownService();
  List<CountdownItem> _timers = [];
  Timer? _ticker;

  List<CountdownItem> get timers => _timers;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  CountdownProvider() {
    _initialize();
  }

  void _initialize() async {
    _timers = await _service.loadTimers();
    _isLoading = false;
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool shouldNotify = false;
      for (var item in _timers) {
        if (item.isRunning && item.remainingDuration.inSeconds > 0) {
          item.remainingDuration =
              item.remainingDuration - const Duration(seconds: 1);
          shouldNotify = true;
        } else if (item.isRunning && item.remainingDuration.inSeconds <= 0) {
          item.isRunning = false;
          // Simpan saat timer selesai secara otomatis
          _service.saveTimers(_timers);
          shouldNotify = true;
        }
      }
      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  // ====================== PERUBAHAN DI SINI ======================
  Future<void> addTimer(String name, Duration duration) async {
    final newItem = CountdownItem(
      name: name,
      originalDuration: duration,
      remainingDuration: duration,
    );
    _timers.add(newItem);
    // Notifikasi UI terlebih dahulu untuk respons instan
    notifyListeners();
    // Kemudian simpan perubahan ke file
    await _service.saveTimers(_timers);
  }

  Future<void> removeTimer(String id) async {
    _timers.removeWhere((item) => item.id == id);
    // Notifikasi UI terlebih dahulu
    notifyListeners();
    // Kemudian simpan perubahan
    await _service.saveTimers(_timers);
  }

  void toggleTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    if (timer.remainingDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      // Notifikasi UI terlebih dahulu
      notifyListeners();
      // Kemudian simpan perubahan
      _service.saveTimers(_timers);
    }
  }

  void resetTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.remainingDuration = timer.originalDuration;
    // Notifikasi UI terlebih dahulu
    notifyListeners();
    // Kemudian simpan perubahan
    _service.saveTimers(_timers);
  }
  // ==================== AKHIR PERUBAHAN ====================

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
