import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/network_monitor_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// 网络异常 Notice Bar
///
/// 显示逻辑（企业级兜底策略）：
/// - wifi / mobile / unknown：网络正常，不显示（Web 平台 connectivity_plus 返回 unknown，默认有网）
/// - none：无网络，显示"网络连接已断开"
class NetworkStatusNoticeBar extends ConsumerWidget {
  const NetworkStatusNoticeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听网络状态
    final status = ref.watch(networkStatusProvider);

    // wifi / mobile / unknown 均为可用网络（Web 平台 unknown 视为可用）
    if (status == NetworkStatus.wifi ||
        status == NetworkStatus.mobile ||
        status == NetworkStatus.unknown) {
      return const SizedBox.shrink(); // 网络正常不显示
    }

    return GestureDetector(
      onTap: () => _showNetworkSettings(context),
      child: Container(
        height: 32,
        color: const Color(0xFFFFF3CD), // 浅黄色警告背景
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.signal_wifi_off,
              size: 16,
              color: Color(0xFF856404),
            ),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).networkDisconnectedOpenSettings,
              style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNetworkSettings(BuildContext context) async {
    // 跳转到系统网络设置（Android/iOS）
    final Uri uri;
    if (Theme.of(context).platform == TargetPlatform.android) {
      uri = Uri.parse('android.settings.WIFI_SETTINGS');
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      uri = Uri.parse('App-Prefs:root=WIFI');
    } else {
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// 用于持有网络状态的 Notifier
class _NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  _NetworkStatusNotifier() : super(NetworkStatus.unknown) {
    NetworkMonitorService().statusStream.listen((status) {
      state = status;
    });
  }
}

/// Riverpod Provider 用于监听网络状态
final networkStatusProvider =
    StateNotifierProvider<_NetworkStatusNotifier, NetworkStatus>((ref) {
      return _NetworkStatusNotifier();
    });
