// lib/presentation/widgets/edit_popup_menu.dart
import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback? onDateChange;
  final VoidCallback? onCodeChange;
  final VoidCallback? onRename;
  final VoidCallback? onMarkAsFinished;
  final VoidCallback? onAddPoint;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;
  final bool isFinished;
  final bool hasPoints;

  const EditPopupMenu({
    super.key,
    this.onDateChange,
    this.onCodeChange,
    this.onRename,
    this.onMarkAsFinished,
    this.onAddPoint,
    this.onReactivate,
    this.onDelete,
    this.isFinished = false,
    this.hasPoints = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date' && onDateChange != null) onDateChange!();
        if (value == 'edit_code' && onCodeChange != null) onCodeChange!();
        if (value == 'rename' && onRename != null) onRename!();
        if (value == 'finish' && onMarkAsFinished != null) onMarkAsFinished!();
        if (value == 'add_point' && onAddPoint != null) onAddPoint!();
        if (value == 'reactivate' && onReactivate != null) onReactivate!();
        if (value == 'delete' && onDelete != null) onDelete!();
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> menuItems = [];

        // Jika ini adalah menu untuk sebuah Point (ditandai dengan onAddPoint == null)
        if (onAddPoint == null) {
          if (!isFinished) {
            if (onDateChange != null) {
              menuItems.add(
                const PopupMenuItem<String>(
                  value: 'edit_date',
                  child: Text('Ubah Tanggal'),
                ),
              );
            }
            if (onCodeChange != null) {
              menuItems.add(
                const PopupMenuItem<String>(
                  value: 'edit_code',
                  child: Text('Ubah Kode Repetisi'),
                ),
              );
            }
          }
        }

        // Jika ini adalah menu untuk Diskusi
        if (onAddPoint != null) {
          if (!isFinished) {
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'add_point',
                child: Text('Tambah Poin'),
              ),
            );
          }
          if (!hasPoints) {
            if (onDateChange != null) {
              menuItems.add(
                const PopupMenuItem<String>(
                  value: 'edit_date',
                  child: Text('Ubah Tanggal'),
                ),
              );
            }
            if (onCodeChange != null) {
              menuItems.add(
                const PopupMenuItem<String>(
                  value: 'edit_code',
                  child: Text('Ubah Kode Repetisi'),
                ),
              );
            }
          }
        }

        if (onRename != null) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: 'rename',
              child: Text('Ubah Nama'),
            ),
          );
        }

        if (!isFinished) {
          // Berlaku untuk Diskusi (jika tidak punya point) dan Point
          if (onMarkAsFinished != null && (onAddPoint == null || !hasPoints)) {
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'finish',
                child: Text('Tandai Selesai'),
              ),
            );
          }
        } else {
          // PERUBAHAN UTAMA: Hanya tampilkan "Aktifkan Lagi" jika tidak memiliki point
          if (onReactivate != null && !hasPoints) {
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'reactivate',
                child: Text('Aktifkan Lagi'),
              ),
            );
          } else if (onReactivate != null && onAddPoint == null) {
            // Ini untuk point, selalu tampilkan
            menuItems.add(const PopupMenuDivider());
            menuItems.add(
              const PopupMenuItem<String>(
                value: 'reactivate',
                child: Text('Aktifkan Lagi'),
              ),
            );
          }
        }

        if (onDelete != null) {
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
