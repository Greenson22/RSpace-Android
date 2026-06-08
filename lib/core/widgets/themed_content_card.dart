import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart'; // Sesuaikan path import

class ThemedContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailingIcon;
  final Widget? leadingIcon;

  const ThemedContentCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon,
    this.leadingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Memanggil warna secara otomatis berdasarkan judul dari AppTheme
    final gradient = AppTheme.getGradientForTitle(title);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Sudut lebih membulat
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading:
                leadingIcon ??
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.folder_special, color: Colors.white),
                ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            trailing:
                trailingIcon ??
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
