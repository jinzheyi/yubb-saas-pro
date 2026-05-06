import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/video_player_route_args.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key, required this.args});

  final VideoPlayerRouteArgs args;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _playbackFailed = false;
  String _resolvedUrl = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final initialUrl = widget.args.url.trim();
    final fileId = widget.args.fileId.trim();
    try {
      var resolvedUrl = initialUrl;
      if (fileId.isNotEmpty) {
        final signed = await ref
            .read(fileRepositoryProvider)
            .getPresignedGetUrl(fileId: fileId);
        resolvedUrl = signed.toString();
      }
      if (resolvedUrl.isEmpty) {
        throw StateError('video url is empty');
      }
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
      );
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _resolvedUrl = resolvedUrl;
        _loading = false;
        _playbackFailed = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = null;
        _resolvedUrl = initialUrl;
        _loading = false;
        _playbackFailed = true;
      });
    }
  }

  Future<void> _openExternally() async {
    final strings = AppLocalizations.of(context);
    final url = _resolvedUrl.trim();
    if (url.isEmpty) {
      return;
    }
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.chatVideoPlayerOpenExternalFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title = widget.args.title?.trim().isNotEmpty == true
        ? widget.args.title!.trim()
        : strings.chatVideoPlayerTitle;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: Center(child: _buildBody(strings)),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF111111),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations strings) {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    final controller = _controller;
    if (_playbackFailed ||
        controller == null ||
        !controller.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              strings.chatVideoPlayerLoadFailed,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.chatVideoPlayerFallbackHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB9C0CC), fontSize: 13),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _playbackFailed = false;
                    });
                    _initialize();
                  },
                  child: Text(strings.retry),
                ),
                if (_resolvedUrl.trim().isNotEmpty)
                  OutlinedButton(
                    onPressed: _openExternally,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF4B5563)),
                    ),
                    child: Text(strings.chatVideoPlayerOpenExternally),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio <= 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        const SizedBox(height: 14),
        IconButton.filled(
          onPressed: () async {
            if (controller.value.isPlaying) {
              await controller.pause();
            } else {
              await controller.play();
            }
            if (!mounted) {
              return;
            }
            setState(() {});
          },
          iconSize: 30,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF246BFD),
            foregroundColor: Colors.white,
          ),
          icon: AppIcon(
            controller.value.isPlaying
                ? AppIconKind.pause
                : AppIconKind.play,
            size: 30,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
