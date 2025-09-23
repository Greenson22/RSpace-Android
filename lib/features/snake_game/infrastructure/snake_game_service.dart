import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../core/services/path_service.dart';
import '../domain/snake_ann.dart';

class SnakeGameService {
  final PathService _pathService = PathService();
  static const String _bestBrainFileName = 'best_snake_brain.json';

  Future<File> get _bestBrainFile async {
    final snakePath = await _pathService.snakeGamePath;
    return File(path.join(snakePath, _bestBrainFileName));
  }

  Future<void> saveBestBrain(NeuralNetwork brain) async {
    final file = await _bestBrainFile;
    final jsonString = jsonEncode(brain.toJson());
    await file.writeAsString(jsonString);
  }

  Future<NeuralNetwork?> loadBestBrain() async {
    final file = await _bestBrainFile;
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      if (jsonString.isNotEmpty) {
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return NeuralNetwork.fromJson(jsonData);
      }
    }
    return null;
  }
}