// lib/data/services/countdown_service.dart
import 'dart:convert';
import 'dart:io';
import '../models/countdown_model.dart';
import 'path_service.dart';

class CountdownService {
  final PathService _pathService = PathService();

  Future<File> _getTimersFile() async {
    final filePath = await _pathService.countdownTimersPath;
    final file = File(filePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
    }
    return file;
  }

  Future<List<CountdownItem>> loadTimers() async {
    final file = await _getTimersFile();
    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CountdownItem.fromJson(json)).toList();
  }

  Future<void> saveTimers(List<CountdownItem> timers) async {
    final file = await _getTimersFile();
    final listJson = timers.map((timer) => timer.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
