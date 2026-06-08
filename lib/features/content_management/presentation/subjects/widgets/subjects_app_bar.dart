// lib/features/content_management/presentation/subjects/widgets/subjects_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/application/subject_provider.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/dialogs/subject_sort_dialog.dart';

class SubjectsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String topicName;
  final bool isSelectionMode;
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final Function(String) onMenuSelected;
  final VoidCallback onExportSelected;

  const SubjectsAppBar({
    super.key,
    required this.topicName,
    required this.isSelectionMode,
    required this.isSearching,
    required this.searchController,
    required this.onToggleSearch,
    required this.onMenuSelected,
    required this.onExportSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    final theme = Theme.of(context);

    // Ambil warna teks default dari tema untuk mengatasi tulisan putih di background putih
    final Color defaultTextColor =
        theme.textTheme.bodyLarge?.color ?? Colors.black87;

    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // --- SKALA UKURAN APPBAR UNTUK MOBILE ---
    const double baseAppBarIconSize = 20.0; // Diturunkan dari 24.0
    final scaledIconSize = baseAppBarIconSize * textScaleFactor;

    if (isSelectionMode) {
      return AppBar(
        title: Text(
          '${provider.selectedSubjects.length} dipilih',
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          iconSize: scaledIconSize,
          onPressed: () => provider.clearSelection(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            iconSize: scaledIconSize,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onExportSelected,
            tooltip: 'Export/Zip Selected Subjects',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.select_all),
            iconSize: scaledIconSize,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => provider.selectAllFilteredSubjects(),
            tooltip: 'Pilih Semua',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.visibility_off_outlined),
            iconSize: scaledIconSize,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => provider.toggleVisibilitySelectedSubjects(),
            tooltip: 'Sembunyikan/Tampilkan Pilihan',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.ac_unit_outlined),
            iconSize: scaledIconSize,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => provider.toggleFreezeSelectedSubjects(),
            tooltip: 'Bekukan/Cairkan Pilihan',
          ),
          const SizedBox(width: 12),
        ],
      );
    }

    return AppBar(
      leadingWidth: 48.0, // Mengharmoniskan lebar tombol back bawaan
      iconTheme: IconThemeData(
        size: scaledIconSize,
      ), // Memaksa back arrow mengikuti skala kecil
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari subject...',
                border: InputBorder.none,
                // PERBAIKAN WARNA: Mengubah hint text agar menggunakan warna kontras tema
                hintStyle: TextStyle(color: defaultTextColor.withOpacity(0.5)),
              ),
              // PERBAIKAN WARNA: Mengubah text warna ketikan agar mengikuti kontras tema (gelap/hitam)
              style: TextStyle(
                color: defaultTextColor,
                fontSize: 16.0, // Pengecilan teks cari untuk mobile
              ),
            )
          : Text(
              'Subjects: $topicName',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ), // Judul utama diperkecil
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          iconSize: scaledIconSize,
          padding:
              EdgeInsets.zero, // Memaksimalkan area klik di ruang sempit mobile
          constraints: const BoxConstraints(),
          onPressed: onToggleSearch,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.sort),
          iconSize: scaledIconSize,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Urutkan Subject',
          onPressed: () => showSubjectSortDialog(context: context),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          iconSize: scaledIconSize,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onSelected: onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'import_zip',
              child: ListTile(
                leading: Icon(Icons.folder_zip, size: 20),
                title: Text('Import ZIP', style: TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'show_hidden',
              child: ListTile(
                leading: Icon(
                  provider.showHiddenSubjects
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
                title: Text(
                  provider.showHiddenSubjects
                      ? 'Sembunyikan Tersembunyi'
                      : 'Tampilkan Tersembunyi',
                  style: const TextStyle(fontSize: 14),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12.0), // Jarak aman ujung kanan AppBar
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
