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
          _service.saveTimers(_timers); // Simpan saat timer selesai otomatis
          shouldNotify = true;
        }
      }
      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  Future<void> addTimer(String name, Duration duration) async {
    final newItem = CountdownItem(
      name: name,
      originalDuration: duration, // Simpan durasi asli
      remainingDuration: duration, // Atur sisa waktu awal
    );
    _timers.add(newItem);
    await _service.saveTimers(_timers);
    notifyListeners();
  }

  Future<void> removeTimer(String id) async {
    _timers.removeWhere((item) => item.id == id);
    await _service.saveTimers(_timers);
    notifyListeners();
  }

  void toggleTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    if (timer.remainingDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      _service.saveTimers(_timers); // Simpan status isRunning
      notifyListeners();
    }
  }

  void resetTimer(String id) {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.remainingDuration = timer.originalDuration; // Reset dari durasi asli
    _service.saveTimers(_timers);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
