// lib/data/services/countdown_service.dart
import 'dart:convert';
import 'dart:io';
import '../../domain/models/countdown_model.dart';
import '../../../../core/services/dua/path_service.dart';

class CountdownService {
  final PathService _pathService = PathService();

  Future<File> _getTimersFile() async {
    final filePath = await _pathService.countdownTimersPath;
    final file = File(filePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      // Membuat file dengan struktur JSON yang baru
      await file.writeAsString(jsonEncode({'metadata': null, 'countdown': []}));
    }
    return file;
  }

  Future<List<CountdownItem>> loadTimers() async {
    final file = await _getTimersFile();
    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) return [];

    final dynamic jsonData = jsonDecode(jsonString);

    // Cek apakah formatnya adalah Map (struktur baru) atau List (struktur lama)
    if (jsonData is Map<String, dynamic>) {
      // Struktur baru: {'metadata': ..., 'countdown': [...]}
      final List<dynamic> jsonList = jsonData['countdown'] ?? [];
      return jsonList.map((json) => CountdownItem.fromJson(json)).toList();
    } else if (jsonData is List) {
      // Struktur lama (untuk kompatibilitas): [...]
      // Konversi data lama ke format baru dan simpan kembali
      final List<CountdownItem> timers = jsonData
          .map((json) => CountdownItem.fromJson(json))
          .toList();
      await saveTimers(timers); // Simpan dalam format baru
      return timers;
    }

    return [];
  }

  Future<void> saveTimers(List<CountdownItem> timers) async {
    final file = await _getTimersFile();
    final listJson = timers.map((timer) => timer.toJson()).toList();

    // Bungkus list ke dalam struktur JSON yang baru
    final newJsonData = {'metadata': null, 'countdown': listJson};

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(newJsonData));
  }

  /// Membaca data saat ini, menambahkan timer baru, lalu menyimpan kembali.
  Future<void> addTimerAndSave(CountdownItem newTimer) async {
    // 1. Baca data yang ada saat ini dari file.
    final List<CountdownItem> currentTimers = await loadTimers();
    // 2. Tambahkan timer baru ke daftar yang sudah ada.
    currentTimers.add(newTimer);
    // 3. Simpan kembali seluruh daftar yang sudah diperbarui.
    await saveTimers(currentTimers);
  }
}
