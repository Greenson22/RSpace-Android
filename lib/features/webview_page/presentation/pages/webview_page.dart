// lib/features/webview_page/presentation/pages/webview_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:my_aplication/core/providers/neuron_provider.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

class WebViewPage extends StatefulWidget {
  final String? initialUrl;
  final String? htmlContent;
  final String title;
  // --- TAMBAHKAN PARAMETER BARU ---
  final Discussion? discussion;

  const WebViewPage({
    super.key,
    this.initialUrl,
    this.htmlContent,
    this.title = 'WebView',
    this.discussion, // Tambahkan di konstruktor
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

  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG EDIT ---
  void _showDiscussionDetailsDialog(
    BuildContext context,
    Discussion discussion,
  ) {
    final discussionProvider = Provider.of<DiscussionProvider>(
      context,
      listen: false,
    );
    String selectedCode = discussion.effectiveRepetitionCode;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Detail Diskusi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discussion.discussion,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Jadwal Tinjau: ${discussion.effectiveDate ?? "N/A"}'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCode,
                      decoration: const InputDecoration(
                        labelText: 'Kode Repetisi',
                      ),
                      items: kRepetitionCodes.map((code) {
                        return DropdownMenuItem(value: code, child: Text(code));
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            selectedCode = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCode != discussion.effectiveRepetitionCode) {
                      discussionProvider.updateDiscussionCode(
                        discussion,
                        selectedCode,
                      );

                      final reward = getNeuronRewardForCode(selectedCode);
                      if (reward > 0) {
                        await Provider.of<NeuronProvider>(
                          context,
                          listen: false,
                        ).addNeurons(reward);
                        showNeuronRewardSnackBar(context, reward);
                      }
                      showAppSnackBar(
                        context,
                        'Kode repetisi berhasil diubah ke $selectedCode.',
                      );
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          // --- TAMBAHKAN TOMBOL EDIT DI SINI ---
          if (widget.discussion != null)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Detail Diskusi',
              onPressed: () =>
                  _showDiscussionDetailsDialog(context, widget.discussion!),
            ),
          NavigationControls(webViewController: _controller),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// ... (Kelas NavigationControls tetap sama)
class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
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
        IconButton(
          icon: const Icon(Icons.replay),
          onPressed: () => webViewController.reload(),
        ),
      ],
    );
  }
}
