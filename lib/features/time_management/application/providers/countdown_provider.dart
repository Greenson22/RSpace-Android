// lib/presentation/providers/countdown_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/countdown_model.dart';
import '../services/countdown_service.dart';

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

  /// Memuat ulang semua timer dari penyimpanan.
  Future<void> refreshTimers() async {
    _isLoading = true;
    notifyListeners();
    // Panggil kembali inisialisasi untuk memuat ulang data
    _initialize();
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
    // Panggil service untuk membaca, menambah, dan menyimpan.
    await _service.addTimerAndSave(newItem);
    // Setelah disimpan, muat ulang semua data untuk memastikan konsistensi.
    await refreshTimers();
  }

  /// Memperbarui timer yang ada berdasarkan ID.
  Future<void> updateTimer(
    String id,
    String newName,
    Duration newDuration,
  ) async {
    final timerIndex = _timers.indexWhere((item) => item.id == id);
    if (timerIndex != -1) {
      final timer = _timers[timerIndex];
      timer.name = newName;
      // Set kedua durasi agar reset berfungsi dengan benar
      timer.remainingDuration = newDuration;
      // Perbarui juga originalDuration
      _timers[timerIndex] = CountdownItem(
        id: timer.id,
        name: newName,
        remainingDuration: newDuration,
        originalDuration: newDuration, // Perbarui ini juga
        isRunning: false, // Selalu set ke false saat diedit
        createdAt: timer.createdAt,
      );
      await _saveChanges();
      notifyListeners();
    }
  }

  // Fungsi ini sekarang menghapus dari memori, lalu langsung menyimpan.
  Future<void> removeTimer(String id) async {
    _timers.removeWhere((item) => item.id == id);
    await _saveChanges(); // Simpan ke file
    notifyListeners(); // Update UI
  }

  // Fungsi ini sekarang mengubah state di memori, lalu langsung menyimpan.
  Future<void> toggleTimer(String id) async {
    final timer = _timers.firstWhere((item) => item.id == id);
    if (timer.remainingDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      await _saveChanges(); // Simpan ke file
      notifyListeners(); // Update UI
    }
  }

  // Fungsi ini sekarang mereset di memori, lalu langsung menyimpan.
  Future<void> resetTimer(String id) async {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.remainingDuration = timer.originalDuration;
    await _saveChanges(); // Simpan ke file
    notifyListeners(); // Update UI
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
