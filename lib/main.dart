// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/content_management/topics/providers/topic_provider.dart';
import 'features/content_management/topics/presentation/topics_page.dart';
import 'features/settings/presentation/pages/settings_page.dart'; // Mengembalikan import ke SettingsPage
import 'features/about/presentation/pages/about_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => TopicProvider())],
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
      home: const MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // Urutan list halaman dikembalikan ke semula:
  // Indeks 0: TopicsPage
  // Indeks 1: SettingsPage (Kembali menampilkan halaman pengaturan utama)
  // Indeks 2: AboutPage
  final List<Widget> _pages = const [
    TopicsPage(),
    SettingsPage(), // Mengembalikan ke SettingsPage
    AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.topic_outlined),
            activeIcon: Icon(Icons.topic),
            label: 'Topics',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.settings_outlined,
            ), // Mengembalikan ikon menjadi roda gigi pengaturan
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
