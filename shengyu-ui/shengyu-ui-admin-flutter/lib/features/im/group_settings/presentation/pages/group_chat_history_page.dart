import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_history_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/enums/message_type.dart';

class GroupChatHistoryPage extends ConsumerStatefulWidget {
  const GroupChatHistoryPage({super.key, required this.args});

  final GroupSettingDetailArgs args;

  @override
  ConsumerState<GroupChatHistoryPage> createState() =>
      _GroupChatHistoryPageState();
}

class _GroupChatHistoryPageState extends ConsumerState<GroupChatHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupHistoryItem> _records = const [];
  bool _loading = false;
  String? _errorMessage;
  String? _chatId;
  _HistoryCategory _category = _HistoryCategory.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.groupSettingsChatHistory),
        actions: [
          IconButton(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: Color(0xFF98A1B2),
                ),
                hintText: strings.groupHistorySearch,
                border: InputBorder.none,
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF98A1B2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryFilterChip(
                label: strings.groupHistoryFilterAll,
                selected: _category == _HistoryCategory.all,
                onTap: () => _changeCategory(_HistoryCategory.all),
              ),
              _HistoryFilterChip(
                label: strings.groupHistoryFilterFile,
                selected: _category == _HistoryCategory.file,
                onTap: () => _changeCategory(_HistoryCategory.file),
              ),
              _HistoryFilterChip(
                label: strings.groupHistoryFilterImage,
                selected: _category == _HistoryCategory.image,
                onTap: () => _changeCategory(_HistoryCategory.image),
              ),
              _HistoryFilterChip(
                label: strings.groupHistoryFilterLink,
                selected: _category == _HistoryCategory.link,
                onTap: () => _changeCategory(_HistoryCategory.link),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _HistoryErrorCard(message: _errorMessage!, onRetry: _search)
          else if (_records.isEmpty)
            const _HistoryEmptyCard()
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < _records.length; index++) ...[
                    ListTile(
                      onTap: () => _openChatAnchor(_records[index]),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      title: Text(
                        _records[index].senderName.trim().isEmpty
                            ? strings.groupHistorySenderUnknown
                            : _records[index].senderName.trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202531),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _contentText(strings, _records[index]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4E5666),
                          ),
                        ),
                      ),
                      trailing: Text(
                        _formatTime(_records[index].sentAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8F96A3),
                        ),
                      ),
                    ),
                    if (index != _records.length - 1)
                      const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF0F2F6),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _changeCategory(_HistoryCategory value) {
    if (_category == value) {
      return;
    }
    setState(() {
      _category = value;
    });
    if (_searchController.text.trim().isNotEmpty) {
      _search();
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final chatId =
          _chatId ??
          await ref
              .read(groupSettingsRepositoryProvider)
              .ensureGroupChatId(widget.args.groupId);
      final records = await ref
          .read(groupSettingsRepositoryProvider)
          .searchGroupHistory(
            chatId: chatId,
            keyword: _searchController.text,
            category: _category.apiValue,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _chatId = chatId;
        _records = _applyLocalTypeFilter(records);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  List<GroupHistoryItem> _applyLocalTypeFilter(List<GroupHistoryItem> items) {
    switch (_category) {
      case _HistoryCategory.all:
      case _HistoryCategory.link:
        return items;
      case _HistoryCategory.file:
        return items
            .where((item) => item.messageType == MessageType.file)
            .toList();
      case _HistoryCategory.image:
        return items
            .where((item) => item.messageType == MessageType.image)
            .toList();
    }
  }

  void _openChatAnchor(GroupHistoryItem item) {
    final chatId = _chatId ?? item.chatId;
    if (chatId.isEmpty || item.messageId.isEmpty) {
      return;
    }
    context.pushNamed(
      RouteNames.chat,
      extra: ChatEntryArgs(
        chatId: chatId,
        conversationType: ConversationType.group,
        targetId: widget.args.groupId,
        title: widget.args.groupName,
        entryMode: ChatEntryMode.anchor,
        anchorSequence: item.sequence.isEmpty ? null : item.sequence,
        anchorMessageId: item.sequence.isEmpty ? item.messageId : null,
        highlightedMessageId: item.messageId,
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).groupHistoryTimeUnknown;
    }
    return DateFormat('MM-dd HH:mm').format(value.toLocal());
  }

  String _contentText(AppLocalizations strings, GroupHistoryItem item) {
    if (item.content.isNotEmpty) {
      return item.content;
    }
    return switch (item.messageType) {
      MessageType.image => strings.chatHistoryPreviewImage,
      MessageType.voice => strings.chatHistoryPreviewVoice,
      MessageType.video => strings.chatHistoryPreviewVideo,
      MessageType.file => strings.chatHistoryPreviewFile,
      MessageType.location => strings.chatMoreActionLocation,
      MessageType.emoji => strings.chatHistoryPreviewEmoji,
      MessageType.sticker => strings.chatHistoryPreviewSticker,
      MessageType.custom => strings.chatHistoryPreviewMessage,
      MessageType.contactCard => strings.chatContactCardLabel,
      MessageType.system => strings.chatHistoryPreviewSystem,
      MessageType.text => strings.chatHistoryPreviewMessage,
    };
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF246BFD) : Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF4E5666),
          ),
        ),
      ),
    );
  }
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(strings.retry)),
        ],
      ),
    );
  }
}

class _HistoryEmptyCard extends StatelessWidget {
  const _HistoryEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context).groupHistoryEmpty,
        style: const TextStyle(fontSize: 15, color: Color(0xFF8F96A3)),
      ),
    );
  }
}

enum _HistoryCategory {
  all(null),
  file('file'),
  image('image'),
  link('link');

  const _HistoryCategory(this.apiValue);

  final String? apiValue;
}
