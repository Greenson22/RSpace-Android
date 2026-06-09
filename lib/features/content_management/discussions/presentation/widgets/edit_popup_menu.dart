// lib/presentation/widgets/edit_popup_menu.dart
import 'package:flutter/material.dart';
import 'popup_menu_items/discussion_menu_items.dart';
import 'popup_menu_items/file_menu_items.dart';
import 'popup_menu_items/lifecycle_menu_items.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onAddPoint;
  final VoidCallback onRename;
  final VoidCallback onSetFilePath;
  final VoidCallback onGenerateHtml;
  final VoidCallback onEditFilePath;
  final VoidCallback onRemoveFilePath;
  final VoidCallback onMarkAsFinished;
  final VoidCallback onReactivate;
  final VoidCallback onDelete;
  final bool isFinished;
  final bool hasPoints;
  final bool hasFilePath;

  const EditPopupMenu({
    super.key,
    required this.onAddPoint,
    required this.onRename,
    required this.onSetFilePath,
    required this.onGenerateHtml,
    required this.onEditFilePath,
    required this.onRemoveFilePath,
    required this.onMarkAsFinished,
    required this.onReactivate,
    required this.onDelete,
    this.isFinished = false,
    this.hasPoints = false,
    this.hasFilePath = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        // Logika onSelected tetap sama
        if (value == 'add_point') onAddPoint();
        if (value == 'rename') onRename();
        if (value == 'set_file_path') onSetFilePath();
        if (value == 'generate_html') onGenerateHtml();
        if (value == 'edit_file_path') onEditFilePath();
        if (value == 'remove_file_path') onRemoveFilePath();
        if (value == 'finish') onMarkAsFinished();
        if (value == 'reactivate') onReactivate();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        // Gabungkan item menu dari komponen-komponen
        menuItems.addAll(
          buildDiscussionMenuItems(
            onAddPoint: onAddPoint,
            onRename: onRename,
            isFinished: isFinished,
          ),
        );

        if (!isFinished) {
          menuItems.add(const PopupMenuDivider());
          menuItems.addAll(
            buildFileMenuItems(
              hasFilePath: hasFilePath,
              onSetFilePath: onSetFilePath,
              onGenerateHtml: onGenerateHtml,
              onEditFilePath: onEditFilePath,
              onRemoveFilePath: onRemoveFilePath,
            ),
          );
        }

        // Tampilkan menu lifecycle hanya jika tidak ada poin
        if (!hasPoints) {
          menuItems.add(const PopupMenuDivider());
          menuItems.addAll(
            buildLifecycleMenuItems(
              isFinished: isFinished,
              onMarkAsFinished: onMarkAsFinished,
              onReactivate: onReactivate,
              onDelete: onDelete,
            ),
          );
        } else {
          menuItems.add(const PopupMenuDivider());
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        return menuItems;
      },
    );
  }
}
