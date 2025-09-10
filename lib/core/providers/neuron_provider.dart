// lib/core/providers/neuron_provider.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class NeuronProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  int _neuronCount = 0;
  int get neuronCount => _neuronCount;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  NeuronProvider() {
    loadNeurons();
  }

  /// Memuat jumlah neuron dari penyimpanan.
  Future<void> loadNeurons() async {
    _isLoading = true;
    notifyListeners();
    _neuronCount = await _prefsService.loadNeurons();
    _isLoading = false;
    notifyListeners();
  }

  /// Menambah neuron, menyimpan, dan memberitahu listener.
  Future<void> addNeurons(int amount) async {
    final newTotal = _neuronCount + amount;
    // Panggil service untuk menyimpan total baru
    await _prefsService.saveNeurons(newTotal);
    // Update state di provider
    _neuronCount = newTotal;
    notifyListeners();
  }

  /// Mengurangi neuron jika jumlahnya mencukupi.
  Future<bool> spendNeurons(int amount) async {
    if (_neuronCount >= amount) {
      final newTotal = _neuronCount - amount;
      await _prefsService.saveNeurons(newTotal);
      _neuronCount = newTotal;
      notifyListeners();
      return true;
    }
    return false;
  }
}
