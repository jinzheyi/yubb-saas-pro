import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_setting_detail_args.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class GroupAnnouncementPage extends ConsumerStatefulWidget {
  const GroupAnnouncementPage({super.key, required this.args});

  final GroupSettingDetailArgs args;

  @override
  ConsumerState<GroupAnnouncementPage> createState() =>
      _GroupAnnouncementPageState();
}

class _GroupAnnouncementPageState extends ConsumerState<GroupAnnouncementPage> {
  final TextEditingController _noticeController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _notifyMembers = true;
  bool _pinNotice = false;
  String _notice = '';
  bool _noticePinned = false;
  String _ownerName = '';
  DateTime? _noticeUpdatedAt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAnnouncement);
  }

  @override
  void dispose() {
    _noticeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(
      groupSettingsControllerProvider(
        GroupContextArgs(
          groupId: widget.args.groupId,
          groupName: widget.args.groupName,
        ),
      ),
    );
    final canEdit =
        state.currentUserRoleCode == 1 || state.currentUserRoleCode == 2;
    final navigator = Navigator.of(context);
    return PopScope(
      canPop: !_editing || !_hasPendingChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldLeave = await _confirmDiscardIfNeeded();
        if (shouldLeave && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: () async {
              final shouldLeave = await _confirmDiscardIfNeeded();
              if (shouldLeave && mounted) {
                navigator.maybePop();
              }
            },
          ),
          centerTitle: true,
          title: Text(strings.groupSettingsGroupNotice),
          actions: [
            if (canEdit)
              TextButton(
                onPressed: _loading || _saving
                    ? null
                    : () => _toggleEdit(canEdit),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _editing
                            ? strings.groupSettingsDone
                            : strings.groupAnnouncementEdit,
                      ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_editing)
              _EditCard(
                controller: _noticeController,
                notifyMembers: _notifyMembers,
                pinNotice: _pinNotice,
                saving: _saving,
                strings: strings,
                onNotifyChanged: (value) {
                  setState(() {
                    _notifyMembers = value;
                  });
                },
                onPinChanged: (value) {
                  setState(() {
                    _pinNotice = value;
                  });
                },
                onCancel: _cancelEdit,
                onPublish: _publish,
              )
            else
              _ViewCard(
                notice: _notice,
                noticePinned: _noticePinned,
                ownerName: _ownerName,
                noticeUpdatedAt: _noticeUpdatedAt,
                canEdit: canEdit,
                strings: strings,
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFE54D4F)),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _loadAnnouncement,
                child: Text(strings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasPendingChanges {
    return _noticeController.text.trim() != _notice ||
        _pinNotice != _noticePinned;
  }

  Future<void> _loadAnnouncement() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await ref
          .read(groupSettingsRepositoryProvider)
          .getGroupSettings(widget.args.groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _notice = snapshot.notice;
        _noticePinned = snapshot.noticePinned;
        _ownerName = snapshot.ownerName;
        _noticeUpdatedAt = snapshot.noticeUpdatedAt;
        _noticeController.text = snapshot.notice;
        _pinNotice = snapshot.noticePinned;
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

  Future<void> _toggleEdit(bool canEdit) async {
    if (!canEdit) {
      return;
    }
    if (_editing) {
      await _publish();
      return;
    }
    setState(() {
      _editing = true;
      _notifyMembers = true;
      _pinNotice = _noticePinned;
      _noticeController.text = _notice;
      _errorMessage = null;
    });
  }

  Future<void> _cancelEdit() async {
    if (_hasPendingChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard != true || !mounted) {
        return;
      }
    }
    setState(() {
      _editing = false;
      _noticeController.text = _notice;
      _notifyMembers = true;
      _pinNotice = _noticePinned;
    });
  }

  Future<void> _publish() async {
    final strings = AppLocalizations.of(context);
    final nextNotice = _noticeController.text.trim();
    if (nextNotice.length > 500) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.groupAnnouncementTooLong)));
      return;
    }
    if (nextNotice == _notice && _pinNotice == _noticePinned) {
      setState(() {
        _editing = false;
      });
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .updateGroupNotice(
            groupId: widget.args.groupId,
            notice: nextNotice,
            notifyMembers: _notifyMembers,
            pinNotice: _pinNotice,
          );
      if (!mounted) {
        return;
      }
      final now = DateTime.now();
      final controller = ref.read(
        groupSettingsControllerProvider(
          GroupContextArgs(
            groupId: widget.args.groupId,
            groupName: widget.args.groupName,
          ),
        ).notifier,
      );
      controller.updateNotice(
        nextNotice,
        noticePinned: _pinNotice,
        noticeUpdatedAt: now,
      );
      setState(() {
        _notice = nextNotice;
        _noticePinned = _pinNotice;
        _noticeUpdatedAt = now;
        _editing = false;
        _saving = false;
      });
      final toast = nextNotice.isEmpty
          ? strings.groupAnnouncementCleared
          : (_notifyMembers
                ? strings.groupAnnouncementPublishNotifySuccess
                : strings.groupAnnouncementPublishSuccess);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(toast)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupAnnouncementPublishFailed)),
      );
    }
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_editing || !_hasPendingChanges) {
      return true;
    }
    return await _showDiscardDialog() ?? false;
  }

  Future<bool?> _showDiscardDialog() {
    final strings = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupAnnouncementDiscardTitle),
          content: Text(strings.groupAnnouncementDiscardContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.confirmAction),
            ),
          ],
        );
      },
    );
  }
}

