import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '10 Animasi Transisi Estetik',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const DummyTopicsPage(),
    );
  }
}

/// 1. HALAMAN UTAMA (Daftar 10 Animasi)
class DummyTopicsPage extends StatelessWidget {
  const DummyTopicsPage({super.key});

  final List<Map<String, dynamic>> animationList = const [
    {
      'name': 'Shared Axis (Zoom & Fade)',
      'desc':
          'Halaman lama membesar tipis, halaman baru memudar masuk. Sangat modern.',
      'icon': '✨',
      'color': Colors.deepPurple,
    },
    {
      'name': 'Fade Through',
      'desc':
          'Efek memudar halus di tempat dengan sedikit skala. Minimalis & bersih.',
      'icon': '🌫️',
      'color': Colors.blue,
    },
    {
      'name': 'Premium Slide (iOS-Style)',
      'desc':
          'Bergeser dari kanan ke kiri dengan kurva melambat yang sangat organik.',
      'icon': '➡️',
      'color': Colors.teal,
    },
    {
      'name': 'Slide Up (Bottom Sheet Style)',
      'desc': 'Halaman baru muncul bergeser naik dari bawah layar ke atas.',
      'icon': '⬆️',
      'color': Colors.orange,
    },
    {
      'name': 'Scale & Pop',
      'desc':
          'Halaman baru meletup membesar dari tengah layar dengan efek memudar.',
      'icon': '💥',
      'color': Colors.pink,
    },
    {
      'name': 'Slide & Fade Combo',
      'desc': 'Kombinasi bergeser dari kanan bawah diagonal sekaligus memudar.',
      'icon': '↗️',
      'color': Colors.indigo,
    },
    {
      'name': 'Rotation & Scale',
      'desc':
          'Efek berputar estetik dibarengi membesar secara halus saat masuk.',
      'icon': '🔄',
      'color': Colors.amber,
    },
    {
      'name': 'Size Reveal (Vertical Expand)',
      'desc': 'Halaman baru terbuka melebar secara vertikal dari tengah.',
      'icon': '↕️',
      'color': Colors.cyan,
    },
    {
      'name': 'Parallax Stack',
      'desc':
          'Halaman lama bergeser sedikit ke kiri, halaman baru menimpa dari kanan.',
      'icon': '📚',
      'color': Colors.purple,
    },
    {
      'name': 'Elastic Bounce Slide',
      'desc': 'Bergeser dari kanan dengan efek memantul (bouncy) yang playful.',
      'icon': '🪀',
      'color': Colors.lightGreen,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '10 Animasi Transisi Halaman',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: animationList.length,
        itemBuilder: (context, index) {
          final item = animationList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: item['color'].withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              onTap: () =>
                  Navigator.push(context, _getRoute(index, item['name'])),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['icon'],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${item['name']}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: item['color'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: item['color'],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Router Helper untuk memetakan klik ke fungsi animasi masing-masing
  Route _getRoute(int index, String name) {
    switch (index) {
      case 0:
        return _createSharedAxisRoute(name);
      case 1:
        return _createFadeThroughRoute(name);
      case 2:
        return _createPremiumSlideRoute(name);
      case 3:
        return _createSlideUpRoute(name);
      case 4:
        return _createScalePopRoute(name);
      case 5:
        return _createSlideFadeComboRoute(name);
      case 6:
        return _createRotationScaleRoute(name);
      case 7:
        return _createSizeRevealRoute(name);
      case 8:
        return _createParallaxStackRoute(name);
      case 9:
        return _createElasticBounceRoute(name);
      default:
        return _createFadeThroughRoute(name);
    }
  }

  // ==========================================
  // 1. SHARED AXIS (ZOOM & FADE)
  // ==========================================
  Route _createSharedAxisRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                CurvedAnimation(parent: secAnim, curve: Curves.easeInOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 2. FADE THROUGH
  // ==========================================
  Route _createFadeThroughRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.98,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.fastOutSlowIn)),
          child: child,
        ),
      ),
    );
  }

  // ==========================================
  // 3. PREMIUM SLIDE (iOS STYLE)
  // ==========================================
  Route _createPremiumSlideRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutQuart)),
        child: child,
      ),
    );
  }

  // ==========================================
  // 4. SLIDE UP
  // ==========================================
  Route _createSlideUpRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  // ==========================================
  // 5. SCALE & POP
  // ==========================================
  Route _createScalePopRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => ScaleTransition(
        scale: Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ==========================================
  // 6. SLIDE & FADE COMBO
  // ==========================================
  Route _createSlideFadeComboRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ==========================================
  // 7. ROTATION & SCALE
  // ==========================================
  Route _createRotationScaleRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => RotationTransition(
        turns: Tween<double>(
          begin: -0.05,
          end: 0.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );
  }

  // ==========================================
  // 8. SIZE REVEAL (VERTICAL EXPAND)
  // ==========================================
  Route _createSizeRevealRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => Align(
        alignment: Alignment.center,
        child: SizeTransition(
          sizeFactor: anim,
          axis: Axis.vertical,
          axisAlignment: 0.0,
          child: child,
        ),
      ),
    );
  }

  // ==========================================
  // 9. PARALLAX STACK
  // ==========================================
  Route _createParallaxStackRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) {
        // Halaman lama bergeser pelan ke kiri (efek parallax kedalaman)
        final slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(parent: secAnim, curve: Curves.easeOut));
        // Halaman baru masuk penuh dari kanan
        final slideIn = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: slideOut,
          child: SlideTransition(position: slideIn, child: child),
        );
      },
    );
  }

  // ==========================================
  // 10. ELASTIC BOUNCE SLIDE
  // ==========================================
  Route _createElasticBounceRoute(String title) {
    return PageRouteBuilder(
      transitionDuration: const Duration(
        milliseconds: 700,
      ), // Membutuhkan waktu lebih lama untuk memantul
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, secAnim) => DummySubjectsPage(title: title),
      transitionsBuilder: (context, anim, secAnim, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.elasticOut)),
        child: child,
      ),
    );
  }
}

/// 2. HALAMAN TUJUAN (Simulasi Halaman Detail/Materi)
class DummySubjectsPage extends StatelessWidget {
  final String title;
  const DummySubjectsPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Halaman Detail',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 90,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              Text(
                'Berhasil Masuk Menggunakan Animasi:\n\n"$title"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali & Lihat Animasi Terbalik'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
