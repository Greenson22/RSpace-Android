// lib/features/content_management/domain/models/discussion_model.dart
import '../../presentation/discussions/utils/repetition_code_utils.dart';

// BARU: Enum untuk tipe tautan diskusi
enum DiscussionLinkType { html, quiz }

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
  String? archivedHtmlContent;

  // ==> FIELD BARU DITAMBAHKAN
  final DiscussionLinkType linkType;
  final String? quizTopicPath; // Format: "CategoryName/TopicName"

  Discussion({
    required this.discussion,
    this.date,
    required this.repetitionCode,
    required this.points,
    this.finished = false,
    this.finish_date,
    this.filePath,
    this.archivedHtmlContent,
    // ==> TAMBAHAN DI KONSTRUKTOR
    this.linkType = DiscussionLinkType.html, // Default ke html
    this.quizTopicPath,
  });

  Point? get _pointWithMinRepetitionCode {
    final activePoints = points.where((p) => !p.finished).toList();
    if (activePoints.isEmpty) {
      return null;
    }
    activePoints.sort((a, b) {
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
      // ==> MEMBACA DATA BARU DARI JSON
      linkType: DiscussionLinkType.values[json['linkType'] as int? ?? 0],
      quizTopicPath: json['quizTopicPath'] as String?,
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
      // ==> MENYIMPAN DATA BARU KE JSON
      'linkType': linkType.index,
      'quizTopicPath': quizTopicPath,
    };
  }
}
