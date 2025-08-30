// lib/presentation/pages/dashboard_page/widgets/dashboard_grid.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme/app_theme.dart';
import '../../1_topics_page.dart';
import '../../my_tasks_page.dart';
import '../../statistics_page.dart';
import '../../backup_management_page.dart';
import '../../file_list_page.dart';
import '../../time_log_page.dart';
import '../../orphaned_files_page.dart';
import '../../unlinked_discussions_page.dart';
import '../../broken_links_page.dart'; // ==> IMPORT HALAMAN BARU
import '../../feedback_center_page.dart';
import 'dashboard_item.dart';

List<VoidCallback> buildDashboardActions(
  BuildContext context, {
  required VoidCallback onShowStorageDialog,
  required bool isPathSet,
}) {
  final List<VoidCallback?> actions = [
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TopicsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyTasksPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeLogPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnlinkedDiscussionsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrphanedFilesPage()),
    ),
    // ==> TAMBAHKAN AKSI BARU DI SINI <==
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrokenLinksPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackCenterPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FileListPage()),
    ),
    if (!isPathSet) onShowStorageDialog,
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupManagementPage()),
    ),
  ];
  return actions.whereType<VoidCallback>().toList();
}

class DashboardGrid extends StatelessWidget {
  final int focusedIndex;
  final List<VoidCallback> dashboardActions;
  final bool isKeyboardActive;
  final bool isPathSet;

  const DashboardGrid({
    super.key,
    required this.focusedIndex,
    required this.dashboardActions,
    required this.isKeyboardActive,
    required this.isPathSet,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount;
        if (screenWidth > 900) {
          crossAxisCount = 4;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // Hapus item menu AI dari daftar ini
        final List<Map<String, dynamic>> allItemData = [
          {
            'icon': Icons.topic_outlined,
            'label': 'Topics',
            'colors': AppTheme.gradientColors1,
          },
          {
            'icon': Icons.task_alt,
            'label': 'My Tasks',
            'colors': AppTheme.gradientColors2,
          },
          {
            'icon': Icons.cleaning_services_outlined,
            'label': 'File Yatim',
            'colors': const [Color(0xFFBDBDBD), Color(0xFF616161)],
          },
          {
            'icon': Icons.heart_broken_outlined,
            'label': 'Cek Tautan Rusak',
            'colors': const [Color(0xFFE57373), Color(0xFFC62828)],
          },
          {
            'icon': Icons.lightbulb_outline,
            'label': 'Pusat Umpan Balik',
            'colors': AppTheme.gradientColors6,
          },
          // ==> TAMBAHKAN DATA ITEM BARU DI SINI <==
          {
            'icon': Icons.cleaning_services_outlined,
            'label': 'File Yatim',
            'colors': const [Color(0xFFBDBDBD), Color(0xFF616161)],
          },
          {
            'icon': Icons.lightbulb_outline,
            'label': 'Pusat Umpan Balik',
            'colors': AppTheme.gradientColors6,
          },
          {
            'icon': Icons.pie_chart_outline_rounded,
            'label': 'Statistik',
            'colors': AppTheme.gradientColors5,
          },
          {
            'icon': Icons.cloud_outlined,
            'label': 'File Online',
            'colors': AppTheme.gradientColors4,
          },
          {
            'icon': Icons.folder_open_rounded,
            'label': 'Penyimpanan Utama',
            'colors': const [Color(0xFF78909C), Color(0xFF546E7A)],
          },
          {
            'icon': Icons.settings_backup_restore_rounded,
            'label': 'Manajemen Backup',
            'colors': const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
          },
        ];

        final List<Map<String, dynamic>> itemData = allItemData
            .where((item) => item['label'] != 'Penyimpanan Utama' || !isPathSet)
            .toList();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0 / themeProvider.dashboardItemScale,
          ),
          itemCount: itemData.length,
          itemBuilder: (context, index) {
            final item = itemData[index];
            return DashboardItem(
              icon: item['icon'],
              label: item['label'],
              gradientColors: item['colors'],
              onTap: dashboardActions[index],
              isFocused: isKeyboardActive && focusedIndex == index,
            );
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        );
      },
    );
  }
}
