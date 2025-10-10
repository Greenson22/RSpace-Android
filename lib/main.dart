// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_aplication/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:my_aplication/features/ai_assistant/application/chat_provider.dart';
import 'package:my_aplication/core/providers/debug_provider.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_provider.dart';
import 'package:my_aplication/features/quiz/application/quiz_category_provider.dart';
import 'package:my_aplication/features/statistics/application/statistics_provider.dart';
import 'package:my_aplication/features/time_management/application/providers/time_log_provider.dart';
import 'package:my_aplication/features/content_management/application/topic_provider.dart';
import 'package:provider/provider.dart';
import 'features/settings/application/theme_provider.dart';
import 'package:my_aplication/features/backup_management/application/sync_provider.dart';
import 'core/providers/neuron_provider.dart';
import 'features/snake_game/application/snake_game_provider.dart';

import 'features/auth/application/auth_provider.dart';
import 'core/widgets/draggable_fab_view.dart';
import 'features/ai_assistant/presentation/widgets/floating_character_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(create: (_) => TimeLogProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => NeuronProvider()),
        ChangeNotifierProvider(create: (_) => QuizCategoryProvider()),
        ChangeNotifierProvider(create: (_) => PerpuskuProvider()),
        ChangeNotifierProvider(create: (_) => SnakeGameProvider()),
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
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          builder: (context, child) {
            return Stack(
              children: [
                // Ini adalah halaman utama Anda (seperti Dashboard, Topics, dll.)
                child!,
                // Tampilkan Flo dan FAB secara kondisional di atas halaman
                if (themeProvider.showFloatingCharacter)
                  const FloatingCharacter(),
                if (themeProvider.showQuickFab) const DraggableFabView(),
              ],
            );
          },
          home: const DashboardPage(),
        );
      },
    );
  }
}
