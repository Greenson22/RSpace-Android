import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import TopicProvider
import 'features/content_management/application/topic_provider.dart';

// Import Halaman
import 'features/content_management/presentation/topics/topics_page.dart';
import 'features/perpusku/presentation/pages/perpusku_topic_page.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Menjadikan MainNavigationPage sebagai halaman pertama
      home: const MainNavigationPage(),
    );
  }
}

// Widget Stateful untuk mengatur Bottom Navigation Bar
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan dirender di dalam navigasi
  final List<Widget> _pages = const [TopicsPage(), PerpuskuTopicPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack digunakan agar state halaman tidak hilang saat pindah tab
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.topic_outlined),
            activeIcon: Icon(Icons.topic),
            label: 'Topics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_library_outlined),
            activeIcon: Icon(Icons.local_library),
            label: 'Perpusku',
          ),
        ],
      ),
    );
  }
}
