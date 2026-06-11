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

    // ==> PERBAIKAN DI SINI: Menggunakan getter dinamis dari Discussion Model <==
    final int itemPercentage = discussion.completionPercentage.round();

    // DEKLARASI WARNA UNTUK TIAP SEGMEN TANGGAL (BUKAN WARNA CERAH)
    Color yearColor = const Color(0xff556b2f); // Olive tua
    Color monthColor = const Color(0xff8b4513); // Saddle Brown
    Color dayColor = const Color(0xff2f4f4f); // Dark Slate Grey

    // FUNGSI PEMBANTU UNTUK MEMECAH TANGGAL YYYY-MM-DD MENJADI SPANS BERWARNA
    List<TextSpan> buildDateSpans(String dateStr) {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return [
          TextSpan(
            text: parts[0],
            style: TextStyle(color: yearColor),
          ),
          const TextSpan(
            text: '-',
            style: TextStyle(color: Colors.grey),
          ),
          TextSpan(
            text: parts[1],
            style: TextStyle(color: monthColor),
          ),
          const TextSpan(
            text: '-',
            style: TextStyle(color: Colors.grey),
          ),
          TextSpan(
            text: parts[2],
            style: TextStyle(color: dayColor),
          ),
        ];
      }
      return [
        TextSpan(
          text: dateStr,
          style: const TextStyle(color: Colors.black87),
        ),
      ];
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: isCompact ? 11.0 : 13.0,
          color: Colors.black87,
        ),
        children: [
          ...buildDateSpans(dateText),
          const TextSpan(text: ' • '),
          TextSpan(
            text: codeText,
            style: TextStyle(
              color: getColorForRepetitionCode(codeText),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = (() async {
                final currentContext = context;
                final scaffoldMessenger = ScaffoldMessenger.of(currentContext);

                // Mencegah interaksi jika diskusi memiliki anak poin
                if (discussion.points.isNotEmpty) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ubah kode melalui poin-poin di dalam diskusi ini.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final currentCode = discussion.repetitionCode;
                final currentIndex = provider.repetitionCodes.indexOf(
                  currentCode,
                );

                if (currentIndex < provider.repetitionCodes.length - 1) {
                  final nextCode = provider.repetitionCodes[currentIndex + 1];
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
                        content: Text('Kode repetisi diubah ke $nextCode.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }),
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
