import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../data/services/local_file_service.dart';
import '3_discussions_page.dart';

class SubjectsPage extends StatefulWidget {
  final String folderPath;
  final String topicName;

  const SubjectsPage({
    super.key,
    required this.folderPath,
    required this.topicName,
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final LocalFileService _fileService = LocalFileService();
  late Future<List<String>> _jsonFilesFuture;

  @override
  void initState() {
    super.initState();
    _jsonFilesFuture = _fileService.getSubjects(widget.folderPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subjects in ${widget.topicName}')),
      body: FutureBuilder<List<String>>(
        future: _jsonFilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada file .json ditemukan.'));
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final subjectName = files[index];
              final filePath = path.join(
                widget.folderPath,
                '$subjectName.json',
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.orange),
                  title: Text(subjectName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiscussionsPage(
                          jsonFilePath: filePath,
                          subjectName: subjectName,
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
