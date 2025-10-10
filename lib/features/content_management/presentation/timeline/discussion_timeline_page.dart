// lib/features/content_management/presentation/timeline/discussion_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/timeline_models.dart';
import 'package:provider/provider.dart';
import '../../domain/models/discussion_model.dart';
import 'discussion_timeline_provider.dart';
import 'widgets/timeline_painter.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
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
  final ScrollController _scrollController = ScrollController();

  // ==> STATE BARU UNTUK DRAG & DROP <==
  bool _isDragMode = false;
  TimelineEvent? _draggedEvent;
  Offset? _dragStartPosition;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDragMode) return;
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    if (provider.timelineData == null) return;

    // Temukan event terdekat dengan titik awal drag
    double closestDistance = double.infinity;
    TimelineEvent? eventToDrag;
    for (final event in provider.timelineData!.events) {
      final distance = (event.position - details.localPosition).distance;
      if (distance < 20 && distance < closestDistance) {
        // Perluas area deteksi
        closestDistance = distance;
        eventToDrag = event;
      }
    }

    if (eventToDrag != null) {
      setState(() {
        _draggedEvent = eventToDrag;
        _dragStartPosition = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedEvent != null) {
      setState(() {
        _pointerPosition = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_draggedEvent != null && _pointerPosition != null) {
      final provider = Provider.of<DiscussionTimelineProvider>(
        context,
        listen: false,
      );
      final timelineData = provider.timelineData!;

      final double startX = 30;
      final double endX =
          (MediaQuery.of(context).size.width * provider.zoomLevel) - 32 - 30;
      final double timelineWidth = endX - startX;

      final double dropX = _pointerPosition!.dx.clamp(startX, endX);
      final double ratio = (dropX - startX) / timelineWidth;

      final int daysToAdd = (timelineData.totalDays * ratio).round();
      final DateTime newDate = timelineData.startDate.add(
        Duration(days: daysToAdd),
      );

      provider.updateEventDate(_draggedEvent!, newDate);
    }
    setState(() {
      _draggedEvent = null;
      _dragStartPosition = null;
      _pointerPosition = null;
    });
  }

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
          // ==> TOMBOL BARU UNTUK MODE DRAG <==
          IconButton(
            icon: Icon(
              Icons.pan_tool_alt_outlined,
              color: _isDragMode ? theme.primaryColorLight : null,
            ),
            onPressed: () {
              setState(() {
                _isDragMode = !_isDragMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isDragMode ? 'Mode Pindah Aktif' : 'Mode Pindah Nonaktif',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Mode Pindah (Drag & Drop)',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: provider.zoomLevel > 0.5 ? provider.zoomOut : null,
            tooltip: 'Perkecil',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: provider.zoomLevel < 5.0 ? provider.zoomIn : null,
            tooltip: 'Perbesar',
          ),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.timelineData == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada diskusi atau poin dengan jadwal aktif di dalam subjek ini untuk ditampilkan di linimasa.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final timelineData = provider.timelineData!;
          final canvasWidth =
              MediaQuery.of(context).size.width * provider.zoomLevel;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MouseRegion(
                      onHover: (event) => setState(
                        () => _pointerPosition = event.localPosition,
                      ),
                      onExit: (_) => setState(() => _pointerPosition = null),
                      child: GestureDetector(
                        onLongPressStart: (details) => setState(
                          () => _pointerPosition = details.localPosition,
                        ),
                        onLongPressMoveUpdate: (details) => setState(
                          () => _pointerPosition = details.localPosition,
                        ),
                        onLongPressEnd: (_) =>
                            setState(() => _pointerPosition = null),
                        onLongPressCancel: () =>
                            setState(() => _pointerPosition = null),
                        onTapDown: (details) => setState(
                          () => _pointerPosition = details.localPosition,
                        ),
                        onTapUp: (_) => setState(() => _pointerPosition = null),
                        // ==> TAMBAHKAN GESTUR PAN <==
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: SizedBox(
                          height: 300,
                          width: canvasWidth - 32,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: TimelinePainter(
                              timelineData: timelineData,
                              context: context,
                              pointerPosition: _pointerPosition,
                              // Kirim event yang sedang di-drag ke painter
                              draggedEvent: _draggedEvent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Legenda', style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Chip(
                        avatar: CircleAvatar(backgroundColor: Colors.blue),
                        label: Text('Diskusi'),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: Container(
                          width: 12,
                          height: 12,
                          color: Colors.blue,
                        ),
                        label: const Text('Poin'),
                      ),
                      ...kRepetitionCodes.map((code) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: getColorForRepetitionCode(code),
                            ),
                            label: Text(code),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
