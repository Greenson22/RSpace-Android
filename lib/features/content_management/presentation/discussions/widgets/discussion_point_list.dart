// lib/features/content_management/presentation/discussions/widgets/discussion_point_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import 'point_tile.dart';

class DiscussionPointList extends StatelessWidget {
  final Discussion discussion;
  final bool isReorderMode;

  const DiscussionPointList({
    super.key,
    required this.discussion,
    this.isReorderMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context);
    if (isReorderMode) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: discussion.points.length,
        itemBuilder: (context, index) {
          final point = discussion.points[index];
          return Card(
            key: ValueKey(point.hashCode),
            margin: const EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 8.0,
            ), // Mengecilkan horizontal margin dari 16 ke 8
            child: ListTile(
              dense: true,
              title: Text(
                point.pointText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.0,
                ), // Disesuaikan ukuran mobile
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, size: 20),
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderPoints(discussion, oldIndex, newIndex);
        },
      );
    }

    final sortedPoints = provider.getSortedPoints(discussion);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20.0,
        4.0,
        8.0,
        4.0,
      ), // MODIFIKASI: Mengecilkan indentasi kiri (dari 30 ke 20) & vertical padding (dari 8 ke 4)
      child: Column(
        children: List.generate(sortedPoints.length, (i) {
          return Column(
            children: [
              PointTile(
                discussion: discussion,
                point: sortedPoints[i],
                isActive: provider.doesPointMatchFilter(sortedPoints[i]),
              ),
              if (i < sortedPoints.length - 1)
                Divider(
                  height: 1, // Memberikan batasan yang lebih tipis
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor.withOpacity(
                          0.2,
                        ) // Opacity sedikit diturunkan
                      : null,
                ),
            ],
          );
        }),
      ),
    );
  }
}
