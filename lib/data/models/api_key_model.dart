// lib/data/models/api_key_model.dart
import 'dart:convert';

class ApiKey {
  String id;
  String name;
  String key;
  bool isActive;

  ApiKey({
    required this.id,
    required this.name,
    required this.key,
    this.isActive = false,
  });

  factory ApiKey.fromJson(Map<String, dynamic> json) => ApiKey(
    id: json['id'],
    name: json['name'],
    key: json['key'],
    isActive: json['isActive'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'key': key,
    'isActive': isActive,
  };
}

// Fungsi helper untuk mengubah list ApiKey menjadi string JSON untuk disimpan
String encodeApiKeys(List<ApiKey> keys) =>
    json.encode(keys.map<Map<String, dynamic>>((key) => key.toJson()).toList());

// Fungsi helper untuk mengubah string JSON kembali menjadi list ApiKey
List<ApiKey> decodeApiKeys(String encodedKeys) {
  if (encodedKeys.isEmpty) return [];
  try {
    final List<dynamic> decoded = json.decode(encodedKeys);
    return decoded.map<ApiKey>((item) => ApiKey.fromJson(item)).toList();
  } catch (e) {
    return [];
  }
}
