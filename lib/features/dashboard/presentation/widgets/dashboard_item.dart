// lib/features/dashboard/presentation/widgets/dashboard_item.dart

import 'package:flutter/material.dart';

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
    return switch (type) {
      DashboardItemType.quickAccess => _buildQuickAccess(context),
      DashboardItemType.listItem => _buildListItem(context),
    };
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(15), // Mengurangi radius border
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15), // Mengurangi radius border
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15), // Mengurangi radius border
            gradient: LinearGradient(
              colors: gradientColors,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 28,
                color: Colors.white,
              ), // Ukuran ikon lebih kecil
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12, // Ukuran font lebih kecil
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
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
            color: (isDark ? Colors.grey[800] : Colors.grey[100]),
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
