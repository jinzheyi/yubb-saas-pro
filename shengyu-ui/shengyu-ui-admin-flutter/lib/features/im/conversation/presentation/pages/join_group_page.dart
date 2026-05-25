import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/presentation/providers/conversation_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_verification_result.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class JoinGroupPage extends ConsumerStatefulWidget {
  const JoinGroupPage({
    super.key,
    this.initialPayload,
    this.manualEntry = false,
  });

  final String? initialPayload;
  final bool manualEntry;

  @override
  ConsumerState<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends ConsumerState<JoinGroupPage> {
  final TextEditingController _inputController = TextEditingController();

  bool _loading = false;
  bool _joining = false;
  bool _hasVerifyAttempted = false;
  bool _isValid = false;
  bool _alreadyInGroup = false;
  String _errorMessage = '';
  String _inviteCode = '';
  String _groupId = '';
  GroupInviteVerificationResult? _verified;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPayload?.trim() ?? '';
    if (initial.isNotEmpty) {
      _inputController.text = initial;
      Future.microtask(_handleManualVerify);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = _verified;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('加入群聊')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '手动输入入群信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: '请输入邀请码或群邀请链接',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleManualVerify(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _handlePasteInvite,
                        child: const Text('粘贴'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : _handleManualVerify,
                        child: Text(_loading ? '校验中...' : '校验'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '支持直接粘贴老项目二维码链接、邀请码文本或扫码结果。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF98A1B2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_hasVerifyAttempted && !_isValid)
            _JoinGroupErrorCard(
              message: _errorMessage.isEmpty ? '邀请码无效或已过期' : _errorMessage,
              onRetry: _resetVerifyState,
            )
          else if (verified != null && _isValid)
            _JoinGroupPreviewCard(
              verified: verified,
              alreadyInGroup: _alreadyInGroup,
              joining: _joining,
              onJoin: _handleJoinGroup,
              onView: _handleViewGroup,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 56),
              alignment: Alignment.center,
              child: Text(
                '等待输入邀请码',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF697386),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePasteInvite() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      _showMessage('剪贴板为空');
      return;
    }
    _inputController.text = text;
    await _handleManualVerify();
  }

  Future<void> _handleManualVerify() async {
    final payload = _parseInvitePayload(_inputController.text);
    if (payload == null) {
      setState(() {
        _hasVerifyAttempted = true;
        _isValid = false;
        _alreadyInGroup = false;
        _errorMessage = '无法识别入群码或邀请链接';
      });
      return;
    }
    setState(() {
      _loading = true;
      _hasVerifyAttempted = true;
      _inviteCode = payload.inviteCode;
      _groupId = payload.groupId;
      _alreadyInGroup = false;
      _errorMessage = '';
    });
    try {
      final verified = await ref
          .read(groupSettingsRepositoryProvider)
          .verifyInviteCode(payload.inviteCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _verified = verified;
        _isValid = verified.valid;
        _groupId = verified.groupId.isNotEmpty
            ? verified.groupId
            : payload.groupId;
        _errorMessage = verified.valid ? '' : '邀请码无效或已过期';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isValid = false;
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleJoinGroup() async {
    if (_joining) {
      return;
    }
    setState(() {
      _joining = true;
    });
    try {
      final result = await ref
          .read(groupSettingsRepositoryProvider)
          .joinGroupByInvite(_inviteCode);
      if (!mounted) {
        return;
      }
      final message = result.message.trim().isEmpty
          ? (result.resultType == 2 ? '申请已提交' : '已加入群聊')
          : result.message.trim();
      _showMessage(message);
      if (result.resultType == 2) {
        context.pop();
        return;
      }
      final chatId = result.chatId.trim().isNotEmpty
          ? result.chatId.trim()
          : await ref
                .read(groupSettingsRepositoryProvider)
                .ensureGroupChatId(
                  result.groupId.isNotEmpty ? result.groupId : _groupId,
                );
      unawaited(
        ref
            .read(conversationListControllerProvider.notifier)
            .syncIncrementally(),
      );
      if (!mounted) {
        return;
      }
      // 先返回上一页，再跳转到聊天页面，避免使用 goNamed 替换整个路由栈
      Navigator.of(context).pop();
      if (!mounted) {
        return;
      }
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs.latest(
          chatId: chatId,
          conversationType: ConversationType.group,
          targetId: result.groupId.isNotEmpty ? result.groupId : _groupId,
          title: _verified?.groupName,
        ),
      );
    } catch (error) {
      final message = error.toString();
      if (message.contains('已在群') || message.contains('already')) {
        setState(() {
          _alreadyInGroup = true;
        });
        return;
      }
      if (message.contains('群聊不存在') || message.contains('不可用')) {
        setState(() {
          _hasVerifyAttempted = true;
          _isValid = false;
          _errorMessage = message;
        });
        return;
      }
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          _joining = false;
        });
      }
    }
  }

  Future<void> _handleViewGroup() async {
    try {
      final chatId = await ref
          .read(groupSettingsRepositoryProvider)
          .ensureGroupChatId(_groupId);
      if (!mounted) {
        return;
      }
      // 先返回上一页，再跳转到聊天页面，避免使用 goNamed 替换整个路由栈
      Navigator.of(context).pop();
      if (!mounted) {
        return;
      }
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs.latest(
          chatId: chatId,
          conversationType: ConversationType.group,
          targetId: _groupId,
          title: _verified?.groupName,
        ),
      );
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _resetVerifyState() {
    setState(() {
      _verified = null;
      _hasVerifyAttempted = false;
      _isValid = false;
      _alreadyInGroup = false;
      _errorMessage = '';
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JoinGroupPreviewCard extends StatelessWidget {
  const _JoinGroupPreviewCard({
    required this.verified,
    required this.alreadyInGroup,
    required this.joining,
    required this.onJoin,
    required this.onView,
  });

  final GroupInviteVerificationResult verified;
  final bool alreadyInGroup;
  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final expireText = _formatExpireText(verified.expireTime);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF5B8FF9),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            verified.groupName.trim().isEmpty
                ? '未命名群聊'
                : verified.groupName.trim(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${verified.memberCount}人',
            style: const TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: '邀请码',
            value: verified.groupId.trim().isEmpty
                ? '--'
                : verified.groupId.trim(),
          ),
          _InfoRow(label: '过期时间', value: expireText),
          if (verified.needApproval)
            const _InfoRow(label: '加入方式', value: '需管理员审核'),
          const SizedBox(height: 20),
          if (alreadyInGroup)
            OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('查看群聊'),
            )
          else
            FilledButton(
              onPressed: joining ? null : onJoin,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                joining ? '提交中...' : (verified.needApproval ? '提交申请' : '加入群聊'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatExpireText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return '--';
    }
    final expire = DateTime.tryParse(text);
    if (expire == null) {
      return text;
    }
    final diff = expire.toLocal().difference(DateTime.now());
    if (diff.inSeconds <= 0) {
      return '已过期';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}小时${diff.inMinutes % 60}分钟后过期';
    }
    return '${diff.inMinutes}分钟后过期';
  }
}

class _JoinGroupErrorCard extends StatelessWidget {
  const _JoinGroupErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFF97316),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF202531),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请重新输入有效的邀请码或邀请链接。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF697386)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('重新输入')),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF98A1B2)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF202531)),
            ),
          ),
        ],
      ),
    );
  }
}

