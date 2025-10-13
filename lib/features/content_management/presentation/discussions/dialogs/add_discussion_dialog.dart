// lib/features/content_management/presentation/discussions/dialogs/add_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';

class AddDiscussionResult {
  final String name;
  final DiscussionLinkType linkType;
  final String? linkData;

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
                title: const Text("Simpan Tautan (Bookmark)"),
                subtitle: const Text(
                  "Membuka alamat URL di browser.",
                  style: TextStyle(fontSize: 12),
                ),
                value: DiscussionLinkType.link,
                groupValue: _linkType,
                onChanged: (value) => setState(() => _linkType = value!),
              ),
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
              String? linkData;
              if (_linkType == DiscussionLinkType.html) {
                linkData = canCreateHtmlOrQuizV2 ? 'create_new' : null;
              } else if (_linkType == DiscussionLinkType.link) {
                linkData = _urlController.text.trim();
              } else if (_linkType == DiscussionLinkType.perpuskuQuiz) {
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
}
