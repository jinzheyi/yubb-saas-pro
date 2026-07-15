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
  bool _hasPageFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            _hasPageFinished = false;
            widget.onLoadStart();
          },
          onPageFinished: (_) {
            _hasPageFinished = true;
            widget.onLoadFinish();
          },
          onWebResourceError: (error) {
            // 只处理主要页面加载失败，忽略子资源（favicon、广告等）加载失败
            // 判断条件：
            // 1. 页面尚未完成加载（_hasPageFinished == false）
            // 2. 错误类型是主要页面错误（非子资源错误）
            final isMainFrameError = error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.connect ||
                error.errorType == WebResourceErrorType.timeout ||
                error.errorType == WebResourceErrorType.unknown;

            if (!_hasPageFinished && isMainFrameError) {
              widget.onLoadError(error.description.trim());
            }
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
