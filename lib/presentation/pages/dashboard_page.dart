// lib/presentation/pages/dashboard_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../../features/content_management/application/topic_provider.dart';
import '../providers/sync_provider.dart'; // Pastikan SyncProvider diimpor
import '../../core/utils/scaffold_messenger_utils.dart';
import 'about_page.dart';
import 'chat_page.dart';
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

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

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

    if (Platform.isAndroid || Platform.isIOS) {
      _loadBannerAd();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      Provider.of<SyncProvider>(
        context,
        listen: false,
      ).addListener(_onSyncStateChanged);
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    Provider.of<SyncProvider>(
      context,
      listen: false,
    ).removeListener(_onSyncStateChanged);
    _focusNode.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd()..load();
    setState(() {
      _isBannerAdReady = true;
    });
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

  void _onSyncStateChanged() {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    if (!syncProvider.isSyncing) {
      Navigator.of(context, rootNavigator: true).pop();
      syncProvider.showResultDialog(context);
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

  Future<void> _handleBackupAndSync() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Backup & Sync'),
            content: const Text(
              'Proses ini akan membuat file backup lokal untuk RSpace & PerpusKu, lalu mengunggahnya ke server. Lanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ya, Lanjutkan'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Consumer<SyncProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 20),
                  Expanded(child: Text(provider.syncStatusMessage)),
                ],
              ),
            );
          },
        ),
      );
      Provider.of<SyncProvider>(
        context,
        listen: false,
      ).performBackupAndUpload();
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
              backgroundColor: backgroundImagePath != null
                  ? Colors.transparent
                  : null,
              appBar: AppBar(
                title: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: backgroundImagePath != null
                    ? Colors.black.withOpacity(0.2)
                    : null,
                elevation: backgroundImagePath != null ? 0 : null,
                actions: [
                  // ==> AKSI UTAMA TETAP DI LUAR <==
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip: 'Chat dengan Flo AI',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Backup & Sync Otomatis',
                    onPressed: _handleBackupAndSync,
                  ),

                  // ==> TOMBOL-TOMBOL LAIN DIKELOMPOKKAN DI SINI <==
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
                        _showStoragePathDialog(context);
                      } else if (value == 'about') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
                          if (_isPathSet)
                            const PopupMenuItem<String>(
                              value: 'storage_path',
                              child: ListTile(
                                leading: Icon(Icons.folder_open_rounded),
                                title: Text('Ubah Penyimpanan Utama'),
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
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
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
                    if (_isBannerAdReady)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
