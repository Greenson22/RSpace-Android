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
import 'package:my_aplication/core/widgets/snow_widget.dart';
import 'package:provider/provider.dart';
import 'core/widgets/underwater_widget.dart';
import 'package:my_aplication/features/link_maintenance/application/providers/unlinked_discussions_provider.dart';
import 'package:my_aplication/features/link_maintenance/application/providers/broken_link_provider.dart';
import 'package:my_aplication/features/finished_discussions/application/finished_discussions_provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'features/prompt_library/application/prompt_provider.dart';
import 'features/my_tasks/presentation/pages/my_tasks_page.dart';
import 'features/settings/application/theme_provider.dart';
import 'package:my_aplication/features/backup_management/application/sync_provider.dart';
import 'features/ai_assistant/presentation/widgets/floating_character_widget.dart';
import 'features/feedback/application/feedback_provider.dart';
import 'core/widgets/draggable_fab_view.dart';
import 'core/providers/neuron_provider.dart';
import 'features/snake_game/application/snake_game_provider.dart';

// ==> IMPORT BARU <==
import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'core/widgets/splash_screen.dart'; // Kita akan buat ini

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  }

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
        // ==> TAMBAHKAN AUTHPROVIDER DI PALING ATAS <==
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TopicProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
        ChangeNotifierProvider(create: (_) => TimeLogProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => UnlinkedDiscussionsProvider()),
        ChangeNotifierProvider(create: (_) => BrokenLinkProvider()),
        ChangeNotifierProvider(create: (_) => FinishedDiscussionsProvider()),
        ChangeNotifierProvider(create: (_) => PromptProvider()),
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
        if (themeProvider.isLoading) {
          return const MaterialApp(home: SplashScreen());
        }

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          // ==> LOGIKA UTAMA ADA DI SINI <==
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              switch (auth.authState) {
                case AuthState.uninitialized:
                  return const SplashScreen(); // Tampilkan splash saat cek login
                case AuthState.authenticated:
                  return const DashboardPage(); // Jika sudah login, ke dashboard
                case AuthState.unauthenticated:
                  return const LoginPage(); // Jika belum, ke halaman login
              }
            },
          ),
          // builder tidak lagi diperlukan di sini karena auth sudah menangani
        );
      },
    );
  }
}
