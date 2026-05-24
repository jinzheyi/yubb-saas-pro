import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_invite_info.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class GroupQrCodePage extends ConsumerStatefulWidget {
  const GroupQrCodePage({super.key, required this.args});

  final GroupSettingDetailArgs args;

  @override
  ConsumerState<GroupQrCodePage> createState() => _GroupQrCodePageState();
}

class _GroupQrCodePageState extends ConsumerState<GroupQrCodePage> {
  GroupInviteInfo? _inviteInfo;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInviteInfo);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final inviteCode = _inviteInfo?.inviteCode.trim() ?? '';
    final qrCodeUrl = _resolveQrCodeUrl(_inviteInfo);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leadingWidth: 68,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF202531),
            padding: const EdgeInsets.only(left: 8),
          ),
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          label: Text(
            strings.backAction,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
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
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: getGroupAvatarColor(widget.args.groupId),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_2_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
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
                            if (qrCodeUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 168,
                                  height: 168,
                                  color: Colors.white,
                                  child: Image.network(
                                    qrCodeUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _InviteCodeFallback(
                                              inviteCode: inviteCode,
                                            ),
                                  ),
                                ),
                              )
                            else
                              _InviteCodeFallback(inviteCode: inviteCode),
                            if (_inviteInfo?.needApproval == true) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E8),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  strings.groupQrCodeNeedApproval,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF8A00),
                                  ),
                                ),
                              ),
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
                            const SizedBox(height: 12),
                            Text(
                              _formatExpireAt(_inviteInfo?.expireAt),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8F96A3),
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: inviteCode.isEmpty
                            ? null
                            : () => _copyInviteCode(context, inviteCode),
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(strings.chatActionCopy),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loadInviteInfo,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(strings.retry),
                      ),
                    ),
                  ],
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

  String _formatExpireAt(DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).groupQrCodeUnavailable;
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  String _resolveQrCodeUrl(GroupInviteInfo? inviteInfo) {
    final raw = inviteInfo?.qrCodeUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }
    final apiUri = Uri.parse(AppConfig.apiBaseUrl);
    final origin = Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    );
    return origin.resolve(raw).toString();
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
