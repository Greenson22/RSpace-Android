// lib/features/quiz/domain/models/quiz_model.dart

class QuizTopic {
  String title;
  Map<String, dynamic> metadata;
  int position;
  String icon;

  QuizTopic({
    required this.title,
    this.metadata = const {},
    this.position = -1,
    this.icon = '❓', // Ikon default untuk kuis
  });

  factory QuizTopic.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};

    return QuizTopic(
      title: json['title'] as String,
      metadata: metadata,
      position: metadata['position'] as int? ?? -1,
      icon: metadata['icon'] as String? ?? '❓',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> mutableMetadata = Map.from(metadata);
    mutableMetadata['position'] = position;
    mutableMetadata['icon'] = icon;

    return {
      'title': title,
      'metadata': mutableMetadata,
      // Di masa depan, bisa ditambahkan list pertanyaan di sini
      'questions': [],
    };
  }
}
