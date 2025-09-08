// lib/presentation/pages/statistics_page/widgets/per_topic_section.dart
import 'package:flutter/material.dart';
import '../../domain/models/statistics_model.dart';

class PerTopicSection extends StatelessWidget {
  final List<TopicStatistics> perTopicStats;
  final int focusedIndex;
  final List<bool> isPanelExpanded;
  final Function(int, bool) onExpansionChanged;

  const PerTopicSection({
    super.key,
    required this.perTopicStats,
    this.focusedIndex = -1,
    required this.isPanelExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              // PERBAIKAN: Nilai 'isExpanded' dari callback harus langsung digunakan.
              // Sebelumnya: onExpansionChanged(index, !isExpanded);
              onExpansionChanged(index, isExpanded);
            },
            children: perTopicStats.map<ExpansionPanel>((topicStat) {
              final index = perTopicStats.indexOf(topicStat);
              final bool isFocused = index == focusedIndex;

              return ExpansionPanel(
                backgroundColor: isFocused
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : null,
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
                isExpanded:
                    isPanelExpanded.isNotEmpty && index < isPanelExpanded.length
                    ? isPanelExpanded[index]
                    : false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
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
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
