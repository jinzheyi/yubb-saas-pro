import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/favorite_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/domain/entities/favorite_item.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/providers/favorite_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/favorite/presentation/states/favorites_state.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_error_view.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  static const _tabs = ['default', 'normal', 'media', 'file'];
  static const _searchDebounce = Duration(milliseconds: 300);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    Future.microtask(
      () => ref.read(favoritesControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(favoritesControllerProvider);
    if (_searchController.text != state.keyword) {
      _searchController.value = TextEditingValue(
        text: state.keyword,
        selection: TextSelection.collapsed(offset: state.keyword.length),
      );
    }
    final tabLabels = <String>[
      strings.favoriteTabDefault,
      strings.favoriteTabNormal,
      strings.favoriteTabMedia,
      strings.favoriteTabFile,
    ];
    final visibleEntries = state.items
        .map(
          (item) => _FavoriteCardEntry(
            item: item,
            display: _buildDisplayItem(strings, item),
          ),
        )
        .where((entry) => _matchesTab(state.tab, entry.display.kind))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        centerTitle: true,
        title: Text(strings.favoritePageTitle),
      ),
      body: switch (state.status) {
        FavoritesStatus.initial || FavoritesStatus.loading
            when state.items.isEmpty =>
          Center(
            child: Text(
              strings.favoriteDetailLoading,
              style: const TextStyle(fontSize: 14, color: Color(0xFF98A1B2)),
            ),
          ),
        FavoritesStatus.failed when state.items.isEmpty => AppErrorView(
          error: state.error,
          onRetry: () => ref.read(favoritesControllerProvider.notifier).load(),
        ),
        _ => Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8ECF3))),
              ),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: strings.favoriteSearchPlaceholder,
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFA7AFB9),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF202531),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final selected = state.tab == _tabs[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == _tabs.length - 1 ? 0 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(favoritesControllerProvider.notifier)
                                  .updateTab(_tabs[index]);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFECEFF7)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tabLabels[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? const Color(0xFF4064A7)
                                      : const Color(0xFF8A93A0),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(favoritesControllerProvider.notifier).refresh(),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  children: [
                    if (visibleEntries.isEmpty &&
                        state.status != FavoritesStatus.loading)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            strings.favoritePageEmpty,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF98A1B2),
                            ),
                          ),
                        ),
                      )
                    else
                      ...visibleEntries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FavoriteCard(
                            item: entry.item,
                            display: entry.display,
                            onTap: () => _openFavorite(entry.item),
                            onLongPress: () => _showItemActions(entry.item),
                          ),
                        ),
                      ),
                    if (state.status == FavoritesStatus.failed &&
                        state.items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            state.error?.message ?? strings.favoriteDetailLoadFailed,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE54D4F),
                            ),
                          ),
                        ),
                      )
                    else if (state.status == FavoritesStatus.loading ||
                        state.loadingMore)
                      _FooterNotice(text: strings.favoriteDetailLoading)
                    else if (!state.hasMore && visibleEntries.isNotEmpty)
                      _FooterNotice(text: strings.chatMediaNoMore)
                    else if (visibleEntries.isNotEmpty)
                      _FooterNotice(text: strings.chatMediaPullMore),
                  ],
                ),
              ),
            ),
          ],
        ),
      },
    );
  }

  void _handleSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      ref.read(favoritesControllerProvider.notifier).updateKeyword(value.trim());
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels < threshold) {
      return;
    }
    ref.read(favoritesControllerProvider.notifier).loadMore();
  }

  void _openFavorite(FavoriteItem item) {
    if (item.favoriteId.trim().isEmpty || item.favoriteId == '0') {
      _showNotice(AppLocalizations.of(context).favoriteOpenFailed);
      return;
    }
    context.pushNamed(
      RouteNames.favoriteDetail,
      extra: FavoriteDetailRouteArgs(favoriteId: item.favoriteId),
    );
  }

  Future<void> _showItemActions(FavoriteItem item) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(strings.favoriteCancelAction),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) {
      await _removeFavorite(item);
    }
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final strings = AppLocalizations.of(context);
    if (item.favoriteId.trim().isEmpty || item.favoriteId == '0') {
      _showNotice(strings.favoriteOpenFailed);
      return;
    }
    try {
      await ref.read(favoritesControllerProvider.notifier).removeFavorite(item);
      if (!mounted) {
        return;
      }
      _showNotice(strings.favoriteCancelSuccess);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showNotice('$error');
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.display,
    required this.onTap,
    required this.onLongPress,
  });

  final FavoriteItem item;
  final _FavoriteDisplayItem display;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      display.typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A93A0),
                      ),
                    ),
                  ),
                  Text(
                    _formatFavoriteTime(
                      strings,
                      item.sendTime.isNotEmpty ? item.sendTime : item.favoriteTime,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          display.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF202531),
                          ),
                        ),
                        if (display.subTitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            display.subTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A93A0),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (display.thumb.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        display.thumb,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _FileThumbPlaceholder(
                          kind: display.kind,
                        ),
                      ),
                    ),
                  ] else if (display.kind == _FavoriteCardKind.file) ...[
                    const SizedBox(width: 12),
                    const _FileThumbPlaceholder(kind: _FavoriteCardKind.file),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileThumbPlaceholder extends StatelessWidget {
  const _FileThumbPlaceholder({required this.kind});

  final _FavoriteCardKind kind;

  @override
  Widget build(BuildContext context) {
    final icon = kind == _FavoriteCardKind.file
        ? Icons.insert_drive_file_outlined
        : Icons.image_not_supported_outlined;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF4B70D0)),
    );
  }
}

