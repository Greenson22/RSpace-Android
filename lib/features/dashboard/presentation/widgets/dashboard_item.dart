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
    return Material(
      borderRadius: BorderRadius.circular(20),
      color: theme.cardTheme.color ?? theme.cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: gradientColors[0].withOpacity(0.3),
        highlightColor: gradientColors[0].withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isFocused
                ? Border.all(color: gradientColors[0], width: 3)
                : null,
          ),
          child:
              child ??
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
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
