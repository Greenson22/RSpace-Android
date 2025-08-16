// lib/presentation/pages/dashboard_page/widgets/dashboard_grid.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../1_topics_page.dart';
import '../../my_tasks_page.dart';
import '../../statistics_page.dart';
import '../../share_page.dart';
import '../../backup_management_page.dart';
import 'dashboard_item.dart';

// ==> TAMBAHAN: Fungsi untuk membangun daftar aksi di luar build method <==
List<VoidCallback> buildDashboardActions(
  BuildContext context, {
  required VoidCallback onShowStorageDialog,
}) {
  return [
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
      MaterialPageRoute(builder: (_) => const StatisticsPage()),
    ),
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SharePage()),
    ),
    onShowStorageDialog,
    () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackupManagementPage()),
    ),
  ];
}

class DashboardGrid extends StatelessWidget {
  // ==> TAMBAHAN: Properti baru <==
  final int focusedIndex;
  final List<VoidCallback> dashboardActions;

  const DashboardGrid({
    super.key,
    required this.focusedIndex,
    required this.dashboardActions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    const List<Color> gradientColors6 = [Color(0xFF7E57C2), Color(0xFF5E35B1)];

    final List<Map<String, dynamic>> itemData = [
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
        'icon': Icons.pie_chart_outline_rounded,
        'label': 'Statistik',
        'colors': AppTheme.gradientColors5,
      },
      {
        'icon': Icons.share_outlined,
        'label': 'Bagikan',
        'colors': const [Color(0xFF26A69A), Color(0xFF00796B)],
      },
      {
        'icon': Icons.folder_open_rounded,
        'label': 'Penyimpanan Utama',
        'colors': const [Color(0xFF78909C), Color(0xFF546E7A)],
      },
      {
        'icon': Icons.settings_backup_restore_rounded,
        'label': 'Manajemen Backup',
        'colors': gradientColors6,
      },
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: itemData.length,
      itemBuilder: (context, index) {
        final item = itemData[index];
        return DashboardItem(
          icon: item['icon'],
          label: item['label'],
          gradientColors: item['colors'],
          onTap: dashboardActions[index],
          isFocused:
              focusedIndex == index, // ==> Tentukan apakah item ini fokus
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
