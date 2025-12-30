// lib/features/prompt_library/domain/models/prompt_concept_model.dart

class PromptConcept {
  final String idPrompt;
  final String title;
  final String content;
  final String description;
  final String fileName;

  PromptConcept({
    required this.idPrompt,
    required this.title,
    required this.content,
    required this.description,
    required this.fileName,
  });

  factory PromptConcept.fromJson(Map<String, dynamic> json, String fileName) {
    return PromptConcept(
      // Menggunakan '??' untuk memberikan nilai default jika null
      // Ini mencegah error "Null is not a subtype of String"
      idPrompt: (json['id_prompt'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Tanpa Judul',
      content: (json['content'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      fileName: fileName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_prompt': idPrompt,
    'title': title,
    'content': content,
    'description': description,
  };
}
