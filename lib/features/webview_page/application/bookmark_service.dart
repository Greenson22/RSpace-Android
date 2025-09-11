// lib/features/webview_page/application/bookmark_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/bookmark_model.dart';

class BookmarkService {
  final PathService _pathService = PathService();

  Future<File> get _file async {
    final filePath = await _pathService.bookmarksPath;
    return File(filePath);
  }

  Future<List<Bookmark>> loadBookmarks() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((item) => Bookmark.fromJson(item)).toList();
    } catch (e) {
      // Jika terjadi error, kembalikan list kosong
      return [];
    }
  }

  Future<void> saveBookmarks(List<Bookmark> bookmarks) async {
    final file = await _file;
    final listJson = bookmarks.map((item) => item.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(listJson));
  }
}
