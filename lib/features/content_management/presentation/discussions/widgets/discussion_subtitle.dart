// lib/features/content_management/presentation/discussions/widgets/discussion_subtitle.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../../../../../core/services/storage_service.dart';
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

  // ==> FUNGSI BARU UNTUK MENAMBAHKAN NEURONS <==
  Future<void> _addNeurons(BuildContext context, int amount) async {
    final prefs = SharedPreferencesService();
    // Cukup panggil saveNeurons, karena sekarang methodnya adalah add.
    await prefs.saveNeurons(amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Kamu mendapatkan +$amount Neurons!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

    // >> PERBAIKAN: Logika disederhanakan, langsung menggunakan getter dari model
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
              // ==> Tampilkan garis bawah hanya jika bisa diklik <==
              decoration: (!discussion.finished && discussion.points.isEmpty)
                  ? TextDecoration.underline
                  : null,
            ),
            // ==> Atur recognizer hanya jika bisa diklik <==
            recognizer: (!discussion.finished && discussion.points.isEmpty)
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
                          // ==> TAMBAHKAN NEURONS DI SINI <==
                          _addNeurons(
                            context,
                            5,
                          ); // Beri 5 neuron setiap kali naik level
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
