// lib/presentation/pages/statistics_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/data/models/statistics_model.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import 'statistics_page/widgets/per_topic_section.dart';
import 'statistics_page/widgets/repetition_code_section.dart';
import 'statistics_page/widgets/summary_card.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FocusNode _focusNode = FocusNode();
  int _focusedTopicIndex = -1;
  Timer? _focusTimer;
  bool _isKeyboardActive = false;
  final ScrollController _scrollController = ScrollController();
  late List<bool> _isPanelExpanded = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      // Panggil generateStatistics dan kemudian update state panel
      provider.generateStatistics().then((_) {
        if (mounted) {
          setState(() {
            _isPanelExpanded = List<bool>.filled(
              provider.stats.perTopicStats.length,
              false,
            );
          });
        }
      });
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final provider = Provider.of<StatisticsProvider>(context, listen: false);
      final totalTopics = provider.stats.perTopicStats.length;

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isKeyboardActive = false);
        });

        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          // Jika ada topik dan fokus belum di item terakhir
          if (totalTopics > 0 && _focusedTopicIndex < totalTopics - 1) {
            setState(() => _focusedTopicIndex++);
          } else {
            // Jika tidak, scroll ke bawah
            _scrollController.animateTo(
              _scrollController.offset + 100,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          // Jika fokus ada di salah satu topik
          if (_focusedTopicIndex > -1) {
            setState(() => _focusedTopicIndex--);
          } else {
            // Jika tidak, scroll ke atas
            _scrollController.animateTo(
              _scrollController.offset - 100,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        // Buka/tutup panel jika salah satu topik sedang fokus
        if (_focusedTopicIndex >= 0 && _focusedTopicIndex < totalTopics) {
          setState(() {
            _isPanelExpanded[_focusedTopicIndex] =
                !_isPanelExpanded[_focusedTopicIndex];
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<StatisticsProvider>(context, listen: false);
    await provider.generateStatistics();
    if (mounted) {
      setState(() {
        // Reset state panel dan fokus setelah data diperbarui
        _isPanelExpanded = List<bool>.filled(
          provider.stats.perTopicStats.length,
          false,
        );
        _focusedTopicIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistik Aplikasi'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Perbarui Data',
              onPressed: _refreshData,
            ),
          ],
        ),
        body: Consumer<StatisticsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = provider.stats;
            // Pastikan _isPanelExpanded diinisialisasi ulang jika data berubah
            if (stats.perTopicStats.isNotEmpty &&
                _isPanelExpanded.length != stats.perTopicStats.length) {
              _isPanelExpanded = List<bool>.filled(
                stats.perTopicStats.length,
                false,
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double breakpoint = 800.0;
                  if (constraints.maxWidth > breakpoint) {
                    return _buildDesktopLayout(stats);
                  } else {
                    return _buildMobileLayout(stats);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AppStatistics stats) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildContentSummary(stats),
        const SizedBox(height: 16),
        _buildTaskSummary(stats),
        const SizedBox(height: 16),
        if (stats.perTopicStats.isNotEmpty)
          PerTopicSection(
            perTopicStats: stats.perTopicStats,
            focusedIndex: _isKeyboardActive ? _focusedTopicIndex : -1,
            isPanelExpanded: _isPanelExpanded,
            onExpansionChanged: (index, isExpanded) {
              setState(() {
                _isPanelExpanded[index] = isExpanded;
              });
            },
          ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppStatistics stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildContentSummary(stats),
                const SizedBox(height: 16),
                _buildTaskSummary(stats),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            // Gunakan SingleChildScrollView di sini agar bisa di-scroll terpisah
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  if (stats.perTopicStats.isNotEmpty)
                    PerTopicSection(
                      perTopicStats: stats.perTopicStats,
                      focusedIndex: _isKeyboardActive ? _focusedTopicIndex : -1,
                      isPanelExpanded: _isPanelExpanded,
                      onExpansionChanged: (index, isExpanded) {
                        setState(() {
                          _isPanelExpanded[index] = isExpanded;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SummaryCard _buildContentSummary(AppStatistics stats) {
    return SummaryCard(
      title: 'Ringkasan Konten',
      icon: Icons.pie_chart,
      color: Colors.blue.shade700,
      children: [
        _buildStatTile(
          context,
          'Total Topik',
          stats.topicCount.toString(),
          Icons.topic_outlined,
        ),
        _buildStatTile(
          context,
          'Total Subjek',
          stats.subjectCount.toString(),
          Icons.class_outlined,
        ),
        _buildStatTile(
          context,
          'Total Diskusi',
          stats.discussionCount.toString(),
          Icons.chat_bubble_outline,
        ),
        _buildStatTile(
          context,
          'Diskusi Selesai',
          stats.finishedDiscussionCount.toString(),
          Icons.check_circle_outline,
          valueColor: Theme.of(context).brightness == Brightness.light
              ? Colors.green.shade800
              : Colors.green.shade300,
        ),
        _buildStatTile(
          context,
          'Total Poin Catatan',
          stats.pointCount.toString(),
          Icons.notes_outlined,
        ),
        if (stats.repetitionCodeCounts.isNotEmpty) ...[
          const Divider(height: 24),
          RepetitionCodeSection(counts: stats.repetitionCodeCounts),
        ],
      ],
    );
  }

  SummaryCard _buildTaskSummary(AppStatistics stats) {
    return SummaryCard(
      title: 'Ringkasan Tugas',
      icon: Icons.task_alt_outlined,
      color: Colors.orange.shade700,
      children: [
        _buildStatTile(
          context,
          'Total Kategori Tugas',
          stats.taskCategoryCount.toString(),
          Icons.category_outlined,
        ),
        _buildStatTile(
          context,
          'Total Tugas',
          stats.taskCount.toString(),
          Icons.list_alt_outlined,
        ),
        _buildStatTile(
          context,
          'Tugas Selesai',
          stats.completedTaskCount.toString(),
          Icons.task_alt,
          valueColor: Theme.of(context).brightness == Brightness.light
              ? Colors.green.shade800
              : Colors.green.shade300,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      visualDensity: VisualDensity.standard,
      leading: Icon(icon, color: theme.textTheme.bodySmall?.color),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: valueColor ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
