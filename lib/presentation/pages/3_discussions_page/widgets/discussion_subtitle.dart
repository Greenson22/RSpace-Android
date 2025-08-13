import 'package:flutter/material.dart';
import '../../../../data/models/discussion_model.dart';
import '../utils/repetition_code_utils.dart';

class DiscussionSubtitle extends StatelessWidget {
  final Discussion discussion;

  const DiscussionSubtitle({super.key, required this.discussion});

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

    // ==> MENGGUNAKAN GETTER EFEKTIF <==
    final dateText = discussion.effectiveDate ?? 'N/A';
    final codeText = discussion.effectiveRepetitionCode;
    Color dateColor = Colors.grey;

    if (discussion.effectiveDate != null) {
      try {
        final discussionDate = DateTime.parse(discussion.effectiveDate!);
        final today = DateTime.now();
        if (discussionDate.isBefore(today.subtract(const Duration(days: -1)))) {
          dateColor = Colors.red;
        } else {
          dateColor = Colors.amber.shade700;
        }
      } catch (e) {
        // Biarkan warna default jika parsing gagal
      }
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
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
            ),
          ),
        ],
      ),
    );
  }
}
