// lib/features/progress/application/palette_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/color_palette_model.dart';

class PaletteService {
  final PathService _pathService = PathService();

  Future<File> get _paletteFile async {
    final progressPath = await _pathService.progressPath;
    return File(path.join(progressPath, 'custom_palettes.json'));
  }

  Future<List<ColorPalette>> loadPalettes() async {
    final file = await _paletteFile;
    if (!await file.exists()) {
      return [];
    }
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => ColorPalette.fromJson(item)).toList();
  }

  Future<void> savePalettes(List<ColorPalette> palettes) async {
    final file = await _paletteFile;
    final listJson = palettes.map((palette) => palette.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
