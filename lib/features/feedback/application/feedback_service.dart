// lib/data/services/feedback_service.dart
import 'dart:convert';
import 'dart:io';
import '../domain/models/feedback_model.dart';
import '../../../core/services/path_service.dart';

class FeedbackService {
  final PathService _pathService = PathService();

  Future<List<FeedbackItem>> loadFeedbackItems() async {
    final filePath = await _pathService.feedbackPath;
    final file = File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
      return [];
    }

    final jsonString = await file.readAsString();
    if (jsonString.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((item) => FeedbackItem.fromJson(item)).toList();
  }

  Future<void> saveFeedbackItems(List<FeedbackItem> items) async {
    final filePath = await _pathService.feedbackPath;
    final file = File(filePath);
    final listJson = items.map((item) => item.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
