// lib/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/quiz/application/quiz_category_provider.dart';
import 'package:provider/provider.dart';

// Tipe data untuk hasil dialog
class AddDiscussionResult {
  final String name;
  final DiscussionLinkType linkType;
  final String?
  linkData; // Berisi 'create_new' (HTML) atau quiz topic path (Kuis)

  AddDiscussionResult({
    required this.name,
    required this.linkType,
    this.linkData,
  });
}

// Fungsi utama untuk menampilkan dialog
Future<AddDiscussionResult?> showAddDiscussionDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String? subjectLinkedPath,
}) async {
  return showDialog<AddDiscussionResult>(
    context: context,
    builder: (context) {
      // Sediakan QuizCategoryProvider untuk dialog
      return ChangeNotifierProvider(
        create: (_) => QuizCategoryProvider(),
        child: _AddDiscussionDialogContent(
          title: title,
          label: label,
          subjectLinkedPath: subjectLinkedPath,
        ),
      );
    },
  );
}

// Widget stateful untuk konten dialog
class _AddDiscussionDialogContent extends StatefulWidget {
  final String title;
  final String label;
  final String? subjectLinkedPath;

  const _AddDiscussionDialogContent({
    required this.title,
    required this.label,
    this.subjectLinkedPath,
  });

  @override
  State<_AddDiscussionDialogContent> createState() =>
      _AddDiscussionDialogContentState();
}

class _AddDiscussionDialogContentState
    extends State<_AddDiscussionDialogContent> {
  final _controller = TextEditingController();
  DiscussionLinkType _linkType = DiscussionLinkType.html;
  String? _selectedQuizTopicPath;

  @override
  Widget build(BuildContext context) {
    final bool canCreateHtml =
        widget.subjectLinkedPath != null &&
        widget.subjectLinkedPath!.isNotEmpty;

    // Set default link type jika tidak bisa membuat HTML
    if (!canCreateHtml && _linkType == DiscussionLinkType.html) {
      _linkType = DiscussionLinkType.quiz;
    }

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(labelText: widget.label),
            ),
            const SizedBox(height: 24),
            Text('Tautkan ke:', style: Theme.of(context).textTheme.titleSmall),
            RadioListTile<DiscussionLinkType>(
              title: const Text("File HTML Baru"),
              subtitle: Text(
                canCreateHtml
                    ? "Membuat file .html baru di folder subjek."
                    : "Subjek ini tidak tertaut ke PerpusKu.",
                style: TextStyle(
                  fontSize: 12,
                  color: canCreateHtml ? null : Colors.orange,
                ),
              ),
              value: DiscussionLinkType.html,
              groupValue: _linkType,
              onChanged: canCreateHtml
                  ? (value) => setState(() => _linkType = value!)
                  : null,
            ),
            RadioListTile<DiscussionLinkType>(
              title: const Text("Topik Kuis"),
              subtitle: const Text(
                "Membuka sesi kuis saat diskusi diklik.",
                style: TextStyle(fontSize: 12),
              ),
              value: DiscussionLinkType.quiz,
              groupValue: _linkType,
              onChanged: (value) => setState(() => _linkType = value!),
            ),
            if (_linkType == DiscussionLinkType.quiz) ...[
              const Divider(),
              _buildQuizTopicSelector(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              if (_linkType == DiscussionLinkType.quiz &&
                  _selectedQuizTopicPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Silakan pilih topik kuis terlebih dahulu.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                AddDiscussionResult(
                  name: _controller.text,
                  linkType: _linkType,
                  linkData: _linkType == DiscussionLinkType.quiz
                      ? _selectedQuizTopicPath
                      : (canCreateHtml ? 'create_new' : null),
                ),
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildQuizTopicSelector() {
    return Consumer<QuizCategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // =================================================================
        // ==> PERBAIKAN UTAMA ADA DI SINI <==
        // Kita secara eksplisit mendeklarasikan tipe variabel `items`.
        final List<DropdownMenuItem<String>> items = provider.categories.expand(
          (category) {
            // Sekarang kita bisa langsung mengambil `topics` dari `category`
            return category.topics.map((topic) {
              final path = '${category.name}/${topic.name}';
              return DropdownMenuItem<String>(
                value: path,
                child: Text('${category.name} > ${topic.name}'),
              );
            });
          },
        ).toList();
        // =================================================================

        return DropdownButtonFormField<String>(
          value: _selectedQuizTopicPath,
          hint: const Text('Pilih Topik Kuis...'),
          isExpanded: true,
          items: items, // Sekarang `items` sudah memiliki tipe yang benar
          onChanged: (value) {
            setState(() {
              _selectedQuizTopicPath = value;
            });
          },
        );
      },
    );
  }
}
