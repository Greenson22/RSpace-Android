// lib/features/content_management/domain/models/discussion_model.dart
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'package:url_launcher/url_launcher.dart';

// ==> PERBAIKAN: Menambahkan 'markdown' ke enum <==
enum DiscussionLinkType { html, none, link, perpuskuQuiz, markdown }

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

  DiscussionLinkType linkType;
  final String? url;
  String? quizName;

  // ==> BARU: Field untuk Highlight <==
  int? highlightColor; // Menyimpan warna sebagai int (0xAARRGGBB)
  String? highlightLabel; // Label keterangan highlight

  Discussion({
    required this.discussion,
    this.date,
    required this.repetitionCode,
    required this.points,
    this.finished = false,
    this.finish_date,
    this.filePath,
    this.archivedHtmlContent,
    this.linkType = DiscussionLinkType.html,
    this.url,
    this.quizName,
    this.highlightColor,
    this.highlightLabel,
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

    int linkTypeIndex = json['linkType'] as int? ?? 0;
    if (linkTypeIndex >= DiscussionLinkType.values.length) {
      linkTypeIndex = DiscussionLinkType.none.index;
    }

    return Discussion(
      discussion: json['discussion'] ?? 'Tidak ada diskusi',
      date: json['date'],
      repetitionCode: json['repetition_code'] ?? '',
      points: pointsList,
      finished: json['finished'] ?? false,
      finish_date: json['finish_date'],
      filePath: json['filePath'],
      linkType: DiscussionLinkType.values[linkTypeIndex],
      url: json['url'] as String?,
      quizName: json['quizName'] as String?,
      highlightColor: json['highlight_color'],
      highlightLabel: json['highlight_label'],
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
      'linkType': linkType.index,
      'url': url,
      'quizName': quizName,
      'highlight_color': highlightColor,
      'highlight_label': highlightLabel,
    };
  }
}
