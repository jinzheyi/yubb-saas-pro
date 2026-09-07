import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/theme/theme_colors.dart';
import 'package:shengyu_ui_admin_im/features/update/domain/app_update_info.dart';
import 'package:shengyu_ui_admin_im/features/update/presentation/providers/update_providers.dart';

class UpdateCheckBinding extends ConsumerStatefulWidget {
  const UpdateCheckBinding({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateCheckBinding> createState() => _UpdateCheckBindingState();
}

class _UpdateCheckBindingState extends ConsumerState<UpdateCheckBinding> {
  bool _checked = false;
  bool _dialogShowing = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnce());
  }

  Future<void> _checkOnce() async {
    if (_checked || !mounted) return;
    _checked = true;
    try {
      final info = await ref.read(updateControllerProvider.notifier).check();
      if (!mounted || !info.hasUpdate || !info.forceUpdate) return;
      await _showForceUpdateDialog(info);
    } catch (_) {
      // 启动检查失败不阻塞用户进入 App，关于页仍可手动重试。
    }
  }

  Future<void> _showForceUpdateDialog(AppUpdateInfo info) async {
    if (_dialogShowing) return;
    _dialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: Text(
                  info.title?.trim().isNotEmpty == true
                      ? info.title!.trim()
                      : '发现新版本',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前版本过低，请更新到 ${info.versionName ?? '最新版本'} 后继续使用。',
                      style: TextStyle(color: ThemeColors.textPrimary(context)),
                    ),
                    if (info.changelog?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        info.changelog!.trim(),
                        style: TextStyle(
                          color: ThemeColors.textSecondary(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (_progress != null) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _progress),
                    ],
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(updateControllerProvider.notifier)
                            .install(
                              info,
                              onProgress: (received, total) {
                                if (total <= 0) return;
                                setDialogState(() {
                                  _progress = received / total;
                                });
                              },
                            );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_errorText(error))),
                        );
                      }
                    },
                    child: const Text('立即更新'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _dialogShowing = false;
  }

  String _errorText(Object error) {
    final text = error.toString();
    if (text.startsWith('StateError: ')) return text.substring(12);
    return '更新失败，请稍后重试';
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
