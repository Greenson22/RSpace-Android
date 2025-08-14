// lib/presentation/pages/statistics_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/statistics_model.dart';
import '../providers/statistics_provider.dart';
import '3_discussions_page/utils/repetition_code_utils.dart'; // DIIMPOR

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<bool> _isPanelExpanded = [];

  @override
  void initState() {
    super.initState();
    // Memuat data statistik saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(
        context,
        listen: false,
      ).generateStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aplikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: () {
              Provider.of<StatisticsProvider>(
                context,
                listen: false,
              ).generateStatistics();
            },
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;

          if (_isPanelExpanded.length != stats.perTopicStats.length) {
            _isPanelExpanded = List<bool>.filled(
              stats.perTopicStats.length,
              false,
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.generateStatistics(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionCard(
                  context,
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
                      valueColor:
                          Theme.of(context).brightness == Brightness.light
                          ? Colors.green.shade800
                          : Colors.green.shade300,
                    ),
                    _buildStatTile(
                      context,
                      'Total Poin Catatan',
                      stats.pointCount.toString(),
                      Icons.notes_outlined,
                    ),
                    // ==> BAGIAN BARU UNTUK REPETITION CODE <==
                    if (stats.repetitionCodeCounts.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildRepetitionCodeSection(
                        context,
                        stats.repetitionCodeCounts,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context,
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
                      valueColor:
                          Theme.of(context).brightness == Brightness.light
                          ? Colors.green.shade800
                          : Colors.green.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (stats.perTopicStats.isNotEmpty)
                  _buildPerTopicSection(context, stats.perTopicStats),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==> WIDGET BARU UNTUK MENAMPILKAN JUMLAH REPETITION CODE <==
  Widget _buildRepetitionCodeSection(
    BuildContext context,
    Map<String, int> counts,
  ) {
    // Mengurutkan map berdasarkan urutan di kRepetitionCodes
    final sortedKeys = counts.keys.toList()
      ..sort(
        (a, b) =>
            getRepetitionCodeIndex(a).compareTo(getRepetitionCodeIndex(b)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah per Kode Repetisi:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sortedKeys.map((code) {
            final count = counts[code]!;
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColorForRepetitionCode(code),
                    fontSize: 12,
                  ),
                ),
              ),
              label: Text(code, style: const TextStyle(color: Colors.white)),
              backgroundColor: getColorForRepetitionCode(code),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPerTopicSection(
    BuildContext context,
    List<TopicStatistics> perTopicStats,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  color: Colors.purple.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistik per Topik',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ExpansionPanelList(
            elevation: 0,
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isPanelExpanded[index] = !isExpanded;
              });
            },
            children: perTopicStats.map<ExpansionPanel>((topicStat) {
              final index = perTopicStats.indexOf(topicStat);
              return ExpansionPanel(
                canTapOnHeader: true,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    leading: Text(
                      topicStat.topicIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      topicStat.topicName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                },
                body: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    children: [
                      _buildStatTile(
                        context,
                        'Jumlah Subjek',
                        topicStat.subjectCount.toString(),
                        Icons.class_outlined,
                        isSubTile: true,
                      ),
                      _buildStatTile(
                        context,
                        'Jumlah Diskusi',
                        topicStat.discussionCount.toString(),
                        Icons.chat_bubble_outline,
                        isSubTile: true,
                      ),
                      _buildStatTile(
                        context,
                        'Total Poin',
                        topicStat.pointCount.toString(),
                        Icons.notes_outlined,
                        isSubTile: true,
                      ),
                    ],
                  ),
                ),
                isExpanded: _isPanelExpanded.isEmpty
                    ? false
                    : _isPanelExpanded[index],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isSubTile = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      visualDensity: isSubTile ? VisualDensity.compact : VisualDensity.standard,
      leading: isSubTile
          ? null
          : Icon(icon, color: theme.textTheme.bodySmall?.color),
      title: Text(
        title,
        style: isSubTile ? const TextStyle(fontSize: 14) : null,
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: isSubTile ? 16 : 18,
          fontWeight: FontWeight.bold,
          color: valueColor ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
