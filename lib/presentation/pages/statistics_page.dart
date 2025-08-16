// lib/presentation/pages/statistics_page.dart

import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
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

          return RefreshIndicator(
            onRefresh: () => provider.generateStatistics(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SummaryCard(
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
                    if (stats.repetitionCodeCounts.isNotEmpty) ...[
                      const Divider(height: 24),
                      RepetitionCodeSection(counts: stats.repetitionCodeCounts),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SummaryCard(
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
                  PerTopicSection(perTopicStats: stats.perTopicStats),
              ],
            ),
          );
        },
      ),
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
