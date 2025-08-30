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
        if (item.isRunning && item.initialDuration.inSeconds > 0) {
          item.initialDuration =
              item.initialDuration - const Duration(seconds: 1);
          shouldNotify = true;
        } else if (item.isRunning && item.initialDuration.inSeconds <= 0) {
          item.isRunning = false;
          shouldNotify = true;
        }
      }
      if (shouldNotify) {
        notifyListeners();
      }
    });
  }

  Future<void> addTimer(String name, Duration duration) async {
    final newItem = CountdownItem(name: name, initialDuration: duration);
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
    if (timer.initialDuration.inSeconds > 0) {
      timer.isRunning = !timer.isRunning;
      _service.saveTimers(_timers);
      notifyListeners();
    }
  }

  void resetTimer(String id, Duration initialDuration) {
    final timer = _timers.firstWhere((item) => item.id == id);
    timer.isRunning = false;
    timer.initialDuration = initialDuration;
    _service.saveTimers(_timers);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
