// lib/features/webview_page/presentation/widgets/navigation_controls.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NavigationControls extends StatelessWidget {
  final WebViewController webViewController;
  final bool isFromDiscussion;

  const NavigationControls({
    super.key,
    required this.webViewController,
    this.isFromDiscussion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Tampilkan tombol ini hanya jika TIDAK dibuka dari diskusi
        if (!isFromDiscussion) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (await webViewController.canGoBack()) {
                await webViewController.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () async {
              if (await webViewController.canGoForward()) {
                await webViewController.goForward();
              }
            },
          ),
        ],
        // Tombol reload tetap ditampilkan
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () => webViewController.reload(),
        ),
      ],
    );
  }
}
