// lib/presentation/pages/3_discussions_page/widgets/point_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../../presentation/providers/discussion_provider.dart';
import '../../../../presentation/widgets/edit_popup_menu.dart';
import '../dialogs/discussion_dialogs.dart';
import '../utils/repetition_code_utils.dart';

class PointTile extends StatelessWidget {
  final Discussion discussion; // ==> DITAMBAHKAN
  final Point point;
  final bool isActive;

  const PointTile({
    super.key,
    required this.discussion, // ==> DITAMBAHKAN
    required this.point,
    this.isActive = true,
  });

  void _showSnackBar(BuildContext context, String message) {
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

  //==> FUNGSI BARU UNTUK MENGHAPUS POINT <==
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscussionProvider>(context, listen: false);

    final Color defaultTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color inactiveColor = Colors.grey;
    final Color effectiveTextColor = isActive
        ? defaultTextColor
        : inactiveColor;

    return ListTile(
      dense: true,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(point.pointText, style: TextStyle(color: effectiveTextColor)),
      subtitle: RichText(
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
              ),
            ),
          ],
        ),
      ),
      trailing: EditPopupMenu(
        onDateChange: () => _changePointDate(context, provider),
        onCodeChange: () => _changePointCode(context, provider),
        onRename: () => _renamePoint(context, provider),
        onDelete: () => _deletePoint(context, provider),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
