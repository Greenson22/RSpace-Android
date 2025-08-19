// lib/presentation/pages/time_log_page/widgets/daily_activity_chart.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/time_log_model.dart';

class DailyActivityChart extends StatefulWidget {
  final List<TimeLogEntry> logs;

  const DailyActivityChart({super.key, required this.logs});

  @override
  State<DailyActivityChart> createState() => _DailyActivityChartState();
}

class _DailyActivityChartState extends State<DailyActivityChart> {
  final Map<String, Color> _taskColors = {};
  late List<String> _allTaskNames;
  late double _maxHours;

  @override
  void initState() {
    super.initState();
    _prepareChartData();
  }

  void _prepareChartData() {
    final allTasks = <String>{};
    double maxMinutes = 0;

    for (final log in widget.logs) {
      double dailyTotalMinutes = 0;
      for (final task in log.tasks) {
        allTasks.add(task.name);
        dailyTotalMinutes += task.durationMinutes;
      }
      if (dailyTotalMinutes > maxMinutes) {
        maxMinutes = dailyTotalMinutes;
      }
    }

    _allTaskNames = allTasks.toList();
    // Bulatkan jam maksimal ke atas agar grafik terlihat bagus
    _maxHours = (maxMinutes / 60).ceilToDouble();
    if (_maxHours == 0) _maxHours = 1; // Hindari pembagian dengan nol

    // Buat warna yang konsisten untuk setiap nama tugas
    for (final taskName in _allTaskNames) {
      _taskColors[taskName] = _generateColor(taskName);
    }
  }

  Color _generateColor(String text) {
    // Fungsi hash sederhana untuk menghasilkan warna dari sebuah string
    final hash = text.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromRGBO(r, g, b, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: widget.logs.map((log) {
                  return _buildBar(context, log);
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildBar(BuildContext context, TimeLogEntry log) {
    final totalMinutes = log.tasks.fold<double>(
      0,
      (sum, task) => sum + task.durationMinutes,
    );
    final totalHours = totalMinutes / 60.0;

    // Tinggi bar dihitung berdasarkan rasio jam hari ini dengan jam maksimal
    final barHeight = 200.0 * (totalHours / _maxHours);

    final stackChildren = <Widget>[];
    double accumulatedHeight = 0;

    // Urutkan task berdasarkan durasi untuk tampilan tumpukan yang lebih baik
    final sortedTasks = List<LoggedTask>.from(log.tasks)
      ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));

    for (final task in sortedTasks) {
      final taskHours = task.durationMinutes / 60.0;
      final segmentHeight = 200.0 * (taskHours / _maxHours);
      if (segmentHeight > 0) {
        stackChildren.add(
          Positioned(
            bottom: accumulatedHeight,
            child: Tooltip(
              message: '${task.name}: ${task.durationMinutes} menit',
              child: Container(
                width: 40,
                height: segmentHeight,
                color: _taskColors[task.name],
              ),
            ),
          ),
        );
      }
      accumulatedHeight += segmentHeight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            totalHours.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: max(barHeight, 0), // Pastikan tinggi tidak negatif
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Stack(children: stackChildren),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM').format(log.date),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _allTaskNames.map((name) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: _taskColors[name]),
                const SizedBox(width: 4),
                Text(name, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
