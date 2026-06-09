// main.dart
import 'dart:io'; // Tambahan: Import ini diperlukan untuk menggunakan class Platform
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'features/content_management/topics/providers/topic_provider.dart';
import 'features/content_management/topics/presentation/topics_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/about/presentation/pages/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Memastikan pengaturan window_manager hanya berjalan di OS Desktop (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Pengaturan awal jendela (bisa disesuaikan ukurannya)
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(600, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle:
          TitleBarStyle.hidden, // Menyembunyikan title bar bawaan desktop asli
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
      title: 'RSpace Next',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
      // Jika Anda menggunakan custom builder untuk window manager di Windows/Linux:
      builder: (context, child) {
        // Kita juga pastikan kustomisasi layout window hanya aktif di desktop
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          return CustomWindowFrame(child: child!);
        }
        return child!;
      },
    );
  }
}

// Widget pembungkus untuk dekorasi title bar kustom di Desktop
class CustomWindowFrame extends StatelessWidget {
  final Widget child;
  const CustomWindowFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Bar kontrol jendela kustom untuk Windows/Linux
          Container(
            height: 32,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Expanded(
                  child: MoveWindowDetector(
                    child: Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'RSpace Next',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                MinimizeWindowButton(),
                MaximizeWindowButton(),
                CloseWindowButton(),
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

// === WIDGET TOMBOL KONTROL WINDOW DESKTOP ===
class MoveWindowDetector extends StatelessWidget {
  final Widget child;
  const MoveWindowDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: child,
    );
  }
}

class MinimizeWindowButton extends StatelessWidget {
  const MinimizeWindowButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 16,
      constraints: const BoxConstraints(minWidth: 46, minHeight: 32),
      icon: const Icon(Icons.minimize),
      onPressed: () async => await windowManager.minimize(),
    );
  }
}

class MaximizeWindowButton extends StatelessWidget {
  const MaximizeWindowButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 16,
      constraints: const BoxConstraints(minWidth: 46, minHeight: 32),
      icon: const Icon(Icons.crop_square),
      onPressed: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
    );
  }
}

class CloseWindowButton extends StatelessWidget {
  const CloseWindowButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 16,
      constraints: const BoxConstraints(minWidth: 46, minHeight: 32),
      icon: const Icon(Icons.close),
      hoverColor: Colors.red.withOpacity(0.8),
      onPressed: () async => await windowManager.close(),
    );
  }
}
