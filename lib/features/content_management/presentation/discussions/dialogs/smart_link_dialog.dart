// lib/features/content_management/presentation/discussions/dialogs/smart_link_dialog.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';

enum SearchMode { cerdas, gemini }

// DIUBAH: Membuat kelas representasi lokal sementara karena LinkSuggestion model dihapus
class LocalLinkSuggestion {
  final String title;
  final String relativePath;
  final double score;

  LocalLinkSuggestion({
    required this.title,
    required this.relativePath,
    required this.score,
  });
}

class SmartLinkDialog extends StatefulWidget {
  final Discussion discussion;
  final String topicName;
  final String subjectName;

  const SmartLinkDialog({
    super.key,
    required this.discussion,
    required this.topicName,
    required this.subjectName,
  });

  @override
  State<SmartLinkDialog> createState() => _SmartLinkDialogState();
}

class _SmartLinkDialogState extends State<SmartLinkDialog> {
  SearchMode _searchMode = SearchMode.cerdas;
  Future<List<LocalLinkSuggestion>>?
  _suggestionsFuture; // DIUBAH: Menggunakan kelas lokal

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  void _fetchSuggestions() {
    if (_searchMode == SearchMode.cerdas) {
      setState(() {
        _suggestionsFuture = _fetchMockSuggestions();
      });
    } else {
      setState(() {
        _suggestionsFuture = _fetchMockGeminiSuggestions();
      });
    }
  }

  // DIUBAH: Fallback generator pengganti SmartLinkService
  Future<List<LocalLinkSuggestion>> _fetchMockSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulasi loading
    return [
      LocalLinkSuggestion(
        title: 'Dokumen Inti ${widget.topicName}',
        relativePath: 'topics/${widget.subjectName.toLowerCase()}/index.html',
        score: 1.0,
      ),
      LocalLinkSuggestion(
        title: 'Catatan Tambahan Pembahasan',
        relativePath: 'topics/${widget.subjectName.toLowerCase()}/note.md',
        score: 0.75,
      ),
    ];
  }

  // DIUBAH: Fallback generator pengganti GeminiService
  Future<List<LocalLinkSuggestion>> _fetchMockGeminiSuggestions() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading AI
    return [
      LocalLinkSuggestion(
        title: '[AI] Analisis Terkait ${widget.discussion.discussion}',
        relativePath: 'topics/ai_generated_preview.html',
        score: 1.0,
      ),
    ];
  }

  void _onSuggestionSelected(String relativePath) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    provider.updateDiscussionFilePath(widget.discussion, relativePath);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber),
          SizedBox(width: 8),
          Text('Saran Tautan Cerdas'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            SegmentedButton<SearchMode>(
              segments: const [
                ButtonSegment(
                  value: SearchMode.cerdas,
                  label: Text('Cerdas'),
                  icon: Icon(Icons.psychology_alt),
                ),
                ButtonSegment(
                  value: SearchMode.gemini,
                  label: Text('AI (Gemini)'),
                  icon: Icon(Icons.auto_awesome),
                  enabled:
                      false, // DIUBAH: Dimatikan sementara karena service AI dihapus
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _searchMode = newSelection.first;
                  _fetchSuggestions();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<LocalLinkSuggestion>>(
                future: _suggestionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada saran yang cocok ditemukan.'),
                    );
                  }

                  final suggestions = snapshot.data!;
                  final maxScore = _searchMode == SearchMode.cerdas
                      ? suggestions.map((s) => s.score).reduce(max)
                      : 1.0;

                  return ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      final percentage = maxScore > 0
                          ? (suggestion.score / maxScore) * 100
                          : 0;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            _searchMode == SearchMode.gemini
                                ? 'AI'
                                : '${percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        title: Text(suggestion.title),
                        subtitle: Text(
                          suggestion.relativePath,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () =>
                            _onSuggestionSelected(suggestion.relativePath),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