class _FooterNotice extends StatelessWidget {
  const _FooterNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
        ),
      ),
    );
  }
}

class _FavoriteCardEntry {
  const _FavoriteCardEntry({required this.item, required this.display});

  final FavoriteItem item;
  final _FavoriteDisplayItem display;
}

enum _FavoriteCardKind { text, image, video, file, link, location }

class _FavoriteDisplayItem {
  const _FavoriteDisplayItem({
    required this.kind,
    required this.title,
    required this.subTitle,
    required this.thumb,
    required this.typeLabel,
  });

  final _FavoriteCardKind kind;
  final String title;
  final String subTitle;
  final String thumb;
  final String typeLabel;
}

_FavoriteDisplayItem _buildDisplayItem(
  AppLocalizations strings,
  FavoriteItem item,
) {
  var kind = _FavoriteCardKind.text;
  var title = item.messagePreview.isNotEmpty
      ? item.messagePreview
      : strings.chatPreviewMessage;
  var subTitle = '';
  var thumb = '';
  var typeLabel = _buildTypeText(strings, item.messageType);

  final parsedContent = _safeParseJson(item.messageContent);
  final parsedExtra = _safeParseJson(item.messageExtra);
  final parsedSnapshot = _safeParseJson(item.messageSnapshot);
  final snapshotContent = parsedSnapshot is Map<String, dynamic>
      ? _safeParseJson(parsedSnapshot['content'])
      : null;
  final snapshotExtra = parsedSnapshot is Map<String, dynamic>
      ? _safeParseJson(parsedSnapshot['extra'])
      : null;

  if (item.messageType == 1) {
    final textContent = _extractText(parsedContent ?? item.messageContent).trim();
    if (_looksLikeLinkContent(textContent)) {
      kind = _FavoriteCardKind.link;
      title = textContent;
      subTitle = textContent;
      typeLabel = strings.favoriteDetailTypeDefault;
    } else {
      kind = _FavoriteCardKind.text;
      title = textContent.isNotEmpty ? textContent : title;
      typeLabel = strings.favoriteDetailTypeDefault;
    }
  } else if (item.messageType == 2) {
    kind = _FavoriteCardKind.image;
    thumb =
        _resolveUrlFromObject(parsedContent) ??
        _resolveUrlFromObject(parsedExtra) ??
        _resolveUrlFromObject(snapshotContent) ??
        _resolveUrlFromObject(snapshotExtra) ??
        item.messageContent.trim();
    final imageName =
        _resolveNameFromObject(parsedContent) ??
        _resolveNameFromObject(parsedExtra) ??
        _resolveNameFromObject(snapshotContent) ??
        _resolveNameFromObject(snapshotExtra) ??
        '';
    final previewText = item.messagePreview.trim();
    final safePreviewText = _looksLikeLinkContent(previewText) ? '' : previewText;
    title = imageName.isNotEmpty
        ? imageName
        : (safePreviewText.isNotEmpty ? safePreviewText : strings.chatPreviewImage);
    typeLabel = strings.favoriteDetailTypeImage;
  } else if (item.messageType == 4) {
    kind = _FavoriteCardKind.video;
    if (parsedExtra is Map<String, dynamic>) {
      thumb =
          parsedExtra['cover']?.toString() ??
          parsedExtra['thumbnail']?.toString() ??
          parsedExtra['thumbUrl']?.toString() ??
          '';
    }
    title = item.messagePreview.isNotEmpty
        ? item.messagePreview
        : strings.chatPreviewVideo;
    typeLabel = strings.favoriteDetailTypeVideo;
  } else if (item.messageType == 5) {
    kind = _FavoriteCardKind.file;
    final fileObj = parsedExtra is Map<String, dynamic>
        ? parsedExtra
        : (snapshotExtra is Map<String, dynamic> ? snapshotExtra : null);
    final fileName = fileObj?['fileName']?.toString() ?? '';
    final fileSizeRaw = fileObj?['size'];
    final size = fileSizeRaw is num
        ? fileSizeRaw.toInt()
        : int.tryParse(fileSizeRaw?.toString() ?? '') ?? 0;
    title = fileName.isNotEmpty
        ? fileName
        : (item.messagePreview.isNotEmpty ? item.messagePreview : strings.chatPreviewFile);
    subTitle = _buildFileSizeText(size);
    typeLabel = strings.favoriteDetailTypeFile;
  } else if (item.messageType == 9) {
    final customObj = parsedContent is Map<String, dynamic>
        ? parsedContent
        : (parsedExtra is Map<String, dynamic> ? parsedExtra : null);
    final customType = customObj?['type']?.toString().toUpperCase() ?? '';
    final customUrl =
        _resolveUrlFromObject(customObj) ??
        _resolveUrlFromObject(snapshotContent) ??
        _resolveUrlFromObject(snapshotExtra) ??
        '';
    if (customType == 'LINK' ||
        customType == 'URL' ||
        customType == 'WEB_LINK' ||
        customUrl.isNotEmpty) {
      kind = _FavoriteCardKind.link;
      title = customObj?['title']?.toString().trim().isNotEmpty == true
          ? customObj!['title'].toString()
          : customUrl;
      subTitle = customUrl;
      typeLabel = strings.favoriteDetailTypeDefault;
    } else {
      kind = _FavoriteCardKind.text;
      title = item.messagePreview.isNotEmpty
          ? item.messagePreview
          : strings.chatPreviewMessage;
      typeLabel = strings.favoriteDetailTypeDefault;
    }
  } else {
    kind = _FavoriteCardKind.text;
    title = item.messagePreview.isNotEmpty
        ? item.messagePreview
        : strings.chatPreviewMessage;
    typeLabel = strings.favoriteDetailTypeDefault;
  }

  return _FavoriteDisplayItem(
    kind: kind,
    title: title,
    subTitle: subTitle,
    thumb: thumb,
    typeLabel: typeLabel,
  );
}

