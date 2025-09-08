// lib/features/prompt_library/application/prompt_provider.dart
import 'package:flutter/material.dart';
import '../../../data/models/prompt_model.dart';
import '../../../data/services/shared_preferences_service.dart';

class PromptProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Prompt> _prompts = [];
  List<Prompt> get prompts => _prompts;

  PromptProvider() {
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    _isLoading = true;
    notifyListeners();
    _prompts = await _prefsService.loadPrompts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePrompts(List<Prompt> prompts) async {
    _prompts = prompts;
    await _prefsService.savePrompts(_prompts);
    notifyListeners();
  }
}
