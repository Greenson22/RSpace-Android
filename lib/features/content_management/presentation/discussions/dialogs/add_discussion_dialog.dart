// lib/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/perpusku/presentation/dialogs/perpusku_quiz_picker_dialog.dart';

class AddDiscussionResult {
  final String name;
  final DiscussionLinkType linkType;
  final dynamic linkData;

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
      return _AddDiscussionDialogContent(
        title: title,
        label: label,
        subjectLinkedPath: subjectLinkedPath,
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
  PerpuskuQuizPickerResult? _selectedQuiz;

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

    if (!canCreateHtmlOrQuizV2 && _linkType == DiscussionLinkType.html) {
      _linkType = DiscussionLinkType.none;
    }

    if (_linkType != DiscussionLinkType.perpuskuQuiz && _selectedQuiz != null) {
      _selectedQuiz = null;
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
                // ==> IKON DITAMBAHKAN <==
                secondary: const Icon(Icons.notes_outlined),
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
                // ==> IKON DITAMBAHKAN <==
                secondary: const Icon(Icons.description_outlined),
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
                // ==> IKON DITAMBAHKAN <==
                secondary: const Icon(Icons.quiz_outlined),
                title: const Text("Kuis Perpusku"),
                subtitle: const Text(
                  "Tautkan ke kuis yang sudah ada di Perpusku.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.perpuskuQuiz,
                groupValue: _linkType,
                onChanged: (value) => setState(() => _linkType = value!),
              ),
              RadioListTile<DiscussionLinkType>(
                // ==> IKON DITAMBAHKAN <==
                secondary: const Icon(Icons.link),
                title: const Text("Simpan Tautan (Bookmark)"),
                subtitle: const Text(
                  "Membuka alamat URL di browser.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.link,
                groupValue: _linkType,
                onChanged: (value) => setState(() => _linkType = value!),
              ),
              if (_linkType == DiscussionLinkType.perpuskuQuiz) ...[
                const Divider(),
                ListTile(
                  title: const Text('Kuis yang Dipilih:'),
                  subtitle: Text(
                    _selectedQuiz == null
                        ? 'Belum ada kuis yang dipilih'
                        : '${_selectedQuiz!.quizName}\n(dari: ${_selectedQuiz!.subjectPath})',
                  ),
                  trailing: ElevatedButton(
                    child: const Text('Pilih...'),
                    onPressed: () async {
                      final result = await showPerpuskuQuizPickerDialog(
                        context,
                      );
                      if (result != null) {
                        setState(() {
                          _selectedQuiz = result;
                        });
                      }
                    },
                  ),
                ),
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
              if (_linkType == DiscussionLinkType.perpuskuQuiz &&
                  _selectedQuiz == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan pilih kuis Perpusku terlebih dahulu.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              dynamic linkData;
              if (_linkType == DiscussionLinkType.html) {
                linkData = canCreateHtmlOrQuizV2 ? 'create_new' : null;
              } else if (_linkType == DiscussionLinkType.link) {
                linkData = _urlController.text.trim();
              } else if (_linkType == DiscussionLinkType.perpuskuQuiz) {
                linkData = _selectedQuiz;
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
}
