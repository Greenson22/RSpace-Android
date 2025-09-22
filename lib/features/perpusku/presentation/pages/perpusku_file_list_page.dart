// lib/features/perpusku/presentation/pages/perpusku_file_list_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import 'package:my_aplication/features/webview_page/presentation/pages/webview_page.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

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
                    try {
                      // Logika baru untuk membuka file
                      if (Platform.isAndroid &&
                          themeProvider.openInAppBrowser) {
                        final fileContent = await File(
                          file.path,
                        ).readAsString();
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
            ),
    );
  }
}
