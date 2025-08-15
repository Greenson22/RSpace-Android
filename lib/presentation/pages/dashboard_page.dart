// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/services/path_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '../theme/app_theme.dart';
import '1_topics_page.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'about_page.dart';
import 'backup_management_page.dart';
import 'my_tasks_page.dart';
import 'share_page.dart';
import 'statistics_page.dart';

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
                    if (provider.recentColors.isEmpty)
                      return const SizedBox.shrink();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
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
                      _DashboardHeader(key: _dashboardPathKey),
                      const SizedBox(height: 20),
                      _buildResponsiveGridView(context, constraints.maxWidth),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveGridView(BuildContext context, double screenWidth) {
    int crossAxisCount;
    if (screenWidth > 900)
      crossAxisCount = 4;
    else if (screenWidth > 600)
      crossAxisCount = 3;
    else
      crossAxisCount = 2;

    const List<Color> gradientColors6 = [Color(0xFF7E57C2), Color(0xFF5E35B1)];

    // ==> DIHAPUS: Tombol "Penyimpanan" <==
    final List<Widget> dashboardItems = [
      _DashboardItem(
        icon: Icons.topic_outlined,
        label: 'Topics',
        gradientColors: AppTheme.gradientColors1,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TopicsPage()),
        ),
      ),
      _DashboardItem(
        icon: Icons.task_alt,
        label: 'My Tasks',
        gradientColors: AppTheme.gradientColors2,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTasksPage()),
        ),
      ),
      _DashboardItem(
        icon: Icons.pie_chart_outline_rounded,
        label: 'Statistik',
        gradientColors: AppTheme.gradientColors5,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsPage()),
        ),
      ),
      _DashboardItem(
        icon: Icons.share_outlined,
        label: 'Bagikan',
        gradientColors: const [Color(0xFF26A69A), Color(0xFF00796B)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SharePage()),
        ),
      ),
      _DashboardItem(
        icon: Icons.folder_open_rounded,
        label: 'Penyimpanan Utama', // Diubah labelnya agar lebih jelas
        gradientColors: const [Color(0xFF78909C), Color(0xFF546E7A)],
        onTap: () => _showStoragePathDialog(context),
      ),
      _DashboardItem(
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            ),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
              final time = DateFormat('HH:mm:ss').format(now);
              return Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(date, style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          const _DashboardPath(),
        ],
      ),
    );
  }
}

class _DashboardPath extends StatefulWidget {
  const _DashboardPath();

  @override
  State<_DashboardPath> createState() => _DashboardPathState();
}

class _DashboardPathState extends State<_DashboardPath> {
  final PathService _pathService = PathService();
  Future<String>? _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture = _pathService.contentsPath;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Text('Memuat path...');
        if (snapshot.hasError) return const Text('Gagal memuat path.');
        if (snapshot.hasData) {
          return Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.data!,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final Widget? child;

  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradientColors,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
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
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              child ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
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
}
