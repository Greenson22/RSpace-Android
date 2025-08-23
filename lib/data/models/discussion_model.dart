// lib/data/models/discussion_model.dart
import 'dart:math';
import '../../presentation/pages/3_discussions_page/utils/repetition_code_utils.dart';

class Point {
  String pointText;
  String repetitionCode;
  String date;
  // ==> FIELD BARU DITAMBAHKAN <==
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
      // ==> DITAMBAHKAN <==
      finished: json['finished'] ?? false,
      finish_date: json['finish_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point_text': pointText,
      'repetition_code': repetitionCode,
      'date': date,
      // ==> DITAMBAHKAN <==
      'finished': finished,
      'finish_date': finish_date,
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
  String? filePath; // ==> FIELD BARU

  Discussion({
    required this.discussion,
    this.date,
    required this.repetitionCode,
    required this.points,
    this.finished = false, // Default value
    this.finish_date,
    this.filePath, // ==> TAMBAHAN DI KONSTRUKTOR
  });

  // ###############################################################
  // ### GETTER DIPERBARUI DENGAN LOGIKA PRIORITAS YANG BENAR ###
  // ###############################################################
  Point? get _pointWithMinRepetitionCode {
    final activePoints = points.where((p) => !p.finished).toList();
    if (activePoints.isEmpty) {
      return null;
    }

    // Cek apakah ada poin aktif dengan kode selain 'R0D'
    final hasNonR0D = activePoints.any((p) => p.repetitionCode != 'R0D');

    // Tentukan poin mana yang akan dipertimbangkan berdasarkan keberadaan non-R0D
    List<Point> pointsToConsider = hasNonR0D
        ? activePoints.where((p) => p.repetitionCode != 'R0D').toList()
        : activePoints;

    if (pointsToConsider.isEmpty) {
      // Fallback jika semua poin aktif adalah R0D dan sudah terfilter (seharusnya tidak terjadi)
      pointsToConsider = activePoints;
    }

    // Urutkan poin yang dipertimbangkan berdasarkan:
    // 1. Indeks kode repetisinya (paling kecil diutamakan)
    // 2. Tanggalnya (paling awal diutamakan jika kodenya sama)
    pointsToConsider.sort((a, b) {
      int codeComparison = getRepetitionCodeIndex(
        a.repetitionCode,
      ).compareTo(getRepetitionCodeIndex(b.repetitionCode));
      if (codeComparison != 0) {
        return codeComparison;
      }
      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0; // Jika tanggal tidak valid, anggap sama
      }
    });

    return pointsToConsider.first;
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
      filePath: json['filePath'], // ==> DITAMBAHKAN
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
      'filePath': filePath, // ==> DITAMBAHKAN
    };
  }
}
