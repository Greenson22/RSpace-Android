// lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_aplication/features/settings/application/theme_provider.dart';
import '../dialogs/theme_settings_dialog.dart';
import '../dialogs/quick_fab_settings_dialog.dart';
import '../dialogs/gemini_api_key_dialog.dart';
import '../dialogs/gemini_prompt_dialog.dart';
import '../dialogs/repetition_code_settings_dialog.dart';
import '../../../dashboard/presentation/dialogs/progress_settings_dialog.dart';
import '../../../dashboard/presentation/dialogs/task_settings_dialog.dart';
import '../dialogs/motivational_quotes_dialog.dart'; // IMPORT DIALOG BARU

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          _buildCategoryHeader(context, 'Tampilan'),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Tema & Tampilan',
            subtitle: 'Atur mode gelap, warna, latar belakang, dan lainnya.',
            onTap: () => showThemeSettingsDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.touch_app_outlined,
            title: 'Tombol Cepat (FAB)',
            subtitle: 'Atur visibilitas, ikon, dan transparansi tombol cepat.',
            onTap: () => showQuickFabSettingsDialog(context),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Tampilkan Karakter Flo'),
                subtitle: const Text('Asisten AI yang melayang di layar.'),
                value: themeProvider.showFloatingCharacter,
                onChanged: (value) => themeProvider.toggleFloatingCharacter(),
              );
            },
          ),
          const Divider(),
          _buildCategoryHeader(context, 'Fungsionalitas'),
          // >> TAMBAHKAN ITEM MENU BARU DI SINI <<
          _buildSettingsTile(
            context,
            icon: Icons.format_quote_outlined,
            title: 'Kata Motivasi',
            subtitle: 'Kelola dan buat daftar kata-kata motivasi harian.',
            onTap: () => showMotivationalQuotesDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.timer_outlined,
            title: 'Bobot Hari Repetisi',
            subtitle: 'Atur jumlah hari untuk setiap kode repetisi.',
            onTap: () => showDialog(
              context: context,
              builder: (_) => const RepetitionCodeSettingsDialog(),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.rule_folder_outlined,
            title: 'Progres Dashboard',
            subtitle: 'Pilih subjek yang dihitung dalam progres.',
            onTap: () => showProgressSettingsDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.playlist_add_check_circle_outlined,
            title: 'Tugas Dashboard',
            subtitle: 'Pilih kategori tugas yang akan dihitung.',
            onTap: () => showTaskSettingsDialog(context),
          ),
          const Divider(),
          _buildCategoryHeader(context, 'Kecerdasan Buatan (AI)'),
          _buildSettingsTile(
            context,
            icon: Icons.vpn_key_outlined,
            title: 'Manajemen API Key',
            subtitle: 'Kelola kunci API untuk layanan Gemini.',
            onTap: () => showGeminiApiKeyDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.smart_toy_outlined,
            title: 'Manajemen Prompt & Model',
            subtitle: 'Atur prompt kustom dan model AI yang digunakan.',
            onTap: () => showGeminiPromptDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
