import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import TopicProvider
import 'features/content_management/topics/providers/topic_provider.dart';

// Import Halaman
import 'features/content_management/topics/presentation/topics_page.dart';
import 'features/perpusku/presentation/pages/perpusku_topic_page.dart';
import 'features/settings/presentation/pages/settings_page.dart'; // Import feature baru Pengaturan
import 'features/about/presentation/pages/about_page.dart'; // Sesuaikan path ini dengan folder About yang sudah ada

void main() {
  // Tambahkan baris ini untuk memastikan inisialisasi binding Flutter
  // selesai sebelum WebViewPlatform atau plugin native lainnya dipanggil.
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

  // Tambahkan halaman baru ke dalam daftar IndexedStack
  final List<Widget> _pages = const [
    TopicsPage(),
    PerpuskuTopicPage(),
    SettingsPage(),
    AboutPage(), // Pastikan nama class-nya sesuai dengan file about Anda
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
        // Gunakan tipe fixed agar label/icon tidak menghilang saat item lebih dari 3
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
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
