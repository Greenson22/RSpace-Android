// lib/features/content_management/presentation/discussions/widgets/discussion_stats_header.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/discussion_provider.dart';
import '../utils/repetition_code_utils.dart';

class DiscussionStatsHeader extends StatefulWidget {
  final Color themeColor;
  const DiscussionStatsHeader({super.key, required this.themeColor});

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

    // ==> PERUBAHAN UTAMA: Perhitungan Progress Berdasarkan Akumulasi Bobot Kode <==
    double totalMaxWeight = total * 100.0;
    double currentActualWeight = 0.0;

    for (var discussion in provider.allDiscussions) {
      final code = discussion.effectiveRepetitionCode;
      currentActualWeight += getProgressPercentageForCode(code);
    }

    final double completionPercentage = totalMaxWeight > 0
        ? (currentActualWeight / totalMaxWeight).clamp(0.0, 1.0)
        : 0.0;

    final int displaySubjectPercent = (completionPercentage * 100).round();

    // Menghitung jumlah rincian kode repetisi secara dinamis
    final Map<String, int> codeCounts = {};
    for (var discussion in provider.allDiscussions) {
      final code = discussion.repetitionCode ?? 'Tanpa Kode';
      if (discussion.finished == true) {
        codeCounts['Finish'] = (codeCounts['Finish'] ?? 0) + 1;
      } else {
        codeCounts[code] = (codeCounts[code] ?? 0) + 1;
      }
    }

    final sortedKeys = codeCounts.keys.toList()
      ..sort((a, b) {
        if (a == 'Finish') return 1;
        if (b == 'Finish') return -1;
        return a.compareTo(b);
      });

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.themeColor.withOpacity(0.2), width: 1.5),
      ),
      color: widget.themeColor.withOpacity(0.03),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          iconTheme: theme.iconTheme.copyWith(size: 24.0),
        ),
        child: ExpansionTile(
          key: const PageStorageKey('discussion-stats-header'),
          initiallyExpanded: _isExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 2.0,
          ),
          onExpansionChanged: (isExpanded) {
            setState(() {
              _isExpanded = isExpanded;
            });
          },
          iconColor: widget.themeColor,
          collapsedIconColor: widget.themeColor.withOpacity(0.7),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ringkasan Subject ($displaySubjectPercent%)', // Menampilkan persentase total subjek
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: widget.themeColor,
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.0,
                      ),
                      children: [
                        const TextSpan(text: 'Total: '),
                        TextSpan(
                          text: '$total',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' ('),
                        TextSpan(
                          text: '$finished Selesai',
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
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completionPercentage,
                  backgroundColor: widget.themeColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionPercentage == 1.0
                        ? Colors.green.shade600
                        : widget.themeColor,
                  ),
                  minHeight: 6,
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
                padding: const EdgeInsets.fromLTRB(14.0, 4.0, 14.0, 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      height: 12,
                      color: widget.themeColor.withOpacity(0.15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 14,
                          color: widget.themeColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rincian Status Repetisi:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: sortedKeys.map((code) {
                        final count = codeCounts[code] ?? 0;
                        final isFinishType = code == 'Finish';
                        final Color codeColor = isFinishType
                            ? Colors.green.shade700
                            : getColorForRepetitionCode(code);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: codeColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: codeColor.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: '$code ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: codeColor,
                                  ),
                                ),
                                TextSpan(
                                  text: '$count',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color
                                        ?.withOpacity(0.8),
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
