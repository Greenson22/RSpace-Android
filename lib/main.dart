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
import 'features/feedback/application/feedback_provider.dart';
import 'core/providers/neuron_provider.dart';
import 'features/snake_game/application/snake_game_provider.dart';

import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'core/widgets/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  if (Platform.isAndroid || Platform.isIOS) {
    MobileAds.instance.initialize();
  }

  // ... (kode QuickActions tidak berubah) ...

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
        ChangeNotifierProvider(create: (_) => FeedbackProvider()),
        ChangeNotifierProvider(create: (_) => NeuronProvider()),
        ChangeNotifierProvider(create: (_) => QuizCategoryProvider()),
        ChangeNotifierProvider(create: (_) => PerpuskuProvider()),
        ChangeNotifierProvider(create: (_) => SnakeGameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ==> 1. UBAH MENJADI STATEFUL WIDGET <==
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // ==> 2. DENGARKAN PERUBAHAN AUTHPROVIDER <==
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  // ==> 3. BUAT FUNGSI UNTUK NAVIGASI <==
  void _onAuthStateChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = navigatorKey.currentState;

    // Jika berhasil terautentikasi, pindah ke Dashboard
    if (authProvider.authState == AuthState.authenticated) {
      navigator?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    }
    // Jika logout atau gagal autentikasi, pindah ke Login
    else if (authProvider.authState == AuthState.unauthenticated) {
      navigator?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RSpace',
          theme: themeProvider.currentTheme,
          // ==> 4. MULAI SELALU DARI SPLASH SCREEN <==
          home: const SplashScreen(),
        );
      },
    );
  }
}
