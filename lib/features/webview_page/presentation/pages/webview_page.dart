// lib/features/webview_page/presentation/pages/webview_page.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import '../widgets/navigation_controls.dart';
import '../pages/dialogs/discussion_details_dialog.dart';

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
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.htmlContent != null) {
      controller.loadHtmlString(widget.htmlContent!);
    } else if (widget.initialUrl != null) {
      controller.loadRequest(Uri.parse(widget.initialUrl!));
    }

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
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
          if (isFromDiscussion)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Detail & Poin',
              onPressed: () =>
                  showDiscussionDetailsDialog(context, widget.discussion!),
            ),
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
