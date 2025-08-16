// lib/presentation/pages/3_discussions_page/widgets/discussion_stats_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/discussion_provider.dart';
import '../../statistics_page/widgets/repetition_code_section.dart';

class DiscussionStatsHeader extends StatelessWidget {
  const DiscussionStatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final theme = Theme.of(context);

    final total = provider.totalDiscussionCount;
    final finished = provider.finishedDiscussionCount;
    final codeCounts = provider.repetitionCodeCounts;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ringkasan Subject',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyLarge,
                    children: [
                      const TextSpan(text: 'Total: '),
                      TextSpan(
                        text: '$total',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' ('),
                      TextSpan(
                        text: '$finished ✔',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                  ),
                ),
              ],
            ),
            if (codeCounts.isNotEmpty) ...[
              const Divider(height: 24),
              RepetitionCodeSection(counts: codeCounts),
            ],
          ],
        ),
      ),
    );
  }
}
