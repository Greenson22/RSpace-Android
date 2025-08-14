// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_aplication/presentation/pages/dashboard_page.dart';
// Perubahan di baris import ini untuk menyesuaikan dengan lokasi file yang baru
import 'package:my_aplication/presentation/pages/linux/dashboard_page_linux.dart';
import 'package:my_aplication/presentation/providers/statistics_provider.dart';
import 'package:my_aplication/presentation/providers/topic_provider.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'presentation/pages/my_tasks_page.dart';
import 'presentation/providers/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Quick Actions ini hanya untuk mobile, jadi kita bungkus dengan pengecekan platform
  if (Platform.isAndroid || Platform.isIOS) {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_my_tasks') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const MyTasksPage()),
        );
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_my_tasks',
        localizedTitle: 'My Tasks',
        icon:
            'ic_task_icon', // Pastikan icon ini ada di resource native Android/iOS
      ),
    ]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Widget untuk memilih halaman utama berdasarkan platform
  Widget _getHomePage() {
    if (Platform.isLinux) {
      return const DashboardPageLinux();
    }
    // Untuk platform lain seperti Android, Windows, macOS, iOS, dll.
    // akan menggunakan dashboard standar.
    return const DashboardPage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          home:
              _getHomePage(), // Menggunakan fungsi untuk memilih halaman utama
        );
      },
    );
  }
}
