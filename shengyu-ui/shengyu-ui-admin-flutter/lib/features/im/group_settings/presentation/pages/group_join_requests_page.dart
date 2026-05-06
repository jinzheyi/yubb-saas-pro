import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_context_args.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_join_request_item.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

enum _JoinRequestTab { pending, processed }

class GroupJoinRequestsPage extends ConsumerStatefulWidget {
  const GroupJoinRequestsPage({super.key, required this.args});

  final GroupContextArgs args;

  @override
  ConsumerState<GroupJoinRequestsPage> createState() =>
      _GroupJoinRequestsPageState();
}

class _GroupJoinRequestsPageState extends ConsumerState<GroupJoinRequestsPage> {
  _JoinRequestTab _activeTab = _JoinRequestTab.pending;
  bool _loading = true;
  String? _errorMessage;
  String _processingRequestId = '';
  List<GroupJoinRequestItem> _items = const <GroupJoinRequestItem>[];

  @override
  void initState() {
    super.initState();
    ref.listenManual<GroupJoinRequestSignal?>(
      groupJoinRequestSignalProvider,
      (previous, next) {
        if (!mounted || next == null) {
          return;
        }
        if (next.groupId != widget.args.groupId) {
          return;
        }
        _loadRequests();
      },
    );
    Future.microtask(_loadRequests);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final pendingSelected = _activeTab == _JoinRequestTab.pending;
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
        title: Text(strings.groupSettingsJoinRequests),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _TabChip(
                    label: strings.groupJoinRequestsTabPending,
                    selected: pendingSelected,
                    onTap: () => _switchTab(_JoinRequestTab.pending),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabChip(
                    label: strings.groupJoinRequestsTabProcessed,
                    selected: !pendingSelected,
                    onTap: () => _switchTab(_JoinRequestTab.processed),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody(strings)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations strings) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF8F96A3)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadRequests,
              child: Text(strings.retry),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _activeTab == _JoinRequestTab.pending
                  ? strings.groupJoinRequestsEmptyPending
                  : strings.groupJoinRequestsEmptyProcessed,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202531),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.args.groupName ?? '',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8F96A3)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final statusText = switch (item.status) {
          2 => strings.groupJoinRequestsStatusApproved,
          3 => strings.groupJoinRequestsStatusRejected,
          _ => strings.groupJoinRequestsStatusPending,
        };
        final statusColor = switch (item.status) {
          2 => const Color(0xFF25B67B),
          3 => const Color(0xFFE54D4F),
          _ => const Color(0xFFFFA940),
        };
        final applicantName = item.applicantNickname.trim().isEmpty
            ? strings.groupJoinRequestsUnknownMember
            : item.applicantNickname.trim();
        final processing = _processingRequestId == item.id;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequestAvatar(
                    name: applicantName,
                    avatarUrl: item.applicantAvatar,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                applicantName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF202531),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.groupJoinRequestsApplyTime(
                            _formatTime(item.createTime),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8F96A3),
                          ),
                        ),
                        if (item.handledTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            strings.groupJoinRequestsHandleTime(
                              _formatTime(item.handledTime),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8F96A3),
                            ),
                          ),
                        ],
                        if ((item.rejectReason ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            strings.groupJoinRequestsHandleResult(
                              item.rejectReason!.trim(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8F96A3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (_activeTab == _JoinRequestTab.pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: processing ? null : () => _reject(item),
                        child: Text(strings.groupJoinRequestsReject),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: processing ? null : () => _approve(item),
                        child: Text(strings.groupJoinRequestsApprove),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final items = await ref
          .read(groupSettingsRepositoryProvider)
          .getGroupJoinRequests(
            groupId: widget.args.groupId,
            status: _activeTab == _JoinRequestTab.pending ? 1 : null,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = _activeTab == _JoinRequestTab.pending
            ? items
            : items.where((item) => item.status != 1).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = const <GroupJoinRequestItem>[];
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _switchTab(_JoinRequestTab tab) {
    if (_activeTab == tab) {
      return;
    }
    setState(() {
      _activeTab = tab;
    });
    _loadRequests();
  }

  Future<void> _approve(GroupJoinRequestItem item) async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _processingRequestId = item.id;
    });
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .approveGroupJoinRequest(requestId: item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupJoinRequestsApproved)),
      );
      await _loadRequests();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _processingRequestId = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _reject(GroupJoinRequestItem item) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.groupJoinRequestsRejectTitle),
          content: Text(
            strings.groupJoinRequestsRejectConfirm(
              item.applicantNickname.trim().isEmpty
                  ? strings.groupJoinRequestsUnknownMember
                  : item.applicantNickname.trim(),
            ),
          ),
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
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _processingRequestId = item.id;
    });
    try {
      await ref
          .read(groupSettingsRepositoryProvider)
          .rejectGroupJoinRequest(
            requestId: item.id,
            rejectReason: strings.groupJoinRequestsRejectedByAdmin,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.groupJoinRequestsRejected)),
      );
      await _loadRequests();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _processingRequestId = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context).groupJoinRequestsTimeUnknown;
    }
    return DateFormat('MM-dd HH:mm').format(value.toLocal());
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF1FF) : const Color(0xFFF4F6FA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF246BFD)
                    : const Color(0xFF8F96A3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = avatarUrl?.trim() ?? '';
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          resolvedAvatar,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF246BFD),
        ),
      ),
    );
  }
}
