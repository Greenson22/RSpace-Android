// lib/presentation/pages/3_discussions_page/dialogs/smart_link_dialog.dart

import 'dart:math'; // Import for max function
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../../data/models/link_suggestion_model.dart';
import '../../../../data/services/gemini_service.dart'; // ==> IMPORT GEMINI SERVICE
import '../../../../data/services/smart_link_service.dart';
import '../../../providers/discussion_provider.dart';

// ==> TAMBAHKAN ENUM UNTUK MODE PENCARIAN
enum SearchMode { cerdas, gemini }

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
  // ==> TAMBAHKAN STATE UNTUK MENGELOLA UI
  SearchMode _searchMode = SearchMode.cerdas;
  Future<List<LinkSuggestion>>? _suggestionsFuture;
  final SmartLinkService _smartLinkService = SmartLinkService();
  // ==> BUAT INSTANCE GEMINI SERVICE
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    // ==> PANGGIL FUNGSI UNTUK MEMUAT DATA AWAL
    _fetchSuggestions();
  }

  // ==> BUAT FUNGSI UNTUK MEMUAT SUGGESTIONS BERDASARKAN MODE
  void _fetchSuggestions() {
    if (_searchMode == SearchMode.cerdas) {
      setState(() {
        _suggestionsFuture = _smartLinkService.findSuggestions(
          discussion: widget.discussion,
          topicName: widget.topicName,
          subjectName: widget.subjectName,
        );
      });
    } else {
      setState(() {
        // Panggil metode baru untuk mendapatkan suggestions dari Gemini
        _suggestionsFuture = _fetchGeminiSuggestions();
      });
    }
  }

  // ==> BUAT FUNGSI HELPER UNTUK MEMANGGIL GEMINI SERVICE
  Future<List<LinkSuggestion>> _fetchGeminiSuggestions() async {
    // Dapatkan daftar semua file sebagai konteks
    final allFiles = await _smartLinkService.getAllPerpuskuFiles();
    if (!mounted) return [];
    // Panggil Gemini untuk mendapatkan hasil
    return await _geminiService.findSmartLinks(
      discussion: widget.discussion,
      allFiles: allFiles,
    );
  }

  void _onSuggestionSelected(String relativePath) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    provider.updateDiscussionFilePath(widget.discussion, relativePath);
    Navigator.of(context).pop(true); // Kirim sinyal sukses
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
        height: 350, // Perbesar sedikit untuk tombol
        child: Column(
          children: [
            // ==> TAMBAHKAN TOMBOL UNTUK MEMILIH MODE
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
                ),
              ],
              selected: {_searchMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _searchMode = newSelection.first;
                  _fetchSuggestions(); // Muat ulang data saat mode berubah
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<LinkSuggestion>>(
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
                            // Tampilkan 'AI' jika mode gemini
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
