// lib/features/webview_page/presentation/pages/webview_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:my_aplication/features/content_management/application/discussion_provider.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/dialogs/confirmation_dialogs.dart';
import 'package:my_aplication/features/content_management/presentation/discussions/utils/repetition_code_utils.dart';
import 'package:my_aplication/core/providers/neuron_provider.dart';
import 'package:my_aplication/core/utils/scaffold_messenger_utils.dart';

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

  // --- FUNGSI INI DIPERBARUI SECARA SIGNIFIKAN ---
  void _showDiscussionDetailsDialog(
    BuildContext context,
    Discussion discussion,
  ) {
    final discussionProvider = Provider.of<DiscussionProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper untuk membuat widget kode yang bisa diketuk
            Widget buildTappableCode(dynamic item) {
              final isPoint = item is Point;
              final currentCode = isPoint
                  ? item.repetitionCode
                  : discussion.repetitionCode;

              return RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(text: 'Kode Repetisi: '),
                    TextSpan(
                      text: currentCode,
                      style: TextStyle(
                        color: getColorForRepetitionCode(currentCode),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final currentIndex = getRepetitionCodeIndex(
                            currentCode,
                          );
                          if (currentIndex <
                              discussionProvider.repetitionCodes.length - 1) {
                            final nextCode = discussionProvider
                                .repetitionCodes[currentIndex + 1];

                            final confirmed =
                                await showRepetitionCodeUpdateConfirmationDialog(
                                  context: context,
                                  currentCode: currentCode,
                                  nextCode: nextCode,
                                );

                            if (confirmed && mounted) {
                              discussionProvider.incrementRepetitionCode(item);

                              final reward = getNeuronRewardForCode(nextCode);
                              if (reward > 0) {
                                await Provider.of<NeuronProvider>(
                                  context,
                                  listen: false,
                                ).addNeurons(reward);
                                showNeuronRewardSnackBar(context, reward);
                              }
                              showAppSnackBar(
                                context,
                                'Kode diubah ke $nextCode.',
                              );

                              // Perbarui UI dialog
                              setDialogState(() {});
                            }
                          }
                        },
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: const Text('Detail & Poin Diskusi'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bagian Diskusi Utama
                      Text(
                        discussion.discussion,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jadwal Tinjau: ${discussion.effectiveDate ?? "N/A"}',
                      ),
                      const SizedBox(height: 8),
                      // Hanya tampilkan jika tidak punya poin
                      if (discussion.points.isEmpty)
                        buildTappableCode(discussion),

                      if (discussion.points.isNotEmpty)
                        const Divider(height: 32),

                      // Bagian Daftar Poin
                      if (discussion.points.isNotEmpty)
                        ...discussion.points.map((point) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ${point.pointText}'),
                                const SizedBox(height: 4),
                                Text(
                                  '  Jadwal: ${point.date}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: buildTappableCode(point),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tutup'),
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
          if (widget.discussion != null)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit Detail & Poin',
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
