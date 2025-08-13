import 'dart:io'; // DIIMPOR untuk deteksi platform
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart'; // DIIMPOR
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/my_tasks_page.dart'; // DIIMPOR
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

// Kunci navigator global untuk navigasi dari luar widget
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Pastikan binding siap sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data lokalisasi Indonesia
  await initializeDateFormatting('id_ID', null);

  // Jalankan kode shortcut hanya jika platformnya adalah Android
  if (Platform.isAndroid) {
    const QuickActions quickActions = QuickActions();

    // Inisialisasi handler untuk saat shortcut ditekan
    quickActions.initialize((String shortcutType) {
      // Cek ID unik dari shortcut yang ditekan
      if (shortcutType == 'action_my_tasks') {
        // Gunakan navigatorKey untuk pindah halaman
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const MyTasksPage()),
        );
      }
    });

    // Atur item shortcut yang akan muncul di menu
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_my_tasks', // ID unik untuk shortcut ini
        localizedTitle: 'My Tasks', // Teks yang ditampilkan ke pengguna
        icon: 'ic_task_icon', // Nama file ikon di folder res/drawable
      ),
    ]);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
          navigatorKey: navigatorKey, // Pasang navigatorKey ke MaterialApp
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
