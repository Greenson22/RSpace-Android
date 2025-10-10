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
    const double discussionRadius = 6.0;
    const double pointRadius = 4.0;

    // --- Langkah 1: Kalkulasi Semua Posisi Terlebih Dahulu ---
    final Map<String, Offset> discussionPositions = {};
    _calculateAllPositions(
      startX,
      timelineWidth,
      timelineY,
      discussionRadius,
      pointRadius,
      discussionPositions,
    );

    // --- Langkah 2: Deteksi Item yang Disorot (Hovered) ---
    TimelineEvent? hoveredEvent = _findHoveredEvent(
      discussionRadius,
      pointRadius,
    );

    // --- Langkah 3: Gambar Semua Komponen ---
    _drawTimelineAxis(canvas, startX, endX, timelineY);
    _drawVerticalLines(
      canvas,
      startX,
      timelineWidth,
      timelineY,
      discussionPositions,
    );
    _drawConnectors(
      canvas,
      hoveredEvent,
      discussionPositions,
      connectorPaint,
      highlightedConnectorPaint(context),
    );
    _drawEvents(canvas, hoveredEvent, discussionRadius, pointRadius);

    if (hoveredEvent != null) {
      _drawTooltip(canvas, size, hoveredEvent);
    }
  }

  void _calculateAllPositions(
    double startX,
    double timelineWidth,
    double timelineY,
    double discussionRadius,
    double pointRadius,
    Map<String, Offset> discussionPositions,
  ) {
    final Map<DateTime, List<TimelineEvent>> eventsByDay = {};
    for (final event in timelineData.events) {
      final dateOnly = DateUtils.dateOnly(DateTime.parse(event.effectiveDate));
      eventsByDay.putIfAbsent(dateOnly, () => []).add(event);
    }

    eventsByDay.forEach((date, eventsOnDay) {
      final double xPos = timelineData.totalDays > 0
          ? startX +
                (date.difference(timelineData.startDate).inDays /
                        timelineData.totalDays) *
                    timelineWidth
          : startX;

      double currentY = timelineY - 40;

      // Posisikan diskusi terlebih dahulu
      for (final event in eventsOnDay) {
        if (event.type == TimelineEventType.discussion) {
          event.position = Offset(xPos, currentY);
          discussionPositions[event.parentDiscussion.discussion] =
              event.position;
          currentY -= (discussionRadius * 2 + 10);
        }
      }

      // Kemudian posisikan poin
      for (final event in eventsOnDay) {
        if (event.type == TimelineEventType.point) {
          event.position = Offset(xPos, currentY);
          currentY -= (pointRadius * 2 + 8);
        }
      }
    });
  }

  TimelineEvent? _findHoveredEvent(
    double discussionRadius,
    double pointRadius,
  ) {
    if (pointerPosition == null) return null;

    TimelineEvent? foundEvent;
    double closestDistance = double.infinity;

    for (final event in timelineData.events) {
      final distance = (event.position - pointerPosition!).distance;
      final radius = event.type == TimelineEventType.discussion
          ? discussionRadius
          : pointRadius;
      if (distance < closestDistance && distance < (radius + 8)) {
        closestDistance = distance;
        foundEvent = event;
      }
    }
    return foundEvent;
  }

  Paint get connectorPaint => Paint()
    ..color = Colors.grey.shade400
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  Paint highlightedConnectorPaint(BuildContext context) => Paint()
    ..color = Theme.of(context).primaryColor
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  void _drawTimelineAxis(
    Canvas canvas,
    double startX,
    double endX,
    double timelineY,
  ) {
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
  }

  void _drawVerticalLines(
    Canvas canvas,
    double startX,
    double timelineWidth,
    double timelineY,
    Map<String, Offset> discussionPositions,
  ) {
    final verticalLinePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;
    timelineData.discussionCounts.forEach((date, count) {
      final double xPos = timelineData.totalDays > 0
          ? startX +
                (date.difference(timelineData.startDate).inDays /
                        timelineData.totalDays) *
                    timelineWidth
          : startX;
      double minY = timelineY;
      timelineData.events
          .where(
            (e) => DateUtils.isSameDay(DateTime.parse(e.effectiveDate), date),
          )
          .forEach((e) {
            if (e.position.dy < minY) minY = e.position.dy;
          });
      if (count > 0) {
        canvas.drawLine(
          Offset(xPos, timelineY),
          Offset(xPos, minY),
          verticalLinePaint,
        );
      }
    });
  }

  void _drawConnectors(
    Canvas canvas,
    TimelineEvent? hoveredEvent,
    Map<String, Offset> discussionPositions,
    Paint defaultPaint,
    Paint highlightedPaint,
  ) {
    for (final event in timelineData.events) {
      if (event.type == TimelineEventType.point) {
        final parentPosition =
            discussionPositions[event.parentDiscussion.discussion];
        if (parentPosition != null) {
          final isHoveredGroup =
              hoveredEvent != null &&
              event.parentDiscussion.discussion ==
                  hoveredEvent.parentDiscussion.discussion;
          canvas.drawLine(
            parentPosition,
            event.position,
            isHoveredGroup ? highlightedPaint : defaultPaint,
          );
        }
      }
    }
  }

  void _drawEvents(
    Canvas canvas,
    TimelineEvent? hoveredEvent,
    double discussionRadius,
    double pointRadius,
  ) {
    for (final event in timelineData.events) {
      final isHoveredGroup =
          hoveredEvent != null &&
          event.parentDiscussion.discussion ==
              hoveredEvent.parentDiscussion.discussion;
      final paint = Paint()..color = event.color;

      if (event.type == TimelineEventType.discussion) {
        final radius = isHoveredGroup
            ? discussionRadius * 1.5
            : discussionRadius;
        if (isHoveredGroup) {
          final glowPaint = Paint()
            ..color = event.color.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(event.position, radius, glowPaint);
        }
        canvas.drawCircle(event.position, radius, paint);
      } else {
        final sizeFactor = isHoveredGroup ? 1.8 : 1.0;
        final rect = Rect.fromCenter(
          center: event.position,
          width: pointRadius * 2 * sizeFactor,
          height: pointRadius * 2 * sizeFactor,
        );
        if (isHoveredGroup) {
          final glowPaint = Paint()
            ..color = event.color.withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            glowPaint,
          );
        }
        canvas.drawRect(rect, paint);
      }
    }
  }

  void _drawTooltip(Canvas canvas, Size size, TimelineEvent item) {
    final isPoint = item.type == TimelineEventType.point;
    final textStyle = TextStyle(color: Colors.white, fontSize: 11);
    final dateStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 10,
    );

    final titleSpan = TextSpan(
      text: (isPoint ? "Poin: " : "") + item.title,
      style: textStyle,
    );

    final parentDiscussionSpan = isPoint
        ? TextSpan(
            text: "\nDiskusi: ${item.parentDiscussion.discussion}",
            style: dateStyle,
          )
        : const TextSpan();

    final dateAndCodeSpan = TextSpan(
      style: dateStyle,
      children: [
        TextSpan(text: '\n${item.effectiveDate} | '),
        TextSpan(
          text: item.effectiveRepetitionCode,
          style: TextStyle(
            color: getColorForRepetitionCode(item.effectiveRepetitionCode),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: TextSpan(
        children: [titleSpan, parentDiscussionSpan, dateAndCodeSpan],
      ),
      textAlign: TextAlign.left,
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: 200);

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
    // Repaint setiap kali posisi pointer berubah untuk interaktivitas
    return true;
  }
}
