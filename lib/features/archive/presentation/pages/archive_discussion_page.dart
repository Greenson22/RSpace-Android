// lib/features/archive/presentation/pages/archive_discussion_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
import 'package:my_aplication/features/archive/application/archive_provider.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:provider/provider.dart';

class ArchiveDiscussionPage extends StatelessWidget {
  final Subject subject;
  const ArchiveDiscussionPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ArchiveProvider()
            ..fetchArchivedDiscussions(subject.topicName, subject.name),
      child: _ArchiveDiscussionView(subject: subject),
    );
  }
}

class _ArchiveDiscussionView extends StatelessWidget {
  final Subject subject;
  const _ArchiveDiscussionView({required this.subject});

  // ==> FUNGSI BARU UNTUK MENANGANI TAP DAN DIALOG LOADING <==
  Future<void> _handleDiscussionTap(
    BuildContext context,
    Discussion discussion,
  ) async {
    final provider = Provider.of<ArchiveProvider>(context, listen: false);

    // Tampilkan dialog loading yang tidak bisa ditutup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Mengunduh file..."),
            ],
          ),
        );
      },
    );

    try {
      // Panggil fungsi provider untuk mengunduh dan membuka file
      await provider.openArchivedHtmlFile(
        discussion,
        subject.topicName,
        subject.name,
      );

      // Tutup dialog loading jika berhasil
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // Tutup dialog loading jika terjadi error
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        // Tampilkan pesan error
        showAppSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ArchiveProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }
          if (provider.discussions.isEmpty) {
            return const Center(
              child: Text('Tidak ada diskusi di dalam arsip subjek ini.'),
            );
          }
          return ListView.builder(
            itemCount: provider.discussions.length,
            itemBuilder: (context, index) {
              final discussion = provider.discussions[index];
              final hasFile =
                  discussion.filePath != null &&
                  discussion.filePath!.isNotEmpty;
              return ListTile(
                leading: Icon(
                  hasFile ? Icons.link : Icons.link_off,
                  color: hasFile ? Theme.of(context).primaryColor : Colors.grey,
                ),
                title: Text(discussion.discussion),
                subtitle: Text('Selesai pada: ${discussion.finish_date}'),
                // ==> PERBARUI onTap UNTUK MEMANGGIL FUNGSI BARU <==
                onTap: hasFile
                    ? () => _handleDiscussionTap(context, discussion)
                    : null,
                enabled: hasFile,
              );
            },
          );
        },
      ),
    );
  }
}
