// lib/features/content_management/presentation/discussions/widgets/discussion_stats_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/discussion_provider.dart';
import '../../discussions/utils/repetition_code_utils.dart'; // Digunakan untuk mewarnai kode repetisi

class DiscussionStatsHeader extends StatefulWidget {
  const DiscussionStatsHeader({super.key});

  @override
  State<DiscussionStatsHeader> createState() => _DiscussionStatsHeaderState();
}

class _DiscussionStatsHeaderState extends State<DiscussionStatsHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: true);
    final theme = Theme.of(context);

    final total = provider.totalDiscussionCount;
    final finished = provider.finishedDiscussionCount;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    // ==> HITUNG JUMLAH KODE REPETISI SECARA DINAMIS <==
    final Map<String, int> codeCounts = {};
    for (var discussion in provider.allDiscussions) {
      final code = discussion.repetitionCode ?? 'Tanpa Kode';

      // PERBAIKAN: Menggunakan properti 'finished' yang valid sesuai skema model data proyek Anda
      if (discussion.finished == true) {
        codeCounts['Finish'] = (codeCounts['Finish'] ?? 0) + 1;
      } else {
        codeCounts[code] = (codeCounts[code] ?? 0) + 1;
      }
    }

    // Mengurutkan kunci agar R0D, R7D, dst tampil rapi (Finish dataruh paling belakang)
    final sortedKeys = codeCounts.keys.toList()
      ..sort((a, b) {
        if (a == 'Finish') return 1;
        if (b == 'Finish') return -1;
        return a.compareTo(b);
      });

    return Card(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey('discussion-stats-header'),
          initiallyExpanded: _isExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 0.0,
          ),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12.0),
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
            if (sortedKeys.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Tidak ada rincian kode repetisi.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 8, color: Colors.black12),
                    const SizedBox(height: 4),
                    Text(
                      'Rincian Status Repetisi:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: sortedKeys.map((code) {
                        final count = codeCounts[code] ?? 0;
                        final isFinishType = code == 'Finish';

                        final Color codeColor = isFinishType
                            ? Colors.green.shade700
                            : getColorForRepetitionCode(code);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: codeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: codeColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 12),
                              children: [
                                TextSpan(
                                  text: '$code: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: codeColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
