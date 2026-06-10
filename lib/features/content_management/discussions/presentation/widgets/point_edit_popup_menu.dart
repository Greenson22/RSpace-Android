// lib/features/content_management/presentation/discussions/widgets/point_edit_popup_menu.dart
import 'package:flutter/material.dart';

class PointEditPopupMenu extends StatelessWidget {
  final VoidCallback? onDateChange;
  final VoidCallback? onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;
  final bool isFinished;

  const PointEditPopupMenu({
    super.key,
    this.onDateChange,
    this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished,
    this.onReactivate,
    this.onDelete,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseIconSize = 18.0;
    final scaledIconSize = baseIconSize * textScaleFactor;

    return PopupMenuButton<String>(
      iconSize: scaledIconSize,
      icon: const Icon(Icons.more_vert),
      // MENYAMAKAN LEBAR MAKSIMAL kontainer popup menu sesuai standar diskusi
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
      onSelected: (value) {
        if (value == 'edit_date' && onDateChange != null) onDateChange!();
        if (value == 'edit_code' && onCodeChange != null) onCodeChange!();
        if (value == 'rename' && onRename != null) onRename!();
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
        if (value == 'reactivate' && onReactivate != null) onReactivate!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        if (!isFinished) {
          if (onDateChange != null) {
            menuItems.add(
              _buildMenuItem(
                'edit_date',
                Icons.calendar_month_outlined,
                'Ubah Tanggal',
              ),
            );
          }
          if (onCodeChange != null) {
            menuItems.add(
              _buildMenuItem(
                'edit_code',
                Icons.repeat_outlined,
                'Ubah Kode Repetisi',
              ),
            );
          }
          if (onRename != null) {
            menuItems.add(
              _buildMenuItem('rename', Icons.edit_outlined, 'Ubah Nama'),
            );
          }
        }

        menuItems.add(const PopupMenuDivider(height: 8));

        if (!isFinished) {
          if (onMarkAsFinished != null) {
            menuItems.add(
              _buildMenuItem(
                'finish',
                Icons.check_circle_outline,
                'Tandai Selesai',
              ),
            );
          }
        } else {
          if (onReactivate != null) {
            menuItems.add(
              _buildMenuItem('reactivate', Icons.replay, 'Aktifkan Lagi'),
            );
          }
        }

        if (onDelete != null) {
          menuItems.add(const PopupMenuDivider(height: 8));
          menuItems.add(
            _buildMenuItem(
              'delete',
              Icons.delete_outline,
              'Hapus',
              color: Colors.red,
            ),
          );
        }

        return menuItems;
      },
    );
  }

  // Fungsi helper pembentuk item dengan tinggi 40, ukuran icon 20, dan ukuran font teks 14 (Sama seperti Discussion)
  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40, // Tinggi item menu diskusi
      child: Row(
        children: [
          Icon(icon, color: color, size: 20), // Ukuran ikon menu diskusi
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
            ), // Ukuran font menu diskusi
          ),
        ],
      ),
    );
  }
}
