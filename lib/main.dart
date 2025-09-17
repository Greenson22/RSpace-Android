// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_aplication/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:my_aplication/features/ai_assistant/application/chat_provider.dart';
import 'package:my_aplication/core/providers/debug_provider.dart';
import 'package:my_aplication/features/quiz/application/quiz_provider.dart';
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
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Key _appKey = UniqueKey();
  DateTime _lastKnownDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.year != _lastKnownDay.year ||
          now.month != _lastKnownDay.month ||
          now.day != _lastKnownDay.day) {
        setState(() {
          _appKey = UniqueKey();
          _lastKnownDay = now;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Tampilkan layar loading jika tema belum siap
        if (themeProvider.isLoading) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final isChristmas = themeProvider.isChristmasTheme;
        final isUnderwater = themeProvider.isUnderwaterTheme;
        final bool showFlo = themeProvider.showFloatingCharacter;
        final bool showQuickFab = themeProvider.showQuickFab;

        return MaterialApp(
          key: _appKey,
          navigatorKey: navigatorKey,
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          home: const DashboardPage(),
          builder: (context, navigator) {
            return Stack(
              children: [
                // Lapisan 0: Latar Belakang (jika tema aktif)
                if (isUnderwater)
                  IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF003973), Color(0xFF33A1FD)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const UnderwaterWidget(
                        totalFish: 15,
                        speed: 1.0,
                        isRunning: true,
                      ),
                    ),
                  ),

                // Lapisan 1: Konten Utama Aplikasi
                if (navigator != null) navigator,

                // Lapisan 2: Overlay Tema (Salju atau Ikan di Latar Depan)
                if (isChristmas)
                  const IgnorePointer(
                    child: SnowWidget(
                      isRunning: true,
                      totalSnow: 200,
                      speed: 0.5,
                      snowColor: Colors.white,
                    ),
                  ),
                if (isUnderwater)
                  const IgnorePointer(
                    child: UnderwaterWidget(
                      totalFish: 5, // Lebih sedikit ikan untuk di depan
                      speed: 1.3, // Sedikit lebih cepat untuk efek parallax
                      isRunning: true,
                    ),
                  ),

                // Lapisan 3 & 4: Overlay Fungsional (Flo & FAB)
                if (showFlo)
                  const IgnorePointer(
                    child: FloatingCharacter(isVisible: true),
                  ),
                if (showQuickFab) const DraggableFabView(),
              ],
            );
          },
        );
      },
    );
  }
}
