import 'package:flutter/material.dart';
import 'presentation/pages/1_topics_page.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Topics and Subjects Lister',
      // Tema sekarang diambil dari file terpisah untuk kerapian
      theme: AppTheme.lightTheme,
      home: const TopicsPage(),
    );
  }
}
