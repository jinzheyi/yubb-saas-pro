import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/update/domain/app_update_info.dart';
import 'package:shengyu_ui_admin_im/features/update/presentation/providers/update_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final updateState = ref.watch(updateControllerProvider);
    final progress = ref.watch(updateDownloadProgressProvider);
    final updateInfo = updateState.valueOrNull;

    return Scaffold(
      backgroundColor: ThemeColors.scaffoldBg(context),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('关于钰信'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          _AppHeader(packageInfo: packageInfo),
          const SizedBox(height: 22),
          _UpdatePanel(
            updateState: updateState,
            updateInfo: updateInfo,
            progress: progress,
            onCheck: () => _checkUpdate(context, ref),
            onInstall: updateInfo == null || !updateInfo.hasUpdate
                ? null
                : () => _installUpdate(context, ref, updateInfo),
          ),
          const SizedBox(height: 16),
          _LinkTile(
            title: '隐私政策',
            onTap: () => _openExternal('https://preview.shengyukj.top/privacy'),
          ),
          _LinkTile(
            title: '用户协议',
            onTap: () =>
                _openExternal('https://preview.shengyukj.top/agreement'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    try {
      final info = await ref.read(updateControllerProvider.notifier).check();
      if (!context.mounted) return;
      final message = info.hasUpdate ? '发现新版本' : '已是最新版本';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    }
  }

  Future<void> _installUpdate(
    BuildContext context,
    WidgetRef ref,
    AppUpdateInfo info,
  ) async {
    if (info.isPatchUpdate) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dart OTA 补丁能力将在二期接入')));
      return;
    }
    try {
      ref.read(updateDownloadProgressProvider.notifier).state = 0;
      await ref
          .read(updateControllerProvider.notifier)
          .install(
            info,
            onProgress: (received, total) {
              if (total <= 0) return;
              ref.read(updateDownloadProgressProvider.notifier).state =
                  received / total;
            },
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorText(error))));
    } finally {
      ref.read(updateDownloadProgressProvider.notifier).state = null;
    }
  }

  Future<void> _openExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _errorText(Object error) {
    final text = error.toString();
    if (text.startsWith('StateError: ')) return text.substring(12);
    return '操作失败，请稍后重试';
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.packageInfo});

  final AsyncValue<PackageInfo> packageInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            '钰',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '钰信',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        packageInfo.when(
          data: (info) => Text(
            '版本 ${info.version} (${info.buildNumber})',
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.textSecondary(context),
            ),
          ),
          loading: () => Text(
            '读取版本中',
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.textSecondary(context),
            ),
          ),
          error: (_, _) => Text(
            '版本信息不可用',
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.textSecondary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdatePanel extends StatelessWidget {
  const _UpdatePanel({
    required this.updateState,
    required this.updateInfo,
    required this.progress,
    required this.onCheck,
    required this.onInstall,
  });

  final AsyncValue<AppUpdateInfo?> updateState;
  final AppUpdateInfo? updateInfo;
  final double? progress;
  final VoidCallback onCheck;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    final info = updateInfo;
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeColors.divider(context)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '版本更新',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
              if (info?.hasUpdate == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: info!.forceUpdate
                        ? const Color(0xFFFFE9E8)
                        : const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    info.forceUpdate ? '强制更新' : '有新版本',
                    style: TextStyle(
                      color: info.forceUpdate
                          ? const Color(0xFFE5484D)
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _UpdateDescription(updateState: updateState, info: info),
          if (progress != null) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: progress == 0 ? null : progress),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: updateState.isLoading ? null : onCheck,
                  child: const Text('检查更新'),
                ),
              ),
              if (info?.hasUpdate == true) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: progress == null ? onInstall : null,
                    child: Text(info!.isPatchUpdate ? '查看补丁' : '立即更新'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateDescription extends StatelessWidget {
  const _UpdateDescription({required this.updateState, required this.info});

  final AsyncValue<AppUpdateInfo?> updateState;
  final AppUpdateInfo? info;

  @override
  Widget build(BuildContext context) {
    if (updateState.isLoading) return const Text('正在检查更新...');
    if (updateState.hasError) return const Text('检查更新失败，请稍后重试');
    if (info == null) return const Text('点击检查更新，获取最新版本状态。');
    if (!info!.hasUpdate) return const Text('已是最新版本。');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${info!.title ?? '钰信更新'} ${info!.versionName ?? ''}'
          '${info!.versionCode == null ? '' : ' (${info!.versionCode})'}',
          style: TextStyle(
            color: ThemeColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          info!.changelog ?? '暂无更新说明',
          style: TextStyle(
            color: ThemeColors.textSecondary(context),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: ThemeColors.surface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
