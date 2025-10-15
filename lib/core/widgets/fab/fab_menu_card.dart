// lib/core/widgets/fab/fab_menu_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:my_aplication/features/backup_management/presentation/pages/backup_management_page.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/subjects_page.dart';
import 'package:my_aplication/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:my_aplication/features/file_management/presentation/pages/file_list_page.dart';
import 'package:my_aplication/features/statistics/presentation/pages/statistics_page.dart';
import 'package:my_aplication/infrastructure/ads/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/storage_service.dart';
import '../../../features/settings/application/theme_provider.dart';
import '../../../features/content_management/application/topic_provider.dart';
import '../../../features/content_management/application/subject_provider.dart';
import '../../../features/my_tasks/presentation/pages/my_tasks_page.dart';
import '../../../features/content_management/domain/models/topic_model.dart';
import '../../../main.dart';
import 'package:my_aplication/features/progress/presentation/pages/progress_page.dart';
import 'package:my_aplication/features/notes/presentation/pages/note_topic_page.dart';

class FabMenuCard extends StatefulWidget {
  final VoidCallback closeMenu;

  const FabMenuCard({super.key, required this.closeMenu});

  @override
  State<FabMenuCard> createState() => _FabMenuCardState();
}

class _FabMenuCardState extends State<FabMenuCard> {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _loadRewardedAd();
    }
  }

  void _loadRewardedAd() {
    setState(() {
      _isAdLoading = true;
    });
    AdService.loadRewardedAd(
      onAdLoaded: (ad) {
        _rewardedAd = ad;
        _setAdCallbacks();
        setState(() {
          _isAdLoading = false;
        });
      },
      onAdFailedToLoad: (error) {
        _rewardedAd = null;
        setState(() {
          _isAdLoading = false;
        });
        print('Failed to load a rewarded ad: ${error.message}');
      },
    );
  }

  void _setAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );
  }

  Future<void> _grantReward(num amount) async {
    final int rewardAmount = amount.toInt();
    final prefs = SharedPreferencesService();
    final currentNeurons = await prefs.loadNeurons();
    await prefs.saveNeurons(currentNeurons + rewardAmount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Selamat! Kamu mendapatkan +$rewardAmount Neurons!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  void _showAd() {
    if (_rewardedAd != null) {
      widget.closeMenu();
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          _grantReward(reward.amount);
        },
      );
    } else if (_isAdLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iklan sedang dimuat, coba sesaat lagi...'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat iklan. Coba lagi nanti.'),
          backgroundColor: Colors.red,
        ),
      );
      _loadRewardedAd();
    }
  }

  void _navigateToPage(BuildContext context, Widget page) {
    widget.closeMenu();
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToSubjectsPage(BuildContext context, Topic topic) {
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    topicProvider.getTopicsPath().then((topicsPath) {
      final folderPath = path.join(topicsPath, topic.name);
      widget.closeMenu();
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => SubjectProvider(folderPath),
            child: SubjectsPage(topicName: topic.name),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final showText = themeProvider.fabMenuShowText;

    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    final topics = topicProvider.allTopics.where((t) => !t.isHidden).toList();

    return SizedBox(
      width: showText ? 250 : 80,
      child: Card(
        elevation: 8.0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: showText ? const Text('Dashboard') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const DashboardPage()),
              ),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.topic_outlined),
                  title: showText
                      ? const Text('Navigasi Cepat')
                      : const SizedBox.shrink(),
                  dense: true,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  childrenPadding: EdgeInsets.zero,
                  children: topics.map((topic) {
                    return ListTile(
                      dense: true,
                      leading: Padding(
                        padding: EdgeInsets.only(left: showText ? 32.0 : 0),
                        child: Center(
                          widthFactor: 1.0,
                          child: Text(
                            topic.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: showText ? Text(topic.name) : null,
                      onTap: () => _navigateToSubjectsPage(context, topic),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.task_alt_outlined),
                title: showText ? const Text('My Tasks') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const MyTasksPage()),
              ),
              ListTile(
                leading: const Icon(Icons.pie_chart_outline_rounded),
                title: showText ? const Text('Statistik') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const StatisticsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.show_chart),
                title: showText ? const Text('Progress') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const ProgressPage()),
              ),
              // ==> ITEM "CATATAN" DITAMBAHKAN DI SINI <==
              ListTile(
                leading: const Icon(Icons.note_alt_outlined),
                title: showText ? const Text('Catatan') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const NoteTopicPage()),
              ),
              if (Platform.isAndroid || Platform.isIOS)
                ListTile(
                  leading: Icon(
                    Icons.video_camera_front_outlined,
                    color: Colors.deepPurple,
                  ),
                  title: showText
                      ? Text(
                          'Dapatkan Neurons',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  dense: true,
                  onTap: _showAd,
                ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: showText ? const Text('File Online') : null,
                dense: true,
                onTap: () => _navigateToPage(context, const FileListPage()),
              ),
              // ==> ITEM "BACKUP" DIPERBARUI DAN DITEMPATKAN DI BAWAH <==
              ListTile(
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: showText ? const Text('Backup & Sync Otomatis') : null,
                dense: true,
                onTap: () =>
                    _navigateToPage(context, const BackupManagementPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