_GroupInvitePayload? _parseInvitePayload(String raw) {
  final rawText = raw.trim();
  if (rawText.isEmpty) {
    return null;
  }
  String safeDecode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  String readQueryValue(String text, String key) {
    final match = RegExp('(?:[?&#]|^)$key=([^&#]+)').firstMatch(text);
    if (match == null || match.groupCount < 1) {
      return '';
    }
    return safeDecode(match.group(1) ?? '');
  }

  String normalizeInviteCode(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final queryCode = RegExp(
      r'GRP[A-Z0-9]{10,}',
      caseSensitive: false,
    ).firstMatch(compact);
    if (queryCode != null) {
      return queryCode.group(0)!.toUpperCase();
    }
    return '';
  }

  final decoded = safeDecode(rawText);
  final codeFromQuery = readQueryValue(decoded, 'code');
  final groupIdFromQuery = readQueryValue(decoded, 'groupId');
  final inviteCode = normalizeInviteCode(
    codeFromQuery.isNotEmpty ? codeFromQuery : decoded,
  );
  if (inviteCode.isEmpty) {
    return null;
  }
  return _GroupInvitePayload(inviteCode: inviteCode, groupId: groupIdFromQuery);
}

class _GroupInvitePayload {
  const _GroupInvitePayload({required this.inviteCode, required this.groupId});

  final String inviteCode;
  final String groupId;
}
