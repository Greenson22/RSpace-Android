// lib/features/perpusku/presentation/pages/perpusku_file_list_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/webview_page/presentation/pages/webview_page.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';

class PerpuskuFileListPage extends StatelessWidget {
  final PerpuskuSubject subject;
  const PerpuskuFileListPage({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchFiles(subject.path),
      child: _PerpuskuFileListView(subject: subject),
    );
  }
}

class _PerpuskuFileListView extends StatelessWidget {
  final PerpuskuSubject subject;
  const _PerpuskuFileListView({required this.subject});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.files.isEmpty
          ? const Center(
              child: Text('Tidak ada file HTML di dalam subjek ini.'),
            )
          : ListView.builder(
              itemCount: provider.files.length,
              itemBuilder: (context, index) {
                final file = provider.files[index];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(file.title),
                  subtitle: Text(file.fileName),
                  onTap: () async {
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
                  },
                );
              },
            ),
    );
  }
}
