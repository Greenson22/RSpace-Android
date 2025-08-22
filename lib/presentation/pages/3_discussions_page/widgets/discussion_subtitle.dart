// lib/presentation/pages/3_discussions_page/widgets/discussion_subtitle.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../providers/discussion_provider.dart';
import '../dialogs/discussion_dialogs.dart';
import '../utils/repetition_code_utils.dart';

class DiscussionSubtitle extends StatelessWidget {
  final Discussion discussion;
  final bool isCompact; // Properti baru

  const DiscussionSubtitle({
    super.key,
    required this.discussion,
    this.isCompact = false, // Nilai default
  });

  @override
  Widget build(BuildContext context) {
    if (discussion.finished) {
      return Text(
        'Selesai pada: ${discussion.finish_date}',
        style: TextStyle(
          color: Colors.green,
          fontStyle: FontStyle.italic,
          fontSize: isCompact ? 11 : 12,
        ),
      );
    }

    final provider = Provider.of<DiscussionProvider>(context, listen: false);

    final visiblePoints = discussion.points
        .where((point) => provider.doesPointMatchFilter(point))
        .toList();

    String? displayDate;
    String? displayCode;

    if (visiblePoints.isNotEmpty) {
      int minCodeIndex = 999;
      for (var point in visiblePoints) {
        final codeIndex = getRepetitionCodeIndex(point.repetitionCode);
        if (codeIndex < minCodeIndex) {
          minCodeIndex = codeIndex;
        }
      }

      final lowestCodePoints = visiblePoints
          .where(
            (point) =>
                getRepetitionCodeIndex(point.repetitionCode) == minCodeIndex,
          )
          .toList();

      lowestCodePoints.sort((a, b) {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

      if (lowestCodePoints.isNotEmpty) {
        final relevantPoint = lowestCodePoints.first;
        displayDate = relevantPoint.date;
        displayCode = relevantPoint.repetitionCode;
      } else {
        displayDate = discussion.effectiveDate;
        displayCode = discussion.effectiveRepetitionCode;
      }
    } else {
      displayDate = discussion.effectiveDate;
      displayCode = discussion.effectiveRepetitionCode;
    }

    final dateText = displayDate ?? 'N/A';
    final codeText = displayCode ?? 'N/A';
    Color dateColor = Colors.grey;

    if (displayDate != null) {
      try {
        final discussionDate = DateTime.parse(displayDate);
        final today = DateTime.now();
        if (discussionDate.isBefore(
          DateTime(today.year, today.month, today.day),
        )) {
          dateColor = Colors.red;
        } else {
          dateColor = Colors.amber.shade700;
        }
      } catch (e) {
        // Biarkan warna default
      }
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: isCompact ? 11 : 12, // Ukuran font dinamis
        ),
        children: [
          const TextSpan(text: 'Date: '),
          TextSpan(
            text: dateText,
            style: TextStyle(color: dateColor, fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: ' | Code: '),
          TextSpan(
            text: codeText,
            style: TextStyle(
              color: getColorForRepetitionCode(codeText),
              fontWeight: FontWeight.bold,
              // ## PERBAIKAN: Tampilkan underline jika diskusi belum selesai (bisa diklik)
              decoration: !discussion.finished
                  ? TextDecoration.underline
                  : null,
            ),
            // ## PERBAIKAN: Logika recognizer diubah agar selalu aktif jika diskusi belum selesai
            recognizer: !discussion.finished
                ? (TapGestureRecognizer()
                    ..onTap = () async {
                      // Aksi ini akan selalu menargetkan diskusi itu sendiri, bukan point di dalamnya.
                      final currentCode = discussion.repetitionCode;
                      final currentIndex = getRepetitionCodeIndex(currentCode);
                      if (currentIndex < provider.repetitionCodes.length - 1) {
                        final nextCode =
                            provider.repetitionCodes[currentIndex + 1];
                        final confirmed =
                            await showRepetitionCodeUpdateConfirmationDialog(
                              context: context,
                              currentCode: currentCode,
                              nextCode: nextCode,
                            );
                        if (confirmed) {
                          provider.incrementRepetitionCode(discussion);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kode repetisi diubah ke $nextCode.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    })
                : null,
          ),
        ],
      ),
    );
  }
}
