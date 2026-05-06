import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_combine_detail_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class ForwardCombineDetailPage extends ConsumerStatefulWidget {
  const ForwardCombineDetailPage({super.key, required this.args});

  final ForwardCombineDetailRouteArgs args;

  @override
  ConsumerState<ForwardCombineDetailPage> createState() =>
      _ForwardCombineDetailPageState();
}

class _ForwardCombineDetailPageState
    extends ConsumerState<ForwardCombineDetailPage> {
  static const int _maxDepth = 20;

  bool _loading = true;
  String _comment = '';
  String _emptyText = '';
  List<_ForwardCombineItem> _items = const <_ForwardCombineItem>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final strings = AppLocalizations.of(context);
    final messageId = widget.args.messageId.trim();
    if (messageId.isEmpty || messageId == '0') {
      setState(() {
        _loading = false;
        _emptyText = strings.chatForwardCombineDetailInvalidParams;
        _items = const <_ForwardCombineItem>[];
      });
      return;
    }
    if (widget.args.depth > _maxDepth) {
      setState(() {
        _loading = false;
        _emptyText = strings.chatForwardCombineDetailQuoteTooDeep;
        _items = const <_ForwardCombineItem>[];
      });
      return;
    }
    setState(() {
      _loading = true;
      _emptyText = '';
    });
    try {
      final detail = await ref
          .read(messageRepositoryProvider)
          .getMessageDetail(messageId: messageId);
      final body = _parseForwardCombineBody(detail.content);
      if (!mounted) {
        return;
      }
      if (body == null) {
        setState(() {
          _loading = false;
          _emptyText = strings.chatForwardCombineDetailContentUnavailable;
          _items = const <_ForwardCombineItem>[];
        });
        return;
      }
      final rawItems = body['messages'];
      final list = <_ForwardCombineItem>[];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is! Map) {
            continue;
          }
          final map = item.map((key, value) => MapEntry(key.toString(), value));
          list.add(
            _ForwardCombineItem(
              messageId: map['messageId']?.toString() ?? '',
              sourceChatId: map['sourceChatId']?.toString() ?? '',
              sourceSequence: map['sourceSequence']?.toString(),
              senderName: map['senderName']?.toString() ?? '',
              sendTime: _formatEnterpriseTime(
                map['sendTime']?.toString() ?? map['timestamp']?.toString(),
              ),
              preview: _buildPreview(
                strings,
                map['messageType'],
                map['content'],
              ),
              refMessageId: map['refMessageId']?.toString() ?? '',
            ),
          );
        }
      }
      setState(() {
        _loading = false;
        _comment = body['comment']?.toString() ?? '';
        _items = list;
        _emptyText = list.isEmpty ? strings.chatForwardCombineDetailEmpty : '';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _emptyText = strings.chatForwardCombineDetailLoadFailed;
        _items = const <_ForwardCombineItem>[];
      });
      _showError(strings.chatForwardCombineDetailLoadFailed);
    }
  }

  Map<String, dynamic>? _parseForwardCombineBody(String raw) {
    final decoded = _decodeJson(raw);
    if (decoded is Map<String, dynamic> &&
        decoded['type']?.toString() == 'FORWARD_COMBINE') {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final nestedContent = _decodeJson(decoded['content']);
      if (nestedContent is Map<String, dynamic> &&
          nestedContent['type']?.toString() == 'FORWARD_COMBINE') {
        return nestedContent;
      }
      final nestedBody = _decodeJson(decoded['body']);
      if (nestedBody is Map<String, dynamic> &&
          nestedBody['type']?.toString() == 'FORWARD_COMBINE') {
        return nestedBody;
      }
    }
    return null;
  }

  Object? _decodeJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if ((!trimmed.startsWith('{') || !trimmed.endsWith('}')) &&
        (!trimmed.startsWith('[') || !trimmed.endsWith(']'))) {
      return null;
    }
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _buildPreview(
    AppLocalizations strings,
    Object? rawType,
    Object? content,
  ) {
    final messageType = rawType is num
        ? rawType.toInt()
        : int.tryParse(rawType?.toString() ?? '') ?? 0;
    if (messageType == 1 || messageType == 100 || messageType == 205) {
      final parsed = _decodeJson(content);
      if (parsed is Map<String, dynamic>) {
        final replyContent = parsed['replyContent']?.toString().trim() ?? '';
        if (replyContent.isNotEmpty) {
          return replyContent;
        }
        final nestedContent = parsed['content']?.toString().trim() ?? '';
        if (nestedContent.isNotEmpty) {
          return nestedContent;
        }
      }
      return content?.toString() ?? strings.chatPreviewMessage;
    }
    if (messageType == 9 || messageType == 106) {
      final parsed = _decodeJson(content);
      if (parsed is Map<String, dynamic>) {
        final innerType = parsed['type']?.toString() ?? '';
        if (innerType == 'FORWARD_COMBINE') {
          return strings.chatForwardCombine;
        }
        if (innerType == 'STICKER') {
          return strings.chatPreviewSticker;
        }
        if (innerType == 'CONTACT_CARD') {
          return strings.chatPreviewContactCard;
        }
      }
      return strings.chatPreviewMessage;
    }
    return switch (messageType) {
      2 || 101 => strings.chatPreviewImage,
      3 || 102 => strings.chatPreviewVoice,
      4 || 103 => strings.chatPreviewVideo,
      5 || 104 => strings.chatPreviewFile,
      6 || 105 => strings.chatPreviewLocation,
      7 => strings.chatPreviewEmoji,
      8 => strings.chatPreviewSticker,
      _ => strings.chatPreviewMessage,
    };
  }

  String _formatEnterpriseTime(String? raw) {
    final strings = AppLocalizations.of(context);
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      return raw.trim();
    }
    final local = parsed.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thatStart = DateTime(local.year, local.month, local.day);
    final diffDays = todayStart.difference(thatStart).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (diffDays == 0) {
      return strings.chatForwardCombineDetailTodayAt('$hh:$mm');
    }
    if (diffDays == 1) {
      return strings.chatForwardCombineDetailYesterdayAt('$hh:$mm');
    }
    final mon = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    if (local.year == now.year) {
      return '$mon-$day $hh:$mm';
    }
    return '${local.year}-$mon-$day $hh:$mm';
  }

  Future<void> _openItem(_ForwardCombineItem item) async {
    final strings = AppLocalizations.of(context);
    final refMessageId = item.refMessageId.trim();
    if (refMessageId.isNotEmpty && refMessageId != '0') {
      final nextDepth = widget.args.depth + 1;
      if (nextDepth > _maxDepth) {
        _showError(strings.chatForwardCombineDetailQuoteTooDeep);
        return;
      }
      if (widget.args.trace.contains(refMessageId)) {
        _showError(strings.chatForwardCombineDetailCircularReference);
        return;
      }
      if (!mounted) {
        return;
      }
      context.pushNamed(
        RouteNames.chatForwardCombineDetail,
        extra: ForwardCombineDetailRouteArgs(
          messageId: refMessageId,
          depth: nextDepth,
          trace: <String>[...widget.args.trace, refMessageId],
        ),
      );
      return;
    }

    final sourceChatId = item.sourceChatId.trim();
    final messageId = item.messageId.trim();
    if (sourceChatId.isEmpty || messageId.isEmpty) {
      _showError(strings.chatForwardCombineDetailInvalidParams);
      return;
    }

    var conversation = ref
        .read(conversationListControllerProvider)
        .conversations
        .where((item) => item.chatId == sourceChatId)
        .firstOrNull;
    if (conversation == null) {
      await ref
          .read(conversationListControllerProvider.notifier)
          .syncIncrementally();
      if (!mounted) {
        return;
      }
      conversation = ref
          .read(conversationListControllerProvider)
          .conversations
          .where((item) => item.chatId == sourceChatId)
          .firstOrNull;
    }
    final entryArgs = ChatEntryArgs(
      chatId: sourceChatId,
      conversationType:
          conversation?.conversationType ?? ConversationType.direct,
      targetId: conversation?.targetId,
      title: conversation?.title,
      entryMode: ChatEntryMode.anchor,
      anchorSequence: item.sourceSequence?.trim().isNotEmpty == true
          ? item.sourceSequence!.trim()
          : null,
      anchorMessageId: item.sourceSequence?.trim().isNotEmpty == true
          ? null
          : messageId,
      highlightedMessageId: messageId,
    );
    if (!mounted) {
      return;
    }
    context.pushNamed(RouteNames.chat, extra: entryArgs);
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.chatForwardCombineDetailTitle)),
      backgroundColor: const Color(0xFFF7F8FA),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    strings.chatForwardCombineDetailLoading,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A1B2),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_comment.trim().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8ECF3)),
                    ),
                    child: Text(
                      _comment.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF202531),
                        height: 1.45,
                      ),
                    ),
                  ),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        _emptyText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                    ),
                  )
                else
                  ..._items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openItem(item),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8ECF3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.senderName.trim().isEmpty
                                            ? strings.chatPreviewUnknownSender
                                            : item.senderName.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF202531),
                                        ),
                                      ),
                                    ),
                                    if (item.sendTime.trim().isNotEmpty)
                                      Text(
                                        item.sendTime.trim(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF98A1B2),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.preview.trim().isEmpty
                                      ? strings.chatPreviewMessage
                                      : item.preview.trim(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5C667A),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ForwardCombineItem {
  const _ForwardCombineItem({
    required this.messageId,
    required this.sourceChatId,
    required this.sourceSequence,
    required this.senderName,
    required this.sendTime,
    required this.preview,
    required this.refMessageId,
  });

  final String messageId;
  final String sourceChatId;
  final String? sourceSequence;
  final String senderName;
  final String sendTime;
  final String preview;
  final String refMessageId;
}
