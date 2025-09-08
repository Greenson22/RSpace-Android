// lib/presentation/pages/3_discussions_page/widgets/point_tile.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/discussion_model.dart';
import '../../../application/discussion_provider.dart';
import '../../../../../presentation/widgets/point_edit_popup_menu.dart';
import '../../../../../presentation/widgets/linkify_text.dart';
import '../dialogs/discussion_dialogs.dart'; // Impor file barrel
import '../utils/repetition_code_utils.dart';

class PointTile extends StatelessWidget {
  final Discussion discussion;
  final Point point;
  final bool isActive;

  const PointTile({
    super.key,
    required this.discussion,
    required this.point,
    this.isActive = true,
  });

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _renamePoint(BuildContext context, DiscussionProvider provider) {
    showTextInputDialog(
      context: context,
      title: 'Ubah Nama Poin',
      label: 'Teks Poin Baru',
      initialValue: point.pointText,
      onSave: (newName) {
        provider.renamePoint(point, newName);
        _showSnackBar(context, 'Poin berhasil diubah.');
      },
    );
  }

  void _deletePoint(BuildContext context, DiscussionProvider provider) {
    showDeletePointConfirmationDialog(
      context: context,
      pointText: point.pointText,
      onDelete: () {
        provider.deletePoint(discussion, point);
        _showSnackBar(context, 'Poin berhasil dihapus.');
      },
    );
  }

  void _changePointDate(
    BuildContext context,
    DiscussionProvider provider,
  ) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(point.date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (newDate != null) {
      provider.updatePointDate(point, newDate);
      _showSnackBar(context, 'Tanggal poin berhasil diubah.');
    }
  }

  void _changePointCode(BuildContext context, DiscussionProvider provider) {
    showRepetitionCodeDialog(
      context,
      point.repetitionCode,
      provider.repetitionCodes,
      (newCode) {
        provider.updatePointCode(point, newCode);
        _showSnackBar(context, 'Kode repetisi poin berhasil diubah.');
      },
    );
  }

  void _markAsFinished(BuildContext context, DiscussionProvider provider) {
    provider.markPointAsFinished(point);
    _showSnackBar(context, 'Poin ditandai selesai.');
  }

  void _reactivatePoint(BuildContext context, DiscussionProvider provider) {
    provider.reactivatePoint(point);
    _showSnackBar(context, 'Poin diaktifkan kembali.');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);
    final bool isFinished = point.finished;

    final Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color inactiveColor = Colors.grey;
    final Color effectiveTextColor = isActive && !isFinished
        ? defaultTextColor
        : inactiveColor;

    return ListTile(
      dense: true,
      leading: Icon(
        isFinished ? Icons.check_circle_outline : Icons.arrow_right,
        color: isFinished ? Colors.green : Colors.grey,
      ),
      title: LinkifyText(
        point.pointText,
        style: TextStyle(
          color: effectiveTextColor,
          decoration: isFinished ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: isFinished
          ? Text('Selesai pada: ${point.finish_date ?? ''}')
          : RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: effectiveTextColor,
                ),
                children: [
                  const TextSpan(text: 'Date: '),
                  TextSpan(
                    text: point.date,
                    style: TextStyle(
                      color: isActive ? Colors.amber : inactiveColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' | Code: '),
                  TextSpan(
                    text: point.repetitionCode,
                    style: TextStyle(
                      color: isActive
                          ? getColorForRepetitionCode(point.repetitionCode)
                          : inactiveColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        if (isFinished) return;
                        final currentCode = point.repetitionCode;
                        final currentIndex = getRepetitionCodeIndex(
                          currentCode,
                        );
                        if (currentIndex <
                            provider.repetitionCodes.length - 1) {
                          final nextCode =
                              provider.repetitionCodes[currentIndex + 1];
                          final confirmed =
                              await showRepetitionCodeUpdateConfirmationDialog(
                                context: context,
                                currentCode: currentCode,
                                nextCode: nextCode,
                              );
                          if (confirmed) {
                            provider.incrementRepetitionCode(point);
                            _showSnackBar(
                              context,
                              'Kode repetisi poin diubah ke $nextCode.',
                            );
                          }
                        }
                      },
                  ),
                ],
              ),
            ),
      trailing: PointEditPopupMenu(
        isFinished: isFinished,
        onDateChange: () => _changePointDate(context, provider),
        onCodeChange: () => _changePointCode(context, provider),
        onRename: () => _renamePoint(context, provider),
        onDelete: () => _deletePoint(context, provider),
        onMarkAsFinished: () => _markAsFinished(context, provider),
        onReactivate: () => _reactivatePoint(context, provider),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
