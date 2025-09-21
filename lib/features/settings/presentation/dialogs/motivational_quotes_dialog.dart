// lib/features/settings/presentation/dialogs/motivational_quotes_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service.dart';

// Fungsi untuk menampilkan dialog
void showMotivationalQuotesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const MotivationalQuotesDialog(),
  );
}

class MotivationalQuotesDialog extends StatefulWidget {
  const MotivationalQuotesDialog({super.key});

  @override
  State<MotivationalQuotesDialog> createState() =>
      _MotivationalQuotesDialogState();
}

class _MotivationalQuotesDialogState extends State<MotivationalQuotesDialog> {
  final GeminiService _geminiService = GeminiService();
  late Future<List<String>> _quotesFuture;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _quotesFuture = _geminiService.getSavedMotivationalQuotes();
  }

  void _refreshQuotes() {
    setState(() {
      _quotesFuture = _geminiService.getSavedMotivationalQuotes();
    });
  }

  Future<void> _generateNewQuotes() async {
    setState(() => _isGenerating = true);
    try {
      await _geminiService.generateAndSaveMotivationalQuotes(count: 10);
      _refreshQuotes();
      if (mounted) {
        showAppSnackBar(context, '10 kutipan motivasi baru berhasil dibuat!');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Gagal membuat kutipan: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _deleteQuote(String quote) async {
    await _geminiService.deleteMotivationalQuote(quote);
    _refreshQuotes();
    if (mounted) {
      showAppSnackBar(context, 'Kutipan dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kata Motivasi'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ini adalah daftar kata-kata motivasi yang akan ditampilkan secara acak di Dashboard.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _quotesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Belum ada kutipan. Coba buat dengan AI.'),
                    );
                  }
                  final quotes = snapshot.data!;
                  return ListView.builder(
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return Card(
                        child: ListTile(
                          title: Text('"$quote"'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteQuote(quote),
                          ),
                        ),
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
        _isGenerating
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Buat Daftar Baru (AI)'),
                onPressed: _generateNewQuotes,
              ),
      ],
    );
  }
}