class _ViewCard extends StatelessWidget {
  const _ViewCard({
    required this.notice,
    required this.noticePinned,
    required this.ownerName,
    required this.noticeUpdatedAt,
    required this.canEdit,
    required this.strings,
  });

  final String notice;
  final bool noticePinned;
  final String ownerName;
  final DateTime? noticeUpdatedAt;
  final bool canEdit;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: notice.trim().isEmpty
          ? Column(
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.campaign_outlined,
                  size: 42,
                  color: Color(0xFFD0D5DD),
                ),
                const SizedBox(height: 12),
                Text(
                  strings.groupAnnouncementEmpty,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF98A1B2),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.groupAnnouncementEmptyHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF98A1B2),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (noticePinned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      strings.groupAnnouncementPinned,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF246BFD),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  notice,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 20),
                _MetaRow(
                  label: strings.groupAnnouncementPublisher,
                  value: ownerName.trim().isEmpty
                      ? strings.groupAnnouncementOwnerFallback
                      : ownerName.trim(),
                ),
                const SizedBox(height: 8),
                _MetaRow(
                  label: strings.groupAnnouncementPublishTime,
                  value: noticeUpdatedAt == null
                      ? ''
                      : DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(noticeUpdatedAt!.toLocal()),
                ),
              ],
            ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({
    required this.controller,
    required this.notifyMembers,
    required this.pinNotice,
    required this.saving,
    required this.strings,
    required this.onNotifyChanged,
    required this.onPinChanged,
    required this.onCancel,
    required this.onPublish,
  });

  final TextEditingController controller;
  final bool notifyMembers;
  final bool pinNotice;
  final bool saving;
  final AppLocalizations strings;
  final ValueChanged<bool> onNotifyChanged;
  final ValueChanged<bool> onPinChanged;
  final VoidCallback onCancel;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 8,
            maxLength: 500,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.groupAnnouncementPlaceholder,
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5EAF3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF246BFD)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.notifications_active_outlined,
            label: strings.groupAnnouncementNotifyMembers,
            value: notifyMembers,
            onChanged: onNotifyChanged,
          ),
          if (notifyMembers)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                strings.groupAnnouncementNotifyMembersHint,
                style: const TextStyle(fontSize: 12, color: Color(0xFF98A1B2)),
              ),
            ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.push_pin_outlined,
            label: strings.groupAnnouncementPinNotice,
            value: pinNotice,
            onChanged: onPinChanged,
          ),
          if (pinNotice)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                strings.groupAnnouncementPinNoticeHint,
                style: const TextStyle(fontSize: 12, color: Color(0xFF98A1B2)),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  child: Text(strings.cancelAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : onPublish,
                  child: Text(strings.groupAnnouncementPublish),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF246BFD)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF202531)),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            style: const TextStyle(fontSize: 13, color: Color(0xFF5B6475)),
          ),
        ),
      ],
    );
  }
}
