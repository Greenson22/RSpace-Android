// lib/data/models/link_suggestion_model.dart

class LinkSuggestion {
  final String title;
  final String relativePath;
  final double score;

  LinkSuggestion({
    required this.title,
    required this.relativePath,
    required this.score,
  });
}
