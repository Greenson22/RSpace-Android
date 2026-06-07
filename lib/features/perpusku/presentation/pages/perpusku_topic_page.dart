// lib/features/perpusku/presentation/pages/perpusku_topic_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_aplication/features/webview_page/presentation/pages/webview_page.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import 'perpusku_subject_page.dart';

class PerpuskuTopicPage extends StatelessWidget {
  const PerpuskuTopicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchTopics(),
      child: const _PerpuskuTopicView(),
    );
  }
}

class _PerpuskuTopicView extends StatefulWidget {
  const _PerpuskuTopicView();

  @override
  State<_PerpuskuTopicView> createState() => _PerpuskuTopicViewState();
}

class _PerpuskuTopicViewState extends State<_PerpuskuTopicView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      Provider.of<PerpuskuProvider>(
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
    final provider = Provider.of<PerpuskuProvider>(context);
    // Logika ThemeProvider dihapus, transparansi diset false secara default
    const isTransparent = false;

    return Scaffold(
      backgroundColor: isTransparent ? Colors.transparent : null,
      appBar: AppBar(
        backgroundColor: isTransparent ? Colors.transparent : null,
        elevation: isTransparent ? 0 : null,
        title: const Text('Perpusku - Topik'),
        actions: [
          IconButton(
            icon: Icon(
              provider.showHiddenTopics
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            onPressed: () => provider.toggleShowHidden(),
            tooltip: provider.showHiddenTopics
                ? 'Sembunyikan Topik Tersembunyi'
                : 'Tampilkan Topik Tersembunyi',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari di semua file Perpusku...',
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
                : _buildTopicList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicList(BuildContext context, PerpuskuProvider provider) {
    if (provider.topics.isEmpty) {
      return Center(
        child: Text(
          provider.showHiddenTopics
              ? 'Tidak ada topik ditemukan di Perpusku.'
              : 'Tidak ada topik yang terlihat.\nCoba aktifkan "Tampilkan Topik Tersembunyi".',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: provider.topics.length,
      itemBuilder: (context, index) {
        final topic = provider.topics[index];
        return ListTile(
          leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
          title: Text(topic.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerpuskuSubjectPage(topic: topic),
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
              // Langsung membuka file menggunakan open_file secara default
              final result = await OpenFile.open(file.path);
              if (result.type != ResultType.done) {
                throw Exception(result.message);
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
