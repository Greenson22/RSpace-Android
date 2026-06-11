// lib/features/content_management/presentation/subjects/widgets/subjects_app_bar.dart
import 'package:flutter/material.dart';

class SubjectsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String topicName;
  final bool isSelectionMode;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final ValueChanged<String?> onMenuSelected;
  final VoidCallback onExportSelected;
  final Color backgroundColor;

  // CALLBACK UNTUK BERSIHKAN SELEKSI, BEKUKAN MASSAL, & SEMBUNYIKAN MASSAL
  final VoidCallback onClearSelection;
  final VoidCallback onBulkFreezeSelected;
  final VoidCallback onBulkHideSelected; // Tambahan untuk sembunyikan massal

  const SubjectsAppBar({
    super.key,
    required this.topicName,
    required this.isSelectionMode,
    required this.isSearching,
    required this.searchController,
    required this.onToggleSearch,
    required this.onMenuSelected,
    required this.onExportSelected,
    required this.backgroundColor,
    required this.onClearSelection,
    required this.onBulkFreezeSelected,
    required this.onBulkHideSelected, // Wajib diisi
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClearSelection, // Memperbaiki fungsi tombol X
            )
          : IconButton(
              iconSize: 18.0,
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari subject...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
            )
          : Text(
              isSelectionMode ? 'Pilih Subject' : topicName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        IconTheme(
          data: const IconThemeData(size: 18.0, color: Colors.white),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isSelectionMode
                ? [
                    // TOMBOL: BEKUKAN MASSAL (BULK FREEZE)
                    IconButton(
                      icon: const Icon(Icons.ac_unit),
                      onPressed: onBulkFreezeSelected,
                      tooltip: 'Bekukan Terpilih',
                    ),
                    // TOMBOL BARU: SEMBUNYIKAN MASSAL (BULK HIDE)
                    IconButton(
                      icon: const Icon(Icons.visibility_off),
                      onPressed: onBulkHideSelected,
                      tooltip: 'Sembunyikan Terpilih',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: onExportSelected,
                      tooltip: 'Export Terpilih',
                    ),
                    const SizedBox(width: 12.0),
                  ]
                : [
                    IconButton(
                      icon: Icon(isSearching ? Icons.close : Icons.search),
                      onPressed: onToggleSearch,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      color: Colors.white,
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'import_zip',
                          child: Text('Import ZIP'),
                        ),
                        const PopupMenuItem(
                          value: 'show_hidden',
                          child: Text('Tampilkan yang Disembunyikan'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12.0),
                  ],
          ),
        ),
      ],
    );
  }
}
