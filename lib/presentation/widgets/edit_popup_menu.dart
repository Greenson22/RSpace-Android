// lib/presentation/widgets/edit_popup_menu.dart
import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished;
  final VoidCallback? onAddPoint;
  final VoidCallback? onReactivate;
  final bool isFinished;
  final bool hasPoints;

  const EditPopupMenu({
    super.key,
    required this.onDateChange,
    required this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished,
    this.onAddPoint,
    this.onReactivate,
    this.isFinished = false,
    this.hasPoints = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
        if (value == 'rename' && onRename != null) onRename!();
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
        if (value == 'add_point' && onAddPoint != null) onAddPoint!();
        if (value == 'reactivate' && onReactivate != null) onReactivate!();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        if (!isFinished) {
          // Menu untuk item yang BELUM selesai
          if (onAddPoint != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'add_point',
                child: Text('Tambah Poin'),
              ),
            );
          }
          if (!hasPoints) {
            menuItems.addAll([
              const PopupMenuItem<String>(
                value: 'edit_date',
                child: Text('Ubah Tanggal'),
              ),
              const PopupMenuItem<String>(
                value: 'edit_code',
                child: Text('Ubah Kode Repetisi'),
              ),
            ]);
          }
          if (onRename != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Ubah Nama'),
              ),
            );
          }
          // --- PERUBAHAN DI SINI ---
          // Opsi "Tandai Selesai" hanya muncul jika tidak ada points
          if (onMarkAsFinished != null && !hasPoints) {
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'finish',
                child: Text('Tandai Selesai'),
              ),
            );
          }
        } else {
          // Menu untuk item yang SUDAH selesai
          if (!hasPoints) {
            menuItems.addAll([
              const PopupMenuItem<String>(
                value: 'edit_date',
                child: Text('Ubah Tanggal'),
              ),
              const PopupMenuItem<String>(
                value: 'edit_code',
                child: Text('Ubah Kode Repetisi'),
              ),
            ]);
          }
          if (onRename != null) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'rename',
                child: Text('Ubah Nama'),
              ),
            );
          }
          if (onReactivate != null) {
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'reactivate',
                child: Text('Aktifkan Lagi'),
              ),
            );
          }
        }

        return menuItems;
      },
    );
  }
}
