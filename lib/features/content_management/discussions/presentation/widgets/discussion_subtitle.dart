// lib/features/content_management/presentation/discussions/widgets/discussion_subtitle.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/discussion_model.dart';
import '../../providers/discussion_provider.dart';
import '../dialogs/discussion_dialogs.dart';
import '../utils/repetition_code_utils.dart';

class DiscussionSubtitle extends StatelessWidget {
  final Discussion discussion;
  final bool isCompact;

  const DiscussionSubtitle({
    super.key,
    required this.discussion,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (discussion.finished) {
      return Text(
        'Selesai pada: ${discussion.finish_date} (100%)',
        style: const TextStyle(
          color: Colors.green,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final displayDate = discussion.effectiveDate;
    final displayCode = discussion.effectiveRepetitionCode;
    final dateText = displayDate ?? 'N/A';
    final codeText = displayCode;

    // HITUNG PERSENTASE INDIVIDUAL DISKUSI
    final int itemPercentage = getProgressPercentageForCode(codeText);

    // DEKLARASI WARNA UNTUK TIAP SEGMEN TANGGAL (BUKAN WARNA CERAH)
    Color yearColor = const Color(0xff556b2f); // Olive tua
    Color monthColor = const Color(0xff4682b4); // Steel Blue kalem
    Color dayColor = const Color(0xff8b4513); // Saddle Brown

    if (displayDate != null) {
      try {
        final discussionDate = DateTime.parse(displayDate);
        final today = DateTime.now();
        // Jika terlambat, buat seluruh segmen menjadi merah gelap/maroon (bukan merah cerah)
        if (discussionDate.isBefore(
          DateTime(today.year, today.month, today.day),
        )) {
          yearColor = const Color(0xff800000);
          monthColor = const Color(0xff800000);
          dayColor = const Color(0xff800000);
        }
      } catch (e) {
        // Biarkan menggunakan warna default
      }
    }

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseFontSize = 10.0;
    final scaledFontSize = baseFontSize * textScaleFactor;

    // FUNGSI HELPER UNTUK MEMECAH PARSING TANGGAL (yyyy-MM-dd)
    List<TextSpan> _buildDateSegments(String dateStr) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return [
          TextSpan(
            text: parts[0],
            style: TextStyle(color: yearColor, fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '-'),
          TextSpan(
            text: parts[1],
            style: TextStyle(color: monthColor, fontWeight: FontWeight.bold),
          ),
          const TextSpan(text: '-'),
          TextSpan(
            text: parts[2],
            style: TextStyle(color: dayColor, fontWeight: FontWeight.bold),
          ),
        ];
      }
      return [
        TextSpan(
          text: dateStr,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: scaledFontSize,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        children: [
          const TextSpan(text: 'Date: '),
          ..._buildDateSegments(dateText),
          const TextSpan(text: ' | Code: '),
          TextSpan(
            text: codeText,
            style: TextStyle(
              color: getColorForRepetitionCode(codeText),
              fontWeight: FontWeight.bold,
              decoration: (!discussion.finished && discussion.points.isEmpty)
                  ? TextDecoration.underline
                  : null,
            ),
            recognizer: (!discussion.finished && discussion.points.isEmpty)
                ? (TapGestureRecognizer()
                    ..onTap = () async {
                      final currentContext = context;
                      final scaffoldMessenger = ScaffoldMessenger.of(
                        currentContext,
                      );
                      final currentCode = discussion.repetitionCode;
                      final currentIndex = getRepetitionCodeIndex(currentCode);
                      if (currentIndex < provider.repetitionCodes.length - 1) {
                        final nextCode =
                            provider.repetitionCodes[currentIndex + 1];
                        final confirmed =
                            await showRepetitionCodeUpdateConfirmationDialog(
                              context: currentContext,
                              currentCode: currentCode,
                              nextCode: nextCode,
                            );
                        if (!currentContext.mounted) return;
                        if (confirmed) {
                          provider.incrementRepetitionCode(discussion);
                          scaffoldMessenger.showSnackBar(
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
          // SEPARASI WARNA PERSEN: Menggunakan Slate/Charcoal Grey kalem (berbeda dari repetition code)
          TextSpan(
            text: ' ($itemPercentage%)',
            style: const TextStyle(
              color: Color(0xff4a5568),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
