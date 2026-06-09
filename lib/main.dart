// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/content_management/topics/providers/topic_provider.dart';
import 'features/content_management/topics/presentation/topics_page.dart';
// Import file data_center_screen yang baru saja Anda tambahkan
import 'features/data_center/presentation/screens/data_center_screen.dart';
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

  // Urutan list halaman yang disesuaikan:
  // Indeks 0: TopicsPage
  // Indeks 1: DataCenterScreen (Menggantikan SettingsPage)
  // Indeks 2: AboutPage
  final List<Widget> _pages = const [
    TopicsPage(),
    DataCenterScreen(), // Menaruh Data Center di posisi Pengaturan
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
            label: 'Topics', // Membuka indeks 0 (TopicsPage)
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.storage_outlined,
            ), // Mengubah ikon agar sesuai dengan Data Center
            activeIcon: Icon(Icons.storage),
            label:
                'Pengaturan', // Tetap menggunakan label Pengaturan sesuai instruksi (Membuka indeks 1)
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: 'About', // Membuka indeks 2 (AboutPage)
          ),
        ],
      ),
    );
  }
}
