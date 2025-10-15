// lib/features/dashboard/presentation/widgets/dashboard_item.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../settings/application/theme_provider.dart';

enum DashboardItemType { quickAccess, listItem }

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final bool isFocused;
  final DashboardItemType type;

  const DashboardItem({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    required this.gradientColors,
    this.isFocused = false,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // ==> GUNAKAN CONSUMER UNTUK MENDAPATKAN NILAI OPACITY <==
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return switch (type) {
          DashboardItemType.quickAccess => _buildQuickAccess(
            context,
            themeProvider.dashboardComponentOpacity,
          ),
          DashboardItemType.listItem => _buildListItem(
            context,
            themeProvider.dashboardComponentOpacity,
          ),
        };
      },
    );
  }

  // ==> FUNGSI DIPERBARUI UNTUK MENERIMA OPACITY <==
  Widget _buildQuickAccess(BuildContext context, double opacity) {
    return Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(opacity),
                gradientColors[1].withOpacity(opacity),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).primaryColorLight,
                    width: 3,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==> FUNGSI DIPERBARUI UNTUK MENERIMA OPACITY <==
  Widget _buildListItem(BuildContext context, double opacity) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      // ==> TERAPKAN OPACITY PADA WARNA KARTU <==
      color: theme.cardColor.withOpacity(opacity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isFocused
            ? BorderSide(color: gradientColors[0], width: 2)
            : BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey[800] : Colors.grey[100])?.withOpacity(
              opacity,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: gradientColors[0], size: 24),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
