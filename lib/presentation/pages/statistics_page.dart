// lib/presentation/pages/statistics_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider dibuat di sini agar data selalu segar setiap kali halaman dibuka
    return ChangeNotifierProvider(
      create: (_) => StatisticsProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Statistik Aplikasi')),
        body: Consumer<StatisticsProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = provider.stats;
            final theme = Theme.of(context);

            return RefreshIndicator(
              onRefresh: () => provider.generateStatistics(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionCard(
                    context,
                    title: 'Konten Pembelajaran',
                    icon: Icons.school_outlined,
                    color: Colors.blue.shade700,
                    children: [
                      _buildStatTile(
                        context,
                        'Jumlah Topik',
                        stats.topicCount.toString(),
                        Icons.topic_outlined,
                      ),
                      _buildStatTile(
                        context,
                        'Jumlah Subjek',
                        stats.subjectCount.toString(),
                        Icons.class_outlined,
                      ),
                      _buildStatTile(
                        context,
                        'Jumlah Diskusi',
                        stats.discussionCount.toString(),
                        Icons.chat_bubble_outline,
                      ),
                      _buildStatTile(
                        context,
                        'Diskusi Selesai',
                        stats.finishedDiscussionCount.toString(),
                        Icons.check_circle_outline,
                        valueColor: theme.brightness == Brightness.light
                            ? Colors.green.shade800
                            : Colors.green.shade300,
                      ),
                      _buildStatTile(
                        context,
                        'Total Poin Catatan',
                        stats.pointCount.toString(),
                        Icons.notes_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    context,
                    title: 'Tugas (My Tasks)',
                    icon: Icons.task_alt_outlined,
                    color: Colors.orange.shade700,
                    children: [
                      _buildStatTile(
                        context,
                        'Jumlah Kategori Tugas',
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
                        valueColor: theme.brightness == Brightness.light
                            ? Colors.green.shade800
                            : Colors.green.shade300,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
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
  }) {
    final theme = Theme.of(context);
    return ListTile(
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
