import 'package:flutter/material.dart';

class SubjectsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String topicName;
  final bool isSelectionMode;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final ValueChanged<String?> onMenuSelected;
  final VoidCallback onExportSelected;

  // 1. TAMBAHKAN PARAMETER INI
  final Color backgroundColor;

  const SubjectsAppBar({
    super.key,
    required this.topicName,
    required this.isSelectionMode,
    required this.isSearching,
    required this.searchController,
    required this.onToggleSearch,
    required this.onMenuSelected,
    required this.onExportSelected,
    required this.backgroundColor, // 2. TAMBAHKAN DI SINI JUGA (Wajib diisi)
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Jika sedang dalam mode seleksi (isSelectionMode), Anda bisa memilih
    // apakah mau pakai warna dinamis atau warna default selection Anda.
    // Di sini kita setel agar kedua kondisi menggunakan warna dinamis yang dikirim.

    return AppBar(
      // 3. PASANG WARNA DINAMIS DI SINI
      backgroundColor: backgroundColor,

      // 4. SETEL WARNA TEKS & IKON MENJADI PUTIH AGAR KONTRAS
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),

      leading: isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => onMenuSelected('clear_selection'),
            )
          : IconButton(
              // Tombol panah kembali kustom saat tidak dalam mode seleksi
              iconSize:
                  18.0, // <-- KONTROL UKURAN PANAH KEMBALI DI SINI (Default: 24.0)
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(
                context,
              ).pop(), // Aksi kembali ke halaman sebelumnya
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
      // === MODIFIKASI UKURAN IKON SEARCH & SHOW MENU DI SINI ===
      actions: [
        IconTheme(
          data: const IconThemeData(
            size:
                18.0, // <-- SILAKAN UBAH UKURAN IKON APP BAR DI SINI (Default: 24.0)
            color: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                      ), // atau Icons.upload_file untuk export
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
                      color: Colors
                          .white, // Latar belakang popup menu tetap putih bersih
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
