import 'browser_content_view_stub.dart'
    if (dart.library.html) 'browser_content_view_web.dart'
    as impl;

import 'package:flutter/material.dart';

class BrowserContentView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return impl.BrowserContentView(
      url: url,
      onLoadStart: onLoadStart,
      onLoadFinish: onLoadFinish,
      onLoadError: onLoadError,
    );
  }
}
