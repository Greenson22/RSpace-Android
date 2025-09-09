// lib/features/dashboard/presentation/widgets/dashboard_app_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../about/presentation/pages/about_page.dart';
import '../../../ai_assistant/presentation/pages/chat_page.dart';
import '../../../settings/application/theme_provider.dart';
import '../../../settings/presentation/dialogs/gemini_api_key_dialog.dart';
import '../../../settings/presentation/dialogs/gemini_prompt_dialog.dart';
import '../../../settings/presentation/dialogs/quick_fab_settings_dialog.dart';
import '../../../settings/presentation/dialogs/theme_settings_dialog.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isPathSet;
  final VoidCallback onShowStorageDialog;
  final VoidCallback onSync;

  const DashboardAppBar({
    super.key,
    required this.isPathSet,
    required this.onShowStorageDialog,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final showFlo = themeProvider.showFloatingCharacter;
    final isTransparent = themeProvider.backgroundImagePath != null;

    return AppBar(
      title: const Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isTransparent ? 0 : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'Chat dengan Flo AI',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.sync_rounded),
          tooltip: 'Backup & Sync Otomatis',
          onPressed: onSync,
        ),
        PopupMenuButton<String>(
          tooltip: 'Opsi Lainnya',
          onSelected: (value) {
            if (value == 'theme_settings') {
              showThemeSettingsDialog(context);
            } else if (value == 'api_key') {
              showGeminiApiKeyDialog(context);
            } else if (value == 'prompt') {
              showGeminiPromptDialog(context);
            } else if (value == 'toggle_flo') {
              themeProvider.toggleFloatingCharacter();
            } else if (value == 'storage_path') {
              onShowStorageDialog();
            } else if (value == 'about') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            } else if (value == 'quick_fab_settings') {
              showQuickFabSettingsDialog(context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'theme_settings',
              child: ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('Pengaturan Tampilan'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'api_key',
              child: ListTile(
                leading: Icon(Icons.vpn_key_outlined),
                title: Text('Manajemen API Key'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'prompt',
              child: ListTile(
                leading: Icon(Icons.smart_toy_outlined),
                title: Text('Manajemen Prompt'),
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
            const PopupMenuItem<String>(
              value: 'quick_fab_settings',
              child: ListTile(
                leading: Icon(Icons.touch_app_outlined),
                title: Text('Pengaturan Tombol Cepat'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_flo',
              child: ListTile(
                leading: Icon(
                  showFlo
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                title: Text(
                  showFlo
                      ? 'Sembunyikan Karakter Flo'
                      : 'Tampilkan Karakter Flo',
                ),
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
