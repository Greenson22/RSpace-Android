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
          // Penyimpanan otomatis saat timer selesai dihapus dari sini
          shouldNotify = true;
        }
      }
      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  // Fungsi-fungsi di bawah ini sekarang hanya mengubah data di memori
  void addTimer(String name, Duration duration) {
    final newItem = CountdownItem(
      name: name,
      originalDuration: duration,
      remainingDuration: duration,
    );
    _timers.add(newItem);
    notifyListeners();
  }

  void removeTimer(String id) {
    _timers.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void toggleTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    if (timer.remainingDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      notifyListeners();
    }
  }

  void resetTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.remainingDuration = timer.originalDuration;
    notifyListeners();
  }

  // ====================== PERUBAHAN UTAMA DI SINI ======================
  @override
  void dispose() {
    _ticker?.cancel();
    // 1. Simpan semua timer ke file JSON saat provider akan dihancurkan (keluar halaman)
    _service.saveTimers(_timers);
    // 2. Hapus semua timer dari memori
    _timers.clear();
    super.dispose();
  }
}
