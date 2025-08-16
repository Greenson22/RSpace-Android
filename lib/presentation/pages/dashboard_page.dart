// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/debug_provider.dart';
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

  final FocusNode _focusNode = FocusNode();
  int _focusedIndex = 0;
  List<VoidCallback> _dashboardActions = [];

  // Timer dan flag untuk mengontrol visibilitas border
  Timer? _focusTimer;
  bool _isKeyboardActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusTimer?.cancel(); // Batalkan timer saat dispose
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Hanya aktifkan timer saat tombol panah ditekan
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => _isKeyboardActive = true);
        _focusTimer?.cancel();
        _focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isKeyboardActive = false);
          }
        });

        final totalItems = _dashboardActions.length;
        if (totalItems == 0) return;

        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount;
        if (screenWidth > 900) {
          crossAxisCount = 4;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        setState(() {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _focusedIndex = (_focusedIndex + crossAxisCount);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _focusedIndex = (_focusedIndex - crossAxisCount);
            if (_focusedIndex < 0) _focusedIndex = 0;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _focusedIndex = (_focusedIndex + 1);
            if (_focusedIndex >= totalItems) _focusedIndex = totalItems - 1;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _focusedIndex = (_focusedIndex - 1);
            if (_focusedIndex < 0) _focusedIndex = 0;
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_focusedIndex < _dashboardActions.length) {
          _dashboardActions[_focusedIndex]();
        }
      }
    }
  }

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
    final debugProvider = Provider.of<DebugProvider>(context);

    _dashboardActions = buildDashboardActions(
      context,
      onShowStorageDialog: () {
        if (!kDebugMode || debugProvider.allowPathChanges) {
          _showStoragePathDialog(context);
        } else {
          showAppSnackBar(
            context,
            'Ubah path dinonaktifkan. Aktifkan melalui ikon developer di AppBar.',
            isError: true,
          );
        }
      },
    );

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (kDebugMode)
              IconButton(
                icon: Icon(
                  debugProvider.allowPathChanges
                      ? Icons.developer_mode
                      : Icons.developer_mode_outlined,
                  color: debugProvider.allowPathChanges ? Colors.amber : null,
                ),
                onPressed: () {
                  debugProvider.togglePathChanges();
                  final message = debugProvider.allowPathChanges
                      ? 'Perubahan path diaktifkan.'
                      : 'Perubahan path dinonaktifkan.';
                  showAppSnackBar(context, message);
                },
                tooltip: 'Aktifkan/Nonaktifkan Ubah Path (Debug)',
              ),
            IconButton(
              icon: const Icon(Icons.color_lens_outlined),
              onPressed: () => _showColorPickerDialog(context),
              tooltip: 'Ganti Warna Primer',
            ),
            IconButton(
              icon: Icon(
                themeProvider.darkTheme
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
              ),
              onPressed: () =>
                  themeProvider.darkTheme = !themeProvider.darkTheme,
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
                      isKeyboardActive: _isKeyboardActive,
                      focusedIndex: _focusedIndex,
                      dashboardActions: _dashboardActions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
