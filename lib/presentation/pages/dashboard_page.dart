// lib/presentation/pages/dashboard_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topic_provider.dart';
import '1_topics_page/utils/scaffold_messenger_utils.dart';
import 'about_page.dart';
import 'dashboard_page/widgets/dashboard_grid.dart';
import 'dashboard_page/widgets/dashboard_header.dart';
import 'dashboard_page/dialogs/theme_settings_dialog.dart';
import 'dashboard_page/dialogs/gemini_api_key_dialog.dart';
import 'dashboard_page/dialogs/gemini_prompt_dialog.dart';

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

  Timer? _focusTimer;
  bool _isKeyboardActive = false;
  bool _isPathSet = false;

  @override
  void initState() {
    super.initState();
    _checkPath();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPath() async {
    final prefsService = SharedPreferencesService();
    final path = await prefsService.loadCustomStoragePath();
    if (mounted) {
      setState(() {
        _isPathSet = path != null && path.isNotEmpty;
      });
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
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
          _isPathSet = true;
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

  @override
  Widget build(BuildContext context) {
    _dashboardActions = buildDashboardActions(
      context,
      onShowStorageDialog: () => _showStoragePathDialog(context),
      isPathSet: _isPathSet,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final backgroundImagePath = themeProvider.backgroundImagePath;
        final isChristmas = themeProvider.isChristmasTheme;
        final bool showFlo = themeProvider.showFloatingCharacter;

        return RawKeyboardListener(
          focusNode: _focusNode,
          onKey: _handleKeyEvent,
          child: Container(
            decoration: backgroundImagePath != null
                ? BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(backgroundImagePath)),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                  )
                : null,
            child: Scaffold(
              backgroundColor: backgroundImagePath != null || isChristmas
                  ? Colors.transparent
                  : null,
              appBar: AppBar(
                title: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: backgroundImagePath != null || isChristmas
                    ? Colors.black.withOpacity(0.2)
                    : null,
                elevation: backgroundImagePath != null || isChristmas
                    ? 0
                    : null,
                actions: [
                  IconButton(
                    icon: Icon(
                      showFlo ? Icons.pets_outlined : Icons.pets_rounded,
                    ),
                    tooltip: showFlo ? 'Nonaktifkan Flo' : 'Aktifkan Flo',
                    onPressed: () => themeProvider.toggleFloatingCharacter(),
                  ),
                  if (_isPathSet)
                    IconButton(
                      icon: const Icon(Icons.folder_open_rounded),
                      onPressed: () => _showStoragePathDialog(context),
                      tooltip: 'Ubah Penyimpanan Utama',
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.smart_toy_outlined),
                    tooltip: 'Pengaturan AI',
                    onSelected: (value) {
                      if (value == 'api_key') {
                        showGeminiApiKeyDialog(context);
                      } else if (value == 'prompt') {
                        showGeminiPromptDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'api_key',
                            child: Text('Manajemen API Key'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'prompt',
                            child: Text('Manajemen Prompt'),
                          ),
                        ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () => showThemeSettingsDialog(context),
                    tooltip: 'Pengaturan Tampilan',
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
                            isPathSet: _isPathSet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
