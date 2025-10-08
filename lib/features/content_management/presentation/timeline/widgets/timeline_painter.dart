// lib/features/content_management/presentation/timeline/widgets/timeline_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/timeline_models.dart';
import '../../discussions/utils/repetition_code_utils.dart';

class TimelinePainter extends CustomPainter {
  final TimelineData timelineData;
  final BuildContext context;
  final Offset? pointerPosition;

  TimelinePainter({
    required this.timelineData,
    required this.context,
    this.pointerPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double timelineY = size.height - 50;
    final double startX = 30;
    final double endX = size.width - 30;
    final double timelineWidth = endX - startX;
    const double dotRadius = 5.0;

    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(startX, timelineY),
      Offset(endX, timelineY),
      linePaint,
    );

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

    final List<TimelineDiscussion> positionedDiscussions = [];
    timelineData.discussionCounts.forEach((date, count) {
      final double xPos = timelineData.totalDays > 0
          ? startX +
                (date.difference(timelineData.startDate).inDays /
                        timelineData.totalDays) *
                    timelineWidth
          : startX;

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
        final yPos = timelineY - 40 - (i * (dotRadius * 2 + 5));
        positionedDiscussions.add(
          TimelineDiscussion(
            discussion: item.discussion,
            position: Offset(xPos, yPos),
            color: item.color,
          ),
        );
      }
    });

    for (final item in positionedDiscussions) {
      final dotPaint = Paint()..color = item.color;
      canvas.drawCircle(item.position, dotRadius, dotPaint);
    }

    if (pointerPosition != null) {
      TimelineDiscussion? hoveredDiscussion;
      double closestDistance = double.infinity;

      for (final item in positionedDiscussions) {
        final distance = (item.position - pointerPosition!).distance;
        if (distance < closestDistance && distance < (dotRadius + 5)) {
          closestDistance = distance;
          hoveredDiscussion = item;
        }
      }

      // ==> PERUBAHAN UTAMA DI BLOK INI <==
      if (hoveredDiscussion != null) {
        // Gambar highlight hanya untuk titik yang di-hover
        final highlightPaint = Paint()
          ..color = hoveredDiscussion.color.withOpacity(0.3)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(
          hoveredDiscussion.position,
          dotRadius + 5,
          highlightPaint,
        );

        // Gambar tooltip hanya untuk satu titik yang di-hover
        _drawTooltip(canvas, size, hoveredDiscussion);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Size size, TimelineDiscussion item) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 11);
    final dateStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 10,
    );

    final titleSpan = TextSpan(
      text: item.discussion.discussion,
      style: textStyle,
    );
    final dateSpan = TextSpan(
      text: '\n${item.discussion.effectiveDate}',
      style: dateStyle,
    );

    final textPainter = TextPainter(
      text: TextSpan(children: [titleSpan, dateSpan]),
      textAlign: TextAlign.left,
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: 150);

    final tooltipPadding = 8.0;
    double xPos = item.position.dx + 15;
    double yPos = item.position.dy - textPainter.height / 2;

    if (xPos + textPainter.width + tooltipPadding * 2 > size.width) {
      xPos = item.position.dx - textPainter.width - 15 - tooltipPadding * 2;
    }
    if (yPos < 0) {
      yPos = 0;
    }
    if (yPos + textPainter.height + tooltipPadding * 2 > size.height) {
      yPos = size.height - textPainter.height - tooltipPadding * 2;
    }

    final rect = RRect.fromLTRBR(
      xPos,
      yPos,
      xPos + textPainter.width + tooltipPadding * 2,
      yPos + textPainter.height + tooltipPadding * 2,
      const Radius.circular(8),
    );

    final bgPaint = Paint()..color = Colors.black.withOpacity(0.75);
    canvas.drawRRect(rect, bgPaint);
    textPainter.paint(
      canvas,
      Offset(xPos + tooltipPadding, yPos + tooltipPadding),
    );
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
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.timelineData != timelineData ||
        oldDelegate.pointerPosition != pointerPosition;
  }
}
