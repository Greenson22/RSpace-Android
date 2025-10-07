// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../../settings/application/theme_provider.dart';
import '../state/dashboard_state.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/dashboard_body.dart';
// Import untuk Flo dan FAB dihapus dari sini

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with DashboardState {
  @override
  Widget build(BuildContext context) {
    // Panggil metode yang sudah publik
    rebuildActions();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final backgroundImagePath = themeProvider.backgroundImagePath;
        final isUnderwater = themeProvider.isUnderwaterTheme;

        // ==> Stack dan widget Flo/FAB dihapus dari sini <==
        return RawKeyboardListener(
          focusNode: focusNode,
          onKey: handleKeyEvent,
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
              backgroundColor: (backgroundImagePath != null || isUnderwater)
                  ? Colors.transparent
                  : null,
              appBar: DashboardAppBar(
                isPathSet: isPathSet,
                isApiConfigured: isApiConfigured,
                onShowStorageDialog: () => showStoragePathDialog(context),
                onSync: handleBackupAndSync,
                onRefresh: () {},
              ),
              body: SafeArea(
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
            ),
          ),
        );
      },
    );
  }
}
