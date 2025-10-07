// lib/features/content_management/domain/models/subject_model.dart

import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

class Subject {
  // Properti ini untuk identifikasi, tidak disimpan di file JSON subject
  String topicName;

  // Properti ini diambil dari metadata di file JSON
  String name;
  String icon;
  int position;
  bool isHidden;
  String? linkedPath;
  bool isFrozen;
  String? frozenDate;
  // ==> PROPERTI BARU UNTUK FITUR KUNCI <==
  bool isLocked;
  String? passwordHash;

  // Properti ini dihitung secara dinamis oleh service berdasarkan konten
  String? date;
  String? repetitionCode;
  int discussionCount;
  int finishedDiscussionCount;
  Map<String, int> repetitionCodeCounts;

  // Konten mentah dari file JSON
  List<Discussion> discussions;

  Subject({
    required this.topicName,
    required this.name,
    required this.icon,
    required this.position,
    this.date,
    this.repetitionCode,
    this.isHidden = false,
    this.linkedPath,
    this.isFrozen = false,
    this.frozenDate,
    // ==> TAMBAHKAN DI KONSTRUKTOR <==
    this.isLocked = false,
    this.passwordHash,
    this.discussionCount = 0,
    this.finishedDiscussionCount = 0,
    this.repetitionCodeCounts = const {},
    this.discussions = const [],
  });

  // Factory constructor untuk membuat objek Subject dari JSON
  factory Subject.fromJson(
    String topicName,
    String subjectName,
    Map<String, dynamic> json,
  ) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final content = json['content'] as List<dynamic>? ?? [];

    // ==> KONTEN TIDAK LANGSUNG DI-PARSE JIKA TERKUNCI <==
    final bool isLocked = metadata['isLocked'] as bool? ?? false;
    final discussions = isLocked
        ? <Discussion>[] // Jika terkunci, kembalikan list kosong sementara
        : content.map((item) => Discussion.fromJson(item)).toList();

    return Subject(
      topicName: topicName,
      name: subjectName,
      icon: metadata['icon'] as String? ?? '📄',
      position: metadata['position'] as int? ?? -1,
      isHidden: metadata['isHidden'] as bool? ?? false,
      linkedPath: metadata['linkedPath'] as String?,
      isFrozen: metadata['isFrozen'] as bool? ?? false,
      frozenDate: metadata['frozenDate'] as String?,
      // ==> BACA DARI JSON <==
      isLocked: isLocked,
      passwordHash: metadata['passwordHash'] as String?,
      discussions: discussions,
      discussionCount: discussions.length,
      finishedDiscussionCount: discussions.where((d) => d.finished).length,
    );
  }

  // Method untuk mengubah objek Subject menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'metadata': {
        'icon': icon,
        'position': position,
        'isHidden': isHidden,
        'linkedPath': linkedPath,
        'isFrozen': isFrozen,
        'frozenDate': frozenDate,
        // ==> SIMPAN KE JSON <==
        'isLocked': isLocked,
        'passwordHash': passwordHash,
      },
      // Konten akan dienkripsi secara terpisah oleh service
      'content': discussions.map((d) => d.toJson()).toList(),
    };
  }
}
