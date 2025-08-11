import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/local_file_service.dart';
import '../widgets/edit_popup_menu.dart';

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
  final LocalFileService _fileService = LocalFileService();
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
      final discussions = await _fileService.loadDiscussions(
        widget.jsonFilePath,
      );
      setState(() {
        _discussions = discussions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat file: $e')));
      }
    }
  }

  Future<void> _saveDiscussions() async {
    try {
      await _fileService.saveDiscussions(widget.jsonFilePath, _discussions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
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
      onDateSelected(DateFormat('yyyy-MM-dd').format(pickedDate));
    }
  }

  void _changeRepetitionCode(
    String currentCode,
    Function(String) onCodeSelected,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String? tempSelectedCode = currentCode;
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Pilih Kode Repetisi'),
              content: DropdownButton<String>(
                value: tempSelectedCode,
                isExpanded: true,
                items: _repetitionCodes.map((String code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(code),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setStateInDialog(() {
                      tempSelectedCode = newValue;
                    });
                    onCodeSelected(newValue);
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRenameDialog(
    String currentName,
    Function(String) onRename,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Nama'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nama Baru'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                onRename(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _discussions.length,
              itemBuilder: (context, index) =>
                  _buildDiscussionCard(_discussions[index], index),
            ),
    );
  }

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
              trailing: EditPopupMenu(
                onDateChange: () => _changeDate((newDate) {
                  setState(() => discussion.date = newDate);
                  _saveDiscussions();
                }),
                onCodeChange: () =>
                    _changeRepetitionCode(discussion.repetitionCode, (newCode) {
                      setState(() => discussion.repetitionCode = newCode);
                      _saveDiscussions();
                    }),
                onRename: () =>
                    _showRenameDialog(discussion.discussion, (newName) {
                      setState(() => discussion.discussion = newName);
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
                    return _buildPointTile(
                      discussion.points[pointIndex],
                      discussionIndex,
                      pointIndex,
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointTile(Point point, int discussionIndex, int pointIndex) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(point.pointText),
      subtitle: Text('Date: ${point.date} | Code: ${point.repetitionCode}'),
      trailing: EditPopupMenu(
        onDateChange: () => _changeDate((newDate) {
          setState(() => point.date = newDate);
          _saveDiscussions();
        }),
        onCodeChange: () =>
            _changeRepetitionCode(point.repetitionCode, (newCode) {
              setState(() => point.repetitionCode = newCode);
              _saveDiscussions();
            }),
        onRename: () => _showRenameDialog(point.pointText, (newName) {
          setState(() => point.pointText = newName);
          _saveDiscussions();
        }),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
