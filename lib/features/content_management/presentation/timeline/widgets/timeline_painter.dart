// lib/features/content_management/presentation/timeline/widgets/timeline_painter.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/timeline_models.dart';
import '../../discussions/utils/repetition_code_utils.dart';

class TimelinePainter extends CustomPainter {
  final TimelineData timelineData;
  final BuildContext context;

  TimelinePainter({required this.timelineData, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final double timelineY = size.height - 50;
    final double startX = 30;
    final double endX = size.width - 30;
    final double timelineWidth = endX - startX;

    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0;

    // Gambar garis utama linimasa
    canvas.drawLine(
      Offset(startX, timelineY),
      Offset(endX, timelineY),
      linePaint,
    );

    // Gambar label tanggal awal dan akhir
    _drawText(
      canvas,
      DateFormat('d MMM').format(timelineData.startDate),
      Offset(startX, timelineY + 15),
      textAlign: TextAlign.left,
    );
    _drawText(
      canvas,
      DateFormat('d MMM yy').format(timelineData.endDate),
      Offset(endX, timelineY + 15),
      textAlign: TextAlign.right,
    );

    // Gambar titik-titik diskusi dan label jumlahnya
    timelineData.discussionCounts.forEach((date, count) {
      final double xPos = timelineData.totalDays > 0
          ? startX +
                (date.difference(timelineData.startDate).inDays /
                        timelineData.totalDays) *
                    timelineWidth
          : startX;

      // Gambar garis vertikal penanda hari
      canvas.drawLine(
        Offset(xPos, timelineY - 5),
        Offset(xPos, timelineY + 5),
        linePaint,
      );

      // Gambar label jumlah diskusi
      _drawText(
        canvas,
        count.toString(),
        Offset(xPos, timelineY - 25),
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      );

      // Ambil diskusi untuk tanggal ini dan gambar titik-titiknya
      final discussionsOnThisDay = timelineData.discussions
          .where(
            (d) => DateUtils.isSameDay(
              DateTime.parse(d.discussion.effectiveDate!),
              date,
            ),
          )
          .toList();

      for (int i = 0; i < discussionsOnThisDay.length; i++) {
        final item = discussionsOnThisDay[i];
        final yPos = timelineY - 40 - (i * 15.0);

        final dotPaint = Paint()..color = item.color;
        canvas.drawCircle(Offset(xPos, yPos), 5, dotPaint);
      }
    });
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    TextAlign textAlign = TextAlign.center,
  }) {
    final textStyle = TextStyle(
      color: color ?? Colors.grey.shade600,
      fontSize: 12,
      fontWeight: fontWeight,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      // ==> PERUBAHAN UTAMA DI SINI <==
      // Mengambil arah teks dari context, bukan dari enum statis.
      // Ini adalah cara alternatif untuk menghindari galat 'ltr' not defined.
      textDirection: Directionality.of(context),
    );
    textPainter.layout();

    double xPos = position.dx;
    if (textAlign == TextAlign.center) {
      xPos -= textPainter.width / 2;
    } else if (textAlign == TextAlign.right) {
      xPos -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(xPos, position.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
