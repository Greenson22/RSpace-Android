import 'dart:math';
import '../../presentation/pages/3_discussions_page/utils/repetition_code_utils.dart';

class Point {
  String pointText;
  String repetitionCode;
  String date;

  Point({
    required this.pointText,
    required this.repetitionCode,
    required this.date,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      pointText: json['point_text'] ?? 'Tidak ada teks poin',
      repetitionCode: json['repetition_code'] ?? '',
      date: json['date'] ?? 'No Date',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point_text': pointText,
      'repetition_code': repetitionCode,
      'date': date,
    };
  }
}

class Discussion {
  String discussion;
  String? date; // Diubah menjadi nullable
  String repetitionCode;
  List<Point> points;
  bool finished; // ==> FIELD BARU <==
  String? finish_date; // ==> FIELD BARU <==

  Discussion({
    required this.discussion,
    this.date,
    required this.repetitionCode,
    required this.points,
    this.finished = false, // Default value
    this.finish_date,
  });

  // ==> GETTER BARU UNTUK MENDAPATKAN POINT DENGAN KODE REPETISI TERKECIL <==
  Point? get _pointWithMinRepetitionCode {
    if (points.isEmpty) {
      return null;
    }
    // Mengurutkan poin berdasarkan indeks kode repetisinya
    final sortedPoints = List<Point>.from(points)
      ..sort(
        (a, b) => getRepetitionCodeIndex(
          a.repetitionCode,
        ).compareTo(getRepetitionCodeIndex(b.repetitionCode)),
      );
    return sortedPoints.first;
  }

  // ==> GETTER BARU UNTUK LOGIKA KODE REPETISI EFEKTIF <==
  String get effectiveRepetitionCode {
    if (finished) return 'Finish';
    return _pointWithMinRepetitionCode?.repetitionCode ?? repetitionCode;
  }

  // ==> GETTER BARU UNTUK LOGIKA TANGGAL EFEKTIF <==
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
      date: json['date'], // Bisa jadi null
      repetitionCode: json['repetition_code'] ?? '',
      points: pointsList,
      finished: json['finished'] ?? false, // ==> DITAMBAHKAN <==
      finish_date: json['finish_date'], // ==> DITAMBAHKAN <==
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussion': discussion,
      'date': date,
      'repetition_code': repetitionCode,
      'points': points.map((p) => p.toJson()).toList(),
      'finished': finished, // ==> DITAMBAHKAN <==
      'finish_date': finish_date, // ==> DITAMBAHKAN <==
    };
  }
}
