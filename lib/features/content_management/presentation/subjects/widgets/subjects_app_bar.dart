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

    if (isSelectionMode) {
      return AppBar(
        title: Text('${provider.selectedSubjects.length} dipilih'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => provider.clearSelection(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: onExportSelected,
            tooltip: 'Export/Zip Selected Subjects',
          ),
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => provider.selectAllFilteredSubjects(),
            tooltip: 'Pilih Semua',
          ),
          IconButton(
            icon: const Icon(Icons.visibility_off_outlined),
            onPressed: () => provider.toggleVisibilitySelectedSubjects(),
            tooltip: 'Sembunyikan/Tampilkan Pilihan',
          ),
          IconButton(
            icon: const Icon(Icons.ac_unit_outlined),
            onPressed: () => provider.toggleFreezeSelectedSubjects(),
            tooltip: 'Bekukan/Cairkan Pilihan',
          ),
        ],
      );
    }

    return AppBar(
      title: isSearching
          ? TextField(
              controller: searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Cari subject...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            )
          : Text(
              'Subjects: $topicName',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
      actions: [
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: onToggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: 'Urutkan Subject',
          onPressed: () => showSubjectSortDialog(context: context),
        ),
        PopupMenuButton<String>(
          onSelected: onMenuSelected,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'import_zip',
              child: ListTile(
                leading: Icon(Icons.folder_zip),
                title: Text('Import ZIP'),
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
                ),
                title: Text(
                  provider.showHiddenSubjects
                      ? 'Sembunyikan Subjects Tersembunyi'
                      : 'Tampilkan Subjects Tersembunyi',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