bool _matchesTab(String tab, _FavoriteCardKind kind) {
  switch (tab) {
    case 'normal':
      return kind != _FavoriteCardKind.image &&
          kind != _FavoriteCardKind.video &&
          kind != _FavoriteCardKind.file;
    case 'media':
      return kind == _FavoriteCardKind.image || kind == _FavoriteCardKind.video;
    case 'file':
      return kind == _FavoriteCardKind.file;
    default:
      return true;
  }
}

String _formatFavoriteTime(AppLocalizations strings, String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return '';
  }
  DateTime? date = DateTime.tryParse(
    normalized.contains(' ') ? normalized.replaceFirst(' ', 'T') : normalized,
  );
  if (date == null) {
    final millis = int.tryParse(normalized);
    if (millis != null && millis > 0) {
      date = DateTime.fromMillisecondsSinceEpoch(
        normalized.length <= 10 ? millis * 1000 : millis,
      );
    }
  }
  if (date == null) {
    return normalized;
  }
  final now = DateTime.now();
  if (date.year == now.year) {
    return '${date.month}-${date.day}';
  }
  return '${date.year}-${date.month}-${date.day}';
}

String _buildTypeText(AppLocalizations strings, int type) {
  switch (type) {
    case 1:
      return strings.favoriteDetailTypeNote;
    case 2:
      return strings.favoriteDetailTypeImage;
    case 3:
      return strings.chatPreviewVoice;
    case 4:
      return strings.favoriteDetailTypeVideo;
    case 5:
      return strings.favoriteDetailTypeFile;
    case 6:
      return strings.chatLocationDefaultTitle;
    case 8:
      return strings.chatPreviewSticker;
    case 9:
      return strings.favoriteDetailTypeDefault;
    default:
      return strings.favoriteDetailTypeDefault;
  }
}

dynamic _safeParseJson(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is Map<String, dynamic> || raw is List) {
    return raw;
  }
  final text = raw.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  if (!((text.startsWith('{') && text.endsWith('}')) ||
      (text.startsWith('[') && text.endsWith(']')))) {
    return null;
  }
  try {
    return jsonDecode(text);
  } catch (_) {
    return null;
  }
}

bool _looksLikeLinkContent(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return false;
  }
  return RegExp(r'^https?:\/\/\S+$', caseSensitive: false).hasMatch(value) ||
      RegExp(r'^www\.\S+$', caseSensitive: false).hasMatch(value);
}

String _extractText(Object? raw) {
  if (raw == null) {
    return '';
  }
  if (raw is String) {
    return raw;
  }
  if (raw is Map<String, dynamic>) {
    for (final key in ['content', 'text', 'title']) {
      final value = raw[key]?.toString() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return '';
}

String? _resolveUrlFromObject(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  for (final key in ['url', 'link', 'href']) {
    final value = raw[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  final nested = raw['content'];
  if (nested is String && _looksLikeLinkContent(nested)) {
    return nested.trim();
  }
  return _resolveUrlFromObject(nested);
}

String? _resolveNameFromObject(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return null;
  }
  for (final key in ['fileName', 'name', 'filename', 'title']) {
    final value = raw[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  return _resolveNameFromObject(raw['content']);
}

String _buildFileSizeText(int size) {
  if (size <= 0) {
    return '';
  }
  if (size < 1024) {
    return '${size}B';
  }
  if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)}KB';
  }
  if (size < 1024 * 1024 * 1024) {
    return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
  }
  return '${(size / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
}
