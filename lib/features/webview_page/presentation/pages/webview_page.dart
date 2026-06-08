// lib/features/webview_page/presentation/pages/webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Tetap dipertahankan
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import '../widgets/navigation_controls.dart';
import '../pages/dialogs/discussion_details_dialog.dart';
import 'dialogs/add_point_dialog_webview.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';
// ==> IMPORT DIALOG BOOKMARK BARU
import 'dialogs/bookmarks_dialog.dart';

class WebViewPage extends StatefulWidget {
  final String? initialUrl;
  final String? htmlContent;
  final String title;
  final Discussion? discussion;

  const WebViewPage({
    super.key,
    this.initialUrl,
    this.htmlContent,
    this.title = 'WebView',
    this.discussion,
  }) : assert(initialUrl != null || htmlContent != null);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    // ========================================================
    // PERUBAHAN UTAMA: Izinkan Akses File Lokal & Atur Pemuatan
    // ========================================================
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).setAllowFileAccess(
        true,
      );
    }

    if (widget.initialUrl != null) {
      if (widget.initialUrl!.startsWith('file://')) {
        // Mengonversi format file:// menjadi path berkas sistem biasa untuk loadFile
        final localPath = Uri.parse(widget.initialUrl!).toFilePath();
        controller.loadFile(localPath);
      } else {
        // Memuat tautan internet standar
        controller.loadRequest(Uri.parse(widget.initialUrl!));
      }
    } else if (widget.htmlContent != null) {
      controller.loadHtmlString(widget.htmlContent!);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFromDiscussion = widget.discussion != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          // ==> TAMBAHKAN TOMBOL BOOKMARK DI SINI
          if (!isFromDiscussion)
            IconButton(
              icon: const Icon(Icons.bookmarks_outlined),
              tooltip: 'Bookmark',
              onPressed: () => showBookmarksDialog(context, _controller),
            ),
          if (isFromDiscussion) ...[
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'Tambah Poin',
              onPressed: () {
                showAddPointDialogFromWebView(
                  context: context,
                  discussion: widget.discussion!,
                  onPointAdded: () {
                    showAppSnackBar(context, 'Poin berhasil ditambahkan.');
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Detail & Poin',
              onPressed: () =>
                  showDiscussionDetailsDialog(context, widget.discussion!),
            ),
          ],
          NavigationControls(
            webViewController: _controller,
            isFromDiscussion: isFromDiscussion,
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
