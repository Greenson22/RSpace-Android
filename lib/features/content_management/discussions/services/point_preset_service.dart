// lib/features/content_management/domain/services/point_preset_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import '../models/point_preset_model.dart';

class PointPresetService {
  final PathService _pathService = PathService();

  Future<List<PointPreset>> loadPresets() async {
    final filePath = await _pathService.pointPresetsPath;
    final file = File(filePath);
    if (!await file.exists()) {
      await file.writeAsString('[]');
      return [];
    }
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => PointPreset.fromJson(item)).toList();
  }

  Future<void> savePresets(List<PointPreset> presets) async {
    final filePath = await _pathService.pointPresetsPath;
    final file = File(filePath);
    final listJson = presets.map((preset) => preset.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
