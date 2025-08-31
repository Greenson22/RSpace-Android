// lib/presentation/pages/exported_discussions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/exported_discussions_provider.dart';

class ExportedDiscussionsPage extends StatelessWidget {
  const ExportedDiscussionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExportedDiscussionsProvider(),
      child: const _ExportedDiscussionsView(),
    );
  }
}

class _ExportedDiscussionsView extends StatelessWidget {
  const _ExportedDiscussionsView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExportedDiscussionsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arsip Diskusi Selesai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadExportedData(),
            tooltip: 'Muat Ulang Arsip',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadExportedData(),
        child: Builder(
          builder: (context) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (provider.exportedTopics.isEmpty) {
              return const Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'File "Export-Finished-Discussions.zip" tidak ditemukan atau kosong.\nSilakan lakukan ekspor terlebih dahulu.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final lastModified = provider.lastModified != null
                ? DateFormat('d MMM yyyy, HH:mm').format(provider.lastModified!)
                : 'N/A';

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Menampilkan data dari arsip yang terakhir diubah pada: $lastModified',
                  ),
                ),
                ...provider.exportedTopics.map((topic) {
                  return ExpansionTile(
                    key: PageStorageKey('topic_${topic.name}'),
                    title: Text(
                      topic.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    leading: const Icon(Icons.topic_outlined),
                    children: topic.subjects.map((subject) {
                      return ExpansionTile(
                        key: PageStorageKey(
                          'subject_${topic.name}_${subject.name}',
                        ),
                        title: Text(subject.name),
                        leading: const Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: Icon(Icons.class_outlined),
                        ),
                        children: subject.discussions.map((discussion) {
                          // >> BARU: Cek apakah ada konten HTML
                          final bool hasHtmlContent =
                              discussion.archivedHtmlContent != null;
                          return ListTile(
                            leading: Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              // >> BARU: Ganti ikon berdasarkan ketersediaan file
                              child: Icon(
                                hasHtmlContent ? Icons.link : Icons.link_off,
                                size: 20,
                                color: hasHtmlContent
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(discussion.discussion),
                            subtitle: Text(
                              'Selesai pada: ${discussion.finish_date ?? 'N/A'}',
                            ),
                            // >> BARU: Tambahkan aksi onTap
                            onTap: hasHtmlContent
                                ? () async {
                                    try {
                                      await provider.openArchivedHtml(
                                        discussion,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                : null,
                            enabled: hasHtmlContent,
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}
