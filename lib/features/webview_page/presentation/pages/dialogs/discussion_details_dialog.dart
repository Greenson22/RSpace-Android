// lib/features/webview_page/presentation/pages/dialogs/discussion_details_dialog.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/discussions/providers/discussion_provider.dart';
import 'package:my_aplication/features/content_management/discussions/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/discussions/presentation/dialogs/confirmation_dialogs.dart';
import 'package:my_aplication/features/content_management/discussions/presentation/utils/repetition_code_utils.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

void showDiscussionDetailsDialog(
  BuildContext context,
  Discussion initialDiscussion,
) {
  // Ambil provider yang aktif di WebViewPage saat ini
  final discussionProvider = Provider.of<DiscussionProvider>(
    context,
    listen: false,
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      // Menyediakan provider aktif ke dalam context dialog baru agar terhindar dari ProviderNotFoundError
      return ChangeNotifierProvider.value(
        value: discussionProvider,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            // Gunakan Consumer internal agar UI otomatis mendengarkan perubahan kode repetisi
            return Consumer<DiscussionProvider>(
              builder: (context, provider, child) {
                // Mencari diskusi berdasarkan hashCode karena model tidak menggunakan properti id
                final discussion = provider.allDiscussions.firstWhere(
                  (d) => d.hashCode == initialDiscussion.hashCode,
                  orElse: () => initialDiscussion,
                );

                // Lakukan sorting poin secara real-time
                final sortedPoints = List<Point>.from(discussion.points);
                sortedPoints.sort((a, b) {
                  switch (provider.sortType) {
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
                      if (dateA == null) return provider.sortAscending ? 1 : -1;
                      if (dateB == null) return provider.sortAscending ? -1 : 1;
                      return dateA.compareTo(dateB);
                  }
                });

                if (!provider.sortAscending) {
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
                                  provider.repetitionCodes.length - 1) {
                                final nextCode =
                                    provider.repetitionCodes[currentIndex + 1];
                                final confirmed =
                                    await showRepetitionCodeUpdateConfirmationDialog(
                                      context: context,
                                      currentCode: currentCode,
                                      nextCode: nextCode,
                                    );

                                if (confirmed && context.mounted) {
                                  // Update kode melalui provider
                                  if (isPoint) {
                                    provider.updatePointCode(item, nextCode);
                                  } else {
                                    provider.updateDiscussionCode(
                                      discussion,
                                      nextCode,
                                    );
                                  }

                                  showAppSnackBar(
                                    context,
                                    'Kode diubah ke $nextCode.',
                                  );
                                }
                              }
                            },
                        ),
                      ],
                    ),
                  );
                }

                final bool isDiscussionActive = provider
                    .doesDiscussionMatchFilter(discussion);

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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDiscussionActive ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Jadwal Tinjau: ${discussion.effectiveDate ?? "N/A"}',
                            style: TextStyle(
                              color: isDiscussionActive ? null : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (discussion.points.isEmpty)
                            buildCodeWidget(
                              item: discussion,
                              isActive:
                                  !discussion.finished && isDiscussionActive,
                            ),
                          if (discussion.points.isNotEmpty)
                            const Divider(height: 32),
                          if (discussion.points.isNotEmpty)
                            ...sortedPoints.map((point) {
                              final bool isActive = provider
                                  .doesPointMatchFilter(point);
                              final Color textColor =
                                  (isActive && !point.finished)
                                  ? Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.color!
                                  : Colors.grey;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '  ${point.pointText}',
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
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
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Tutup'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}
