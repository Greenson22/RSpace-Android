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

        // Perubahan di sini: Ditambahkan onAddPoint == null
        // Blok ini sekarang hanya untuk menu Point, bukan Discussion
        if (onAddPoint == null &&
            onDateChange != null &&
            onCodeChange != null) {
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
          // Logika ini sekarang menjadi satu-satunya yang menambahkan
          // 'Ubah Tanggal' dan 'Ubah Kode' untuk Diskusi (jika tidak punya poin)
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
