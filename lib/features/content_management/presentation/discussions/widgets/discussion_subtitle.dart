// lib/presentation/pages/3_discussions_page/widgets/discussion_subtitle.dart
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
    final currentNeurons = await prefs.loadNeurons();
    await prefs.saveNeurons(currentNeurons + amount);

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

    final visiblePoints = discussion.points
        .where((point) => provider.doesPointMatchFilter(point))
        .toList();

    String? displayDate;
    String? displayCode;

    if (visiblePoints.isNotEmpty) {
      // #############################################
      // ### LOGIKA PEMBARUAN DIMULAI DI SINI ###
      // #############################################

      // Langkah 1: Cek apakah ada poin yang memiliki kode selain R0D
      final hasNonR0DPoints = visiblePoints.any(
        (point) =>
            point.repetitionCode != 'R0D' && point.repetitionCode != 'Finish',
      );

      List<Point> pointsToConsider = [];
      if (hasNonR0DPoints) {
        // Jika ada, hanya ambil poin yang bukan R0D
        pointsToConsider = visiblePoints
            .where(
              (point) =>
                  point.repetitionCode != 'R0D' &&
                  point.repetitionCode != 'Finish',
            )
            .toList();
      } else {
        // Jika tidak, ambil semua poin yang terlihat (hanya R0D)
        pointsToConsider = visiblePoints
            .where((point) => point.repetitionCode != 'Finish')
            .toList();
      }

      // Jika setelah pemfilteran list kosong (misal semua poin R0D sudah selesai)
      if (pointsToConsider.isEmpty) {
        // Fallback ke diskusi itu sendiri
        displayDate = discussion.effectiveDate;
        displayCode = discussion.effectiveRepetitionCode;
      } else {
        // Langkah 2: Temukan kode repetisi terkecil dari poin yang tersisa
        int minCodeIndex = 999;
        for (var point in pointsToConsider) {
          final codeIndex = getRepetitionCodeIndex(point.repetitionCode);
          if (codeIndex < minCodeIndex) {
            minCodeIndex = codeIndex;
          }
        }

        // Langkah 3: Ambil semua poin dengan kode repetisi terkecil tersebut
        final lowestCodePoints = pointsToConsider
            .where(
              (point) =>
                  getRepetitionCodeIndex(point.repetitionCode) == minCodeIndex,
            )
            .toList();

        // Langkah 4: Urutkan berdasarkan tanggal untuk mendapatkan poin yang paling mendesak
        lowestCodePoints.sort((a, b) {
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });

        // Langkah 5: Tampilkan informasi dari poin yang paling mendesak
        if (lowestCodePoints.isNotEmpty) {
          final relevantPoint = lowestCodePoints.first;
          displayDate = relevantPoint.date;
          displayCode = relevantPoint.repetitionCode;
        } else {
          // Fallback ke diskusi itu sendiri jika tidak ada poin yang relevan
          displayDate = discussion.effectiveDate;
          displayCode = discussion.effectiveRepetitionCode;
        }
      }

      // #############################################
      // ### LOGIKA PEMBARUAN SELESAI DI SINI ###
      // #############################################
    } else {
      displayDate = discussion.effectiveDate;
      displayCode = discussion.effectiveRepetitionCode;
    }

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
