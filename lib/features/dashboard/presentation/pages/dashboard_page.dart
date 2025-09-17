// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../state/dashboard_state.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_body.dart';
// ==> IMPORT WIDGET BARU <==
import '../../../../core/widgets/underwater_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with DashboardState {
  @override
  Widget build(BuildContext context) {
    // ==> PERBAIKAN: Panggil metode yang sudah publik
    rebuildActions();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final backgroundImagePath = themeProvider.backgroundImagePath;
        // ==> CEK APAKAH TEMA BAWAH AIR AKTIF <==
        final isUnderwater = themeProvider.isUnderwaterTheme;

        return RawKeyboardListener(
          focusNode: focusNode,
          onKey: handleKeyEvent,
          child: Scaffold(
            // Biarkan Scaffold yang mengelola latarnya
            backgroundColor: (backgroundImagePath != null || isUnderwater)
                ? Colors.transparent
                : null,
            extendBodyBehindAppBar:
                isUnderwater, // Agar AppBar transparan di atas body
            appBar: DashboardAppBar(
              isPathSet: isPathSet,
              onShowStorageDialog: () => showStoragePathDialog(context),
              onSync: handleBackupAndSync,
              onRefresh: () {},
            ),
            // Gunakan Stack untuk menumpuk latar belakang dan konten
            body: Stack(
              children: [
                // Lapisan 1: Latar Belakang (jika ada)
                if (backgroundImagePath != null)
                  Positioned.fill(
                    child: Image.file(
                      File(backgroundImagePath),
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                if (isUnderwater)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003973), Color(0xFF33A1FD)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const UnderwaterWidget(isRunning: true),
                    ),
                  ),

                // Lapisan 2: Konten Utama
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: DashboardBody(
                          dashboardPathKey: dashboardPathKey,
                          isKeyboardActive: isKeyboardActive,
                          focusedIndex: focusedIndex,
                          dashboardActions: dashboardActions,
                          isPathSet: isPathSet,
                          onRefresh: refreshData,
                        ),
                      ),
                      if (isBannerAdReady)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: bannerAd!.size.width.toDouble(),
                            height: bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: bannerAd!),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
