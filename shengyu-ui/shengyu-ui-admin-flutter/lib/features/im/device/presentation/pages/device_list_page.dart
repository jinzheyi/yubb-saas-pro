import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/im/device/domain/device_info.dart';
import 'package:shengyu_ui_admin_im/features/im/device/presentation/providers/device_providers.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

class DeviceListPage extends ConsumerWidget {
  const DeviceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(deviceListProvider);

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, size: 22, color: ThemeColors.headerIcon(context)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(strings.deviceListTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deviceListProvider.notifier).refresh();
        },
        child: state.status == DeviceListStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : state.status == DeviceListStatus.failed
            ? _buildErrorView(context, state, ref)
            : state.devices.isEmpty
            ? _buildEmptyView(context)
            : _buildDeviceList(context, state, ref, strings),
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    DeviceListState state,
    WidgetRef ref,
    AppLocalizations strings,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.devices.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: ThemeColors.divider(context),
      ),
      itemBuilder: (context, index) {
        final device = state.devices[index];
        return _DeviceListTile(
          device: device,
          isKicking: state.kickingDeviceType == device.deviceType.value,
          onKick: () => _showKickConfirmDialog(context, ref, device),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, DeviceListState state, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: ThemeColors.textSecondary(context)),
          const SizedBox(height: 12),
          Text(
            state.error ?? strings.operationFailed(''),
            style: TextStyle(color: ThemeColors.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.read(deviceListProvider.notifier).refresh();
            },
            child: Text(strings.refreshAction),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.devices_other_outlined, size: 48, color: ThemeColors.emptyText(context)),
          const SizedBox(height: 12),
          Text(
            strings.deviceListEmpty,
            style: TextStyle(fontSize: 14, color: ThemeColors.emptyText(context)),
          ),
        ],
      ),
    );
  }

  Future<void> _showKickConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    DeviceInfo device,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.deviceKickConfirmTitle),
          content: Text(
            strings.deviceKickConfirmMessage(device.deviceName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: ThemeColors.errorText(context),
              ),
              child: Text(strings.deviceKickAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(deviceListProvider.notifier).kickDevice(device.deviceType.value);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.deviceKickedSuccess(device.deviceName)),
        backgroundColor: const Color(0xFF07C160),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DeviceListTile extends StatelessWidget {
  const _DeviceListTile({
    required this.device,
    required this.isKicking,
    required this.onKick,
  });

  final DeviceInfo device;
  final bool isKicking;
  final VoidCallback onKick;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isCurrent = device.isCurrentDevice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _DeviceIcon(deviceType: device.deviceType),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.deviceName.isNotEmpty
                            ? device.deviceName
                            : device.deviceType.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? ThemeColors.noticeText(context)
                              : ThemeColors.textPrimary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.noticeBg(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          strings.deviceListCurrent,
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.noticeText(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(context, strings),
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent) ...[
            const SizedBox(width: 12),
            if (isKicking)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              TextButton(
                onPressed: onKick,
                style: TextButton.styleFrom(
                  foregroundColor: ThemeColors.errorText(context),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(strings.deviceListKick, style: const TextStyle(fontSize: 13)),
              ),
          ] else ...[
            Icon(Icons.check_circle, size: 20, color: ThemeColors.noticeText(context)),
          ],
        ],
      ),
    );
  }

  String _buildSubtitle(BuildContext context, AppLocalizations strings) {
    final parts = <String>[];
    parts.add(_formatTime(context, device.lastActiveTime));
    if (device.ipAddress.isNotEmpty) {
      parts.add(device.ipAddress);
    }
    return parts.join(' · ');
  }

  String _formatTime(BuildContext context, DateTime time) {
    final strings = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return strings.deviceTimeJustNow;
    } else if (diff.inMinutes < 60) {
      return strings.deviceTimeMinutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return strings.deviceTimeHoursAgo(diff.inHours);
    } else if (diff.inDays < 30) {
      return strings.deviceTimeDaysAgo(diff.inDays);
    } else {
      return '${time.year}-${_pad(time.month)}-${_pad(time.day)} ${_pad(time.hour)}:${_pad(time.minute)}';
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon({required this.deviceType});

  final DeviceType deviceType;

  @override
  Widget build(BuildContext context) {
    final iconColor = _resolveColor();
    final icon = _resolveIcon();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }

  IconData _resolveIcon() {
    switch (deviceType) {
      case DeviceType.web:
        return Icons.public_outlined;
      case DeviceType.windows:
        return Icons.desktop_windows_outlined;
      case DeviceType.mac:
        return Icons.laptop_mac_outlined;
      case DeviceType.android:
        return Icons.android_outlined;
      case DeviceType.ios:
        return Icons.phone_iphone_outlined;
      case DeviceType.miniProgram:
        return Icons.apps_outlined;
    }
  }

  Color _resolveColor() {
    switch (deviceType) {
      case DeviceType.web:
        return const Color(0xFF246BFD);
      case DeviceType.windows:
        return const Color(0xFF00A4EF);
      case DeviceType.mac:
        return const Color(0xFF555555);
      case DeviceType.android:
        return const Color(0xFF3DDC84);
      case DeviceType.ios:
        return const Color(0xFF8E8E93);
      case DeviceType.miniProgram:
        return const Color(0xFF07C160);
    }
  }
}
