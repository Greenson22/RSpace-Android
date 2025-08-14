import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../providers/discussion_provider.dart';
import '../utils/repetition_code_utils.dart';

class DiscussionSubtitle extends StatelessWidget {
  final Discussion discussion;

  const DiscussionSubtitle({super.key, required this.discussion});

  @override
  Widget build(BuildContext context) {
    // Jika diskusi sudah selesai, tampilkan tanggal selesai.
    if (discussion.finished) {
      return Text(
        'Selesai pada: ${discussion.finish_date}',
        style: const TextStyle(
          color: Colors.green,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Ambil provider untuk mendapatkan pengaturan filter.
    final provider = Provider.of<DiscussionProvider>(context, listen: false);

    // Filter points yang sesuai dengan kriteria filter aktif.
    final visiblePoints = discussion.points
        .where((point) => provider.doesPointMatchFilter(point))
        .toList();

    String? displayDate;
    String? displayCode;

    // === LOGIKA BARU DENGAN PRIORITAS TANGGAL TERTUA ===
    if (visiblePoints.isNotEmpty) {
      // 1. Temukan repetition code terendah di antara point yang terlihat.
      int minCodeIndex = 999;
      for (var point in visiblePoints) {
        final codeIndex = getRepetitionCodeIndex(point.repetitionCode);
        if (codeIndex < minCodeIndex) {
          minCodeIndex = codeIndex;
        }
      }

      // 2. Saring lagi untuk mendapatkan semua point dengan code terendah itu.
      final lowestCodePoints = visiblePoints
          .where(
            (point) =>
                getRepetitionCodeIndex(point.repetitionCode) == minCodeIndex,
          )
          .toList();

      // 3. Urutkan kelompok point tersebut berdasarkan tanggal (tertua ke terbaru).
      lowestCodePoints.sort((a, b) {
        final dateA = DateTime.tryParse(a.date);
        final dateB = DateTime.tryParse(b.date);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1; // Pindahkan null ke akhir
        if (dateB == null) return -1; // Pindahkan null ke akhir
        return dateA.compareTo(dateB); // Ascending (tertua dulu)
      });

      // 4. Ambil point pertama (yang paling relevan) dari daftar yang sudah diurutkan.
      if (lowestCodePoints.isNotEmpty) {
        final relevantPoint = lowestCodePoints.first;
        displayDate = relevantPoint.date;
        displayCode = relevantPoint.repetitionCode;
      } else {
        // Fallback jika terjadi kasus aneh, meskipun seharusnya tidak terjadi.
        displayDate = discussion.effectiveDate;
        displayCode = discussion.effectiveRepetitionCode;
      }
    } else {
      // Jika tidak ada point yang lolos filter (atau tidak ada point sama sekali),
      // gunakan logika getter efektif dari model Discussion seperti sebelumnya.
      displayDate = discussion.effectiveDate;
      displayCode = discussion.effectiveRepetitionCode;
    }
    // === AKHIR LOGIKA BARU ===

    final dateText = displayDate ?? 'N/A';
    final codeText = displayCode ?? 'N/A';
    Color dateColor = Colors.grey;

    if (displayDate != null) {
      try {
        final discussionDate = DateTime.parse(displayDate);
        final today = DateTime.now();
        // Warnai merah jika tanggalnya sebelum hari ini
        if (discussionDate.isBefore(
          DateTime(today.year, today.month, today.day),
        )) {
          dateColor = Colors.red;
        } else {
          dateColor = Colors.amber.shade700;
        }
      } catch (e) {
        // Biarkan warna default jika parsing tanggal gagal
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
