// lib/features/time_management/presentation/dialogs/activity_chart_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/time_log_model.dart';
import '../widgets/daily_activity_chart.dart';

enum ChartFilterType { last30Days, range, month, year, allTime }

void showActivityChartDialog(BuildContext context, List<TimeLogEntry> logs) {
  showDialog(
    context: context,
    builder: (context) {
      return ActivityChartDialog(logs: logs);
    },
  );
}

class ActivityChartDialog extends StatefulWidget {
  final List<TimeLogEntry> logs;

  const ActivityChartDialog({super.key, required this.logs});

  @override
  State<ActivityChartDialog> createState() => _ActivityChartDialogState();
}

class _ActivityChartDialogState extends State<ActivityChartDialog> {
  ChartFilterType _selectedFilter = ChartFilterType.last30Days;
  DateTimeRange? _selectedRange;
  DateTime? _selectedMonth;
  int? _selectedYear;

  List<TimeLogEntry> _filteredLogs = [];
  TimeLogEntry? _mostActiveDay;
  TimeLogEntry? _leastActiveDay;
  double _maxMinutes = -1;
  double _minMinutes = double.infinity;

  late List<int> _availableYears;
  late List<DateTime> _availableMonths;

  double _barWidth = 40.0;
  static const double _minBarWidth = 10.0;
  static const double _maxBarWidth = 100.0;

  void _zoomIn() {
    setState(() {
      _barWidth = (_barWidth + 10.0).clamp(_minBarWidth, _maxBarWidth);
    });
  }

  void _zoomOut() {
    setState(() {
      _barWidth = (_barWidth - 10.0).clamp(_minBarWidth, _maxBarWidth);
    });
  }

  @override
  void initState() {
    super.initState();
    _prepareFilterOptions();
    _applyFilter();
  }

  void _prepareFilterOptions() {
    if (widget.logs.isEmpty) {
      _availableYears = [];
      _availableMonths = [];
      return;
    }

    final years = <int>{};
    final months = <DateTime>{};
    for (final log in widget.logs) {
      years.add(log.date.year);
      months.add(DateTime(log.date.year, log.date.month));
    }

    _availableYears = years.toList()..sort((a, b) => b.compareTo(a));
    _availableMonths = months.toList()..sort((a, b) => b.compareTo(a));
  }

  void _applyFilter() {
    List<TimeLogEntry> newFilteredLogs;
    final now = DateTime.now();

    switch (_selectedFilter) {
      case ChartFilterType.allTime:
        newFilteredLogs = List.from(widget.logs);
        break;
      case ChartFilterType.last30Days:
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        newFilteredLogs = widget.logs
            .where((log) => log.date.isAfter(thirtyDaysAgo))
            .toList();
        break;
      case ChartFilterType.range:
        if (_selectedRange == null) {
          newFilteredLogs = [];
          break;
        }
        final startDate = DateUtils.dateOnly(_selectedRange!.start);
        final endDate = DateUtils.dateOnly(_selectedRange!.end);
        newFilteredLogs = widget.logs.where((log) {
          final logDate = DateUtils.dateOnly(log.date);
          return !logDate.isBefore(startDate) && !logDate.isAfter(endDate);
        }).toList();
        break;
      case ChartFilterType.month:
        if (_selectedMonth == null) {
          newFilteredLogs = [];
          break;
        }
        newFilteredLogs = widget.logs
            .where(
              (log) =>
                  log.date.year == _selectedMonth!.year &&
                  log.date.month == _selectedMonth!.month,
            )
            .toList();
        break;
      case ChartFilterType.year:
        if (_selectedYear == null) {
          newFilteredLogs = [];
          break;
        }
        newFilteredLogs = widget.logs
            .where((log) => log.date.year == _selectedYear)
            .toList();
        break;
    }

    newFilteredLogs.sort((a, b) => a.date.compareTo(b.date));
    setState(() {
      _filteredLogs = newFilteredLogs;
      _calculateStats();
    });
  }

