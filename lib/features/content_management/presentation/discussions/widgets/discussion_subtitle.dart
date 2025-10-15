// lib/features/content_management/presentation/discussions/widgets/discussion_subtitle.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../dialogs/discussion_dialogs.dart';
import '../utils/repetition_code_utils.dart';
import '../../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../../../core/providers/neuron_provider.dart';

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
        'Selesai pada: ${discussion.finish_date}',
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

    // ========== PERBAIKAN UTAMA DI SINI ==========
    // Secara manual menghitung ukuran font berdasarkan skala global.
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseFontSize = 11.0; // Ukuran dasar yang lebih kecil
    final scaledFontSize = baseFontSize * textScaleFactor;

    return RichText(
      text: TextSpan(
        // Terapkan gaya baru di sini
        style: TextStyle(
          fontSize: scaledFontSize,
          color: Theme.of(context).textTheme.bodySmall?.color,
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

                          final reward = getNeuronRewardForCode(nextCode);
                          if (reward > 0) {
                            await Provider.of<NeuronProvider>(
                              currentContext,
                              listen: false,
                            ).addNeurons(reward);
                            showNeuronRewardSnackBar(currentContext, reward);
                          }

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
        ],
      ),
    );
  }
}
