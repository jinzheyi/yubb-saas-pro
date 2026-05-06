import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/l10n/app_strings.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';

class AppErrorView extends ConsumerWidget {
  const AppErrorView({super.key, this.error, this.onRetry});

  final AppError? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error?.message ?? strings.unknownError),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      ),
    );
  }
}
