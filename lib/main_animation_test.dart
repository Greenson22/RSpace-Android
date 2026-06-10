import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulasi Animasi Transisi',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const DummyTopicsPage(),
    );
  }
}

/// 1. HALAMAN UTAMA (Simulasi TopicsPage)
class DummyTopicsPage extends StatelessWidget {
  const DummyTopicsPage({super.key});

  // Contoh data topik sederhana
  final List<Map<String, String>> topics = const [
    {'name': 'Matematika Diskrit', 'icon': '📐'},
    {'name': 'Pemrograman Mobile', 'icon': '📱'},
    {'name': 'Basis Data', 'icon': '🗄️'},
    {'name': 'Jaringan Komputer', 'icon': '🌐'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Animasi Transisi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Klik topik di bawah untuk melihat jenis animasi:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // TOMBOL 1: Shared Axis
            _buildTopicCard(
              context,
              title: topics[0]['name']!,
              icon: topics[0]['icon']!,
              subtitle: 'Animasi 1: Shared Axis (Modern Zoom & Fade)',
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                context,
                _createSharedAxisRoute(topics[0]['name']!),
              ),
            ),

            // TOMBOL 2: Fade Through
            _buildTopicCard(
              context,
              title: topics[1]['name']!,
              icon: topics[1]['icon']!,
              subtitle: 'Animasi 2: Fade Through (Minimalis & Ringan)',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                _createFadeThroughRoute(topics[1]['name']!),
              ),
            ),

            // TOMBOL 3: Premium Slide
            _buildTopicCard(
              context,
              title: topics[2]['name']!,
              icon: topics[2]['icon']!,
              subtitle: 'Animasi 3: Premium Slide (iOS-Style Smooth)',
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                _createPremiumSlideRoute(topics[2]['name']!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required String title,
    required String icon,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RUTE ANIMASI 1: SHARED AXIS
  // ==========================================
  Route _createSharedAxisRoute(String topicName) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DummySubjectsPage(topicName: topicName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final pageScale = Tween<double>(begin: 0.94, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        );
        final pageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
        );
        final secondaryScale = Tween<double>(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(
            parent: secondaryAnimation,
            curve: Curves.easeInOutCubic,
          ),
        );

        return FadeTransition(
          opacity: pageFade,
          child: ScaleTransition(
            scale: pageScale,
            child: ScaleTransition(scale: secondaryScale, child: child),
          ),
        );
      },
    );
  }

  // ==========================================
  // RUTE ANIMASI 2: FADE THROUGH
  // ==========================================
  Route _createFadeThroughRoute(String topicName) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DummySubjectsPage(topicName: topicName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ==========================================
  // RUTE ANIMASI 3: PREMIUM SLIDE
  // ==========================================
  Route _createPremiumSlideRoute(String topicName) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) =>
          DummySubjectsPage(topicName: topicName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
            );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}

/// 2. HALAMAN TUJUAN (Simulasi SubjectsPage)
class DummySubjectsPage extends StatelessWidget {
  final String topicName;
  const DummySubjectsPage({super.key, required this.topicName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topicName, style: const TextStyle(color: Colors.white)),
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
                Icons.folder_open_rounded,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              Text(
                'Halaman Sub-Materi untuk:\n"$topicName"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Topik'),
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
