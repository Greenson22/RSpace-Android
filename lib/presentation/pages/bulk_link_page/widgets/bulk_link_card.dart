// lib/presentation/pages/bulk_link_page/widgets/bulk_link_card.dart

import 'package:flutter/material.dart';
import '../../../../data/models/unlinked_discussion_model.dart';
import '../../../../data/models/link_suggestion_model.dart';

class BulkLinkCard extends StatefulWidget {
  final UnlinkedDiscussion discussion;
  final List<LinkSuggestion> suggestions;
  final VoidCallback onSkip;
  final ValueChanged<String> onLink;
  final ValueChanged<String> onSearch;
  // >> BARU: Tambahkan properti untuk progres
  final int currentDiscussionNumber;
  final int totalDiscussions;

  const BulkLinkCard({
    super.key,
    required this.discussion,
    required this.suggestions,
    required this.onSkip,
    required this.onLink,
    required this.onSearch,
    required this.currentDiscussionNumber,
    required this.totalDiscussions,
  });

  @override
  State<BulkLinkCard> createState() => _BulkLinkCardState();
}

class _BulkLinkCardState extends State<BulkLinkCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.onSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BulkLinkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.discussion != oldWidget.discussion) {
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Discussion Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // >> BARU: Tampilkan progres di sini
                  Text(
                    'Diskusi ${widget.currentDiscussionNumber} dari ${widget.totalDiscussions}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    widget.discussion.discussion.discussion,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi: ${widget.discussion.topicName} > ${widget.discussion.subjectName}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari file HTML...',
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
          const SizedBox(height: 16),

          // Suggestions List
          Expanded(
            child: widget.suggestions.isEmpty
                ? const Center(
                    child: Text('Tidak ada file yang cocok ditemukan.'),
                  )
                : ListView.builder(
                    itemCount: widget.suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = widget.suggestions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(suggestion.title),
                          subtitle: Text(suggestion.relativePath),
                          onTap: () => widget.onLink(suggestion.relativePath),
                        ),
                      );
                    },
                  ),
          ),

          // Action Buttons
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Lewati Diskusi Ini'),
          ),
        ],
      ),
    );
  }
}
