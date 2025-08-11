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
  List<Discussion> _allDiscussions = [];
  List<Discussion> _filteredDiscussions = [];
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _arePointsVisible = {};
  bool _isSearching = false;
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
    _searchController.addListener(_filterDiscussions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDiscussions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDiscussions = _allDiscussions
          .where(
            (discussion) => discussion.discussion.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> _loadDiscussions() async {
    try {
      final discussions = await _fileService.loadDiscussions(
        widget.jsonFilePath,
      );
      setState(() {
        _allDiscussions = discussions;
        _filteredDiscussions = _allDiscussions;
        for (int i = 0; i < _allDiscussions.length; i++) {
          _arePointsVisible[i] = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Gagal memuat file: $e', isError: true);
    }
  }

  Future<void> _saveDiscussions() async {
    try {
      await _fileService.saveDiscussions(widget.jsonFilePath, _allDiscussions);
      _showSnackBar('Perubahan berhasil disimpan!');
    } catch (e) {
      _showSnackBar('Gagal menyimpan perubahan: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showTextInputDialog({
    required String title,
    required String label,
    required Function(String) onSave,
  }) async {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSave(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDiscussion() async {
    await _showTextInputDialog(
      title: 'Tambah Diskusi Baru',
      label: 'Nama Diskusi',
      onSave: (name) {
        final newDiscussion = Discussion(
          discussion: name,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          repetitionCode: 'R0D',
          points: [],
        );
        setState(() {
          _allDiscussions.add(newDiscussion);
          _filterDiscussions();
          _arePointsVisible[_allDiscussions.length - 1] = false;
        });
        _saveDiscussions();
      },
    );
  }

  Future<void> _addPoint(Discussion discussion) async {
    await _showTextInputDialog(
      title: 'Tambah Poin Baru',
      label: 'Teks Poin',
      onSave: (text) {
        final newPoint = Point(
          pointText: text,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          repetitionCode: 'R0D',
        );
        setState(() {
          discussion.points.add(newPoint);
        });
        _saveDiscussions();
      },
    );
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
      _saveDiscussions();
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
                    setStateInDialog(() => tempSelectedCode = newValue);
                    onCodeSelected(newValue);
                    _saveDiscussions();
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ubah Nama'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Baru'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                onRename(controller.text);
                Navigator.of(context).pop();
                _saveDiscussions();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final discussionsToShow = _searchController.text.isEmpty
        ? _allDiscussions
        : _filteredDiscussions;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari diskusi...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : Text(widget.subjectName),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : discussionsToShow.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isNotEmpty
                    ? 'Diskusi tidak ditemukan.'
                    : 'Tidak ada diskusi. Tekan + untuk menambah.',
              ),
            )
          : ListView.builder(
              itemCount: discussionsToShow.length,
              itemBuilder: (context, index) {
                final discussion = discussionsToShow[index];
                final originalIndex = _allDiscussions.indexOf(discussion);
                return _buildDiscussionCard(discussion, originalIndex);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDiscussion,
        tooltip: 'Tambah Diskusi',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDiscussionCard(Discussion discussion, int index) {
    bool arePointsVisible = _arePointsVisible[index] ?? false;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            title: Text(
              discussion.discussion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${discussion.date} | Code: ${discussion.repetitionCode}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditPopupMenu(
                  onDateChange: () => _changeDate((newDate) {
                    setState(() => discussion.date = newDate);
                  }),
                  onCodeChange: () => _changeRepetitionCode(
                    discussion.repetitionCode,
                    (newCode) {
                      setState(() => discussion.repetitionCode = newCode);
                    },
                  ),
                  onRename: () =>
                      _showRenameDialog(discussion.discussion, (newName) {
                        setState(() => discussion.discussion = newName);
                      }),
                ),
                if (discussion.points.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      arePointsVisible ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _arePointsVisible[index] = !arePointsVisible;
                      });
                    },
                  ),
              ],
            ),
          ),
          if (discussion.points.isNotEmpty)
            Visibility(
              visible: arePointsVisible,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                  top: 8.0,
                  right: 16.0,
                  bottom: 8.0,
                ),
                child: Column(
                  children: [
                    ...discussion.points.map((point) => _buildPointTile(point)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Poin'),
                        onPressed: () => _addPoint(discussion),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointTile(Point point) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(point.pointText),
      subtitle: Text('Date: ${point.date} | Code: ${point.repetitionCode}'),
      trailing: EditPopupMenu(
        onDateChange: () => _changeDate((newDate) {
          setState(() => point.date = newDate);
        }),
        onCodeChange: () =>
            _changeRepetitionCode(point.repetitionCode, (newCode) {
              setState(() => point.repetitionCode = newCode);
            }),
        onRename: () => _showRenameDialog(point.pointText, (newName) {
          setState(() => point.pointText = newName);
        }),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
