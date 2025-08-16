// lib/presentation/pages/dashboard_page/widgets/dashboard_grid.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../1_topics_page.dart';
import '../../my_tasks_page.dart';
import '../../statistics_page.dart';
import '../../share_page.dart';
import '../../backup_management_page.dart';
import 'dashboard_item.dart';

class DashboardGrid extends StatelessWidget {
  final VoidCallback onShowStorageDialog;

  const DashboardGrid({super.key, required this.onShowStorageDialog});

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

    final List<Widget> dashboardItems = [
      DashboardItem(
        icon: Icons.topic_outlined,
        label: 'Topics',
        gradientColors: AppTheme.gradientColors1,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TopicsPage()),
        ),
      ),
      DashboardItem(
        icon: Icons.task_alt,
        label: 'My Tasks',
        gradientColors: AppTheme.gradientColors2,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTasksPage()),
        ),
      ),
      DashboardItem(
        icon: Icons.pie_chart_outline_rounded,
        label: 'Statistik',
        gradientColors: AppTheme.gradientColors5,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsPage()),
        ),
      ),
      DashboardItem(
        icon: Icons.share_outlined,
        label: 'Bagikan',
        gradientColors: const [Color(0xFF26A69A), Color(0xFF00796B)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SharePage()),
        ),
      ),
      DashboardItem(
        icon: Icons.folder_open_rounded,
        label: 'Penyimpanan Utama',
        gradientColors: const [Color(0xFF78909C), Color(0xFF546E7A)],
        onTap: onShowStorageDialog,
      ),
      DashboardItem(
        icon: Icons.settings_backup_restore_rounded,
        label: 'Manajemen Backup',
        gradientColors: gradientColors6,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupManagementPage()),
        ),
      ),
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: dashboardItems.length,
      itemBuilder: (context, index) => dashboardItems[index],
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
