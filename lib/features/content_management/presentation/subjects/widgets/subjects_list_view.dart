// lib/features/content_management/presentation/subjects/widgets/subjects_list_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/application/subject_provider.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/widgets/subject_list_tile.dart';

class SubjectsListView extends StatelessWidget {
  final bool isKeyboardActive;
  final int focusedIndex;
  // Callbacks
  final Function(BuildContext, Subject) onTap;
  final Function(BuildContext, Subject)
  onEdit; // DIUBAH: Menggabungkan onRename dan onIconChange menjadi onEdit
  final Function(BuildContext, Subject) onDelete;
  final Function(BuildContext, Subject) onToggleVisibility;
  final Function(BuildContext, Subject) onLinkPath;
  final Function(BuildContext, Subject) onEditIndexFile;
  final Function(BuildContext, Subject) onMove;
  final Function(BuildContext, Subject) onToggleFreeze;
  final Function(BuildContext, Subject) onToggleLock;
  final Function(BuildContext, Subject) onTimeline;
  final Function(BuildContext, Subject) onViewJson;
  final Function(BuildContext, Subject) onExport;

  const SubjectsListView({
    super.key,
    required this.isKeyboardActive,
    required this.focusedIndex,
    required this.onTap,
    required this.onEdit, // DIUBAH
    required this.onDelete,
    required this.onToggleVisibility,
    required this.onLinkPath,
    required this.onEditIndexFile,
    required this.onMove,
    required this.onToggleFreeze,
    required this.onToggleLock,
    required this.onTimeline,
    required this.onViewJson,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty State Checks
        if (provider.allSubjects.isEmpty) {
          return _buildNoContentState();
        }

        final subjectsToShow = provider.filteredSubjects;
        if (subjectsToShow.isEmpty) {
          return _buildFilteredEmptyState(provider);
        }

        return ListView.builder(
          // MODIFIKASI: Padding atas-bawah disesuaikan agar lebih rapat
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subject = subjectsToShow[index];
            return SubjectListTile(
              key: ValueKey(subject.name + subject.position.toString()),
              subject: subject,
              isFocused: isKeyboardActive && index == focusedIndex,
              onTap: () => onTap(context, subject),
              onEdit: () => onEdit(
                context,
                subject,
              ), // DIUBAH: Mengikuti parameter baru milik SubjectListTile
              onDelete: () => onDelete(context, subject),
              onToggleVisibility: () => onToggleVisibility(context, subject),
              onLinkPath: () => onLinkPath(context, subject),
              onEditIndexFile: () => onEditIndexFile(context, subject),
              onMove: () => onMove(context, subject),
              onToggleFreeze: () => onToggleFreeze(context, subject),
              onToggleLock: () => onToggleLock(context, subject),
              onTimeline: () => onTimeline(context, subject),
              onViewJson: () => onViewJson(context, subject),
              onExport: () => onExport(context, subject),
            );
          },
        );
      },
    );
  }

  Widget _buildNoContentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.class_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Subject',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambah subject di topik ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyState(SubjectProvider provider) {
    final isSearching = provider.searchQuery.isNotEmpty;
    if (isSearching) {
      return const Center(child: Text('Subject tidak ditemukan.'));
    } else if (!provider.showHiddenSubjects) {
      return const Center(
        child: Text(
          'Tidak ada subject yang terlihat.\nCoba tampilkan subject tersembunyi.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
