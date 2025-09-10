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
        style: TextStyle(
          color: Colors.green,
          fontStyle: FontStyle.italic,
          fontSize: isCompact ? 11 : 12,
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

    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: isCompact ? 11 : 12),
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
                      // ==> PERBAIKAN DIMULAI DI SINI <==
                      // 1. Simpan context sebelum await
                      final currentContext = context;
                      final scaffoldMessenger = ScaffoldMessenger.of(
                        currentContext,
                      );

                      final currentCode = discussion.repetitionCode;
                      final currentIndex = getRepetitionCodeIndex(currentCode);
                      if (currentIndex < provider.repetitionCodes.length - 1) {
                        final nextCode =
                            provider.repetitionCodes[currentIndex + 1];

                        // 2. Lakukan operasi async (await)
                        final confirmed =
                            await showRepetitionCodeUpdateConfirmationDialog(
                              context: currentContext,
                              currentCode: currentCode,
                              nextCode: nextCode,
                            );

                        // 3. Setelah await, cek apakah widget masih mounted
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
                      // ==> PERBAIKAN SELESAI <==
                    })
                : null,
          ),
        ],
      ),
    );
  }
}
