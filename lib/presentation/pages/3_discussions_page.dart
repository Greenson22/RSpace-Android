import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/discussion_model.dart';
import '../../data/services/local_file_service.dart';
import '3_discussions_page/dialogs/discussion_dialogs.dart';
import '3_discussions_page/utils/repetition_code_utils.dart'; // <-- IMPORT BARU
import '3_discussions_page/widgets/discussion_card.dart';

class DiscussionsPage extends StatefulWidget {
  // ... (Konstruktor tetap sama)
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
  // ... (Properti state tetap sama)
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

  // ... (Metode initState, dispose, load, save, filter, sort tetap sama)
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
            discussion.date = getNewDateForRepetitionCode(
              newCode,
            ); // <-- PANGGIL FUNGSI DARI UTILITAS
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
        point.date = getNewDateForRepetitionCode(
          newCode,
        ); // <-- PANGGIL FUNGSI DARI UTILITAS
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

  // --- DIALOGS FOR FILTER & SORT (Handlers) ---

  void _clearFilters() {
    setState(() {
      _activeFilterType = null;
      _selectedRepetitionCode = null;
      _selectedDateRange = null;
      _filterAndSortDiscussions();
    });
    _prefsService.saveFilterPreference(null, null);
    _showSnackBar('Semua filter telah dihapus.');
  }

  void _handleShowFilterDialog() {
    showFilterDialog(
      context: context,
      isFilterActive: _activeFilterType != null,
      onClearFilters: _clearFilters,
      onShowRepetitionCodeFilter: _handleShowRepetitionCodeFilterDialog,
      onShowDateFilter: _handleShowDateFilterDialog,
    );
  }

  void _handleShowRepetitionCodeFilterDialog() {
    showRepetitionCodeFilterDialog(
      context: context,
      repetitionCodes: _repetitionCodes,
      onSelectCode: (code) {
        setState(() {
          _activeFilterType = 'code';
          _selectedRepetitionCode = code;
          _selectedDateRange = null;
          _filterAndSortDiscussions();
        });
        _prefsService.saveFilterPreference('code', code);
        _showSnackBar('Filter diterapkan: Kode = $code');
      },
    );
  }

  void _handleShowDateFilterDialog() {
    showDateFilterDialog(
      context: context,
      initialDateRange: _selectedDateRange,
      onSelectRange: (range) {
        setState(() {
          _activeFilterType = 'date';
          _selectedDateRange = range;
          _selectedRepetitionCode = null;
          _filterAndSortDiscussions();
        });
        final dateRangeString =
            '${range.start.toIso8601String()}/${range.end.toIso8601String()}';
        _prefsService.saveFilterPreference('date', dateRangeString);
        final startDate = DateFormat('dd/MM/yy').format(range.start);
        final endDate = DateFormat('dd/MM/yy').format(range.end);
        _showSnackBar('Filter diterapkan: $startDate - $endDate');
      },
    );
  }

  void _handleShowSortDialog() {
    showSortDialog(
      context: context,
      initialSortType: _sortType,
      initialSortAscending: _sortAscending,
      onApplySort: (sortType, sortAscending) {
        setState(() {
          _sortType = sortType;
          _sortAscending = sortAscending;
          _sortDiscussions();
        });
        _prefsService.saveSortPreferences(_sortType, _sortAscending);
        _showSnackBar('Diskusi telah diurutkan.');
      },
    );
  }

  // HAPUS SEMUA METODE UI HELPER DI SINI:
  // _getColorForRepetitionCode
  // _getNewDateForRepetitionCode
  // _getSubtitleRichText

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
            onPressed: _handleShowFilterDialog,
            tooltip: 'Filter Diskusi',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _handleShowSortDialog,
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
                // SEDERHANAKAN PEMANGGILAN DiscussionCard
                return DiscussionCard(
                  discussion: discussion,
                  index: originalIndex,
                  arePointsVisible: _arePointsVisible,
                  onToggleVisibility: (idx) => setState(
                    () => _arePointsVisible[idx] =
                        !(_arePointsVisible[idx] ?? false),
                  ),
                  onAddPoint: () => _addPoint(discussion),
                  onMarkAsFinished: () => _markAsFinished(discussion),
                  onRename: () => _handleDiscussionRename(discussion),
                  onDiscussionDateChange: () =>
                      _handleDiscussionDateChange(discussion),
                  onDiscussionCodeChange: () =>
                      _handleDiscussionCodeChange(discussion),
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
