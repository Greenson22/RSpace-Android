// lib/features/content_management/presentation/discussions/widgets/discussion_point_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import 'point_tile.dart';

class DiscussionPointList extends StatelessWidget {
  final Discussion discussion;
  // ==> TAMBAHKAN PROPERTI BARU <==
  final bool isReorderMode;

  const DiscussionPointList({
    super.key,
    required this.discussion,
    this.isReorderMode = false, // Nilai default
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context);

    // ==> TAMPILKAN WIDGET BERBEDA BERDASARKAN MODE <==
    if (isReorderMode) {
      // Gunakan ReorderableListView saat mode urut aktif
      return ReorderableListView.builder(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: discussion.points.length,
        itemBuilder: (context, index) {
          final point = discussion.points[index];
          return Card(
            key: ValueKey(point.hashCode),
            margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
            child: ListTile(
              dense: true,
              title: Text(
                point.pointText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          provider.reorderPoints(discussion, oldIndex, newIndex);
        },
      );
    }

    // Tampilan normal seperti sebelumnya
    final sortedPoints = provider.getSortedPoints(discussion);

    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 8.0, 16.0, 8.0),
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
                  color: Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : null,
                ),
            ],
          );
        }),
      ),
    );
  }
}
