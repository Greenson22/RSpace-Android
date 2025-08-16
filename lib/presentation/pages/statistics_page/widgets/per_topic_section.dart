// lib/presentation/pages/statistics_page/widgets/per_topic_section.dart
import 'package:flutter/material.dart';
import '../../../../data/models/statistics_model.dart';

class PerTopicSection extends StatefulWidget {
  final List<TopicStatistics> perTopicStats;

  const PerTopicSection({super.key, required this.perTopicStats});

  @override
  State<PerTopicSection> createState() => _PerTopicSectionState();
}

class _PerTopicSectionState extends State<PerTopicSection> {
  late List<bool> _isPanelExpanded;

  @override
  void initState() {
    super.initState();
    _isPanelExpanded = List<bool>.filled(widget.perTopicStats.length, false);
  }

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
              setState(() {
                _isPanelExpanded[index] = !isExpanded;
              });
            },
            children: widget.perTopicStats.map<ExpansionPanel>((topicStat) {
              final index = widget.perTopicStats.indexOf(topicStat);
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
                isExpanded: _isPanelExpanded[index],
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
