import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/browser_page_args.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/widgets/browser_content_view.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key, required this.args});

  final BrowserPageArgs args;

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  bool _loading = true;
  String _webUrl = '';
  String _rawContent = '';
  String? _loadErrorText;
  var _reloadVersion = 0;

  @override
  void initState() {
    super.initState();
    _rawContent = widget.args.rawContent?.trim() ?? '';
    _webUrl = _normalizeWebUrl(widget.args.url);
    if (_webUrl.isEmpty) {
      _loading = false;
    }
  }

  String _normalizeWebUrl(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return '';
    }
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    if (text.startsWith('www.')) {
      return 'https://$text';
    }
    return '';
  }

  String get _addressText => _webUrl.isNotEmpty ? _webUrl : _rawContent;

  bool get _isFileSource => widget.args.source.trim() == 'file';

  String _sourceTag(AppLocalizations strings) {
    return switch (widget.args.source.trim()) {
      'scan' => strings.browserSourceScan,
      'message' => strings.browserSourceMessage,
      'file' => strings.browserSourceFile,
      _ => strings.browserSourceExternal,
    };
  }

  Future<void> _copyAddress(AppLocalizations strings) async {
    final text = _addressText.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.browserNothingToCopy)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.browserCopySuccess)));
  }

  Future<void> _openExternal(AppLocalizations strings) async {
    final text = _addressText.trim();
    if (text.isEmpty) {
      return;
    }
    try {
      await launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.browserOpenExternalFailed)),
      );
    }
  }

  Future<void> _retryLoad() async {
    if (_webUrl.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _loadErrorText = null;
      _reloadVersion += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title = widget.args.title?.trim().isNotEmpty == true
        ? widget.args.title!.trim()
        : strings.browserTitle;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _sourceTag(strings),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF246BFD),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _addressText.isNotEmpty
                      ? _addressText
                      : strings.browserUnknownSafeLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _webUrl.isNotEmpty
                ? Stack(
                    children: [
                      if (_loadErrorText == null)
                        Positioned.fill(
                          child: BrowserContentView(
                            key: ValueKey('$_webUrl-$_reloadVersion'),
                            url: _webUrl,
                            onLoadStart: () {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _loading = true;
                                _loadErrorText = null;
                              });
                            },
                            onLoadFinish: () {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _loading = false;
                              });
                            },
                            onLoadError: (errorText) {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _loading = false;
                                _loadErrorText = errorText.trim();
                              });
                            },
                          ),
                        ),
                      if (_loadErrorText != null)
                        Positioned.fill(
                          child: _BrowserErrorView(
                            title: _isFileSource
                                ? strings.browserFileFailedTitle
                                : strings.browserBlockedTitle,
                            description: _isFileSource
                                ? strings.browserFileFailedDesc
                                : strings.browserBlockedDesc,
                            detailText: _loadErrorText!,
                            retryLabel: strings.retry,
                            onRetry: _retryLoad,
                            externalLabel: strings.browserOpenExternally,
                            onOpenExternal: () => _openExternal(strings),
                          ),
                        ),
                      if (_loading)
                        Positioned.fill(
                          child: _BrowserLoadingOverlay(
                            title: _isFileSource
                                ? strings.browserFileLoadingTitle
                                : strings.browserTitle,
                            description: _isFileSource
                                ? strings.browserFileLoadingDesc
                                : strings.browserUnknownSafeLink,
                          ),
                        ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.browserBlockedTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202531),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          strings.browserBlockedDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF8F96A3),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.browserBlockedLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF98A1B2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _rawContent.isNotEmpty
                                    ? _rawContent
                                    : strings.browserEmptyContent,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF202531),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _copyAddress(strings),
                    child: Text(
                      _webUrl.isNotEmpty
                          ? strings.browserCopyLink
                          : strings.browserCopyContent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _addressText.trim().isEmpty
                        ? null
                        : () => _openExternal(strings),
                    child: Text(strings.browserOpenExternally),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserLoadingOverlay extends StatelessWidget {
  const _BrowserLoadingOverlay({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202531),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF8F96A3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserErrorView extends StatelessWidget {
  const _BrowserErrorView({
    required this.title,
    required this.description,
    required this.detailText,
    required this.retryLabel,
    required this.onRetry,
    required this.externalLabel,
    required this.onOpenExternal,
  });

  final String title;
  final String description;
  final String detailText;
  final String retryLabel;
  final VoidCallback onRetry;
  final String externalLabel;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF8F96A3),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: SelectableText(
              detailText,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF202531),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onOpenExternal,
                  child: Text(externalLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
