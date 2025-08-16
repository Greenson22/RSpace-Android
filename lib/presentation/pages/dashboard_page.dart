// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '../theme/app_theme.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'about_page.dart';
import 'dashboard_page/widgets/dashboard_grid.dart';
import 'dashboard_page/widgets/dashboard_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Key _dashboardPathKey = UniqueKey();

  Future<void> _showStoragePathDialog(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan Utama',
    );

    if (selectedDirectory != null) {
      final prefsService = SharedPreferencesService();
      await prefsService.saveCustomStoragePath(selectedDirectory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mengubah lokasi dan memuat ulang data...'),
          ),
        );

        final topicProvider = Provider.of<TopicProvider>(
          context,
          listen: false,
        );
        final statisticsProvider = Provider.of<StatisticsProvider>(
          context,
          listen: false,
        );

        await Future.wait([
          topicProvider.fetchTopics(),
          statisticsProvider.generateStatistics(),
        ]);

        setState(() {
          _dashboardPathKey = UniqueKey();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          showAppSnackBar(
            context,
            'Lokasi penyimpanan diubah dan data berhasil dimuat ulang.',
          );
        }
      }
    } else {
      if (mounted) showAppSnackBar(context, 'Pemilihan folder dibatalkan.');
    }
  }

  void _showColorPickerDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    Color pickerColor = themeProvider.primaryColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Warna Primer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) => pickerColor = color,
                  labelTypes: const [ColorLabelType.hex],
                  pickerAreaHeightPercent: 0.8,
                  enableAlpha: false,
                ),
                const Divider(),
                Text(
                  'Pilihan Warna',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                BlockPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (color) {
                    pickerColor = color;
                    themeProvider.setPrimaryColor(pickerColor);
                    Navigator.of(context).pop();
                  },
                  availableColors: AppTheme.selectableColors,
                  layoutBuilder: (context, colors, child) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) => child(color)).toList(),
                    );
                  },
                ),
                const Divider(),
                Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    if (provider.recentColors.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Warna Terakhir Digunakan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        BlockPicker(
                          pickerColor: pickerColor,
                          onColorChanged: (color) {
                            pickerColor = color;
                            themeProvider.setPrimaryColor(pickerColor);
                            Navigator.of(context).pop();
                          },
                          availableColors: provider.recentColors,
                          layoutBuilder: (context, colors, child) {
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: colors
                                  .map((color) => child(color))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Pilih'),
              onPressed: () {
                themeProvider.setPrimaryColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens_outlined),
            onPressed: () => _showColorPickerDialog(context),
            tooltip: 'Ganti Warna Primer',
          ),
          IconButton(
            icon: Icon(
              themeProvider.darkTheme ? Icons.wb_sunny : Icons.nightlight_round,
            ),
            onPressed: () => themeProvider.darkTheme = !themeProvider.darkTheme,
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
            tooltip: 'Tentang Aplikasi',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: () async {
                await Provider.of<TopicProvider>(
                  context,
                  listen: false,
                ).fetchTopics();
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  DashboardHeader(key: _dashboardPathKey),
                  const SizedBox(height: 20),
                  DashboardGrid(
                    onShowStorageDialog: () => _showStoragePathDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
