// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_aplication/presentation/pages/dashboard_page.dart';
import 'package:my_aplication/presentation/providers/debug_provider.dart';
import 'package:my_aplication/presentation/providers/statistics_provider.dart';
import 'package:my_aplication/presentation/providers/time_log_provider.dart';
import 'package:my_aplication/presentation/providers/topic_provider.dart';
import 'package:my_aplication/presentation/widgets/snow_widget.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'presentation/pages/my_tasks_page.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/floating_character_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

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
        icon: 'ic_task_icon',
      ),
    ]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(create: (_) => TimeLogProvider()),
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
        final isChristmas = themeProvider.isChristmasTheme;

        // ==> GUNAKAN STATE BARU DARI PROVIDER <==
        final bool showFlo = themeProvider.showFloatingCharacter;

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          home: const DashboardPage(),
          builder: (context, navigator) {
            return Stack(
              children: [
                if (navigator != null) navigator,
                if (isChristmas)
                  IgnorePointer(
                    child: const SnowWidget(
                      isRunning: true,
                      totalSnow: 200,
                      speed: 0.5,
                      snowColor: Colors.white,
                    ),
                  ),
                // ==> ATUR KONDISI UNTUK MENAMPILKAN FLO <==
                if (showFlo)
                  const IgnorePointer(
                    child: FloatingCharacter(isVisible: true),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
