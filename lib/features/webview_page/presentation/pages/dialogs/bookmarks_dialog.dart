// lib/features/webview_page/presentation/dialogs/bookmarks_dialog.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../application/bookmark_service.dart';
import '../../../domain/models/bookmark_model.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

/// Menampilkan dialog untuk mengelola bookmark.
void showBookmarksDialog(BuildContext context, WebViewController controller) {
  showDialog(
    context: context,
    builder: (context) => BookmarksDialog(controller: controller),
  );
}

class BookmarksDialog extends StatefulWidget {
  final WebViewController controller;

  const BookmarksDialog({super.key, required this.controller});

  @override
  State<BookmarksDialog> createState() => _BookmarksDialogState();
}

class _BookmarksDialogState extends State<BookmarksDialog> {
  final BookmarkService _bookmarkService = BookmarkService();
  late Future<List<Bookmark>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _bookmarksFuture = _bookmarkService.loadBookmarks();
  }

  void _refreshBookmarks() {
    setState(() {
      _bookmarksFuture = _bookmarkService.loadBookmarks();
    });
  }

  Future<void> _addCurrentPage() async {
    final String? url = await widget.controller.currentUrl();
    final String title =
        await widget.controller.getTitle() ?? url ?? 'Tanpa Judul';

    if (url != null && url.isNotEmpty) {
      final newBookmark = Bookmark(title: title, url: url);
      final currentBookmarks = await _bookmarksFuture;

      // Cek agar tidak ada URL duplikat
      if (currentBookmarks.any((b) => b.url == url)) {
        if (mounted) showAppSnackBar(context, 'Halaman ini sudah di-bookmark.');
        return;
      }

      currentBookmarks.add(newBookmark);
      await _bookmarkService.saveBookmarks(currentBookmarks);
      _refreshBookmarks();
      if (mounted) showAppSnackBar(context, 'Bookmark ditambahkan!');
    } else {
      if (mounted)
        showAppSnackBar(
          context,
          'Tidak dapat menambahkan bookmark untuk halaman ini.',
          isError: true,
        );
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final currentBookmarks = await _bookmarksFuture;
    currentBookmarks.removeWhere((b) => b.id == bookmark.id);
    await _bookmarkService.saveBookmarks(currentBookmarks);
    _refreshBookmarks();
    if (mounted) showAppSnackBar(context, 'Bookmark dihapus.');
  }

  void _navigateToBookmark(Bookmark bookmark) {
    widget.controller.loadRequest(Uri.parse(bookmark.url));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bookmark'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: FutureBuilder<List<Bookmark>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Gagal memuat bookmark.'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada bookmark.'));
            }

            final bookmarks = snapshot.data!;
            return ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return ListTile(
                  title: Text(
                    bookmark.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    bookmark.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _navigateToBookmark(bookmark),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteBookmark(bookmark),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: _addCurrentPage,
          icon: const Icon(Icons.add),
          label: const Text('Halaman Ini'),
        ),
      ],
    );
  }
}
