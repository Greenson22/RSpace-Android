// lib/features/dashboard/presentation/state/dashboard_state.dart

import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/scaffold_messenger_utils.dart';
import '../../../../infrastructure/ads/ad_service.dart';
import '../../../backup_management/application/sync_provider.dart';
import '../../../statistics/application/statistics_provider.dart';
import '../../../content_management/application/topic_provider.dart';
// ==> IMPORT SERVICE BARU <==
import '../../../settings/application/services/api_config_service.dart';
import '../pages/dashboard_page.dart';
import '../widgets/dashboard_grid.dart';
import '../../../backup_management/presentation/dialogs/sync_result_dialog.dart';

mixin DashboardState on State<DashboardPage> {
  Key dashboardPathKey = UniqueKey();
  BannerAd? bannerAd;
  bool isBannerAdReady = false;

  final FocusNode focusNode = FocusNode();
  int focusedIndex = 0;
  List<VoidCallback> dashboardActions = [];

  Timer? focusTimer;
  bool isKeyboardActive = false;
  bool isPathSet = false;
  bool isApiConfigured = false;

  // ==> GUNAKAN SERVICE BARU <==
  final ApiConfigService _apiConfigService = ApiConfigService();

  @override
  void initState() {
    super.initState();
    _checkPath();
    _checkApiConfig();

    if (Platform.isAndroid || Platform.isIOS) {
      _loadBannerAd();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    focusNode.dispose();
    focusTimer?.cancel();
    super.dispose();
  }

  void _loadBannerAd() {
    bannerAd = AdService.createBannerAd(
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            isBannerAdReady = true;
          });
        }
      },
    )..load();
  }

  Future<void> _checkPath() async {
    final prefsService = SharedPreferencesService();
    final path = await prefsService.loadCustomStoragePath();
    if (mounted) {
      setState(() {
        isPathSet = path != null && path.isNotEmpty;
      });
    }
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> _checkApiConfig() async {
    final apiConfig = await _apiConfigService.loadConfig();
    if (mounted) {
      setState(() {
        // Hanya periksa domain, tidak lagi memeriksa apiKey
        isApiConfigured =
            (apiConfig['domain'] != null && apiConfig['domain']!.isNotEmpty);
      });
    }
  }

  void rebuildActions() {
    dashboardActions = buildDashboardActions(
      context,
      onShowStorageDialog: () => showStoragePathDialog(context),
      isPathSet: isPathSet,
    );
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() => isKeyboardActive = true);
        focusTimer?.cancel();
        focusTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => isKeyboardActive = false);
          }
        });

        final totalItems = dashboardActions.length;
        if (totalItems == 0) return;

        final screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = screenWidth < 450 ? 2 : 5;

        setState(() {
          if (focusedIndex < 5) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              int nextIndex = focusedIndex + crossAxisCount;
              if (nextIndex < 5 && nextIndex < totalItems) {
                focusedIndex = nextIndex;
              } else {
                focusedIndex = 5;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              int prevIndex = focusedIndex - crossAxisCount;
              if (prevIndex >= 0) {
                focusedIndex = prevIndex;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if ((focusedIndex + 1) % crossAxisCount != 0 &&
                  focusedIndex < 4) {
                focusedIndex++;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (focusedIndex % crossAxisCount != 0 && focusedIndex > 0) {
                focusedIndex--;
              }
            }
          } else {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (focusedIndex < totalItems - 1) {
                focusedIndex++;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (focusedIndex > 5) {
                focusedIndex--;
              } else {
                focusedIndex = 0;
              }
            }
          }
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (focusedIndex < dashboardActions.length) {
          dashboardActions[focusedIndex]();
        }
      }
    }
  }

  Future<void> handleBackupAndSync() async {
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

    if (!confirmed || !mounted) return;

    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

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

    final SyncResult result = await syncProvider.performBackupAndUpload();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showSyncResultDialog(context, result);
    }
  }

  Future<void> showStoragePathDialog(BuildContext context) async {
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
          dashboardPathKey = UniqueKey();
          isPathSet = true;
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

  Future<void> refreshData() async {
    await Provider.of<TopicProvider>(context, listen: false).fetchTopics();
    if (mounted) {
      setState(() {
        dashboardPathKey = UniqueKey();
      });
    }
  }
}
