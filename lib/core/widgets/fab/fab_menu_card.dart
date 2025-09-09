// lib/core/widgets/fab/fab_menu_card.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/backup_management/presentation/pages/backup_management_page.dart';
import 'package:my_aplication/features/content_management/presentation/subjects/subjects_page.dart';
import 'package:my_aplication/features/file_management/presentation/pages/file_list_page.dart';
import 'package:my_aplication/features/statistics/presentation/pages/statistics_page.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../../features/content_management/application/topic_provider.dart';
import '../../../features/content_management/application/subject_provider.dart';
import '../../../features/my_tasks/presentation/pages/my_tasks_page.dart';
import '../../../features/content_management/domain/models/topic_model.dart';
import '../../../main.dart';

class FabMenuCard extends StatelessWidget {
  final VoidCallback closeMenu;

  const FabMenuCard({super.key, required this.closeMenu});

  void _navigateToPage(BuildContext context, Widget page) {
    closeMenu();
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToSubjectsPage(BuildContext context, Topic topic) {
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    topicProvider.getTopicsPath().then((topicsPath) {
      final folderPath = path.join(topicsPath, topic.name);
      closeMenu();
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
    final topicProvider = Provider.of<TopicProvider>(context, listen: false);
    final topics = topicProvider.allTopics.where((t) => !t.isHidden).toList();

    return SizedBox(
      width: 250,
      child: Card(
        elevation: 8.0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Navigasi Cepat
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.topic_outlined),
                  title: const Text('Navigasi Cepat ke Topik'),
                  dense: true,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  childrenPadding: const EdgeInsets.only(left: 16),
                  children: topics.map((topic) {
                    return ListTile(
                      dense: true,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          topic.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(topic.name),
                      onTap: () => _navigateToSubjectsPage(context, topic),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),

              // Menu Navigasi Utama
              ListTile(
                leading: const Icon(Icons.task_alt_outlined),
                title: const Text('Buka My Tasks'),
                dense: true,
                onTap: () => _navigateToPage(context, const MyTasksPage()),
              ),
              ListTile(
                leading: const Icon(Icons.pie_chart_outline_rounded),
                title: const Text('Buka Statistik'),
                dense: true,
                onTap: () => _navigateToPage(context, const StatisticsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Buka File Online'),
                dense: true,
                onTap: () => _navigateToPage(context, const FileListPage()),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore_rounded),
                title: const Text('Buka Manajemen Backup'),
                dense: true,
                onTap: () =>
                    _navigateToPage(context, const BackupManagementPage()),
              ),
              // ListTile untuk "Buka Kelola Data" telah dihapus dari sini
            ],
          ),
        ),
      ),
    );
  }
}
