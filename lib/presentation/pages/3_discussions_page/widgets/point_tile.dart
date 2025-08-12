import 'package:flutter/material.dart';
import '../../../../data/models/discussion_model.dart';
import '../../../widgets/edit_popup_menu.dart';
import '../utils/repetition_code_utils.dart'; // <-- IMPORT BARU

class PointTile extends StatelessWidget {
  final Point point;
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback onRename;
  // HAPUS: final Color Function(String) getColorForRepetitionCode;

  const PointTile({
    super.key,
    required this.point,
    required this.onDateChange,
    required this.onCodeChange,
    required this.onRename,
    // HAPUS: required this.getColorForRepetitionCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(point.pointText),
      subtitle: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
          children: [
            const TextSpan(text: 'Date: '),
            TextSpan(
              text: point.date,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: ' | Code: '),
            TextSpan(
              text: point.repetitionCode,
              style: TextStyle(
                color: getColorForRepetitionCode(
                  point.repetitionCode,
                ), // <-- PANGGIL FUNGSI DARI UTILITAS
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailing: EditPopupMenu(
        onDateChange: onDateChange,
        onCodeChange: onCodeChange,
        onRename: onRename,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
