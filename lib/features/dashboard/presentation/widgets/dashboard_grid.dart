// lib/features/dashboard/presentation/widgets/dashboard_grid.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/perpusku/presentation/pages/perpusku_topic_page.dart'; // IMPORT BARU
import 'package:my_aplication/features/prompt_library/presentation/prompt_library_page.dart';
import 'package:my_aplication/features/snake_game/presentation/pages/snake_game_page.dart';
import 'package:provider/provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../content_management/presentation/topics/topics_page.dart';
import '../../../my_tasks/presentation/pages/my_tasks_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../backup_management/presentation/pages/backup_management_page.dart';
import '../../../file_management/presentation/pages/file_list_page.dart';
import '../../../feedback/presentation/pages/feedback_center_page.dart';
import '../../../time_management/presentation/pages/time_log_page.dart';
import '../dialogs/data_management_dialog.dart';
import 'dashboard_item.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import 'package:my_aplication/features/quiz/presentation/pages/quiz_category_page.dart'; // UBAH IMPORT
import '../../../webview_page/presentation/pages/webview_page.dart';

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
    // ==> TAMBAHKAN NAVIGASI BARU DI SINI (SESUAIKAN URUTAN JIKA PERLU)
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerpuskuTopicPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyTasksPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgressPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimeLogPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuizCategoryPage(),
      ), // UBAH NAVIGASI
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FileListPage()),
    ),
    () => showDataManagementDialog(context),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackCenterPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PromptLibraryPage()),
    ),
    // --- PERUBAHAN DI SINI ---
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SnakeGamePage()),
    ),
    if (Platform.isAndroid)
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WebViewPage(
            initialUrl: 'https://www.google.com',
            title: 'Web Browser',
          ),
        ),
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

        final List<Map<String, dynamic>> allItemData = [
          {
            'icon': Icons.topic_outlined,
            'label': 'Topics',
            'subtitle': 'Kelola semua materi Anda',
            'colors': AppTheme.gradientColors1,
          },
          // ==> TAMBAHKAN ITEM BARU DI SINI
          {
            'icon': Icons.menu_book_outlined,
            'label': 'Perpusku',
            'subtitle': 'Jelajahi file materi Anda',
            'colors': AppTheme.gradientColors8,
          },
          {
            'icon': Icons.task_alt,
            'label': 'My Tasks',
            'subtitle': 'Lacak semua tugas Anda',
            'colors': AppTheme.gradientColors2,
          },
          {
            'icon': Icons.show_chart,
            'label': 'Progress',
            'subtitle': 'Lihat progress belajar',
            'colors': AppTheme.gradientColors9,
          },
          {
            'icon': Icons.timer_outlined,
            'label': 'Jurnal',
            'subtitle': 'Catat & lihat aktivitas',
            'colors': AppTheme.gradientColors3,
          },
          {
            'icon': Icons.pie_chart_outline_rounded,
            'label': 'Statistik',
            'subtitle': 'Lihat progres & data',
            'colors': AppTheme.gradientColors5,
          },
          {
            'icon': Icons.quiz_outlined,
            'label': 'Kuis',
            'subtitle': 'Uji pemahaman Anda',
            'colors': const [Color(0xFF43A047), Color(0xFF66BB6A)],
          },
          {
            'icon': Icons.cloud_outlined,
            'label': 'File Online',
            'subtitle': 'Akses file dari server',
            'colors': AppTheme.gradientColors4,
          },
          {
            'icon': Icons.construction_outlined,
            'label': 'Kelola Data',
            'subtitle': 'Perawatan & manajemen data',
            'colors': const [Color(0xFF78909C), Color(0xFF546E7A)],
          },
          {
            'icon': Icons.lightbulb_outline,
            'label': 'Umpan Balik',
            'subtitle': 'Kirim ide, bug, atau saran',
            'colors': AppTheme.gradientColors6,
          },
          {
            'icon': Icons.library_books_outlined,
            'label': 'Pustaka Prompt',
            'subtitle': 'Simpan & kelola prompt AI',
            'colors': AppTheme.gradientColors7,
          },
          {
            'icon': Icons.catching_pokemon,
            'label': 'Game Ular AI',
            'subtitle': 'Latih & lihat AI bermain ular',
            'colors': const [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          },
          if (Platform.isAndroid)
            {
              'icon': Icons.public,
              'label': 'WebView',
              'subtitle': 'Buka halaman web',
              'colors': const [Color(0xFF1E88E5), Color(0xFF42A5F5)],
            },
          {
            'icon': Icons.folder_open_rounded,
            'label': 'Penyimpanan',
            'subtitle': 'Atur lokasi penyimpanan data',
            'colors': const [Color(0xFF78909C), Color(0xFF546E7A)],
          },
          {
            'icon': Icons.settings_backup_restore_rounded,
            'label': 'Backup',
            'subtitle': 'Cadangkan & pulihkan data',
            'colors': AppTheme.gradientColors8,
          },
        ];

        final List<Map<String, dynamic>> itemData = allItemData
            .where((item) => item['label'] != 'Penyimpanan' || !isPathSet)
            .toList();

        final quickAccessItems = itemData.take(5).toList();
        final listItems = itemData.skip(5).toList();
        final quickAccessCrossAxisCount = screenWidth < 450 ? 2 : 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: quickAccessCrossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: quickAccessItems.length,
              itemBuilder: (context, index) {
                final item = quickAccessItems[index];
                return DashboardItem(
                  icon: item['icon'],
                  label: item['label'],
                  gradientColors: item['colors'],
                  onTap: dashboardActions[index],
                  isFocused: isKeyboardActive && focusedIndex == index,
                  type: DashboardItemType.quickAccess,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              "Fitur Lainnya",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListView.separated(
              itemCount: listItems.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = listItems[index];
                final overallIndex = index + 5;
                return DashboardItem(
                  icon: item['icon'],
                  label: item['label'],
                  subtitle: item['subtitle'],
                  gradientColors: item['colors'],
                  onTap: dashboardActions[overallIndex],
                  isFocused: isKeyboardActive && focusedIndex == overallIndex,
                  type: DashboardItemType.listItem,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
