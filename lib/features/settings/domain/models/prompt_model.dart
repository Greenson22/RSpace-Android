// lib/data/models/prompt_model.dart
import 'dart:convert';

class Prompt {
  String id;
  String name;
  String content;
  bool isActive;
  final bool isDefault;

  Prompt({
    required this.id,
    required this.name,
    required this.content,
    this.isActive = false,
    this.isDefault = false,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) => Prompt(
    id: json['id'],
    name: json['name'],
    content: json['content'],
    isActive: json['isActive'] ?? false,
    isDefault: json['isDefault'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'content': content,
    'isActive': isActive,
    'isDefault': isDefault,
  };
}

// Helper functions
String encodePrompts(List<Prompt> prompts) =>
    json.encode(prompts.map<Map<String, dynamic>>((p) => p.toJson()).toList());

List<Prompt> decodePrompts(String encodedPrompts) {
  if (encodedPrompts.isEmpty) return [];
  try {
    final List<dynamic> decoded = json.decode(encodedPrompts);
    return decoded.map<Prompt>((item) => Prompt.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
}
