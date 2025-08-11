import 'package:flutter/material.dart';

class EditPopupMenu extends StatelessWidget {
  final VoidCallback onDateChange;
  final VoidCallback onCodeChange;

  const EditPopupMenu({
    super.key,
    required this.onDateChange,
    required this.onCodeChange,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit_date') onDateChange();
        if (value == 'edit_code') onCodeChange();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit_date',
          child: Text('Ubah Tanggal'),
        ),
        const PopupMenuItem<String>(
          value: 'edit_code',
          child: Text('Ubah Kode Repetisi'),
        ),
      ],
    );
  }
}
