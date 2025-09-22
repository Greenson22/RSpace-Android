// lib/features/perpusku/presentation/pages/perpusku_subject_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import 'package:my_aplication/features/webview_page/presentation/pages/webview_page.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';
import 'perpusku_file_list_page.dart';

class PerpuskuSubjectPage extends StatelessWidget {
  final PerpuskuTopic topic;
  const PerpuskuSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchSubjects(topic.path),
      child: _PerpuskuSubjectView(topic: topic),
    );
  }
}

class _PerpuskuSubjectView extends StatefulWidget {
  final PerpuskuTopic topic;
  const _PerpuskuSubjectView({required this.topic});

  @override
  State<_PerpuskuSubjectView> createState() => _PerpuskuSubjectViewState();
}

class _PerpuskuSubjectViewState extends State<_PerpuskuSubjectView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<PerpuskuProvider>(
        context,
        listen: false,
      ).searchInTopic(widget.topic.path, _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari file di dalam topik ini...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.isSearching
                ? _buildSearchResults(context, provider)
                : _buildSubjectList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(BuildContext context, PerpuskuProvider provider) {
    if (provider.subjects.isEmpty) {
      return const Center(child: Text('Tidak ada subjek di dalam topik ini.'));
    }
    return ListView.builder(
      itemCount: provider.subjects.length,
      itemBuilder: (context, index) {
        final subject = provider.subjects[index];
        return ListTile(
          leading: Text(subject.icon, style: const TextStyle(fontSize: 24)),
          title: Text(subject.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerpuskuFileListPage(subject: subject),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, PerpuskuProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(child: Text('File tidak ditemukan.'));
    }
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final file = provider.searchResults[index];
        return ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(file.title),
          subtitle: Text(file.path),
          onTap: () async {
            try {
              if (Platform.isAndroid && themeProvider.openInAppBrowser) {
                final fileContent = await File(file.path).readAsString();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebViewPage(
                      title: file.title,
                      htmlContent: fileContent,
                    ),
                  ),
                );
              } else {
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  throw Exception(result.message);
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membuka file: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }
}
