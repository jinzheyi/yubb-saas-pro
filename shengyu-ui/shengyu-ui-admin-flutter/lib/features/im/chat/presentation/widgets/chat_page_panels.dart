import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/core/platform/media_picker_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_item.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/sticker_payload.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/sticker_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_message_action.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/models/chat_more_panel_action.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/emoji/chat_emoji_catalog.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ChatPageHeader extends StatelessWidget {
  const ChatPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onInitiateGroup,
    this.onOpenSettings,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onInitiateGroup;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 44,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE8ECF3), width: 0.5),
      ),
      leadingWidth: 74,
      leading: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              const AppIcon(
                AppIconKind.chevronLeft,
                size: 18,
                color: Color(0xFF202531),
              ),
              const SizedBox(width: 2),
              Text(
                AppLocalizations.of(context).backAction,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF202531),
                ),
              ),
            ],
          ),
        ),
      ),
      titleSpacing: 0,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202531),
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF98A1B2)),
            ),
          ],
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          splashRadius: 17,
          onPressed: onInitiateGroup,
          icon: const AppIcon(
            AppIconKind.groupAdd,
            size: 21,
            color: Color(0xFF202531),
          ),
        ),
        if (onOpenSettings != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              splashRadius: 17,
              onPressed: onOpenSettings,
              icon: const AppIcon(
                AppIconKind.more,
                size: 21,
                color: Color(0xFF202531),
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class ChatGroupNoticeBanner extends StatelessWidget {
  const ChatGroupNoticeBanner({
    super.key,
    required this.notice,
    required this.onTap,
    required this.onDismiss,
  });

  final String notice;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFAF0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3B2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).chatHeaderGroupNotice,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9A5B00),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7A4A00),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: AppIcon(
                    AppIconKind.close,
                    size: 12,
                    color: Color(0xFFB77A1A),
                  ),
                ),
              ),
              const AppIcon(
                AppIconKind.chevronRight,
                size: 14,
                color: Color(0xFFB77A1A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMorePanel extends StatelessWidget {
  const ChatMorePanel({
    super.key,
    required this.strings,
    required this.onExecuteAction,
  });

  final AppLocalizations strings;
  final Future<void> Function(ChatMorePanelAction action) onExecuteAction;

  @override
  Widget build(BuildContext context) {
    final items = [
      _AttachmentAction(
        action: ChatMorePanelAction.album,
        icon: AppIconKind.photo,
        label: strings.attachImageAction,
        color: const Color(0xFFEEF3FF),
        iconColor: const Color(0xFF2F6BFF),
      ),
      _AttachmentAction(
        action: ChatMorePanelAction.camera,
        icon: AppIconKind.camera,
        label: strings.chatMoreActionCamera,
        color: const Color(0xFFEEF4FF),
        iconColor: const Color(0xFF2F6BFF),
      ),
      _AttachmentAction(
        action: ChatMorePanelAction.location,
        icon: AppIconKind.location,
        label: strings.chatMoreActionLocation,
        color: const Color(0xFFFFF2DE),
        iconColor: const Color(0xFFFFA940),
      ),
      _AttachmentAction(
        action: ChatMorePanelAction.file,
        icon: AppIconKind.folder,
        label: strings.attachFileAction,
        color: const Color(0xFFE8FAF3),
        iconColor: const Color(0xFF25B67B),
      ),
      _AttachmentAction(
        action: ChatMorePanelAction.contact,
        icon: AppIconKind.badge,
        label: strings.chatMoreActionContactCard,
        color: const Color(0xFFFFF2DE),
        iconColor: const Color(0xFFFFA940),
      ),
      _AttachmentAction(
        action: ChatMorePanelAction.favorite,
        icon: AppIconKind.starOutline,
        label: strings.chatActionFavorite,
        color: const Color(0xFFFFF2DE),
        iconColor: const Color(0xFFFFA940),
      ),
    ];

    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      child: Wrap(
        spacing: 0,
        runSpacing: 18,
        children: [
          for (final item in items)
            _AttachmentActionButton(
              action: item,
              onTap: () => onExecuteAction(item.action),
            ),
        ],
      ),
    );
  }
}

class ChatMessageActionSheet extends StatelessWidget {
  const ChatMessageActionSheet({
    super.key,
    required this.actions,
    required this.onSelectAction,
    this.compact = false,
  });

  final List<({ChatMessageAction action, Object icon, String label})> actions;
  final Future<void> Function(ChatMessageAction action) onSelectAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SafeArea(child: SizedBox.shrink());
    }

    const itemWidth = 70.0;
    const itemHeight = 70.0;

    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: compact
              ? BorderRadius.zero
              : const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(12, 14, 12, 18),
        child: Wrap(
          spacing: 0,
          runSpacing: 0,
          children: [
            for (var index = 0; index < actions.length; index++)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(),
                  child: InkWell(
                    onTap: () => onSelectAction(actions[index].action),
                    hoverColor: const Color(0x0F1F2329),
                    splashColor: const Color(0x0F1F2329),
                    highlightColor: const Color(0x0F1F2329),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chatPanelIconWidget(
                          actions[index].icon,
                          size: 22,
                          color:
                              actions[index].action == ChatMessageAction.delete
                              ? const Color(0xFFFF4D4F)
                              : const Color(0xFF202531),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          actions[index].label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                actions[index].action ==
                                    ChatMessageAction.delete
                                ? const Color(0xFFFF4D4F)
                                : const Color(0xFF202531),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatMultiSelectToolbar extends StatelessWidget {
  const ChatMultiSelectToolbar({
    super.key,
    required this.onForward,
    required this.onDelete,
  });

  final VoidCallback onForward;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomToolbarAction(
                icon: AppIconKind.redo,
                label: strings.chatForwardMenu,
                onTap: onForward,
              ),
            ),
            Expanded(
              child: _BottomToolbarAction(
                icon: AppIconKind.delete,
                label: strings.chatActionDelete,
                onTap: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatReadonlyFooter extends StatelessWidget {
  const ChatReadonlyFooter({super.key, required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
        ),
        child: Text(
          hintText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
        ),
      ),
    );
  }
}

class ChatMentionPanel extends StatelessWidget {
  const ChatMentionPanel({
    super.key,
    required this.searchController,
    required this.items,
    required this.loading,
    required this.canMentionAll,
    required this.onKeywordChanged,
    required this.onClose,
    required this.onSelectAll,
    required this.onSelectItem,
  });

  final TextEditingController searchController;
  final List<ChatMentionPanelItem> items;
  final bool loading;
  final bool canMentionAll;
  final ValueChanged<String> onKeywordChanged;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final ValueChanged<ChatMentionPanelItem> onSelectItem;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5F9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        const AppIcon(
                          AppIconKind.search,
                          size: 18,
                          color: Color(0xFF98A1B2),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: onKeywordChanged,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: strings.chatMentionSearchPlaceholder,
                              hintStyle: const TextStyle(
                                color: Color(0xFF98A1B2),
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF202531),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onClose,
                  child: Text(
                    strings.chatMentionClose,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3370FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: loading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        strings.chatMentionLoading,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (canMentionAll)
                        _MentionMemberTile.atAll(callback: onSelectAll),
                      for (final item in items)
                        _MentionMemberTile(
                          item: item,
                          onTap: () => onSelectItem(item),
                        ),
                      if (!canMentionAll && items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              strings.chatMentionEmpty,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF98A1B2),
                              ),
                            ),
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

class ChatMentionPanelItem {
  const ChatMentionPanelItem({
    required this.userId,
    required this.displayName,
    required this.mentionName,
    required this.userName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String mentionName;
  final String userName;
  final String? avatarUrl;
}

class ChatEmojiStickerPanel extends StatefulWidget {
  const ChatEmojiStickerPanel({
    super.key,
    required this.stickerRepository,
    required this.fileRepository,
    required this.mediaPickerService,
    required this.currentUserId,
    required this.maxStickerCount,
    required this.onManage,
    required this.onInsertEmoji,
    required this.onDeleteEmoji,
    required this.onSendSticker,
    required this.onShowNotice,
    required this.onShowSuccessNotice,
  });

  final StickerRepository stickerRepository;
  final FileRepository fileRepository;
  final MediaPickerService mediaPickerService;
  final String currentUserId;
  final int maxStickerCount;
  final VoidCallback onManage;
  final ValueChanged<String> onInsertEmoji;
  final VoidCallback onDeleteEmoji;
  final Future<bool> Function(StickerPayload payload) onSendSticker;
  final ValueChanged<String> onShowNotice;
  final ValueChanged<String> onShowSuccessNotice;

  @override
  State<ChatEmojiStickerPanel> createState() => _ChatEmojiStickerPanelState();
}

class _ChatEmojiStickerPanelState extends State<ChatEmojiStickerPanel> {
  static const _recentEmojiStorageKey = 'im_chat_recent_emoji_v1';
  static final List<String> _emojiItems = ChatEmojiCatalog.codes;

  String _tab = 'emoji';
  bool _loading = true;
  bool _uploadingSticker = false;
  String? _error;
  List<String> _recentEmojis = const <String>[];
  List<StickerItem> _recent = const <StickerItem>[];
  List<StickerItem> _favorites = const <StickerItem>[];

  @override
  void initState() {
    super.initState();
    _loadRecentEmojis();
    _loadStickers();
  }

  Future<void> _loadRecentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        prefs.getStringList(_recentEmojiStorageKey) ?? const <String>[];
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEmojis = stored
          .where((item) => _emojiItems.contains(item))
          .toList(growable: false);
    });
  }

  Future<void> _touchRecentEmoji(String emojiCode) async {
    final next = <String>[
      emojiCode,
      ..._recentEmojis.where((item) => item != emojiCode),
    ];
    if (next.length > 24) {
      next.removeRange(24, next.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentEmojiStorageKey, next);
    if (!mounted) {
      return;
    }
    setState(() {
      _recentEmojis = next;
    });
  }

  Future<void> _loadStickers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await widget.stickerRepository.getStickerCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _recent = catalog.recent;
        _favorites = catalog.favorites;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sendSticker(StickerItem item) async {
    try {
      try {
        await widget.stickerRepository.recordRecentUse(
          stickerId: item.stickerId,
        );
      } catch (_) {
        // 老项目这里是附加链路，失败不阻断发送。
      }
      try {
        await _loadStickers();
      } catch (_) {
        // ignore
      }
      final sent = await widget.onSendSticker(
        StickerPayload(
          stickerId: item.stickerId,
          fileId: item.fileId ?? '',
          url: item.url,
          thumbFileId: item.thumbFileId,
          thumbUrl: item.thumbUrl,
          md5: item.md5,
          width: item.width ?? 0,
          height: item.height ?? 0,
          mimeType: item.mimeType,
        ),
      );
      if (!mounted || !sent) {
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      widget.onShowNotice(error.toString());
    }
  }

  Future<void> _uploadSticker() async {
    if (_uploadingSticker || widget.currentUserId.trim().isEmpty) {
      return;
    }
    final strings = AppLocalizations.of(context);
    final currentCount = _buildStickerList().length;
    if (currentCount >= widget.maxStickerCount) {
      widget.onShowNotice(
        strings.chatMaxStickerReached(widget.maxStickerCount),
      );
      return;
    }
    setState(() {
      _uploadingSticker = true;
    });
    try {
      final picked = await widget.mediaPickerService.pickImage();
      if (picked == null) {
        return;
      }
      final upload = await widget.fileRepository.uploadAndCreateFile(
        taskId: DateTime.now().microsecondsSinceEpoch.toString(),
        purpose: UploadPurpose.stickerOriginal,
        scope: UploadScope.sticker(userId: widget.currentUserId),
        localUri: picked.path,
        displayName: picked.name.trim().isEmpty ? 'sticker' : picked.name,
        mimeType: picked.mimeType,
      );
      final uploaded = await widget.stickerRepository.uploadSticker(
        fileId: upload.file.fileId,
        url: upload.file.url,
        name: upload.file.name,
        md5: upload.file.md5 ?? '',
        mimeType: upload.file.mimeType,
      );
      await _loadStickers();
      if (!mounted) {
        return;
      }
      widget.onShowSuccessNotice(strings.chatStickerAdded);
      await _sendSticker(uploaded);
    } catch (error) {
      if (mounted) {
        widget.onShowNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingSticker = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final allStickers = _buildStickerList();
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FC),
        border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _tab == 'emoji'
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_recentEmojis.isNotEmpty) ...[
                              Text(
                                strings.chatEmojiRecent,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF98A1B2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _EmojiGrid(
                                items: _recentEmojis,
                                onTap: (emojiCode) async {
                                  await _touchRecentEmoji(emojiCode);
                                  widget.onInsertEmoji(emojiCode);
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              strings.chatEmojiAll,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF98A1B2),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _EmojiGrid(
                              items: _emojiItems,
                              onTap: (emojiCode) async {
                                await _touchRecentEmoji(emojiCode);
                                widget.onInsertEmoji(emojiCode);
                              },
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          if (_loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (_error != null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF98A1B2),
                                  ),
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: allStickers.length + 2,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _StickerActionTile(
                                  icon: AppIconKind.add,
                                  label: _uploadingSticker
                                      ? strings.chatUploading
                                      : strings.chatStickerAdd,
                                  onTap: _uploadingSticker
                                      ? null
                                      : _uploadSticker,
                                );
                              }
                              if (index == 1) {
                                return _StickerActionTile(
                                  icon: AppIconKind.tune,
                                  label: strings.chatEmojiManage,
                                  onTap: widget.onManage,
                                );
                              }
                              final item = allStickers[index - 2];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _sendSticker(item),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: Image.network(
                                      item.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: AppIcon(
                                                AppIconKind.smile,
                                                size: 28,
                                                color: Color(0xFF98A1B2),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE8ECF3))),
                ),
                child: Row(
                  children: [
                    _BottomTabIcon(
                      icon: AppIconKind.smile,
                      active: _tab == 'emoji',
                      onTap: () => setState(() => _tab = 'emoji'),
                    ),
                    const SizedBox(width: 8),
                    _BottomTabIcon(
                      icon: AppIconKind.collections,
                      active: _tab == 'sticker',
                      onTap: () => setState(() => _tab = 'sticker'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_tab == 'emoji')
            Positioned(
              right: 16,
              bottom: 58,
              child: InkWell(
                onTap: widget.onDeleteEmoji,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 42,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8ECF3)),
                  ),
                  child: const AppIcon(
                    AppIconKind.backspace,
                    size: 20,
                    color: Color(0xFF98A1B2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<StickerItem> _buildStickerList() {
    final seen = <String>{};
    final merged = <StickerItem>[];
    for (final item in [..._recent, ..._favorites]) {
      if (item.stickerId.isEmpty || seen.contains(item.stickerId)) {
        continue;
      }
      seen.add(item.stickerId);
      merged.add(item);
    }
    return merged;
  }
}

class _BottomTabIcon extends StatelessWidget {
  const _BottomTabIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final Object icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF246BFD) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: _chatPanelIconWidget(
          icon,
          size: 20,
          color: active ? const Color(0xFF246BFD) : const Color(0xFF98A1B2),
        ),
      ),
    );
  }
}

class _StickerActionTile extends StatelessWidget {
  const _StickerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            alignment: Alignment.center,
            child: _chatPanelIconWidget(
              icon,
              size: 30,
              color: const Color(0xFF98A1B2),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF98A1B2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        mainAxisExtent: 48,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final asset = ChatEmojiCatalog.assetFor(item);
        if (asset == null || asset.isEmpty) {
          return const SizedBox.shrink();
        }
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTap(item),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentAction {
  const _AttachmentAction({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final ChatMorePanelAction action;
  final Object icon;
  final String label;
  final Color color;
  final Color iconColor;
}

class _MentionMemberTile extends StatelessWidget {
  const _MentionMemberTile({this.item, this.onTap}) : isAtAll = false;

  const _MentionMemberTile.atAll({required VoidCallback callback})
    : item = null,
      onTap = callback,
      isAtAll = true;

  final ChatMentionPanelItem? item;
  final VoidCallback? onTap;
  final bool isAtAll;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final displayName = isAtAll
        ? '@${strings.chatMentionAllMembers}'
        : item!.displayName;
    final desc = isAtAll
        ? strings.chatMentionAllMembersHint
        : item!.userName.trim().isNotEmpty &&
              item!.userName.trim() != item!.mentionName
        ? item!.userName.trim()
        : item!.mentionName != item!.displayName
        ? item!.mentionName
        : null;
    final avatarText = isAtAll
        ? '@'
        : (displayName.isEmpty ? '?' : displayName.substring(0, 1));
    final avatarColor = isAtAll
        ? const Color(0xFF3370FF)
        : const Color(0xFF8F959E);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(18),
                  image:
                      !isAtAll &&
                          item!.avatarUrl != null &&
                          item!.avatarUrl!.trim().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item!.avatarUrl!.trim()),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child:
                    (!isAtAll &&
                        item!.avatarUrl != null &&
                        item!.avatarUrl!.trim().isNotEmpty)
                    ? null
                    : Text(
                        avatarText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF202531),
                      ),
                    ),
                    if (desc != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF98A1B2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomToolbarAction extends StatelessWidget {
  const _BottomToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _chatPanelIconWidget(
              icon,
              size: 22,
              color: const Color(0xFF202531),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7380)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentActionButton extends StatelessWidget {
  const _AttachmentActionButton({required this.action, required this.onTap});

  final _AttachmentAction action;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: _chatPanelIconWidget(
                action.icon,
                color: action.iconColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4E5666)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _chatPanelIconWidget(
  Object icon, {
  required double size,
  required Color color,
}) {
  if (icon is AppIconKind) {
    return AppIcon(icon, size: size, color: color);
  }
  if (icon is IconData) {
    return Icon(icon, size: size, color: color);
  }
  return SizedBox(width: size, height: size);
}
