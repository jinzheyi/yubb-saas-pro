import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

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
  late final web.HTMLIFrameElement _iframe;
  late final String _viewType;
  static int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _viewType = 'browser-content-view-${_nextId++}';
    _iframe = web.HTMLIFrameElement()
      ..src = widget.url
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen';
    _iframe.addEventListener(
      'load',
      ((web.Event _) {
        if (!mounted) {
          return;
        }
        _dispatchAfterBuild(widget.onLoadFinish);
      }).toJS,
    );
    _iframe.addEventListener(
      'error',
      ((web.Event _) {
        if (!mounted) {
          return;
        }
        _dispatchAfterBuild(() => widget.onLoadError('iframe_load_failed'));
      }).toJS,
    );
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (_) => _iframe);
    _dispatchAfterBuild(widget.onLoadStart);
  }

  @override
  void didUpdateWidget(covariant BrowserContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url) {
      return;
    }
    _dispatchAfterBuild(widget.onLoadStart);
    _iframe.src = widget.url;
  }

  void _dispatchAfterBuild(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      callback();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
