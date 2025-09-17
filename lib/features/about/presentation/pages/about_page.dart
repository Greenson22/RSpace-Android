// lib/features/about/presentation/pages/about_page.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  String _version = '...';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPackageInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'Versi ${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang RSpace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fitur Aplikasi'),
            Tab(text: 'Pengembang'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(context),
          _buildDeveloperTab(context, textTheme),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(BuildContext context) {
    final features = [
      {
        'icon': Icons.account_tree_outlined,
        'title': 'Konten Hirarkis',
        'subtitle': 'Atur materi dalam Topik > Subjek > Diskusi > Poin.',
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Spaced Repetition',
        'subtitle': 'Perkuat ingatan dengan jadwal tinjau otomatis.',
      },
      {
        'icon': Icons.task_alt_outlined,
        'title': 'Manajemen Tugas',
        'subtitle': 'Lacak semua tugas dengan kategori, tanggal, dan progres.',
      },
      {
        'icon': Icons.show_chart,
        'title': 'Progres Belajar',
        'subtitle': 'Visualisasikan kemajuan belajar Anda secara detail.',
      },
      {
        'icon': Icons.quiz_outlined,
        'title': 'Kuis Interaktif',
        'subtitle': 'Uji pemahaman dengan kuis yang dibuat oleh AI.',
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Asisten AI "Flo"',
        'subtitle': 'Dapatkan jawaban dan rangkuman dari data aplikasi Anda.',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Sistem Neuron',
        'subtitle': 'Kumpulkan poin (Neuron) sebagai motivasi belajar.',
      },
      {
        'icon': Icons.folder_zip_outlined,
        'title': 'Backup & Sync',
        'subtitle': 'Amankan dan sinkronkan data Anda ke server pribadi.',
      },
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _AnimatedFeatureListItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          index: index,
        );
      },
    );
  }

  Widget _buildDeveloperTab(BuildContext context, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/pictures/profile.jpg'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frendy Rikal Gerung, S.Kom.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lulusan Sarjana Komputer dari Universitas Negeri Manado',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Dibuat dengan semangat untuk menyediakan alat bantu belajar yang personal, cerdas, dan sepenuhnya offline untuk menjaga privasi data Anda.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('LinkedIn'),
                onPressed: () => launchUrl(
                  Uri.parse('https://www.linkedin.com/in/fr-gerung/'),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email'),
                onPressed: () =>
                    launchUrl(Uri.parse('mailto:frendygerung@gmail.com')),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(_version, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AnimatedFeatureListItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const _AnimatedFeatureListItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AnimatedFeatureListItem> createState() =>
      __AnimatedFeatureListItemState();
}

class __AnimatedFeatureListItemState extends State<_AnimatedFeatureListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                ),
              ],
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.subtitle),
          ),
        ),
      ),
    );
  }
}
