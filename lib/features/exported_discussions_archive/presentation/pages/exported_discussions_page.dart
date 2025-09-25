// lib/presentation/pages/exported_discussions_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../application/exported_discussions_provider.dart';

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

class _ExportedDiscussionsView extends StatefulWidget {
  const _ExportedDiscussionsView();

  @override
  State<_ExportedDiscussionsView> createState() =>
      _ExportedDiscussionsViewState();
}

class _ExportedDiscussionsViewState extends State<_ExportedDiscussionsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<ExportedDiscussionsProvider>(
        context,
        listen: false,
      ).search(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

            if (provider.archiveDir == null ||
                !provider.archiveDir!.existsSync()) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Folder "finish_discussions" tidak ditemukan.\nSilakan lakukan arsip terlebih dahulu.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final lastModified = provider.lastModified != null
                ? DateFormat('d MMM yyyy, HH:mm').format(provider.lastModified!)
                : 'N/A';

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari di dalam arsip...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                if (provider.exportedTopics.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        provider.searchQuery.isNotEmpty
                            ? 'Tidak ada hasil untuk "${provider.searchQuery}"'
                            : 'Arsip ini kosong.',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text('Arsip terakhir diubah: $lastModified'),
                        ),
                        ...provider.exportedTopics.map((topic) {
                          final bool isSearchActive =
                              provider.searchQuery.isNotEmpty;
                          return ExpansionTile(
                            key: PageStorageKey('topic_${topic.name}'),
                            initiallyExpanded: isSearchActive,
                            title: Text(
                              topic.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            leading: Text(
                              topic.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            children: topic.subjects.map((subject) {
                              return ExpansionTile(
                                key: PageStorageKey(
                                  'subject_${topic.name}_${subject.name}',
                                ),
                                initiallyExpanded: isSearchActive,
                                title: Text(subject.name),
                                leading: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    subject.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                children: subject.discussions.map((discussion) {
                                  final bool hasHtmlLink =
                                      discussion.filePath != null &&
                                      discussion.filePath!.isNotEmpty;
                                  return ListTile(
                                    leading: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 32.0,
                                      ),
                                      child: Icon(
                                        hasHtmlLink
                                            ? Icons.link
                                            : Icons.link_off,
                                        size: 20,
                                        color: hasHtmlLink
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                      ),
                                    ),
                                    title: Text(discussion.discussion),
                                    subtitle: Text(
                                      'Selesai pada: ${discussion.finish_date ?? 'N/A'}',
                                    ),
                                    onTap: hasHtmlLink
                                        ? () async {
                                            try {
                                              await provider.openLinkedHtmlFile(
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
                                    enabled: hasHtmlLink,
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
