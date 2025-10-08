// lib/features/content_management/presentation/timeline/discussion_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/models/discussion_model.dart';
import 'discussion_timeline_provider.dart';
import 'widgets/timeline_painter.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import '../../domain/models/timeline_models.dart';
import 'dialogs/reschedule_discussions_dialog.dart';

class DiscussionTimelinePage extends StatelessWidget {
  final String subjectName;
  final List<Discussion> discussions;
  final String subjectJsonPath;

  const DiscussionTimelinePage({
    super.key,
    required this.subjectName,
    required this.discussions,
    required this.subjectJsonPath,
  });

  @override
  Widget build(BuildContext context) {
    // Di sini kita tidak perlu `Provider.of` karena kita membuat instance baru.
    // Provider yang ada di `subjects_page` tidak dibawa ke sini.
    return ChangeNotifierProvider(
      create: (_) => DiscussionTimelineProvider(discussions, subjectJsonPath),
      child: _DiscussionTimelineView(subjectName: subjectName),
    );
  }
}

class _DiscussionTimelineView extends StatefulWidget {
  final String subjectName;
  const _DiscussionTimelineView({required this.subjectName});

  @override
  State<_DiscussionTimelineView> createState() =>
      _DiscussionTimelineViewState();
}

class _DiscussionTimelineViewState extends State<_DiscussionTimelineView> {
  Offset? _pointerPosition;

  Future<void> _handleReschedule(BuildContext context) async {
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );

    final RescheduleDialogResult? result =
        await showRescheduleDiscussionsDialog(context);

    if (result != null && mounted) {
      try {
        final resultMessage = await provider.rescheduleDiscussions(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultMessage), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionTimelineProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Linimasa: ${widget.subjectName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: provider.isProcessing
                ? null
                : () => _handleReschedule(context),
            tooltip: 'Atur Ulang Jadwal (AI)',
          ),
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
          if (provider.isLoading || provider.isProcessing) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    provider.isProcessing
                        ? 'Menjadwalkan ulang...'
                        : 'Memuat data...',
                  ),
                ],
              ),
            );
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
            return !date.isBefore(DateUtils.dateOnly(timelineData.startDate)) &&
                !date.isAfter(DateUtils.dateOnly(timelineData.endDate));
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
