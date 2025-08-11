import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/services/local_file_service.dart';
import '2_subjects_page.dart';

class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  // 1. Membuat instance dari service
  final LocalFileService _fileService = LocalFileService();
  late Future<List<String>> _folderListFuture;

  @override
  void initState() {
    super.initState();
    // 2. Memanggil method dari service untuk mendapatkan data
    _folderListFuture = _fileService.getTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: FutureBuilder<List<String>>(
        future: _folderListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Tidak ada folder topik ditemukan.'),
            );
          }

          final folders = snapshot.data!;
          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderName = folders[index];
              final folderPath = path.join(
                _fileService.getTopicsPath(),
                folderName,
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.teal),
                  title: Text(folderName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectsPage(
                          folderPath: folderPath,
                          topicName: folderName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
