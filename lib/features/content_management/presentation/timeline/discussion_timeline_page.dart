// lib/features/content_management/presentation/timeline/discussion_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/discussion_model.dart';
import 'discussion_timeline_provider.dart';
import 'widgets/timeline_painter.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import '../../domain/models/timeline_models.dart';

class DiscussionTimelinePage extends StatelessWidget {
  final String subjectName;
  final List<Discussion> discussions;

  const DiscussionTimelinePage({
    super.key,
    required this.subjectName,
    required this.discussions,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiscussionTimelineProvider(discussions),
      child: _DiscussionTimelineView(subjectName: subjectName),
    );
  }
}

// ==> UBAH MENJADI STATEFULWIDGET <==
class _DiscussionTimelineView extends StatefulWidget {
  final String subjectName;
  const _DiscussionTimelineView({required this.subjectName});

  @override
  State<_DiscussionTimelineView> createState() =>
      _DiscussionTimelineViewState();
}

class _DiscussionTimelineViewState extends State<_DiscussionTimelineView> {
  // ==> TAMBAHKAN STATE UNTUK MENYIMPAN POSISI HOVER/TAP <==
  Offset? _pointerPosition;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionTimelineProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Linimasa: ${widget.subjectName}'),
        actions: [
          if (provider.selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.clearDateRange(),
              tooltip: 'Reset Rentang Waktu',
            ),
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            onPressed: () => provider.setDateRange(context),
            tooltip: 'Pilih Rentang Waktu',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.timelineData == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada diskusi dengan jadwal aktif di dalam subjek ini untuk ditampilkan di linimasa.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final timelineData = provider.timelineData!;

          final List<TimelineDiscussion> timelineDiscussions = [];

          final discussionsToDisplay = provider.discussions.where((d) {
            if (d.effectiveDate == null) return false;
            final date = DateTime.tryParse(d.effectiveDate!);
            if (date == null) return false;
            return !date.isBefore(timelineData.startDate) &&
                !date.isAfter(
                  timelineData.endDate.add(
                    const Duration(days: 1) - const Duration(microseconds: 1),
                  ),
                );
          }).toList();

          for (var discussion in discussionsToDisplay) {
            timelineDiscussions.add(
              TimelineDiscussion(
                discussion: discussion,
                position: Offset.zero,
                color: getColorForRepetitionCode(
                  discussion.effectiveRepetitionCode,
                ),
              ),
            );
          }

          final finalTimelineData = TimelineData(
            discussions: timelineDiscussions,
            startDate: timelineData.startDate,
            endDate: timelineData.endDate,
            totalDays: timelineData.totalDays,
            discussionCounts: timelineData.discussionCounts,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==> BUNGKUS CUSTOMPAINT DENGAN GESTUREDETECTOR <==
                GestureDetector(
                  onPanStart: (details) =>
                      setState(() => _pointerPosition = details.localPosition),
                  onPanUpdate: (details) =>
                      setState(() => _pointerPosition = details.localPosition),
                  onPanEnd: (_) => setState(() => _pointerPosition = null),
                  onTapDown: (details) =>
                      setState(() => _pointerPosition = details.localPosition),
                  onTapUp: (_) => setState(() => _pointerPosition = null),
                  child: SizedBox(
                    height: 300,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: TimelinePainter(
                        timelineData: finalTimelineData,
                        context: context,
                        // ==> KIRIM POSISI POINTER KE PAINTER <==
                        pointerPosition: _pointerPosition,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Text('Legenda', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 8.0,
                  children: kRepetitionCodes.map((code) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: getColorForRepetitionCode(code),
                      ),
                      label: Text(code),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
