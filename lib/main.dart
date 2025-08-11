import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

// Tambahkan ini di file pubspec.yaml Anda:
// dependencies:
//   flutter:
//     sdk: flutter
//   path: ^1.8.0
//   intl: ^0.18.0  //<-- Pastikan versi ini atau yang terbaru ada

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topics and Subjects Lister',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        ),
      ),
      home: const TopicsPage(),
    );
  }
}

// Halaman 1 & 2 (Topics & Subjects) tidak ada perubahan signifikan
// ... (kode untuk TopicsPage dan SubjectsPage tetap sama seperti sebelumnya)

// -------------------------------------------------------------------
// Halaman 1: Topics (Daftar Folder) - (Tidak ada perubahan)
// -------------------------------------------------------------------
class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  final String _topicsPath =
      '/home/lemon-manis-22/RikalG22/RSpace_data/data/contents/topics'; // Ganti dengan path Anda
  late Future<List<String>> _folderListFuture;

  @override
  void initState() {
    super.initState();
    _folderListFuture = _getFolders();
  }

  Future<List<String>> _getFolders() async {
    final directory = Directory(_topicsPath);
    if (!await directory.exists()) {
      // Jika direktori tidak ada, coba buat
      try {
        await directory.create(recursive: true);
        return []; // Kembalikan list kosong karena baru dibuat
      } catch (e) {
        throw Exception('Gagal membuat direktori: $_topicsPath \nError: $e');
      }
    }
    final List<String> folderNames = directory
        .listSync()
        .whereType<Directory>()
        .map((item) => path.basename(item.path))
        .toList();
    folderNames.sort();
    return folderNames;
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
              final folderPath = path.join(_topicsPath, folderName);
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

// -------------------------------------------------------------------
// Halaman 2: Subjects (Daftar file .json) - (Tidak ada perubahan)
// -------------------------------------------------------------------
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
  late Future<List<String>> _jsonFilesFuture;

  @override
  void initState() {
    super.initState();
    _jsonFilesFuture = _getJsonFiles();
  }

  Future<List<String>> _getJsonFiles() async {
    final directory = Directory(widget.folderPath);
    if (!await directory.exists()) {
      throw Exception('Folder tidak ditemukan.');
    }
    final List<String> fileNames = directory
        .listSync()
        .whereType<File>()
        .where((item) => item.path.toLowerCase().endsWith('.json'))
        .map((item) => path.basenameWithoutExtension(item.path))
        .toList();
    fileNames.sort();
    return fileNames;
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

// --- *** DIPERBARUI: Model Data Point dengan toJson *** ---
class Point {
  String pointText;
  String repetitionCode;
  String date;

  Point({
    required this.pointText,
    required this.repetitionCode,
    required this.date,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      pointText: json['point_text'] ?? 'Tidak ada teks poin',
      repetitionCode: json['repetition_code'] ?? '',
      date: json['date'] ?? 'No Date',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point_text': pointText,
      'repetition_code': repetitionCode,
      'date': date,
    };
  }
}

// --- *** DIPERBARUI: Model Data Discussion dengan toJson *** ---
class Discussion {
  String discussion;
  String date;
  String repetitionCode;
  List<Point> points;

  Discussion({
    required this.discussion,
    required this.date,
    required this.repetitionCode,
    required this.points,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    var pointsListFromJson = json['points'] as List<dynamic>?;
    List<Point> pointsList = pointsListFromJson != null
        ? pointsListFromJson.map((p) => Point.fromJson(p)).toList()
        : [];

    return Discussion(
      discussion: json['discussion'] ?? 'Tidak ada diskusi',
      date: json['date'] ?? 'No Date',
      repetitionCode: json['repetition_code'] ?? '',
      points: pointsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussion': discussion,
      'date': date,
      'repetition_code': repetitionCode,
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}

// --- *** DIPERBARUI TOTAL: Halaman 3: Discussions *** ---
class DiscussionsPage extends StatefulWidget {
  final String jsonFilePath;
  final String subjectName;

  const DiscussionsPage({
    super.key,
    required this.jsonFilePath,
    required this.subjectName,
  });

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  bool _isLoading = true;
  List<Discussion> _discussions = [];
  final List<String> _repetitionCodes = const [
    'R0D',
    'R1D',
    'R3D',
    'R7D',
    'R7D2',
    'R7D3',
    'R30D',
    'Finish',
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  Future<void> _loadDiscussions() async {
    try {
      final file = File(widget.jsonFilePath);
      if (!await file.exists()) {
        // Jika file tidak ada, buat dengan struktur dasar
        await file.writeAsString(jsonEncode({'content': []}));
      }
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final contentList = jsonData['content'] as List<dynamic>;

      setState(() {
        _discussions = contentList
            .map((item) => Discussion.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat file: $e')));
    }
  }

  Future<void> _saveDiscussions() async {
    try {
      final file = File(widget.jsonFilePath);
      final newJsonData = {
        'content': _discussions.map((d) => d.toJson()).toList(),
      };
      // Menggunakan JsonEncoder untuk pretty print
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(newJsonData));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan berhasil disimpan!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan perubahan: $e')));
    }
  }

  Future<void> _changeDate(Function(String) onDateSelected) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      onDateSelected(formattedDate);
    }
  }

  void _changeRepetitionCode(
    String currentCode,
    Function(String) onCodeSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedCode = currentCode;
        return AlertDialog(
          title: const Text('Pilih Kode Repetisi'),
          content: DropdownButton<String>(
            value: selectedCode,
            isExpanded: true,
            items: _repetitionCodes.map((String code) {
              return DropdownMenuItem<String>(value: code, child: Text(code));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedCode = newValue;
                onCodeSelected(newValue);
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // -- Build method utama --
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _discussions.length,
              itemBuilder: (context, discussionIndex) {
                final discussion = _discussions[discussionIndex];
                return _buildDiscussionCard(discussion, discussionIndex);
              },
            ),
    );
  }

  // -- Widget untuk membangun setiap kartu diskusi --
  Widget _buildDiscussionCard(Discussion discussion, int discussionIndex) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.blue,
              ),
              title: Text(
                discussion.discussion,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Date: ${discussion.date} | Code: ${discussion.repetitionCode}',
              ),
              trailing: _buildPopupMenu(
                onDateChange: () => _changeDate((newDate) {
                  setState(() => discussion.date = newDate);
                  _saveDiscussions();
                }),
                onCodeChange: () =>
                    _changeRepetitionCode(discussion.repetitionCode, (newCode) {
                      setState(() => discussion.repetitionCode = newCode);
                      _saveDiscussions();
                    }),
              ),
            ),
            if (discussion.points.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                  top: 8.0,
                  right: 16.0,
                ),
                child: Column(
                  children: List.generate(discussion.points.length, (
                    pointIndex,
                  ) {
                    final point = discussion.points[pointIndex];
                    return _buildPointTile(point, discussionIndex, pointIndex);
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- Widget untuk membangun setiap baris point --
  Widget _buildPointTile(Point point, int discussionIndex, int pointIndex) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(point.pointText),
      subtitle: Text('Date: ${point.date} | Code: ${point.repetitionCode}'),
      trailing: _buildPopupMenu(
        onDateChange: () => _changeDate((newDate) {
          setState(() => point.date = newDate);
          _saveDiscussions();
        }),
        onCodeChange: () =>
            _changeRepetitionCode(point.repetitionCode, (newCode) {
              setState(() => point.repetitionCode = newCode);
              _saveDiscussions();
            }),
      ),
      contentPadding: const EdgeInsets.only(left: 0, right: 0),
    );
  }

  // -- Widget untuk membangun tombol popup menu --
  Widget _buildPopupMenu({
    required VoidCallback onDateChange,
    required VoidCallback onCodeChange,
  }) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit_date',
          child: Text('Ubah Tanggal'),
        ),
        const PopupMenuItem<String>(
          value: 'edit_code',
          child: Text('Ubah Kode Repetisi'),
        ),
      ],
    );
  }
}
