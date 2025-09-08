// lib/features/prompt_library/domain/models/prompt_variation_model.dart

class PromptVariation {
  final String nama;
  final String versi;
  final String deskripsi;
  final List<String> targetModelAi;
  final String isiPrompt;

  PromptVariation({
    required this.nama,
    required this.versi,
    required this.deskripsi,
    required this.targetModelAi,
    required this.isiPrompt,
  });

  factory PromptVariation.fromJson(Map<String, dynamic> json) =>
      PromptVariation(
        nama: json['nama'] as String,
        versi: json['versi'] as String,
        deskripsi: json['deskripsi'] as String,
        targetModelAi: List<String>.from(json['target_model_ai'] as List),
        isiPrompt: json['isi_prompt'] as String,
      );

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'versi': versi,
    'deskripsi': deskripsi,
    'target_model_ai': targetModelAi,
    'isi_prompt': isiPrompt,
  };
}
