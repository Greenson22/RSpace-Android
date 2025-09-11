// lib/features/webview_page/presentation/dialogs/discussion_details_dialog.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/add_point_dialog.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/confirmation_dialogs.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:my_aplication/core/providers/neuron_provider.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

void showDiscussionDetailsDialog(BuildContext context, Discussion discussion) {
  final discussionProvider = Provider.of<DiscussionProvider>(
    context,
    listen: false,
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final sortedPoints = List<Point>.from(discussion.points);

          sortedPoints.sort((a, b) {
            switch (discussionProvider.sortType) {
              case 'name':
                return a.pointText.toLowerCase().compareTo(
                  b.pointText.toLowerCase(),
                );
              case 'code':
                return getRepetitionCodeIndex(
                  a.repetitionCode,
                ).compareTo(getRepetitionCodeIndex(b.repetitionCode));
              default: // date
                final dateA = DateTime.tryParse(a.date);
                final dateB = DateTime.tryParse(b.date);
                if (dateA == null && dateB == null) return 0;
                if (dateA == null)
                  return discussionProvider.sortAscending ? 1 : -1;
                if (dateB == null)
                  return discussionProvider.sortAscending ? -1 : 1;
                return dateA.compareTo(dateB);
            }
          });

          if (!discussionProvider.sortAscending) {
            final reversedList = sortedPoints.reversed.toList();
            sortedPoints.clear();
            sortedPoints.addAll(reversedList);
          }

          Widget buildCodeWidget({
            required dynamic item,
            required bool isActive,
          }) {
            final isPoint = item is Point;
            final currentCode = isPoint
                ? item.repetitionCode
                : discussion.repetitionCode;
            final textColor = isActive
                ? getColorForRepetitionCode(currentCode)
                : Colors.grey;

            if (!isActive || (isPoint && item.finished)) {
              return RichText(
                text: TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  children: [
                    const TextSpan(text: 'Kode Repetisi: '),
                    TextSpan(
                      text: currentCode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }

            return RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Kode Repetisi: '),
                  TextSpan(
                    text: currentCode,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final currentIndex = getRepetitionCodeIndex(
                          currentCode,
                        );
                        if (currentIndex <
                            discussionProvider.repetitionCodes.length - 1) {
                          final nextCode = discussionProvider
                              .repetitionCodes[currentIndex + 1];

                          final confirmed =
                              await showRepetitionCodeUpdateConfirmationDialog(
                                context: context,
                                currentCode: currentCode,
                                nextCode: nextCode,
                              );

                          if (confirmed && context.mounted) {
                            discussionProvider.incrementRepetitionCode(item);

                            final reward = getNeuronRewardForCode(nextCode);
                            if (reward > 0) {
                              await Provider.of<NeuronProvider>(
                                context,
                                listen: false,
                              ).addNeurons(reward);
                              showNeuronRewardSnackBar(context, reward);
                            }
                            showAppSnackBar(
                              context,
                              'Kode diubah ke $nextCode.',
                            );

                            setDialogState(() {});
                          }
                        }
                      },
                  ),
                ],
              ),
            );
          }

          return AlertDialog(
            title: const Text('Detail & Poin Diskusi'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.discussion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Jadwal Tinjau: ${discussion.effectiveDate ?? "N/A"}'),
                    const SizedBox(height: 8),
                    if (discussion.points.isEmpty)
                      buildCodeWidget(
                        item: discussion,
                        isActive: !discussion.finished,
                      ),

                    if (discussion.points.isNotEmpty) const Divider(height: 32),

                    if (discussion.points.isNotEmpty)
                      ...sortedPoints.map((point) {
                        final bool isActive = discussionProvider
                            .doesPointMatchFilter(point);
                        final Color textColor = (isActive && !point.finished)
                            ? Theme.of(context).textTheme.bodyLarge!.color!
                            : Colors.grey;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${point.pointText}',
                                style: TextStyle(
                                  color: textColor,
                                  decoration: point.finished
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '  Jadwal: ${point.date}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: textColor),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: buildCodeWidget(
                                  item: point,
                                  isActive: isActive,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            // --- PERBAIKAN DI SINI ---
            // Pindahkan 'actions' ke level AlertDialog, bukan di dalam content
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tambah Poin'),
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Future.delayed(Duration.zero, () {
                    showAddPointDialog(
                      context: context,
                      discussion: discussion,
                      title: 'Tambah Poin Baru',
                      label: 'Teks Poin',
                      onSave: (text, repetitionCode) {
                        discussionProvider.addPoint(
                          discussion,
                          text,
                          repetitionCode: repetitionCode,
                        );
                        showAppSnackBar(context, 'Poin berhasil ditambahkan.');
                      },
                    );
                  });
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    },
  );
}
