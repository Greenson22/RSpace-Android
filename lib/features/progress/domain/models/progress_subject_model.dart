// lib/features/progress/domain/models/progress_subject_model.dart

class SubMateri {
  String namaMateri;
  String progress;
  String? finishedDate;

  SubMateri({
    required this.namaMateri,
    required this.progress,
    this.finishedDate,
  });

  factory SubMateri.fromJson(Map<String, dynamic> json) {
    return SubMateri(
      namaMateri: json['nama_materi'] as String,
      progress: json['progress'] as String,
      finishedDate: json['finishedDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'finishedDate': finishedDate,
    };
  }
}

class ProgressSubject {
  String namaMateri;
  String progress;
  List<SubMateri> subMateri;
  int? backgroundColor;
  int? textColor;
  int? progressBarColor;
  String icon;
  bool isHidden;
  String section; // Properti untuk kategori bagian
  String type; // 'list' atau 'note'
  String? noteContent;

  ProgressSubject({
    required this.namaMateri,
    required this.progress,
    required this.subMateri,
    this.backgroundColor,
    this.textColor,
    this.progressBarColor,
    this.icon = '📚',
    this.isHidden = false,
    this.section = 'queue',
    this.type = 'list', // Default ke daftar sub-materi
    this.noteContent,
  });

  factory ProgressSubject.fromJson(Map<String, dynamic> json) {
    var subMateriList = json['sub_materi'] as List? ?? [];
    List<SubMateri> subMateri = subMateriList
        .map((i) => SubMateri.fromJson(i))
        .toList();

    return ProgressSubject(
      namaMateri: json['nama_materi'] as String,
      progress: json['progress'] as String,
      subMateri: subMateri,
      backgroundColor: json['backgroundColor'] as int?,
      textColor: json['textColor'] as int?,
      progressBarColor: json['progressBarColor'] as int?,
      icon: json['icon'] as String? ?? '📚',
      isHidden: json['isHidden'] as bool? ?? false,
      section: json['section'] as String? ?? 'queue',
      type: json['type'] as String? ?? 'list',
      noteContent: json['noteContent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_materi': namaMateri,
      'progress': progress,
      'sub_materi': subMateri.map((e) => e.toJson()).toList(),
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'progressBarColor': progressBarColor,
      'icon': icon,
      'isHidden': isHidden,
      'section': section,
      'type': type,
      'noteContent': noteContent,
    };
  }
}
