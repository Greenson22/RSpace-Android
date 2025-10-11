// lib/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/quiz/application/quiz_category_provider.dart';
import 'package:provider/provider.dart';
// import 'perpusku:quiz_picker_dialog.dart';

class AddDiscussionResult {
  final String name;
  final DiscussionLinkType linkType;
  final String?
  linkData; // Berisi 'create_new' (HTML), 'create_new_quiz' (Kuis v2), quiz topic path (Kuis v1), URL (Link), atau null (None)

  AddDiscussionResult({
    required this.name,
    required this.linkType,
    this.linkData,
  });
}

Future<AddDiscussionResult?> showAddDiscussionDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String? subjectLinkedPath,
}) async {
  return showDialog<AddDiscussionResult>(
    context: context,
    builder: (context) {
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
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _urlController = TextEditingController();
  DiscussionLinkType _linkType = DiscussionLinkType.none;
  String? _selectedQuizTopicPath;

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreateHtmlOrQuizV2 =
        widget.subjectLinkedPath != null &&
        widget.subjectLinkedPath!.isNotEmpty;

    // Jika subjek tidak tertaut, reset pilihan ke 'none'
    if (!canCreateHtmlOrQuizV2 &&
        (_linkType == DiscussionLinkType.html ||
            _linkType == DiscussionLinkType.perpuskuQuiz)) {
      _linkType = DiscussionLinkType.none;
    }

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _linkType == DiscussionLinkType.link
                      ? 'Nama Tautan'
                      : widget.label,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              if (_linkType == DiscussionLinkType.link)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat URL',
                      hintText: 'https://contoh.com',
                    ),
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'URL tidak boleh kosong.';
                      }
                      final uri = Uri.tryParse(value.trim());
                      if (uri == null || !uri.isAbsolute) {
                        return 'Format URL tidak valid.';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Opsi Tautan:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioListTile<DiscussionLinkType>(
                title: const Text("Tanpa Tautan File"),
                subtitle: const Text(
                  "Hanya untuk catatan internal.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.none,
                groupValue: _linkType,
                onChanged: (value) => setState(() => _linkType = value!),
              ),
              RadioListTile<DiscussionLinkType>(
                title: const Text("File HTML Baru"),
                subtitle: Text(
                  canCreateHtmlOrQuizV2
                      ? "Membuat file .html baru di folder subjek."
                      : "Subjek ini tidak tertaut ke PerpusKu.",
                  style: TextStyle(
                    fontSize: 12,
                    color: canCreateHtmlOrQuizV2 ? null : Colors.orange,
                  ),
                ),
                value: DiscussionLinkType.html,
                groupValue: _linkType,
                onChanged: canCreateHtmlOrQuizV2
                    ? (value) => setState(() => _linkType = value!)
                    : null,
              ),
              RadioListTile<DiscussionLinkType>(
                title: const Text("Kuis Perpusku (v2)"),
                subtitle: Text(
                  canCreateHtmlOrQuizV2
                      ? "Membuat file kuis .json baru di folder subjek."
                      : "Subjek ini tidak tertaut ke Perpusku.",
                  style: TextStyle(
                    fontSize: 12,
                    color: canCreateHtmlOrQuizV2 ? null : Colors.orange,
                  ),
                ),
                value: DiscussionLinkType.perpuskuQuiz,
                groupValue: _linkType,
                onChanged: canCreateHtmlOrQuizV2
                    ? (value) => setState(() => _linkType = value!)
                    : null,
              ),
              RadioListTile<DiscussionLinkType>(
                title: const Text("Topik Kuis (v1)"),
                subtitle: const Text(
                  "Membuka sesi kuis v1 saat diskusi diklik.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.quiz,
                groupValue: _linkType,
                onChanged: (value) => setState(() => _linkType = value!),
              ),
              RadioListTile<DiscussionLinkType>(
                title: const Text("Simpan Tautan (Bookmark)"),
                subtitle: const Text(
                  "Membuka alamat URL di browser.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.link,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_linkType == DiscussionLinkType.quiz &&
                  _selectedQuizTopicPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan pilih topik kuis v1 terlebih dahulu.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              String? linkData;
              if (_linkType == DiscussionLinkType.html) {
                linkData = canCreateHtmlOrQuizV2 ? 'create_new' : null;
              } else if (_linkType == DiscussionLinkType.quiz) {
                linkData = _selectedQuizTopicPath;
              } else if (_linkType == DiscussionLinkType.link) {
                linkData = _urlController.text.trim();
              } else if (_linkType == DiscussionLinkType.perpuskuQuiz) {
                // ==> KIRIM SINYAL UNTUK MEMBUAT KUIS BARU <==
                linkData = 'create_new_quiz';
              }

              Navigator.pop(
                context,
                AddDiscussionResult(
                  name: _controller.text,
                  linkType: _linkType,
                  linkData: linkData,
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

        final List<DropdownMenuItem<String>> items = provider.categories.expand(
          (category) {
            return category.topics.map((topic) {
              final path = '${category.name}/${topic.name}';
              return DropdownMenuItem<String>(
                value: path,
                child: Text('${category.name} > ${topic.name}'),
              );
            });
          },
        ).toList();

        return DropdownButtonFormField<String>(
          value: _selectedQuizTopicPath,
          hint: const Text('Pilih Topik Kuis v1...'),
          isExpanded: true,
          items: items,
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
