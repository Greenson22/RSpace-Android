// lib/features/data_center/presentation/screens/data_center_screen.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/data_center/presentation/widgets/backup_tab.dart';
import 'package:my_aplication/features/data_center/presentation/widgets/local_sharing_tab.dart';

class DataCenterScreen extends StatelessWidget {
  const DataCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Center'),
          backgroundColor: Colors.indigo[700],
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.backup_outlined), text: 'Backup'),
              Tab(icon: Icon(Icons.wifi_find_outlined), text: 'Local Sharing'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BackupTab(), // Mandiri mengelola logika backup
            LocalSharingTab(), // Mandiri mengelola logika wifi sharing
          ],
        ),
      ),
    );
  }
}
