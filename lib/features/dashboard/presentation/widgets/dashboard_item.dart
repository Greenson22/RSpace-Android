// lib/presentation/pages/dashboard_page/widgets/dashboard_item.dart
import 'package:flutter/material.dart';

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Widget? child;
  final bool isFocused; // ==> TAMBAHKAN PROPERTI isFocused

  const DashboardItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradientColors,
    this.child,
    this.isFocused = false, // ==> SET NILAI DEFAULT
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: gradientColors[0].withOpacity(0.3),
        highlightColor: gradientColors[0].withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.grey[850] : Colors.white,
            border: isFocused
                ? Border.all(color: gradientColors[0], width: 3)
                : Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child:
              child ??
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.textTheme.bodyLarge?.color,
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
}
