// lib/features/content_management/presentation/discussions/widgets/discussion_point_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import 'point_tile.dart';

class DiscussionPointList extends StatelessWidget {
  final Discussion discussion;

  const DiscussionPointList({super.key, required this.discussion});

  @override
  Widget build(BuildContext context) {
    // ==> PROVIDER SEKARANG DIDENGARKAN (LISTEN: TRUE) <==
    final provider = Provider.of<DiscussionProvider>(context);

    // ==> PANGGIL FUNGSI BARU DARI PROVIDER <==
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
