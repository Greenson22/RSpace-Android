// lib/presentation/pages/feedback_center_page/widgets/feedback_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/feedback_model.dart';
import '../../../providers/feedback_provider.dart';
import '../dialogs/feedback_dialogs.dart';

class FeedbackCard extends StatelessWidget {
  final FeedbackItem item;

  const FeedbackCard({super.key, required this.item});

  // Helper untuk mendapatkan data visual berdasarkan tipe
  Map<String, dynamic> _getUIData(FeedbackType type, BuildContext context) {
    switch (type) {
      case FeedbackType.idea:
        return {'icon': '💡', 'color': Colors.amber.shade700};
      case FeedbackType.bug:
        return {'icon': '🐞', 'color': Colors.red.shade700};
      case FeedbackType.suggestion:
        return {'icon': '⭐', 'color': Colors.blue.shade700};
    }
  }

  // Helper untuk mendapatkan warna status
  Color _getStatusColor(FeedbackStatus status, BuildContext context) {
    switch (status) {
      case FeedbackStatus.fresh:
        return Colors.grey.shade600;
      case FeedbackStatus.inProgress:
        return Theme.of(context).primaryColor;
      case FeedbackStatus.done:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeedbackProvider>(context, listen: false);
    final uiData = _getUIData(item.type, context);
    final statusColor = _getStatusColor(item.status, context);
    final formattedDate = DateFormat(
      'd MMM yyyy, HH:mm',
    ).format(item.updatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(uiData['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          item.status.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showAddEditFeedbackDialog(
                        context,
                        item: item,
                        provider: provider,
                      );
                    } else if (value == 'status') {
                      showChangeStatusDialog(context, item, provider);
                    } else if (value == 'delete') {
                      provider.deleteItem(item.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'status',
                      child: Text('Ubah Status'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                item.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Diperbarui: $formattedDate',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
