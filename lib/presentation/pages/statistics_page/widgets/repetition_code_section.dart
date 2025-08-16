// lib/presentation/pages/statistics_page/widgets/repetition_code_section.dart
import 'package:flutter/material.dart';
import '../../3_discussions_page/utils/repetition_code_utils.dart';

class RepetitionCodeSection extends StatelessWidget {
  final Map<String, int> counts;

  const RepetitionCodeSection({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    // Mengurutkan map berdasarkan urutan di kRepetitionCodes
    final sortedKeys = counts.keys.toList()
      ..sort(
        (a, b) =>
            getRepetitionCodeIndex(a).compareTo(getRepetitionCodeIndex(b)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah per Kode Repetisi:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: sortedKeys.map((code) {
            final count = counts[code]!;
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getColorForRepetitionCode(code),
                    fontSize: 12,
                  ),
                ),
              ),
              label: Text(code, style: const TextStyle(color: Colors.white)),
              backgroundColor: getColorForRepetitionCode(code),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }
}
