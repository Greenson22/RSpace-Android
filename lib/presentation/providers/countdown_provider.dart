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

  // ====================== PERUBAHAN UTAMA DI SINI ======================

  // Menyimpan perubahan ke file JSON.
  Future<void> _saveChanges() async {
    await _service.saveTimers(_timers);
  }

  // Fungsi ini sekarang menambahkan ke memori, lalu langsung menyimpan.
  Future<void> addTimer(String name, Duration duration) async {
    final newItem = CountdownItem(
      name: name,
      originalDuration: duration,
      remainingDuration: duration,
    );
    _timers.add(newItem);
    notifyListeners(); // Update UI
    await _saveChanges(); // Simpan ke file
  }

  // Fungsi ini sekarang menghapus dari memori, lalu langsung menyimpan.
  Future<void> removeTimer(String id) async {
    _timers.removeWhere((item) => item.id == id);
    notifyListeners(); // Update UI
    await _saveChanges(); // Simpan ke file
  }

  // Fungsi ini sekarang mengubah state di memori, lalu langsung menyimpan.
  Future<void> toggleTimer(String id) async {
    final timer = _timers.firstWhere((item) => item.id == id);
    if (timer.remainingDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      notifyListeners(); // Update UI
      await _saveChanges(); // Simpan ke file
    }
  }

  // Fungsi ini sekarang mereset di memori, lalu langsung menyimpan.
  Future<void> resetTimer(String id) async {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.remainingDuration = timer.originalDuration;
    notifyListeners(); // Update UI
    await _saveChanges(); // Simpan ke file
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
