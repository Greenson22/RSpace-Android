// lib/features/prompt_library/domain/models/prompt_concept_model.dart

import 'prompt_variation_model.dart';

class PromptConcept {
  final String idPrompt;
  final String judulUtama;
  final String deskripsiUtama;
  final List<PromptVariation> variasiPrompt;
  // Menyimpan nama file untuk referensi
  final String fileName;

  PromptConcept({
    required this.idPrompt,
    required this.judulUtama,
    required this.deskripsiUtama,
    required this.variasiPrompt,
    required this.fileName,
  });

  factory PromptConcept.fromJson(Map<String, dynamic> json, String fileName) {
    var variasiList = json['variasi_prompt'] as List;
    List<PromptVariation> variasiPromptList = variasiList
        .map((i) => PromptVariation.fromJson(i))
        .toList();

    return PromptConcept(
      idPrompt: json['id_prompt'] as String,
      judulUtama: json['judul_utama'] as String,
      deskripsiUtama: json['deskripsi_utama'] as String,
      variasiPrompt: variasiPromptList,
      fileName: fileName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_prompt': idPrompt,
    'judul_utama': judulUtama,
    'deskripsi_utama': deskripsiUtama,
    'variasi_prompt': variasiPrompt.map((v) => v.toJson()).toList(),
  };
}
