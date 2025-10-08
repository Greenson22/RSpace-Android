// lib/features/dashboard/presentation/widgets/dashboard_app_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../about/presentation/pages/about_page.dart';
import '../../../ai_assistant/presentation/pages/chat_page.dart';
import '../../../settings/application/theme_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../auth/presentation/profile_page.dart';
import '../../../auth/application/auth_provider.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isPathSet;
  final bool isApiConfigured;
  final VoidCallback onShowStorageDialog;
  final VoidCallback onSync;
  final VoidCallback onRefresh;

  const DashboardAppBar({
    super.key,
    required this.isPathSet,
    required this.isApiConfigured,
    required this.onShowStorageDialog,
    required this.onSync,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTransparent = themeProvider.backgroundImagePath != null;

    return AppBar(
      title: const Text(
        '🚀 RSpace',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isTransparent ? 0 : null,
      actions: [
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.authState == AuthState.authenticated && isApiConfigured) {
              return IconButton(
                icon: const Icon(Icons.sync_rounded),
                tooltip: 'Backup & Sync Otomatis',
                onPressed: onSync,
              );
            }
            return const SizedBox.shrink();
          },
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          tooltip: 'Profil & Akun',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Chat dengan Flo AI',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Opsi Lainnya',
          onSelected: (value) async {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            } else if (value == 'storage_path') {
              onShowStorageDialog();
            } else if (value == 'about') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Pengaturan'),
              ),
            ),
            if (isPathSet)
              const PopupMenuItem<String>(
                value: 'storage_path',
                child: ListTile(
                  leading: Icon(Icons.folder_open_rounded),
                  title: Text('Ubah Penyimpanan Utama'),
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Tentang Aplikasi'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
