// lib/features/prompt_library/infrastructure/prompt_library_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../../core/services/dua/path_service.dart';
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

  Future<List<String>> getCategories() async {
    final libraryDir = await _getLibraryDirectory();
    final entities = libraryDir.listSync();
    return entities
        .whereType<Directory>()
        .map((dir) => path.basename(dir.path))
        .toList()
      ..sort();
  }

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
    return prompts..sort((a, b) => a.judulUtama.compareTo(b.judulUtama));
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
}
