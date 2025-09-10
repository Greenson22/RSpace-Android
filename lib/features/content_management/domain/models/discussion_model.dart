// lib/data/models/discussion_model.dart
import '../../presentation/discussions/utils/repetition_code_utils.dart';

class Point {
  String pointText;
  String repetitionCode;
  String date;
  bool finished;
  String? finish_date;

  Point({
    required this.pointText,
    required this.repetitionCode,
    required this.date,
    this.finished = false,
    this.finish_date,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      pointText: json['point_text'] ?? 'Tidak ada teks poin',
      repetitionCode: json['repetition_code'] ?? '',
      date: json['date'] ?? 'No Date',
      finished: json['finished'] ?? false,
      finish_date: json['finish_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point_text': pointText,
      'repetition_code': repetitionCode,
      'date': date,
      'finished': finished,
      'finish_date': finish_date,
    };
  }
}

class Discussion {
  String discussion;
  String? date;
  String repetitionCode;
  List<Point> points;
  bool finished;
  String? finish_date;
  String? filePath;
  // >> BARU: Field sementara untuk menampung konten HTML dari arsip
  String? archivedHtmlContent;

  Discussion({
    required this.discussion,
    this.date,
    required this.repetitionCode,
    required this.points,
    this.finished = false,
    this.finish_date,
    this.filePath,
    this.archivedHtmlContent, // Tambahkan di konstruktor
  });

  Point? get _pointWithMinRepetitionCode {
    final activePoints = points.where((p) => !p.finished).toList();
    if (activePoints.isEmpty) {
      return null;
    }

    // >> PERBAIKAN: Logika diubah untuk memprioritaskan kode terkecil (R0D)
    // Tidak ada lagi logika pemisahan R0D. Semua poin aktif diurutkan.
    activePoints.sort((a, b) {
      // Urutan pertama berdasarkan indeks kode repetisi (R0D akan menjadi yang terkecil)
      int codeComparison = getRepetitionCodeIndex(
        a.repetitionCode,
      ).compareTo(getRepetitionCodeIndex(b.repetitionCode));

      if (codeComparison != 0) {
        return codeComparison;
      }

      // Jika kodenya sama, urutkan berdasarkan tanggal (yang lebih dulu lebih utama)
      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateA.compareTo(dateB);
      } catch (e) {
        // Jika tanggal tidak valid, anggap sama
        return 0;
      }
    });

    return activePoints.first;
  }

  String get effectiveRepetitionCode {
    if (finished) return 'Finish';
    return _pointWithMinRepetitionCode?.repetitionCode ?? repetitionCode;
  }

  String? get effectiveDate {
    if (finished) return finish_date;
    return _pointWithMinRepetitionCode?.date ?? date;
  }

  factory Discussion.fromJson(Map<String, dynamic> json) {
    var pointsListFromJson = json['points'] as List<dynamic>?;
    List<Point> pointsList = pointsListFromJson != null
        ? pointsListFromJson.map((p) => Point.fromJson(p)).toList()
        : [];

    return Discussion(
      discussion: json['discussion'] ?? 'Tidak ada diskusi',
      date: json['date'],
      repetitionCode: json['repetition_code'] ?? '',
      points: pointsList,
      finished: json['finished'] ?? false,
      finish_date: json['finish_date'],
      filePath: json['filePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussion': discussion,
      'date': date,
      'repetition_code': repetitionCode,
      'points': points.map((p) => p.toJson()).toList(),
      'finished': finished,
      'finish_date': finish_date,
      'filePath': filePath,
    };
  }
}
