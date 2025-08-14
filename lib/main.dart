// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_aplication/presentation/providers/statistics_provider.dart';
import 'package:my_aplication/presentation/providers/topic_provider.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/my_tasks_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (Platform.isAndroid) {
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
        icon: 'ic_task_icon',
      ),
    ]);
  }

  runApp(
    // DIUBAH: Menggunakan MultiProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => TopicProvider(),
        ), // TopicProvider ditambahkan di sini
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(),
        ), // DITAMBAHKAN
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Topics and Subjects Lister',
          theme: themeProvider.darkTheme
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          home: const DashboardPage(),
        );
      },
    );
  }
}
