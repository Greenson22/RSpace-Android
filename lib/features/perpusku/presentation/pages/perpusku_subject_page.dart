// lib/features/perpusku/presentation/pages/perpusku_subject_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/perpusku_provider.dart';
import '../../domain/models/perpusku_models.dart';
import 'perpusku_file_list_page.dart';

class PerpuskuSubjectPage extends StatelessWidget {
  final PerpuskuTopic topic;
  const PerpuskuSubjectPage({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PerpuskuProvider()..fetchSubjects(topic.path),
      child: _PerpuskuSubjectView(topic: topic),
    );
  }
}

class _PerpuskuSubjectView extends StatefulWidget {
  final PerpuskuTopic topic;
  const _PerpuskuSubjectView({required this.topic});

  @override
  State<_PerpuskuSubjectView> createState() => _PerpuskuSubjectViewState();
}

class _PerpuskuSubjectViewState extends State<_PerpuskuSubjectView> {
  final TextEditingController _searchController = TextEditingController();
  List<PerpuskuSubject> _filteredSubjects = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PerpuskuProvider>(context, listen: false);
    provider.addListener(_filterList);
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final provider = Provider.of<PerpuskuProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSubjects = provider.subjects;
      } else {
        _filteredSubjects = provider.subjects
            .where((s) => s.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterList);
    _searchController.dispose();
    Provider.of<PerpuskuProvider>(
      context,
      listen: false,
    ).removeListener(_filterList);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PerpuskuProvider>(context);

    // Panggil _filterList saat build pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchController.text.isEmpty) {
        _filteredSubjects = provider.subjects;
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari subjek di dalam topik ini...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSubjects.isEmpty
                ? const Center(child: Text('Tidak ada subjek ditemukan.'))
                : ListView.builder(
                    itemCount: _filteredSubjects.length,
                    itemBuilder: (context, index) {
                      final subject = _filteredSubjects[index];
                      return ListTile(
                        leading: Text(
                          subject.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(subject.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PerpuskuFileListPage(subject: subject),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
