// lib/presentation/pages/3_discussions_page/widgets/discussion_stats_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../../../../statistics/presentation/widgets/repetition_code_section.dart';

class DiscussionStatsHeader extends StatefulWidget {
  const DiscussionStatsHeader({super.key});

  @override
  State<DiscussionStatsHeader> createState() => _DiscussionStatsHeaderState();
}

class _DiscussionStatsHeaderState extends State<DiscussionStatsHeader> {
  // --- PERUBAHAN DI SINI ---
  bool _isExpanded = false; // Diubah dari true menjadi false

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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: const PageStorageKey('discussion-stats-header'),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (isExpanded) {
          setState(() {
            _isExpanded = isExpanded;
          });
        },
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Ringkasan Subject',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Pindahkan ringkasan total ke sini agar selalu terlihat
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                if (codeCounts.isNotEmpty) ...[
                  const Divider(height: 16),
                  RepetitionCodeSection(counts: codeCounts),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
