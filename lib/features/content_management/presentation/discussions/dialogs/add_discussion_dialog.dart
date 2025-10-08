// lib/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/quiz/application/quiz_category_provider.dart';
import 'package:provider/provider.dart';

class AddDiscussionResult {
  final String name;
  final DiscussionLinkType linkType;
  final String?
  linkData; // Berisi 'create_new' (HTML), quiz topic path (Kuis), URL (Link), atau null (None)

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
    final bool canCreateHtml =
        widget.subjectLinkedPath != null &&
        widget.subjectLinkedPath!.isNotEmpty;

    if (!canCreateHtml && _linkType == DiscussionLinkType.html) {
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
                    // ==> PERBAIKAN DI BLOK VALIDATOR INI <==
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
                    content: Text('Silakan pilih topik kuis terlebih dahulu.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              String? linkData;
              if (_linkType == DiscussionLinkType.html) {
                linkData = canCreateHtml ? 'create_new' : null;
              } else if (_linkType == DiscussionLinkType.quiz) {
                linkData = _selectedQuizTopicPath;
              } else if (_linkType == DiscussionLinkType.link) {
                linkData = _urlController.text.trim();
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
          hint: const Text('Pilih Topik Kuis...'),
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