  void _calculateStats() {
    if (_filteredLogs.isEmpty) {
      setState(() {
        _mostActiveDay = null;
        _leastActiveDay = null;
      });
      return;
    }

    TimeLogEntry? mostDay;
    TimeLogEntry? leastDay;
    double maxMins = -1;
    double minMins = double.infinity;

    for (final log in _filteredLogs) {
      final totalMinutes = log.tasks.fold<double>(
        0,
        (sum, task) => sum + task.durationMinutes,
      );
      if (totalMinutes > maxMins) {
        maxMins = totalMinutes;
        mostDay = log;
      }
      if (totalMinutes > 0 && totalMinutes < minMins) {
        minMins = totalMinutes;
        leastDay = log;
      }
    }

    setState(() {
      _mostActiveDay = mostDay;
      _leastActiveDay = (mostDay == leastDay) ? null : leastDay;
      _maxMinutes = maxMins;
      _minMinutes = minMins;
    });
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    if (range != null) {
      setState(() {
        _selectedRange = range;
        _selectedFilter = ChartFilterType.range;
        _applyFilter();
      });
    }
  }

  Future<void> _pickMonth() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Bulan'),
        children: _availableMonths
            .map(
              (month) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, month),
                child: Text(DateFormat('MMMM yyyy', 'id_ID').format(month)),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedMonth = selected;
        _selectedFilter = ChartFilterType.month;
        _applyFilter();
      });
    }
  }

  Future<void> _pickYear() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Tahun'),
        children: _availableYears
            .map(
              (year) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, year),
                child: Text(year.toString()),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedYear = selected;
        _selectedFilter = ChartFilterType.year;
        _applyFilter();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Grafik Aktivitas Harian'),
      contentPadding: const EdgeInsets.only(top: 12.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==> PERBAIKAN DI SINI <==
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SegmentedButton<ChartFilterType>(
                  segments: const [
                    ButtonSegment(
                      value: ChartFilterType.last30Days,
                      label: Text('30 Hari'),
                    ),
                    ButtonSegment(
                      value: ChartFilterType.month,
                      label: Text('Bulan'),
                    ),
                    ButtonSegment(
                      value: ChartFilterType.year,
                      label: Text('Tahun'),
                    ),
                    ButtonSegment(
                      value: ChartFilterType.range,
                      label: Text('Rentang'),
                    ),
                    ButtonSegment(
                      value: ChartFilterType.allTime,
                      label: Text('Semua'),
                    ),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (newSelection) {
                    final filter = newSelection.first;
                    if (filter == ChartFilterType.last30Days ||
                        filter == ChartFilterType.allTime) {
                      setState(() => _selectedFilter = filter);
                      _applyFilter();
                    } else if (filter == ChartFilterType.month) {
                      _pickMonth();
                    } else if (filter == ChartFilterType.year) {
                      _pickYear();
                    } else if (filter == ChartFilterType.range) {
                      _pickDateRange();
                    }
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: _barWidth > _minBarWidth ? _zoomOut : null,
                    tooltip: 'Perkecil',
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: _barWidth < _maxBarWidth ? _zoomIn : null,
                    tooltip: 'Perbesar',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.maxFinite,
            height: 420,
            child: _filteredLogs.isEmpty
                ? const Center(child: Text('Tidak ada data untuk filter ini.'))
                : Column(
                    children: [
                      if (_mostActiveDay != null)
                        _buildStatRow(
                          context,
                          icon: Icons.whatshot_rounded,
                          color: Colors.orange.shade700,
                          title: 'Hari Terproduktif',
                          date: _mostActiveDay!.date,
                          durationMinutes: _maxMinutes,
                        ),
                      if (_leastActiveDay != null)
                        _buildStatRow(
                          context,
                          icon: Icons.airline_seat_recline_normal_rounded,
                          color: Colors.blue.shade700,
                          title: 'Hari Tersantai',
                          date: _leastActiveDay!.date,
                          durationMinutes: _minMinutes,
                        ),
                      if (_mostActiveDay != null || _leastActiveDay != null)
                        const Divider(height: 24),
                      Expanded(
                        child: DailyActivityChart(
                          logs: _filteredLogs,
                          barWidth: _barWidth,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

Widget _buildStatRow(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required DateTime date,
  required double durationMinutes,
}) {
  final hours = (durationMinutes / 60).floor();
  final minutes = (durationMinutes % 60).round();
  final durationString =
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  final dateString = DateFormat('EEE, d MMM yyyy', 'id_ID').format(date);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text('$title:', style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(
          '$dateString ($durationString jam)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
