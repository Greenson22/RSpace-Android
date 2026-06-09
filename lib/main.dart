// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart'; // 1. Import package window_manager

import 'features/content_management/topics/providers/topic_provider.dart';
import 'features/content_management/topics/presentation/topics_page.dart';
import 'features/settings/presentation/pages/settings_page.dart'; // Mengembalikan import ke SettingsPage
import 'features/about/presentation/pages/about_page.dart';

void main() async {
  // 2. Ubah menjadi async
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Inisialisasi window_manager jika berjalan di Desktop (Windows)
  await windowManager.ensureInitialized();

  // Pengaturan awal jendela (bisa disesuaikan ukurannya)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(600, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle:
        TitleBarStyle.hidden, // Menyembunyikan title bar bawaan Windows asli
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
      // 4. Gunakan builder untuk menyisipkan Custom Window Title Bar di atas semua halaman
      builder: (context, child) {
        final platform = Theme.of(context).platform;

        // Tampilkan custom window title bar hanya pada platform Desktop
        if (platform == TargetPlatform.windows ||
            platform == TargetPlatform.macOS ||
            platform == TargetPlatform.linux) {
          return WindowControlWrapper(child: child!);
        }

        return child!;
      },
      home: const MainNavigationPage(),
    );
  }
}

// 5. Widget Wrapper untuk membuat struktur Custom Window Title Bar
class WindowControlWrapper extends StatelessWidget {
  final Widget child;

  const WindowControlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Mengambil warna dasar tema (deepPurple) agar bar menyatu secara visual
    final Color barColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Column(
        children: [
          // Bar Kontrol Jendela Kustom (Paling Atas)
          Container(
            height: 32, // Tinggi standar bar title yang nyaman diklik
            color: barColor,
            child: Row(
              children: [
                // Area Judul / Area Kosong yang bisa digunakan untuk menggeser (drag) jendela aplikasi
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      windowManager
                          .startDragging(); // Memungkinkan window digeser lewat area ini
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.apps, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'My App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Wadah Tombol Minimize, Maximize, dan Close
                SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Minimize
                      SizedBox(
                        width: 45,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.minimize,
                            size: 16,
                            color: Colors.white,
                          ),
                          hoverColor: Colors.white.withOpacity(0.1),
                          onPressed: () async {
                            await windowManager.minimize();
                          },
                        ),
                      ),
                      // Tombol Maximize / Restore
                      SizedBox(
                        width: 45,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.crop_square,
                            size: 14,
                            color: Colors.white,
                          ),
                          hoverColor: Colors.white.withOpacity(0.1),
                          onPressed: () async {
                            if (await windowManager.isMaximized()) {
                              await windowManager.unmaximize();
                            } else {
                              await windowManager.maximize();
                            }
                          },
                        ),
                      ),
                      // Tombol Close
                      SizedBox(
                        width: 45,
                        height: 32,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                          hoverColor:
                              Colors.redAccent, // Berubah merah saat di-hover
                          onPressed: () async {
                            await windowManager.close();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Halaman Aplikasi Utama (MainNavigationPage) diletakkan di bawah bar kontrol
          Expanded(child: child),
        ],
      ),
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

  final List<Widget> _pages = const [TopicsPage(), SettingsPage(), AboutPage()];

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
