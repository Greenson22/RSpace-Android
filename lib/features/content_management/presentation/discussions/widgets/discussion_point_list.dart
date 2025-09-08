// lib/presentation/pages/3_discussions_page/widgets/discussion_point_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../utils/repetition_code_utils.dart';
import 'point_tile.dart';

class DiscussionPointList extends StatelessWidget {
  final Discussion discussion;

  const DiscussionPointList({super.key, required this.discussion});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);

    // Logika sorting dipindahkan ke sini
    final sortedPoints = _getSortedPoints(provider);

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

  List<Point> _getSortedPoints(DiscussionProvider provider) {
    final allPoints = List<Point>.from(discussion.points);
    final sortType = provider.sortType;
    final sortAscending = provider.sortAscending;

    allPoints.sort((a, b) {
      switch (sortType) {
        case 'name':
          return a.pointText.toLowerCase().compareTo(b.pointText.toLowerCase());
        case 'code':
          return getRepetitionCodeIndex(
            a.repetitionCode,
          ).compareTo(getRepetitionCodeIndex(b.repetitionCode));
        default: // date
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return sortAscending ? 1 : -1;
          if (dateB == null) return sortAscending ? -1 : 1;
          return dateA.compareTo(dateB);
      }
    });

    if (!sortAscending) {
      return allPoints.reversed.toList();
    }
    return allPoints;
  }
}
