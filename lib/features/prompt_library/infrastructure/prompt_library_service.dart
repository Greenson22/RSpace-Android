// lib/features/prompt_library/infrastructure/prompt_library_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../core/services/path_service.dart';
import '../domain/models/prompt_concept_model.dart';

class PromptLibraryService {
  final PathService _pathService = PathService();

  Future<Directory> _getLibraryDirectory() async {
    final libraryPath = await _pathService.promptLibraryPath;
    final directory = Directory(libraryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> createCategory(String categoryName) async {
    final libraryDir = await _getLibraryDirectory();
    final newCategoryDir = Directory(path.join(libraryDir.path, categoryName));

    if (await newCategoryDir.exists()) {
      throw Exception('Kategori dengan nama "$categoryName" sudah ada.');
    }
    try {
      await newCategoryDir.create();
    } catch (e) {
      throw Exception('Gagal membuat kategori: $e');
    }
  }

  Future<List<String>> getCategories({bool includeHidden = false}) async {
    final libraryDir = await _getLibraryDirectory();
    final entities = libraryDir.listSync();

    return entities
        .whereType<Directory>()
        .map((dir) => path.basename(dir.path))
        .where((name) {
          if (includeHidden) return true;
          return !name.startsWith('.');
        })
        .toList()
      ..sort();
  }

  Future<void> renameCategory(String oldName, String newName) async {
    final libraryDir = await _getLibraryDirectory();
    final oldDir = Directory(path.join(libraryDir.path, oldName));
    final newDir = Directory(path.join(libraryDir.path, newName));

    if (!await oldDir.exists()) {
      throw Exception('Kategori asal tidak ditemukan.');
    }
    if (await newDir.exists()) {
      throw Exception('Kategori dengan nama "$newName" sudah ada.');
    }

    try {
      await oldDir.rename(newDir.path);
    } catch (e) {
      throw Exception('Gagal mengubah nama kategori: $e');
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    final libraryDir = await _getLibraryDirectory();
    final categoryDir = Directory(path.join(libraryDir.path, categoryName));

    if (await categoryDir.exists()) {
      try {
        await categoryDir.delete(recursive: true);
      } catch (e) {
        throw Exception('Gagal menghapus kategori: $e');
      }
    }
  }

  // --- BARU: Ikon Kategori ---

  Future<String?> getCategoryIcon(String category) async {
    try {
      final libraryDir = await _getLibraryDirectory();
      final metaFile = File(
        path.join(libraryDir.path, category, 'metadata.json'),
      );
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return json['icon'] as String?;
      }
    } catch (e) {
      debugPrint('Error reading category icon: $e');
    }
    return null;
  }

  Future<void> saveCategoryIcon(String category, String icon) async {
    try {
      final libraryDir = await _getLibraryDirectory();
      final metaFile = File(
        path.join(libraryDir.path, category, 'metadata.json'),
      );

      Map<String, dynamic> data = {};
      if (await metaFile.exists()) {
        try {
          data = jsonDecode(await metaFile.readAsString());
        } catch (_) {
          // Ignore error, start with empty map
        }
      }

      data['icon'] = icon;
      await metaFile.writeAsString(jsonEncode(data));
    } catch (e) {
      throw Exception('Gagal menyimpan ikon kategori: $e');
    }
  }

  // ---------------------------

  Future<List<PromptConcept>> getPromptsInCategory(String category) async {
    final libraryDir = await _getLibraryDirectory();
    final categoryDir = Directory(path.join(libraryDir.path, category));
    if (!await categoryDir.exists()) return [];

    final files = categoryDir.listSync().whereType<File>().where(
      (file) => file.path.endsWith('.json'),
    );

    final List<PromptConcept> prompts = [];
    for (final file in files) {
      final prompt = await readPromptConcept(
        category,
        path.basename(file.path),
      );
      if (prompt != null) {
        prompts.add(prompt);
      }
    }
    return prompts..sort((a, b) => a.title.compareTo(b.title));
  }

  Future<PromptConcept?> readPromptConcept(
    String category,
    String fileName,
  ) async {
    try {
      final libraryDir = await _getLibraryDirectory();
      final file = File(path.join(libraryDir.path, category, fileName));
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return PromptConcept.fromJson(jsonData, fileName);
      }
    } catch (e) {
      debugPrint('Error reading prompt concept: $e');
    }
    return null;
  }

  Future<void> savePromptConcept(
    String category,
    String fileName,
    PromptConcept prompt,
  ) async {
    final libraryDir = await _getLibraryDirectory();
    final categoryDir = Directory(path.join(libraryDir.path, category));
    if (!await categoryDir.exists()) {
      await categoryDir.create();
    }
    final file = File(path.join(categoryDir.path, fileName));
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(prompt.toJson()));
  }

  Future<void> deletePrompt(String category, String fileName) async {
    try {
      final libraryDir = await _getLibraryDirectory();
      final file = File(path.join(libraryDir.path, category, fileName));

      if (await file.exists()) {
        await file.delete();
      } else {
        debugPrint('File prompt tidak ditemukan saat ingin dihapus: $fileName');
      }
    } catch (e) {
      throw Exception('Gagal menghapus prompt: $e');
    }
  }
}
