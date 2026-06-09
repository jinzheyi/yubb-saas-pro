import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/forward_target_route_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_names.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/features/contacts/domain/entities/contact_profile.dart';
import 'package:shengyu_ui_admin_im/features/contacts/presentation/providers/contacts_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/contact_card_share_payload.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

class ContactProfilePage extends ConsumerStatefulWidget {
  const ContactProfilePage({
    super.key,
    required this.userId,
    required this.name,
    required this.departmentName,
  });

  final String userId;
  final String name;
  final String departmentName;

  @override
  ConsumerState<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends ConsumerState<ContactProfilePage> {
  ContactProfile? _profile;
  var _loading = true;
  var _followLoading = false;
  var _isFollowing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final displayName = _displayName(strings);
    final session = ref.watch(authSessionProvider);
    final isCurrentUser = widget.userId.trim().isNotEmpty &&
        widget.userId.trim() == session.userId.trim();

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: AppIcon(
            AppIconKind.chevronLeft,
            size: 20,
            color: ThemeColors.headerIcon(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _showMoreMenu,
            child: Text(
              strings.contactsDetailMore,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ThemeColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFE54D4F),
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ThemeColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: ThemeColors.textPrimary(context),
                                ),
                              ),
                            ),
                            if (_profile?.sex != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                _profile!.sex == 0 ? Icons.male : Icons.female,
                                size: 18,
                                color: _profile!.sex == 0
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFFEC4899),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              _InfoRow(
                                label: strings.contactsDetailName,
                                value: displayName,
                              ),
                              _InfoRow(
                                label: strings.contactsDetailMobile,
                                value: _profile?.phone ?? '',
                              ),
                              _InfoRow(
                                label: strings.contactsDetailEmail,
                                value: _profile?.email ?? '',
                                placeholder: strings.contactsDetailUnset,
                              ),
                              _InfoRow(
                                label: strings.contactsDetailPost,
                                value: _profile?.postName ?? '',
                                placeholder: strings.contactsDetailUnset,
                              ),
                              _InfoRow(
                                label: strings.contactsDetailDepartment,
                                value:
                                    _profile?.departmentName.isNotEmpty == true
                                    ? _profile!.departmentName
                                    : widget.departmentName,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrentUser)
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(32, 12, 32, 12),
                      decoration: BoxDecoration(
                        color: ThemeColors.surface(context),
                        border: Border(
                          top: BorderSide(
                            color: ThemeColors.divider(context),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FooterAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: strings.contactsDetailMessage,
                            onTap: _openChat,
                          ),
                          _FooterAction(
                            icon: Icons.phone_outlined,
                            label: strings.contactsDetailCall,
                            onTap: () => _showMessage(
                              strings.contactsDetailCallInDevelopment,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _loadProfile() async {
    final strings = AppLocalizations.of(context);
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = strings.contactsDetailInvalidUser;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ref.read(contactsRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.getContactProfile(widget.userId),
        repository.getContactStar(widget.userId),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = results[0] as ContactProfile;
        _isFollowing = results[1] as bool;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = strings.contactsDetailLoadFailed;
      });
    }
  }

  String _displayName(AppLocalizations strings) {
    final profileName = _profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) {
      return profileName;
    }
    final initialName = widget.name.trim();
    if (initialName.isNotEmpty) {
      return initialName;
    }
    return strings.profileUnknownUser;
  }

  Future<void> _openChat() async {
    if (widget.userId.trim().isEmpty) {
      return;
    }
    final displayName = _displayName(AppLocalizations.of(context));
    try {
      final conversation = await ref.read(
        directConversationProvider(widget.userId).future,
      );
      if (!mounted) {
        return;
      }
      context.pushNamed(
        RouteNames.chat,
        extra: ChatEntryArgs.latest(
          chatId: conversation.chatId,
          conversationType: ConversationType.direct,
          targetId: conversation.targetId,
          title: conversation.title.trim().isEmpty
              ? displayName
              : conversation.title.trim(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(AppLocalizations.of(context).operationFailed(error.toString()));
    }
  }

  Future<void> _showMoreMenu() async {
    final strings = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return;
    }
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        box.size.width - 200,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        12,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'follow',
          child: Text(
            _isFollowing
                ? strings.contactsDetailUnfollow
                : strings.contactsDetailFollow,
          ),
        ),
        PopupMenuItem<String>(
          value: 'share',
          child: Text(strings.contactsDetailShareCard),
        ),
      ],
    );
    if (!mounted || selected == null) {
      return;
    }
    if (selected == 'follow') {
      await _toggleFollow();
      return;
    }
    await _shareContactCard();
  }

  Future<void> _toggleFollow() async {
    final strings = AppLocalizations.of(context);
    if (_followLoading || widget.userId.trim().isEmpty) {
      return;
    }
    setState(() {
      _followLoading = true;
    });
    final nextValue = !_isFollowing;
    try {
      await ref
          .read(contactsRepositoryProvider)
          .updateContactStar(widget.userId, nextValue);
      if (!mounted) {
        return;
      }
      setState(() {
        _isFollowing = nextValue;
      });
      _showMessage(
        nextValue
            ? strings.contactsDetailFollowSuccess
            : strings.contactsDetailUnfollowSuccess,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(strings.contactsDetailActionFailedRetry);
    } finally {
      if (mounted) {
        setState(() {
          _followLoading = false;
        });
      }
    }
  }

  Future<void> _shareContactCard() async {
    final strings = AppLocalizations.of(context);
    final userId = widget.userId.trim();
    if (userId.isEmpty) {
      _showMessage(strings.contactsDetailInvalidUser);
      return;
    }
    final displayName = _displayName(strings);
    final payload = ContactCardSharePayload(
      userId: userId,
      displayName: displayName,
      departmentName: _profile?.departmentName.trim().isNotEmpty == true
          ? _profile!.departmentName.trim()
          : widget.departmentName.trim(),
      postName: _profile?.postName.trim() ?? '',
      avatar: _profile?.avatarUrl.trim() ?? '',
    );
    await context.pushNamed(
      RouteNames.chatForwardTarget,
      extra: ForwardTargetRouteArgs(contactCardPayload: payload),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.placeholder,
    this.isLast = false,
  });

  final String label;
  final String value;
  final String? placeholder;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final trimmed = value.trim();
    final hasValue = trimmed.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: ThemeColors.divider(context),
                  width: 0.5,
                ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: ThemeColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasValue ? trimmed : (placeholder ?? ''),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: hasValue
                  ? ThemeColors.textPrimary(context)
                  : ThemeColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1677FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D0EA5E9),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1677FF),
            ),
          ),
        ],
      ),
    );
  }
}
