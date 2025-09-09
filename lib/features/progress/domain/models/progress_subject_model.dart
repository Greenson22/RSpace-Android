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

  ProgressSubject({
    required this.namaMateri,
    required this.progress,
    required this.subMateri,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
    };
  }
}
