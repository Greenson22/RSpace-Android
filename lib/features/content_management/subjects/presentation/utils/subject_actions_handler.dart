// lib/features/content_management/presentation/subjects/utils/subject_actions_handler.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/subject_dialogs.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/move_subject_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/generate_index_template_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/generate_index_prompt_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/subject_password_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/view_json_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/export_subject_dialog.dart';
import 'package:my_aplication/features/content_management/subjects/presentation/dialogs/export_bulk_subjects_dialog.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/subjects/providers/subject_provider.dart';
import 'package:my_aplication/features/content_management/discussions/providers/discussion_provider.dart';
import 'package:my_aplication/features/content_management/discussions/presentation/discussions_page.dart';
import 'package:my_aplication/features/content_management/timeline/presentation/discussion_timeline_page.dart';
import 'package:my_aplication/features/html_editor/presentation/pages/html_editor_page.dart';

class SubjectActionsHandler {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  static Future<void> importSubjectsZip(BuildContext context) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final message = await provider.importBulkSubjectsZip();
    if (message != null && context.mounted) {
      showSnackBar(
        context,
        message,
        isError:
            message.toLowerCase().contains('gagal') ||
            message.toLowerCase().contains('error'),
      );
    }
  }

  static Future<void> exportSelectedSubjects(
    BuildContext context,
    String topicName,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final hasLinkedPath = provider.selectedSubjects.any(
      (s) => s.linkedPath != null && s.linkedPath!.isNotEmpty,
    );
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => ExportBulkSubjectsDialog(
        count: provider.selectedSubjects.length,
        topicName: topicName,
        hasAnyLinkedPath: hasLinkedPath,
      ),
    );
    if (result != null && result is Map<String, dynamic> && context.mounted) {
      try {
        final message = await provider.exportBulkSubjectsZip(
          result['fileName'],
          result['includePerpus'],
        );
        if (message != null && context.mounted) {
          showSnackBar(context, message);
        }
      } catch (e) {
        if (context.mounted)
          showSnackBar(
            context,
            'Gagal mengekspor: ${e.toString()}',
            isError: true,
          );
      }
    }
  }

  static Future<void> exportSingleSubjectZip(
    BuildContext context,
    Subject subject,
  ) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => ExportSubjectDialog(subject: subject),
    );
    if (result != null && result is Map<String, dynamic> && context.mounted) {
      final provider = Provider.of<SubjectProvider>(context, listen: false);
      try {
        final message = await provider.exportSubjectZip(
          subject,
          result['fileName'],
          result['includePerpus'],
        );
        if (message != null && context.mounted) {
          showSnackBar(context, message);
        }
      } catch (e) {
        if (context.mounted)
          showSnackBar(context, 'Gagal ekspor: ${e.toString()}', isError: true);
      }
    }
  }

  static Future<void> showJsonContent(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final content = await provider.getRawJsonContent(subject);
    if (context.mounted) {
      showViewJsonDialog(context, subject.name, content);
    }
  }

  static Future<void> toggleLock(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    if (subject.isLocked) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(subject.name),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'unlock'),
              child: const ListTile(
                leading: Icon(Icons.lock_open),
                title: Text('Buka Kunci'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'remove'),
              child: const ListTile(
                leading: Icon(Icons.lock_reset),
                title: Text('Hapus Kunci Permanen'),
              ),
            ),
          ],
        ),
      );
      if (choice == 'unlock' && context.mounted) {
        final password = await showSubjectPasswordDialog(
          context: context,
          subjectName: subject.name,
          mode: PasswordDialogMode.enter,
        );
        if (password != null) {
          try {
            await provider.unlockSubject(subject.name, password);
          } catch (e) {
            if (context.mounted)
              showSnackBar(context, e.toString(), isError: true);
          }
        }
      } else if (choice == 'remove' && context.mounted) {
        final password = await showSubjectPasswordDialog(
          context: context,
          subjectName: subject.name,
          mode: PasswordDialogMode.remove,
        );
        if (password != null) {
          try {
            await provider.removeLock(subject.name, password);
            if (context.mounted)
              showSnackBar(
                context,
                'Kunci pada subject "${subject.name}" telah dihapus.',
              );
          } catch (e) {
            if (context.mounted)
              showSnackBar(context, e.toString(), isError: true);
          }
        }
      }
    } else {
      final password = await showSubjectPasswordDialog(
        context: context,
        subjectName: subject.name,
        mode: PasswordDialogMode.set,
      );
      if (password != null) {
        try {
          await provider.lockSubject(subject.name, password);
          if (context.mounted)
            showSnackBar(
              context,
              'Subject "${subject.name}" berhasil dikunci.',
            );
        } catch (e) {
          if (context.mounted)
            showSnackBar(context, e.toString(), isError: true);
        }
      }
    }
  }

  static Future<void> moveSubject(
    BuildContext context,
    Subject subject,
    String currentTopicName,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final destinationTopic = await showMoveSubjectDialog(
      context,
      currentTopicName,
    );
    if (destinationTopic != null && context.mounted) {
      try {
        await provider.moveSubject(subject, destinationTopic);
        if (context.mounted)
          showSnackBar(
            context,
            'Subject "${subject.name}" berhasil dipindahkan ke topik "${destinationTopic.name}".',
          );
      } catch (e) {
        if (context.mounted)
          showSnackBar(
            context,
            'Gagal memindahkan: ${e.toString()}',
            isError: true,
          );
      }
    }
  }

  static Future<void> linkSubject(BuildContext context, Subject subject) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final newPath = await showLinkOrCreatePerpuskuDialog(
      context: context,
      forSubjectName: subject.name,
    );
    if (newPath != null) {
      try {
        await provider.updateSubjectLinkedPath(subject.name, newPath);
        if (context.mounted)
          showSnackBar(
            context,
            'Subject "${subject.name}" berhasil ditautkan.',
          );
      } catch (e) {
        if (context.mounted)
          showSnackBar(
            context,
            'Gagal menautkan subject: ${e.toString()}',
            isError: true,
          );
      }
    }
  }

  static Future<void> addSubject(BuildContext context) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showSubjectTextInputDialog(
      context: context,
      title: 'Tambah Subject Baru',
      label: 'Nama Subject di RSpace',
      onSave: (name, icon) async {
        // DIUBAH: Mengambil argument name dan icon
        final newPath = await showLinkOrCreatePerpuskuDialog(
          context: context,
          forSubjectName: name,
        );
        if (newPath != null) {
          try {
            await provider.addSubject(name);
            await provider.updateSubjectLinkedPath(name, newPath);
            if (context.mounted) {
              showSnackBar(
                context,
                'Subject "$name" berhasil ditambahkan dan ditautkan.',
              );
            }
          } catch (e) {
            if (context.mounted) {
              showSnackBar(context, e.toString(), isError: true);
            }
          }
        }
      },
    );
  }

  // DIUBAH: Menyesuaikan callback dialog kombinasi Nama & Ikon yang baru
  static Future<void> renameSubject(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await showSubjectTextInputDialog(
      context: context,
      title: 'Ubah Subject',
      label: 'Nama Baru',
      initialValue: subject.name,
      initialIcon: subject.icon,
      onSave: (newName, newIcon) async {
        try {
          await provider.renameSubject(subject.name, newName);
          if (context.mounted)
            showSnackBar(context, 'Subject berhasil diubah.');
        } catch (e) {
          if (context.mounted)
            showSnackBar(context, e.toString(), isError: true);
        }
      },
    );
  }

  static Future<void> deleteSubject(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final result = await showDeleteConfirmationDialog(
      context: context,
      subjectName: subject.name,
      linkedPath: subject.linkedPath,
    );
    if (result != null && result['confirmed'] == true) {
      try {
        await provider.deleteSubject(
          subject.name,
          deleteLinkedFolder: result['deleteFolder'] ?? false,
        );
        if (context.mounted)
          showSnackBar(context, 'Subject "${subject.name}" berhasil dihapus.');
      } catch (e) {
        if (context.mounted) showSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  static Future<void> toggleVisibility(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final newVisibility = !subject.isHidden;
    try {
      await provider.toggleSubjectVisibility(subject.name, newVisibility);
      final message = newVisibility ? 'disembunyikan' : 'ditampilkan kembali';
      if (context.mounted)
        showSnackBar(context, 'Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      if (context.mounted) showSnackBar(context, e.toString(), isError: true);
    }
  }

  static Future<void> toggleFreeze(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    try {
      await provider.toggleSubjectFreeze(subject.name);
      final message = subject.isFrozen ? 'diaktifkan kembali' : 'dibekukan';
      if (context.mounted)
        showSnackBar(context, 'Subject "${subject.name}" berhasil $message.');
    } catch (e) {
      if (context.mounted) showSnackBar(context, e.toString(), isError: true);
    }
  }

  static Future<void> showEditIndexOptions(
    BuildContext context,
    Subject subject,
  ) async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    Future<void> openInternalEditor() async {
      try {
        final content = await provider.readIndexFileContent(subject);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HtmlEditorPage(
                pageTitle: 'Template: ${subject.name}',
                initialContent: content,
                onSave: (newContent) =>
                    provider.saveIndexFileContent(subject, newContent),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted)
          showSnackBar(
            context,
            'Gagal memuat konten: ${e.toString()}',
            isError: true,
          );
      }
    }

    Future<void> openExternalEditor() async {
      try {
        await provider.editSubjectIndexFile(subject);
      } catch (e) {
        if (context.mounted)
          showSnackBar(
            context,
            'Gagal membuka file: ${e.toString()}',
            isError: true,
          );
      }
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Metode Edit Template'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ai_direct'),
            child: const ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Generate dengan AI (Otomatis)'),
              subtitle: Text('Buat & simpan template baru berdasarkan tema.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'ai_prompt'),
            child: const ListTile(
              leading: Icon(Icons.copy_all_outlined),
              title: Text('Generate Prompt (Manual)'),
              subtitle: Text('Buat prompt untuk digunakan di Gemini Web.'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final subChoice = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pilih Editor'),
                  content: const Text(
                    'Buka dengan editor internal atau aplikasi eksternal?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'internal'),
                      child: const Text('Internal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'external'),
                      child: const Text('Eksternal'),
                    ),
                  ],
                ),
              );
              if (subChoice == 'internal') {
                await openInternalEditor();
              } else if (subChoice == 'external') {
                await openExternalEditor();
              }
            },
            child: const ListTile(
              leading: Icon(Icons.edit_document),
              title: Text('Edit Manual'),
              subtitle: Text('Buka file index.html di editor.'),
            ),
          ),
        ],
      ),
    );

    if (choice == 'ai_direct' && context.mounted) {
      final success = await showDialog<bool>(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: GenerateIndexTemplateDialog(subject: subject),
        ),
      );
      if (success == true && context.mounted) {
        showSnackBar(context, 'Template baru berhasil dibuat oleh AI!');
      }
    } else if (choice == 'ai_prompt' && context.mounted) {
      await showGenerateIndexPromptDialog(context, subject);
    }
  }

  static Future<void> navigateToDiscussionsPage(
    BuildContext context,
    Subject subject,
  ) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    if (subject.isLocked && !subjectProvider.isUnlocked(subject.name)) {
      final password = await showSubjectPasswordDialog(
        context: context,
        subjectName: subject.name,
        mode: PasswordDialogMode.enter,
      );
      if (password == null) return;
      try {
        await subjectProvider.unlockSubject(subject.name, password);
        final unlockedSubject = subjectProvider.allSubjects.firstWhere(
          (s) => s.name == subject.name,
        );
        if (context.mounted) _navigate(context, unlockedSubject);
      } catch (e) {
        if (context.mounted) showSnackBar(context, e.toString(), isError: true);
        return;
      }
    } else {
      _navigate(context, subject);
    }
  }

  static Future<void> _navigate(BuildContext context, Subject subject) async {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    if (subject.isFrozen) {
      showSnackBar(
        context,
        'Subject ini sedang dibekukan dan tidak bisa dibuka.',
      );
      return;
    }
    String? currentLinkedPath = subject.linkedPath;
    if (currentLinkedPath == null || currentLinkedPath.isEmpty) {
      final newPath = await showLinkOrCreatePerpuskuDialog(
        context: context,
        forSubjectName: subject.name,
      );
      if (!context.mounted) return;
      if (newPath != null) {
        try {
          await subjectProvider.updateSubjectLinkedPath(subject.name, newPath);
          currentLinkedPath = newPath;
        } catch (e) {
          showSnackBar(
            context,
            'Gagal menautkan subject: ${e.toString()}',
            isError: true,
          );
          return;
        }
      } else {
        return;
      }
    }
    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (newContext) => ChangeNotifierProvider(
          create: (_) => DiscussionProvider(
            jsonFilePath,
            linkedPath: currentLinkedPath,
            subject: subject,
          ),
          child: DiscussionsPage(
            subjectName: subject.name,
            linkedPath: currentLinkedPath,
          ),
        ),
      ),
    ).then((_) {
      if (context.mounted) subjectProvider.fetchSubjects();
    });
  }

  static void navigateToTimelinePage(BuildContext context, Subject subject) {
    if (subject.isLocked &&
        !Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).isUnlocked(subject.name)) {
      showSnackBar(
        context,
        'Buka kunci subjek terlebih dahulu untuk melihat linimasa.',
      );
      return;
    }
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    final jsonFilePath = path.join(
      subjectProvider.topicPath,
      '${subject.name}.json',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: subjectProvider,
          child: DiscussionTimelinePage(
            subjectName: subject.name,
            discussions: subject.discussions,
            subjectJsonPath: jsonFilePath,
          ),
        ),
      ),
    ).then((_) {
      subjectProvider.fetchSubjects();
    });
  }
}
