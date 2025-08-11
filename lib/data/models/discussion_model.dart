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
  String date;
  String repetitionCode;
  List<Point> points;

  Discussion({
    required this.discussion,
    required this.date,
    required this.repetitionCode,
    required this.points,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    var pointsListFromJson = json['points'] as List<dynamic>?;
    List<Point> pointsList = pointsListFromJson != null
        ? pointsListFromJson.map((p) => Point.fromJson(p)).toList()
        : [];

    return Discussion(
      discussion: json['discussion'] ?? 'Tidak ada diskusi',
      date: json['date'] ?? 'No Date',
      repetitionCode: json['repetition_code'] ?? '',
      points: pointsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussion': discussion,
      'date': date,
      'repetition_code': repetitionCode,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}
