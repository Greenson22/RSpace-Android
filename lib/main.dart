import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // DITAMBAHKAN
import 'package:provider/provider.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

// DIUBAH menjadi async
void main() async {
  // DITAMBAHKAN untuk memastikan binding siap sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // DITAMBAHKAN untuk inisialisasi data lokalisasi Indonesia
  await initializeDateFormatting('id_ID', null);

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
