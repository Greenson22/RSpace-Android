// lib/features/settings/domain/models/gemini_settings_model.dart
import 'dart:convert';
import 'api_key_model.dart';
import 'prompt_model.dart';

// Definisikan prompt default di sini sebagai konstanta global
const String defaultMotivationalPrompt =
    'Berikan saya satu kalimat motivasi singkat tentang belajar atau pengetahuan dalam Bahasa Indonesia. Kalimat harus inspiratif dan tidak lebih dari 20 kata. Jangan gunakan tanda kutip di awal dan akhir kalimat.';

class GeminiSettings {
  final List<ApiKey> apiKeys;
  final List<Prompt> prompts;
  final String contentModelId;
  final String chatModelId;
  final String generalModelId;
  final String quizModelId;
  final String titleGenerationModelId;
  final String motivationalQuotePrompt;

  GeminiSettings({
    this.apiKeys = const [],
    this.prompts = const [],
    this.contentModelId = 'gemini-1.5-flash-latest',
    this.chatModelId = 'gemini-1.5-flash-latest',
    this.generalModelId = 'gemini-1.5-flash-latest',
    this.quizModelId = 'gemini-1.5-flash-latest',
    this.titleGenerationModelId = 'gemini-1.5-flash-latest',
    this.motivationalQuotePrompt =
        defaultMotivationalPrompt, // Gunakan konstanta
  });

  factory GeminiSettings.fromJson(Map<String, dynamic> json) {
    return GeminiSettings(
      apiKeys:
          (json['apiKeys'] as List<dynamic>?)
              ?.map((e) => ApiKey.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      prompts:
          (json['prompts'] as List<dynamic>?)
              ?.map((e) => Prompt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      contentModelId:
          json['contentModelId'] as String? ?? 'gemini-1.5-flash-latest',
      chatModelId: json['chatModelId'] as String? ?? 'gemini-1.5-flash-latest',
      generalModelId:
          json['generalModelId'] as String? ?? 'gemini-1.5-flash-latest',
      quizModelId: json['quizModelId'] as String? ?? 'gemini-1.5-flash-latest',
      titleGenerationModelId:
          json['titleGenerationModelId'] as String? ??
          'gemini-1.5-flash-latest',
      motivationalQuotePrompt:
          json['motivationalQuotePrompt'] as String? ??
          defaultMotivationalPrompt, // Gunakan konstanta
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiKeys': apiKeys.map((e) => e.toJson()).toList(),
      'prompts': prompts.map((e) => e.toJson()).toList(),
      'contentModelId': contentModelId,
      'chatModelId': chatModelId,
      'generalModelId': generalModelId,
      'quizModelId': quizModelId,
      'titleGenerationModelId': titleGenerationModelId,
      'motivationalQuotePrompt': motivationalQuotePrompt,
    };
  }

  GeminiSettings copyWith({
    List<ApiKey>? apiKeys,
    List<Prompt>? prompts,
    String? contentModelId,
    String? chatModelId,
    String? generalModelId,
    String? quizModelId,
    String? titleGenerationModelId,
    String? motivationalQuotePrompt,
  }) {
    return GeminiSettings(
      apiKeys: apiKeys ?? this.apiKeys,
      prompts: prompts ?? this.prompts,
      contentModelId: contentModelId ?? this.contentModelId,
      chatModelId: chatModelId ?? this.chatModelId,
      generalModelId: generalModelId ?? this.generalModelId,
      quizModelId: quizModelId ?? this.quizModelId,
      titleGenerationModelId:
          titleGenerationModelId ?? this.titleGenerationModelId,
      motivationalQuotePrompt:
          motivationalQuotePrompt ?? this.motivationalQuotePrompt,
    );
  }
}
