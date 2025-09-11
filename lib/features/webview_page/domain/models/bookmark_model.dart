// lib/features/webview_page/domain/models/bookmark_model.dart
import 'package:uuid/uuid.dart';

class Bookmark {
  final String id;
  final String title;
  final String url;

  Bookmark({String? id, required this.title, required this.url})
    : id = id ?? const Uuid().v4();

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'url': url};
  }
}
