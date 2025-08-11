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
            return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
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
            final discussionDate = DateTime.parse(discussion.date);
            final startDate = _selectedDateRange!.start;
            final endDate = _selectedDateRange!.end.add(
              const Duration(days: 1),
            );
            matchesFilter =
                discussionDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                discussionDate.isBefore(endDate);
          } catch (e) {
            matchesFilter = false;
          }
        }
        return matchesSearchQuery && matchesFilter;
      }).toList();

      _sortDiscussions();
    });
  }

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

  // Lokasi: lib/presentation/pages/3_discussions_page.dart

  Future<void> _loadDiscussions() async {
    try {
      final discussions = await _fileService.loadDiscussions(
        widget.jsonFilePath,
      );
      setState(() {
        _allDiscussions = discussions;
        // Baris ini tidak lagi diperlukan karena _filterAndSortDiscussions akan menanganinya
        // _filteredDiscussions = _allDiscussions;
        for (int i = 0; i < _allDiscussions.length; i++) {
          _arePointsVisible[i] = false;
        }
        _filterAndSortDiscussions(); // <-- PERBAIKAN: Panggil fungsi ini
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
          _filterAndSortDiscussions();
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
        setState(() => discussion.points.add(newPoint));
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

  Future<void> _showFilterDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Diskusi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Berdasarkan Kode Repetisi'),
                onTap: () {
                  Navigator.pop(context);
                  _showRepetitionCodeFilterDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Berdasarkan Tanggal'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateFilterDialog();
                },
              ),
            ],
          ),
          actions: [
            if (_activeFilterType != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearFilters();
                },
                child: const Text('Hapus Filter'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRepetitionCodeFilterDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Kode Repetisi'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _repetitionCodes.length,
              itemBuilder: (context, index) {
                final code = _repetitionCodes[index];
                return ListTile(
                  title: Text(code),
                  onTap: () {
                    setState(() {
                      _activeFilterType = 'code';
                      _selectedRepetitionCode = code;
                      _selectedDateRange = null;
                      _filterAndSortDiscussions();
                    });
                    _prefsService.saveFilterPreference('code', code);
                    Navigator.pop(context);
                    _showSnackBar('Filter diterapkan: Kode = $code');
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDateFilterDialog() async {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Opsi Tanggal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Hari Ini'),
                onTap: () {
                  setState(() {
                    _activeFilterType = 'date';
                    _selectedDateRange = DateTimeRange(start: now, end: now);
                    _selectedRepetitionCode = null;
                    _filterAndSortDiscussions();
                  });
                  final dateRangeString =
                      '${now.toIso8601String()}/${now.toIso8601String()}';
                  _prefsService.saveFilterPreference('date', dateRangeString);
                  Navigator.pop(context);
                  _showSnackBar('Filter diterapkan: Hari Ini');
                },
              ),
              ListTile(
                title: const Text('Hari ini dan sebelumnya'),
                onTap: () {
                  final start = DateTime(2000);
                  setState(() {
                    _activeFilterType = 'date';
                    _selectedDateRange = DateTimeRange(start: start, end: now);
                    _selectedRepetitionCode = null;
                    _filterAndSortDiscussions();
                  });
                  final dateRangeString =
                      '${start.toIso8601String()}/${now.toIso8601String()}';
                  _prefsService.saveFilterPreference('date', dateRangeString);
                  Navigator.pop(context);
                  _showSnackBar('Filter diterapkan: Hari ini dan sebelumnya');
                },
              ),
              ListTile(
                title: const Text('Pilih Rentang Tanggal'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    initialDateRange: _selectedDateRange,
                  );
                  if (pickedRange != null) {
                    setState(() {
                      _activeFilterType = 'date';
                      _selectedDateRange = pickedRange;
                      _selectedRepetitionCode = null;
                      _filterAndSortDiscussions();
                      final startDate = DateFormat(
                        'dd/MM/yy',
                      ).format(pickedRange.start);
                      final endDate = DateFormat(
                        'dd/MM/yy',
                      ).format(pickedRange.end);
                      final dateRangeString =
                          '${pickedRange.start.toIso8601String()}/${pickedRange.end.toIso8601String()}';
                      _prefsService.saveFilterPreference(
                        'date',
                        dateRangeString,
                      );
                      _showSnackBar('Filter diterapkan: $startDate - $endDate');
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSortDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Urutkan Diskusi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Urutkan berdasarkan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Tanggal'),
                    value: 'date',
                    groupValue: _sortType,
                    onChanged: (value) =>
                        setDialogState(() => _sortType = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Nama'),
                    value: 'name',
                    groupValue: _sortType,
                    onChanged: (value) =>
                        setDialogState(() => _sortType = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Kode Repetisi'),
                    value: 'code',
                    groupValue: _sortType,
                    onChanged: (value) =>
                        setDialogState(() => _sortType = value!),
                  ),
                  const Divider(),
                  const Text(
                    'Urutan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Menaik (Ascending)'),
                    value: true,
                    groupValue: _sortAscending,
                    onChanged: (value) =>
                        setDialogState(() => _sortAscending = value!),
                  ),
                  RadioListTile<bool>(
                    title: const Text('Menurun (Descending)'),
                    value: false,
                    groupValue: _sortAscending,
                    onChanged: (value) =>
                        setDialogState(() => _sortAscending = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _sortDiscussions();
                    });
                    _prefsService.saveSortPreferences(
                      _sortType,
                      _sortAscending,
                    );
                    Navigator.pop(context);
                    _showSnackBar('Diskusi telah diurutkan.');
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final discussionsToShow =
        (_activeFilterType != null || _searchController.text.isNotEmpty)
        ? _filteredDiscussions
        : _allDiscussions;

    String emptyText = 'Tidak ada diskusi. Tekan + untuk menambah.';
    if (_searchController.text.isNotEmpty || _activeFilterType != null) {
      if (discussionsToShow.isEmpty) {
        emptyText = 'Diskusi tidak ditemukan.';
      }
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
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Diskusi',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
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
                  onDateChange: () => _changeDate(
                    (newDate) => setState(() => discussion.date = newDate),
                  ),
                  onCodeChange: () => _changeRepetitionCode(
                    discussion.repetitionCode,
                    (newCode) =>
                        setState(() => discussion.repetitionCode = newCode),
                  ),
                  onRename: () => _showRenameDialog(
                    discussion.discussion,
                    (newName) =>
                        setState(() => discussion.discussion = newName),
                  ),
                ),
                if (discussion.points.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      arePointsVisible ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(
                      () => _arePointsVisible[index] = !arePointsVisible,
                    ),
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
        onDateChange: () =>
            _changeDate((newDate) => setState(() => point.date = newDate)),
        onCodeChange: () => _changeRepetitionCode(
          point.repetitionCode,
          (newCode) => setState(() => point.repetitionCode = newCode),
        ),
        onRename: () => _showRenameDialog(
          point.pointText,
          (newName) => setState(() => point.pointText = newName),
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
