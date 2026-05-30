import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_info.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';

class GroupQrCodePage extends ConsumerStatefulWidget {
  const GroupQrCodePage({super.key, required this.args});

  final GroupSettingDetailArgs args;

  @override
  ConsumerState<GroupQrCodePage> createState() => _GroupQrCodePageState();
}

class _GroupQrCodePageState extends ConsumerState<GroupQrCodePage> {
  GroupInviteInfo? _inviteInfo;
  List<GroupMember> _members = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInviteInfo);
    Future.microtask(_loadMembers);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final inviteCode = _inviteInfo?.inviteCode.trim() ?? '';
    final qrCodeContent = _inviteInfo?.effectiveQrCodeContent ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.groupSettingsGroupQrCode),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                GroupAvatarWidget.fromMembers(
                  members: _members
                      .take(4)
                      .map((m) => GroupAvatarMember(
                            userId: m.userId,
                            name: m.nickname.isNotEmpty ? m.nickname : m.userName,
                            avatarUrl: m.avatarUrl,
                          ))
                      .toList(),
                  size: 62,
                  borderRadius: 14,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.args.groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 212),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE54D4F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: _loadInviteInfo,
                              child: Text(strings.retry),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (qrCodeContent.isNotEmpty)
                              Container(
                                width: 168,
                                height: 168,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: QrImageView(
                                  data: qrCodeContent,
                                  version: QrVersions.auto,
                                  size: 168.0,
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.white,
                                ),
                              )
                            else
                              _InviteCodeFallback(inviteCode: inviteCode),
                            if (_inviteInfo?.needApproval == true) ...[
                              const SizedBox(height: 12),
                              _ApprovalHintWidget(),
                            ],
                            const SizedBox(height: 12),
                            SelectableText(
                              inviteCode.isEmpty
                                  ? strings.groupQrCodeUnavailable
                                  : inviteCode,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF202531),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.groupQrCodeHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF8F96A3),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: inviteCode.isEmpty
                      ? null
                      : () => _copyInviteCode(context, inviteCode),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(strings.chatActionCopy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadInviteInfo() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final inviteInfo = await ref
          .read(groupSettingsRepositoryProvider)
          .getGroupInviteInfo(widget.args.groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _inviteInfo = inviteInfo;
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

  Future<void> _loadMembers() async {
    try {
      final members = await ref
          .read(groupSettingsRepositoryProvider)
          .getGroupMembers(widget.args.groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
    }
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    final strings = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.groupQrCodeCopySuccess)));
  }
}

class _InviteCodeFallback extends StatelessWidget {
  const _InviteCodeFallback({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SelectableText(
        inviteCode.isEmpty
            ? AppLocalizations.of(context).groupQrCodeUnavailable
            : inviteCode,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF202531),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ApprovalHintWidget extends StatelessWidget {
  const _ApprovalHintWidget();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFFFF8A00),
              ),
              const SizedBox(width: 4),
              Text(
                strings.groupQrCodeNeedApproval,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF8A00),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strings.groupQrCodeNeedApprovalHint,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFB8860B),
          ),
        ),
      ],
    );
  }
}
