// lib/features/progress/domain/models/progress_subject_model.dart

class SubMateri {
  String namaMateri;
  String progress;

  SubMateri({required this.namaMateri, required this.progress});

  factory SubMateri.fromJson(Map<String, dynamic> json) {
    return SubMateri(
      namaMateri: json['nama_materi'] as String,
      progress: json['progress'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'nama_materi': namaMateri, 'progress': progress};
  }
}

class ProgressSubject {
  String namaMateri;
  String progress;
  List<SubMateri> subMateri;
  // Ganti 'color' dengan tiga properti warna baru
  int? backgroundColor;
  int? textColor;
  int? progressBarColor;

  ProgressSubject({
    required this.namaMateri,
    required this.progress,
    required this.subMateri,
    this.backgroundColor,
    this.textColor,
    this.progressBarColor,
  });

  factory ProgressSubject.fromJson(Map<String, dynamic> json) {
    var subMateriList = json['sub_materi'] as List;
    List<SubMateri> subMateri = subMateriList
        .map((i) => SubMateri.fromJson(i))
        .toList();

    return ProgressSubject(
      namaMateri: json['nama_materi'] as String,
      progress: json['progress'] as String,
      subMateri: subMateri,
      // Baca tiga warna dari JSON
      backgroundColor: json['backgroundColor'] as int?,
      textColor: json['textColor'] as int?,
      progressBarColor: json['progressBarColor'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
      // Simpan tiga warna ke JSON
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'progressBarColor': progressBarColor,
    };
  }
}
