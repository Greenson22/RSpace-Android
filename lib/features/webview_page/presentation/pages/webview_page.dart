// lib/features/webview_page/presentation/pages/webview_page.dart

import 'dart:io' show Platform; // Untuk mengecek OS/Platform runtime
import 'package:flutter/foundation.dart'
    show kIsWeb; // Untuk mengecek lingkungan Web
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // Tetap dipertahankan
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart'; //
import '../widgets/navigation_controls.dart'; //
import '../pages/dialogs/discussion_details_dialog.dart'; //
import 'dialogs/add_point_dialog_webview.dart'; //
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart'; //
// ==> IMPORT DIALOG BOOKMARK BARU
import 'dialogs/bookmarks_dialog.dart'; //

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
  }) : assert(initialUrl != null || htmlContent != null); //

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  // Mengubah menjadi nullable agar aman ketika tidak diinisialisasi pada platform yang tidak didukung
  WebViewController? _controller;
  bool _isSupportedPlatform = true;

  @override
  void initState() {
    super.initState();

    // Jalankan pengecekan platform: webview_flutter secara default tidak mendukung Desktop (Linux, Windows, macOS)
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      setState(() {
        _isSupportedPlatform = false;
      });
      return; // Batalkan inisialisasi controller agar tidak crash
    }

    // Memastikan fallback register jika berjalan di Android
    if (Platform.isAndroid && WebViewPlatform.instance == null) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      //
      params = AndroidWebViewControllerCreationParams(); //
    } else {
      params = const PlatformWebViewControllerCreationParams(); //
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params); //

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted) //
      ..setBackgroundColor(const Color(0x00000000)) //
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)'); //
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url'); //
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url'); //
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
'''); //
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              //
              debugPrint('blocking navigation to ${request.url}'); //
              return NavigationDecision.prevent; //
            }
            debugPrint('allowing navigation to ${request.url}'); //
            return NavigationDecision.navigate; //
          },
        ),
      );

    // ========================================================
    // PERUBAHAN UTAMA: Izinkan Akses File Lokal & Atur Pemuatan
    // ========================================================
    if (controller.platform is AndroidWebViewController) {
      //
      (controller.platform as AndroidWebViewController).setAllowFileAccess(
        //
        true,
      ); //
    }

    if (widget.initialUrl != null) {
      //
      if (widget.initialUrl!.startsWith('file://')) {
        //
        // Mengonversi format file:// menjadi path berkas sistem biasa untuk loadFile
        final localPath = Uri.parse(widget.initialUrl!).toFilePath(); //
        controller.loadFile(localPath); //
      } else {
        // Memuat tautan internet standar
        controller.loadRequest(Uri.parse(widget.initialUrl!)); //
      }
    } else if (widget.htmlContent != null) {
      //
      controller.loadHtmlString(widget.htmlContent!); //
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFromDiscussion = widget.discussion != null; //

    // --- SKALA UKURAN APPBAR UNTUK MOBILE (Disamakan dengan TopicsPage) ---
    final textScaleFactor = MediaQuery.of(context).textScaleFactor; //
    const double baseAppBarIconSize = 20.0; //
    final scaledAppBarIconSize = baseAppBarIconSize * textScaleFactor; //

    // Menggunakan warna utama default palet aplikasi (Colors.deepPurple)
    const Color defaultThemeColor = Colors.deepPurple; //

    return Scaffold(
      appBar: AppBar(
        backgroundColor: defaultThemeColor, //
        foregroundColor: Colors.white, //
        elevation: 0, //
        leadingWidth: 48.0, //
        iconTheme: IconThemeData(
          size: scaledAppBarIconSize, //
          color: Colors.white, //
        ),
        title: Text(
          widget.title, //
          style: const TextStyle(
            fontSize: 18.0, //
            fontWeight: FontWeight.w600, //
            color: Colors.white, //
          ),
          overflow: TextOverflow.ellipsis, //
        ),
        actions: <Widget>[
          // ==> TAMBAHKAN TOMBOL BOOKMARK DI SINI (Hanya muncul jika controller aktif)
          if (!isFromDiscussion && _controller != null) //
            IconButton(
              icon: const Icon(Icons.bookmarks_outlined), //
              iconSize: scaledAppBarIconSize, //
              color: Colors.white, //
              tooltip: 'Bookmark', //
              onPressed: () => showBookmarksDialog(context, _controller!), //
            ),
          if (isFromDiscussion) ...[
            //
            IconButton(
              icon: const Icon(Icons.add_comment_outlined), //
              iconSize: scaledAppBarIconSize, //
              color: Colors.white, //
              tooltip: 'Tambah Poin', //
              onPressed: () {
                showAddPointDialogFromWebView(
                  //
                  context: context, //
                  discussion: widget.discussion!, //
                  onPointAdded: () {
                    showAppSnackBar(context, 'Poin berhasil ditambahkan.'); //
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_note), //
              iconSize: scaledAppBarIconSize, //
              color: Colors.white, //
              tooltip: 'Edit Detail & Poin', //
              onPressed: () =>
                  showDiscussionDetailsDialog(context, widget.discussion!), //
            ),
          ],
          // Hanya muat NavigationControls jika _controller berhasil diinisialisasi
          if (_controller != null) //
            NavigationControls(
              webViewController: _controller!, //
              isFromDiscussion: isFromDiscussion, //
            ),
          const SizedBox(width: 12.0), //
        ],
      ),
      // Tampilkan WebViewWidget jika platform mendukung, jika tidak tampilkan pesan informasi
      body:
          _isSupportedPlatform &&
              _controller !=
                  null //
          ? WebViewWidget(controller: _controller!) //
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.computer, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'WebView tidak didukung di platform Desktop (Linux).\n\nSilakan jalankan aplikasi ini di emulator/perangkat Android atau iOS untuk melihat konten.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
