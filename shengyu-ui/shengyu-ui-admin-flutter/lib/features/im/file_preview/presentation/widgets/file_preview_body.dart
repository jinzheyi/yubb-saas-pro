import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/states/file_preview_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FilePreviewBody extends StatelessWidget {
  const FilePreviewBody({super.key, required this.state});

  final FilePreviewState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final descriptor = state.descriptor;
    final plan = state.openPlan;
    final fileName = (descriptor?.fileName.trim().isNotEmpty ?? false)
        ? descriptor!.fileName.trim()
        : strings.filePreviewTitle;
    final fallbackText = plan?.fallbackMessage?.trim() ?? '';
    final resolvedUrl =
        plan?.resolvedUrl ??
        descriptor?.downloadUrl ??
        descriptor?.previewUrl ??
        descriptor?.convertedPdfUrl ??
        descriptor?.viewerUrl ??
        '';
    final detailText = resolvedUrl.isNotEmpty ? resolvedUrl : fallbackText;

    return switch (plan?.renderStrategy) {
      FileRenderStrategy.nativeImage => ColoredBox(
        color: Colors.black,
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Image.network(
              resolvedUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _FallbackDetail(
                  fileName: fileName,
                  strategyLabel: _strategyLabel(strings, plan?.renderStrategy),
                  detailText: detailText,
                );
              },
            ),
          ),
        ),
      ),
      FileRenderStrategy.nativeVideo => _VideoPreview(url: resolvedUrl),
      FileRenderStrategy.nativeAudio => _AudioPreview(url: resolvedUrl),
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.serverConvertedPdf ||
      FileRenderStrategy.serverConvertedHtml ||
      FileRenderStrategy.embeddedOfficeViewer => _WebDocumentPreview(
        url: resolvedUrl,
        fallbackDetailText: detailText,
      ),
      FileRenderStrategy.nativeText => _RemoteTextPreview(
        url: resolvedUrl,
        selectable: true,
      ),
      FileRenderStrategy.nativeMarkdown => _RemoteTextPreview(
        url: resolvedUrl,
        selectable: true,
      ),
      _ => Padding(
        padding: const EdgeInsets.all(16),
        child: _FallbackDetail(
          fileName: fileName,
          strategyLabel: _strategyLabel(strings, plan?.renderStrategy),
          detailText: detailText,
        ),
      ),
    };
  }

  String _strategyLabel(
    AppLocalizations strings,
    FileRenderStrategy? strategy,
  ) {
    return switch (strategy) {
      FileRenderStrategy.nativePdf => strings.filePreviewModePdf,
      FileRenderStrategy.nativeImage => strings.filePreviewModeImage,
      FileRenderStrategy.nativeVideo => strings.filePreviewModeVideo,
      FileRenderStrategy.nativeAudio => strings.filePreviewModeAudio,
      FileRenderStrategy.nativeText => strings.filePreviewModeText,
      FileRenderStrategy.nativeMarkdown => strings.filePreviewModeMarkdown,
      FileRenderStrategy.serverConvertedPdf => strings.filePreviewModeServerPdf,
      FileRenderStrategy.serverConvertedHtml =>
        strings.filePreviewModeServerHtml,
      FileRenderStrategy.embeddedOfficeViewer => strings.filePreviewModeOffice,
      FileRenderStrategy.downloadOnly => strings.filePreviewModeDownloadOnly,
      null => strings.filePreviewModeUnknown,
    };
  }
}

class _WebDocumentPreview extends StatelessWidget {
  const _WebDocumentPreview({
    required this.url,
    required this.fallbackDetailText,
  });

  final String url;
  final String fallbackDetailText;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(fallbackDetailText),
      );
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(fallbackDetailText),
      );
    }
    return _PlatformWebView(url: url);
  }
}

class _PlatformWebView extends StatefulWidget {
  const _PlatformWebView({required this.url});

  final String url;

  @override
  State<_PlatformWebView> createState() => _PlatformWebViewState();
}

class _PlatformWebViewState extends State<_PlatformWebView> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _loading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _loading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_loading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _FallbackDetail extends StatelessWidget {
  const _FallbackDetail({
    required this.fileName,
    required this.strategyLabel,
    required this.detailText,
  });

  final String fileName;
  final String strategyLabel;
  final String detailText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fileName),
        const SizedBox(height: 8),
        Text(strategyLabel),
        const SizedBox(height: 8),
        SelectableText(detailText),
      ],
    );
  }
}

class _RemoteTextPreview extends StatelessWidget {
  const _RemoteTextPreview({required this.url, required this.selectable});

  final String url;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const Center(child: SelectableText(''));
    }
    return FutureBuilder<String>(
      future: NetworkAssetBundle(Uri.parse(url)).loadString(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(url),
          );
        }
        final text = snapshot.data ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: selectable ? SelectableText(text) : Text(text),
        );
      },
    );
  }
}

class _AudioPreview extends StatefulWidget {
  const _AudioPreview({required this.url});

  final String url;

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = true;
  bool _playing = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.positionStream.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });
    _player.durationStream.listen((duration) {
      if (!mounted || duration == null) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _playing = state.playing;
      });
    });
    _initialize();
  }

  Future<void> _initialize() async {
    final rawUrl = widget.url.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _loading = false;
        _errorText = '';
      });
      return;
    }
    try {
      await _player.setUrl(rawUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = rawUrl;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorText != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(_errorText!),
      );
    }
    final maxSeconds = _duration.inMilliseconds <= 0
        ? 1.0
        : _duration.inMilliseconds.toDouble();
    final currentSeconds = _position.inMilliseconds.clamp(
      0,
      maxSeconds.toInt(),
    );
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.filled(
              onPressed: () async {
                if (_playing) {
                  await _player.pause();
                  return;
                }
                await _player.play();
              },
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(height: 12),
            Slider(
              value: currentSeconds.toDouble(),
              min: 0,
              max: maxSeconds,
              onChanged: (value) async {
                await _player.seek(Duration(milliseconds: value.round()));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.url});

  final String url;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final rawUrl = widget.url.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _loading = false;
        _errorText = '';
      });
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
      await controller.initialize();
      controller.setLooping(false);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = rawUrl;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final controller = _controller;
    if (_errorText != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(_errorText ?? ''),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio <= 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            const SizedBox(height: 12),
            IconButton.filled(
              onPressed: () async {
                if (controller.value.isPlaying) {
                  await controller.pause();
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                  return;
                }
                await controller.play();
                if (!mounted) {
                  return;
                }
                setState(() {});
              },
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
