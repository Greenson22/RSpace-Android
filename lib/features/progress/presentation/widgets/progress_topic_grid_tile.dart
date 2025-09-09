// lib/features/progress/presentation/widgets/progress_topic_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/progress/domain/models/progress_topic_model.dart';

class ProgressTopicGridTile extends StatelessWidget {
  final ProgressTopic topic;
  final VoidCallback onTap;

  const ProgressTopicGridTile({
    super.key,
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined, // Ikon default, bisa dikostumisasi nanti
                size: 40,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  topic.topics,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
