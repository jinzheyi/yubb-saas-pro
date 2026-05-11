import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowserContentView extends StatefulWidget {
  const BrowserContentView({
    super.key,
    required this.url,
    required this.onLoadStart,
    required this.onLoadFinish,
    required this.onLoadError,
  });

  final String url;
  final VoidCallback onLoadStart;
  final VoidCallback onLoadFinish;
  final ValueChanged<String> onLoadError;

  @override
  State<BrowserContentView> createState() => _BrowserContentViewState();
}

class _BrowserContentViewState extends State<BrowserContentView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => widget.onLoadStart(),
          onPageFinished: (_) => widget.onLoadFinish(),
          onWebResourceError: (error) {
            widget.onLoadError(error.description.trim());
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
