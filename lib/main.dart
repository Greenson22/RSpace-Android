import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/pages/1_topics_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';

void main() {
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
          // Tema sekarang diambil dari provider
          theme: themeProvider.darkTheme
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          home: const TopicsPage(),
        );
      },
    );
  }
}
