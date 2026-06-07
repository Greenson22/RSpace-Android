import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import TopicProvider dan TopicsPage
// Sesuaikan path ini dengan struktur folder di project Anda jika ada peringatan error import
import 'features/content_management/application/topic_provider.dart';
import 'features/content_management/presentation/topics/topics_page.dart';

void main() {
  // Membungkus runApp dengan MultiProvider agar state bisa diakses secara global
  runApp(
    MultiProvider(
      providers: [
        // Mendaftarkan TopicProvider ke dalam widget tree
        ChangeNotifierProvider(create: (context) => TopicProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menghilangkan banner debug di kanan atas
      debugShowCheckedModeBanner: false,

      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Menjadikan TopicsPage sebagai halaman pertama yang muncul saat aplikasi dibuka
      home: const TopicsPage(),
    );
  }
}
