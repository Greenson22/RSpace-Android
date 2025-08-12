import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/local_file_service.dart';
import '3_discussions_page/dialogs/discussion_dialogs.dart';
import '3_discussions_page/widgets/discussion_card.dart';

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
  // ... (semua properti state tetap sama)
  final LocalFileService _fileService = LocalFileService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  bool _isLoading = true;
  List<Discussion> _allDiscussions = [];
  List<Discussion> _filteredDiscussions = [];
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _arePointsVisible = {};
  bool _isSearching = false;

  String? _activeFilterType;
  String? _selectedRepetitionCode;
  DateTimeRange? _selectedDateRange;

  String _sortType = 'date';
  bool _sortAscending = true;

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
    _loadInitialData();
    _searchController.addListener(_filterAndSortDiscussions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA & STATE LOGIC (Tidak ada perubahan di sini) ---
  Future<void> _loadInitialData() async {
    await _loadPreferences();
    await _loadDiscussions();
  }

  Future<void> _loadPreferences() async {
    final sortPrefs = await _prefsService.loadSortPreferences();
    final filterPrefs = await _prefsService.loadFilterPreference();
    setState(() {
      _sortType = sortPrefs['sortType'];
      _sortAscending = sortPrefs['sortAscending'];
      _activeFilterType = filterPrefs['filterType'];
      if (_activeFilterType == 'code') {
        _selectedRepetitionCode = filterPrefs['filterValue'];
      } else if (_activeFilterType == 'date' &&
          filterPrefs['filterValue'] != null) {
        final dates = filterPrefs['filterValue']!.split('/');
        _selectedDateRange = DateTimeRange(
          start: DateTime.parse(dates[0]),
          end: DateTime.parse(dates[1]),
        );
      }
    });
  }

  Future<void> _loadDiscussions() async {
    try {
      final discussions = await _fileService.loadDiscussions(
        widget.jsonFilePath,
      );
      setState(() {
        _allDiscussions = discussions;
        _allDiscussions.asMap().forEach((index, _) {
          _arePointsVisible[index] = false;
        });
        _filterAndSortDiscussions();
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

  void _filterAndSortDiscussions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDiscussions = _allDiscussions.where((discussion) {
        final matchesSearchQuery = discussion.discussion.toLowerCase().contains(
          query,
        );

        bool matchesFilter = true;
        if (_activeFilterType == 'code' && _selectedRepetitionCode != null) {
          matchesFilter = discussion.repetitionCode == _selectedRepetitionCode;
        } else if (_activeFilterType == 'date' && _selectedDateRange != null) {
          try {
            if (discussion.date == null) {
              matchesFilter = false;
            } else {
              final discussionDate = DateTime.parse(discussion.date!);
              final startDate = _selectedDateRange!.start;
              final endDate = _selectedDateRange!.end.add(
                const Duration(days: 1),
              );
              matchesFilter =
                  discussionDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  discussionDate.isBefore(endDate);
            }
          } catch (e) {
            matchesFilter = false;
          }
        }
        return matchesSearchQuery && matchesFilter;
      }).toList();
      _sortDiscussions();
    });
  }

  void _sortDiscussions() {
    List<Discussion> listToSort = List.from(_filteredDiscussions);
    List<Discussion> allListToSort = List.from(_allDiscussions);

    Comparator<Discussion> comparator;
    switch (_sortType) {
      case 'name':
        comparator = (a, b) =>
            a.discussion.toLowerCase().compareTo(b.discussion.toLowerCase());
        break;
      case 'code':
        comparator = (a, b) => a.repetitionCode.compareTo(b.repetitionCode);
        break;
      case 'date':
      default:
        comparator = (a, b) {
          try {
            if (a.date == null && b.date == null) return 0;
            if (a.date == null) return _sortAscending ? 1 : -1;
            if (b.date == null) return _sortAscending ? -1 : 1;
            return DateTime.parse(a.date!).compareTo(DateTime.parse(b.date!));
          } catch (e) {
            return 0;
          }
        };
        break;
    }

    listToSort.sort(comparator);
    allListToSort.sort(comparator);

    if (!_sortAscending) {
      _filteredDiscussions = listToSort.reversed.toList();
      _allDiscussions = allListToSort.reversed.toList();
    } else {
      _filteredDiscussions = listToSort;
      _allDiscussions = allListToSort;
    }
  }

  // --- UI HANDLERS & ACTIONS ---

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

  Future<void> _addDiscussion() async {
    await showTextInputDialog(
      context: context,
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
          _arePointsVisible[_allDiscussions.length - 1] = false;
          _filterAndSortDiscussions();
        });
        _saveDiscussions();
      },
    );
  }

  Future<void> _addPoint(Discussion discussion) async {
    await showTextInputDialog(
      context: context,
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

  // --- HANDLERS FOR DISCUSSION ACTIONS ---

  void _handleDiscussionDateChange(Discussion discussion) async {
    if (discussion.finished) {
      _showSnackBar('Tidak dapat mengubah tanggal diskusi yang sudah selesai.');
      return;
    }
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(discussion.date ?? '') ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        discussion.date = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      _saveDiscussions();
    }
  }

  void _handleDiscussionCodeChange(Discussion discussion) {
    if (discussion.finished) {
      _showSnackBar('Tidak dapat mengubah kode diskusi yang sudah selesai.');
      return;
    }
    showRepetitionCodeDialog(
      context,
      discussion.repetitionCode,
      _repetitionCodes,
      (newCode) {
        setState(() {
          discussion.repetitionCode = newCode;
          if (newCode != 'Finish') {
            discussion.date = _getNewDateForRepetitionCode(newCode);
          }
        });
        _saveDiscussions();
      },
    );
  }

  Future<void> _handleDiscussionRename(Discussion discussion) async {
    await showTextInputDialog(
      context: context,
      title: "Ubah Nama Diskusi",
      label: "Nama Baru",
      initialValue: discussion.discussion,
      onSave: (newName) {
        setState(() {
          discussion.discussion = newName;
        });
        _saveDiscussions();
      },
    );
  }

  Future<void> _markAsFinished(Discussion discussion) async {
    setState(() {
      discussion.finished = true;
      discussion.repetitionCode = 'Finish';
      discussion.finish_date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      discussion.date = null;
    });
    await _saveDiscussions();
    _showSnackBar('Diskusi "${discussion.discussion}" ditandai selesai.');
  }

  // --- HANDLERS FOR POINT ACTIONS ---

  void _handlePointDateChange(Point point) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(point.date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        point.date = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      _saveDiscussions();
    }
  }

  void _handlePointCodeChange(Point point) {
    showRepetitionCodeDialog(context, point.repetitionCode, _repetitionCodes, (
      newCode,
    ) {
      setState(() {
        point.repetitionCode = newCode;
        point.date = _getNewDateForRepetitionCode(newCode);
      });
      _saveDiscussions();
    });
  }

  void _handlePointRename(Point point) async {
    await showTextInputDialog(
      context: context,
      title: 'Ubah Nama Poin',
      label: 'Nama Baru',
      initialValue: point.pointText,
      onSave: (newName) {
        setState(() {
          point.pointText = newName;
        });
        _saveDiscussions();
      },
    );
  }

  // --- UI HELPER METHODS (Tidak ada perubahan di sini) ---
  Color _getColorForRepetitionCode(String code) {
    switch (code) {
      case 'R0D':
        return Colors.orange.shade700;
      case 'R1D':
        return Colors.blue.shade600;
      case 'R3D':
        return Colors.teal.shade500;
      case 'R7D':
        return Colors.cyan.shade600;
      case 'R7D2':
        return Colors.purple.shade400;
      case 'R7D3':
        return Colors.indigo.shade500;
      case 'R30D':
        return Colors.brown.shade500;
      case 'Finish':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getNewDateForRepetitionCode(String code) {
    final now = DateTime.now();
    int daysToAdd;
    switch (code) {
      case 'R1D':
        daysToAdd = 1;
        break;
      case 'R3D':
        daysToAdd = 3;
        break;
      case 'R7D':
        daysToAdd = 7;
        break;
      case 'R7D2':
        daysToAdd = 14;
        break;
      case 'R7D3':
        daysToAdd = 21;
        break;
      case 'R30D':
        daysToAdd = 30;
        break;
      default:
        daysToAdd = 0;
        break;
    }
    return DateFormat('yyyy-MM-dd').format(now.add(Duration(days: daysToAdd)));
  }

  Widget _getSubtitleRichText(Discussion discussion) {
    if (discussion.finished) {
      return Text(
        'Selesai pada: ${discussion.finish_date}',
        style: const TextStyle(
          color: Colors.green,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    final dateText = discussion.date ?? 'N/A';
    final codeText = discussion.repetitionCode;
    Color dateColor = Colors.grey;
    if (discussion.date != null) {
      try {
        final discussionDate = DateTime.parse(discussion.date!);
        final today = DateTime.now();
        if (discussionDate.isBefore(today.subtract(const Duration(days: -1)))) {
          dateColor = Colors.red;
        } else {
          dateColor = Colors.amber.shade700;
        }
      } catch (e) {
        /* fallback */
      }
    }
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          const TextSpan(text: 'Date: '),
          TextSpan(
            text: dateText,
            style: TextStyle(color: dateColor, fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' | Code: '),
          TextSpan(
            text: codeText,
            style: TextStyle(
              color: _getColorForRepetitionCode(codeText),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final discussionsToShow =
        _searchController.text.isNotEmpty || _activeFilterType != null
        ? _filteredDiscussions
        : _allDiscussions;

    String emptyText = 'Tidak ada diskusi. Tekan + untuk menambah.';
    if ((_searchController.text.isNotEmpty || _activeFilterType != null) &&
        discussionsToShow.isEmpty) {
      emptyText = 'Diskusi tidak ditemukan.';
    }

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
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchController.clear();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              /* Add filter dialog logic here */
            },
            tooltip: 'Filter Diskusi',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              /* Add sort dialog logic here */
            },
            tooltip: 'Urutkan Diskusi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : discussionsToShow.isEmpty
          ? Center(child: Text(emptyText))
          : ListView.builder(
              itemCount: discussionsToShow.length,
              itemBuilder: (context, index) {
                final discussion = discussionsToShow[index];
                final originalIndex = _allDiscussions.indexOf(discussion);
                return DiscussionCard(
                  discussion: discussion,
                  index: originalIndex,
                  arePointsVisible: _arePointsVisible,
                  onToggleVisibility: (idx) => setState(
                    () => _arePointsVisible[idx] =
                        !(_arePointsVisible[idx] ?? false),
                  ),
                  getColorForRepetitionCode: _getColorForRepetitionCode,
                  getSubtitleRichText: _getSubtitleRichText,
                  onAddPoint: () => _addPoint(discussion),
                  onMarkAsFinished: () => _markAsFinished(discussion),
                  onRename: () => _handleDiscussionRename(discussion),
                  // Teruskan handler yang benar
                  onDiscussionDateChange: () =>
                      _handleDiscussionDateChange(discussion),
                  onDiscussionCodeChange: () =>
                      _handleDiscussionCodeChange(discussion),
                  // Handler untuk Point
                  onPointDateChange: _handlePointDateChange,
                  onPointCodeChange: _handlePointCodeChange,
                  onPointRename: _handlePointRename,
                );
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
}
