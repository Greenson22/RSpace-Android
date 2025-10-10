// lib/features/content_management/presentation/timeline/discussion_timeline_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/timeline_models.dart';
import 'package:provider/provider.dart';
import '../../domain/models/discussion_model.dart';
import 'discussion_timeline_provider.dart';
import 'widgets/timeline_painter.dart';
import '../../presentation/discussions/utils/repetition_code_utils.dart';
import 'dialogs/reschedule_discussions_dialog.dart';
import 'dialogs/timeline_settings_dialog.dart';

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
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  bool _isDragMode = false;
  TimelineEvent? _draggedEvent;
  Offset? _dragStartPosition;

  bool _isSelectionMode = false;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDragMode) return;
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    if (provider.timelineData == null) return;

    double closestDistance = double.infinity;
    TimelineEvent? eventToDrag;
    for (final event in provider.timelineData!.events) {
      final distance = (event.position - details.localPosition).distance;
      if (distance < 20 && distance < closestDistance) {
        closestDistance = distance;
        eventToDrag = event;
      }
    }

    if (eventToDrag != null) {
      setState(() {
        if (provider.selectedEvents.contains(eventToDrag)) {
          _draggedEvent = eventToDrag;
        } else {
          provider.clearSelection();
          _draggedEvent = eventToDrag;
        }
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
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    if (_draggedEvent != null &&
        _pointerPosition != null &&
        _dragStartPosition != null) {
      final timelineData = provider.timelineData!;

      final double startX = 30;
      final double endX =
          (MediaQuery.of(context).size.width * provider.zoomLevel) - 32 - 30;
      final double timelineWidth = endX - startX;

      final double dx = _pointerPosition!.dx - _dragStartPosition!.dx;
      final double dateRatio = dx / timelineWidth;
      final int dayOffset = (timelineData.totalDays * dateRatio).round();
      final dateOffset = Duration(days: dayOffset);

      if (provider.isSelectionMode) {
        provider.updateSelectedEventsDate(dateOffset);
      } else {
        final currentEventDate = DateTime.parse(_draggedEvent!.effectiveDate);
        final newDate = currentEventDate.add(dateOffset);
        provider.updateEventDate(_draggedEvent!, newDate);
      }
    }
    setState(() {
      _draggedEvent = null;
      _dragStartPosition = null;
      _pointerPosition = null;
    });
  }

  void _onTapDown(TapDownDetails details) {
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );
    if (_isSelectionMode) {
      double closestDistance = double.infinity;
      TimelineEvent? eventToSelect;
      for (final event in provider.timelineData!.events) {
        final distance = (event.position - details.localPosition).distance;
        if (distance < 15 && distance < closestDistance) {
          closestDistance = distance;
          eventToSelect = event;
        }
      }
      if (eventToSelect != null) {
        provider.toggleEventSelection(eventToSelect);
      }
    } else {
      setState(() => _pointerPosition = details.localPosition);
    }
  }

  // ==> FUNGSI INI DIPERBARUI UNTUK MENAMBAHKAN KONFIRMASI <==
  Future<void> _handleReschedule(BuildContext context) async {
    final provider = Provider.of<DiscussionTimelineProvider>(
      context,
      listen: false,
    );

    // Langkah 1: Tampilkan dialog pengaturan
    final RescheduleDialogResult? result =
        await showRescheduleDiscussionsDialog(context);

    // Jika pengguna memilih pengaturan dan tidak membatalkan
    if (result != null && mounted) {
      // Langkah 2: Tampilkan dialog konfirmasi
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Penjadwalan Ulang'),
          content: const Text(
            'Anda yakin ingin melanjutkan? Tindakan ini akan mengubah tanggal item yang sudah lewat dan mengurutkan ulang jadwal di masa depan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        ),
      );

      // Langkah 3: Jika dikonfirmasi, jalankan prosesnya
      if (confirmed == true && mounted) {
        try {
          final resultMessage = await provider.rescheduleDiscussions(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultMessage),
              backgroundColor: Colors.green,
            ),
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
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionTimelineProvider>(context);
    final theme = Theme.of(context);

    final currentAppBar = _isSelectionMode
        ? AppBar(
            title: Text('${provider.selectedEvents.length} Item Dipilih'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                provider.clearSelection();
                setState(() => _isSelectionMode = false);
              },
            ),
          )
        : AppBar(
            title: Text('Linimasa: ${widget.subjectName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => showTimelineSettingsDialog(context),
                tooltip: 'Pengaturan Tampilan',
              ),
              IconButton(
                icon: Icon(
                  Icons.select_all,
                  color: _isSelectionMode ? theme.primaryColorLight : null,
                ),
                onPressed: () {
                  setState(() => _isSelectionMode = !_isSelectionMode);
                  if (!_isSelectionMode) {
                    provider.clearSelection();
                  }
                },
                tooltip: 'Mode Seleksi',
              ),
              IconButton(
                icon: Icon(
                  Icons.pan_tool_alt_outlined,
                  color: _isDragMode ? theme.primaryColorLight : null,
                ),
                onPressed: () {
                  setState(() => _isDragMode = !_isDragMode);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isDragMode
                            ? 'Mode Pindah Aktif'
                            : 'Mode Pindah Nonaktif',
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
          );

    return Scaffold(
      appBar: currentAppBar,
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

          final maxStackPerDay = timelineData.discussionCounts.values.fold(
            0,
            (max, current) => current > max ? current : max,
          );
          final double canvasHeight =
              100 +
              (maxStackPerDay *
                  (provider.discussionRadius * 2 + provider.discussionSpacing));

          return Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Scrollbar(
                    controller: _horizontalScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _horizontalScrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: MouseRegion(
                          onHover: (event) => setState(
                            () => _pointerPosition = event.localPosition,
                          ),
                          onExit: (_) =>
                              setState(() => _pointerPosition = null),
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
                            onTapDown: _onTapDown,
                            onTapUp: (_) {
                              if (!_isSelectionMode) {
                                setState(() => _pointerPosition = null);
                              }
                            },
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: SizedBox(
                              height: canvasHeight,
                              width: canvasWidth - 32,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: TimelinePainter(
                                  timelineData: timelineData,
                                  context: context,
                                  pointerPosition: _pointerPosition,
                                  draggedEvent: _draggedEvent,
                                  selectedEvents: provider.selectedEvents,
                                  discussionRadius: provider.discussionRadius,
                                  pointRadius: provider.pointRadius,
                                  discussionSpacing: provider.discussionSpacing,
                                  pointSpacing: provider.pointSpacing,
                                ),
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
                                backgroundColor: getColorForRepetitionCode(
                                  code,
                                ),
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
            ),
          );
        },
      ),
    );
  }
}
