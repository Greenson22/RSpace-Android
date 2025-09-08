// lib/presentation/pages/dashboard_page/widgets/dashboard_grid.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/prompt_library/presentation/prompt_library_page.dart';
import 'package:provider/provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../content_management/presentation/topics/topics_page.dart';
import '../../../my_tasks/presentation/pages/my_tasks_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../backup_management/presentation/pages/backup_management_page.dart';
import '../../../file_management/presentation/pages/file_list_page.dart';
import '../../../feedback/presentation/pages/feedback_center_page.dart';
import '../../../time_management/presentation/pages/time_hub_page.dart';
import '../dialogs/data_management_dialog.dart';
import 'dashboard_item.dart';

// ==> FUNGSI INI DIPERBARUI <==
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
      MaterialPageRoute(builder: (_) => const TimeHubPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FileListPage()),
    ),
    // ==> PANGGIL FUNGSI UNTUK MENAMPILKAN DIALOG
    () => showDataManagementDialog(context),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackCenterPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PromptLibraryPage()),
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

        // ==> LIST DATA INI DIPERBARUI <==
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
            'icon': Icons.watch_later_outlined,
            'label': 'Waktu',
            'colors': AppTheme.gradientColors3,
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
          // ==> TOMBOL BARU DITAMBAHKAN DI SINI
          {
            'icon': Icons.construction_outlined,
            'label': 'Kelola Data',
            'colors': const [Color(0xFF78909C), Color(0xFF546E7A)],
          },
          {
            'icon': Icons.lightbulb_outline,
            'label': 'Pusat Umpan Balik',
            'colors': AppTheme.gradientColors6,
          },
          {
            'icon': Icons.library_books_outlined,
            'label': 'Pustaka Prompt',
            'colors': AppTheme.gradientColors7,
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
