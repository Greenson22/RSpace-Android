// lib/presentation/pages/3_discussions_page/dialogs/smart_link_dialog.dart

import 'dart:math'; // Import for max function
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../../data/models/link_suggestion_model.dart';
import '../../../../data/services/smart_link_service.dart';
import '../../../providers/discussion_provider.dart';

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
  late Future<List<LinkSuggestion>> _suggestionsFuture;
  final SmartLinkService _smartLinkService = SmartLinkService();

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _smartLinkService.findSuggestions(
      discussion: widget.discussion,
      topicName: widget.topicName,
      subjectName: widget.subjectName,
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
        height: 300,
        child: FutureBuilder<List<LinkSuggestion>>(
          future: _suggestionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Tidak ada saran yang cocok ditemukan.'),
              );
            }

            final suggestions = snapshot.data!;
            // ==> PERUBAHAN DIMULAI DI SINI <==

            // 1. Cari skor tertinggi dari semua saran.
            // Gunakan import 'dart:math'; jika belum ada.
            final maxScore = suggestions.map((s) => s.score).reduce(max);

            return ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];

                // 2. Hitung persentase relevansi.
                final percentage = maxScore > 0
                    ? (suggestion.score / maxScore) * 100
                    : 0;

                return ListTile(
                  // 3. Tampilkan persentase di CircleAvatar.
                  leading: CircleAvatar(
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  title: Text(suggestion.title),
                  subtitle: Text(
                    suggestion.relativePath,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _onSuggestionSelected(suggestion.relativePath),
                );
              },
            );
            // ==> PERUBAHAN SELESAI DI SINI <==
          },
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
