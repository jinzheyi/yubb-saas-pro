import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限拒绝引导对话框
///
/// 当用户永久拒绝权限时，引导用户前往系统设置开启权限
class PermissionDeniedDialog extends StatelessWidget {
  const PermissionDeniedDialog({
    super.key,
    required this.permissionType,
    required this.onOpenSettings,
    required this.onCancel,
  });

  final String permissionType;
  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  /// 显示权限拒绝对话框
  static Future<bool> show(
    BuildContext context, {
    required String permissionType,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDeniedDialog(
        permissionType: permissionType,
        onOpenSettings: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2334),
      title: const Text(
        '需要权限',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        '通话功能需要$permissionType权限，请在系统设置中开启',
        style: const TextStyle(
          color: Color(0xFFB8C0CC),
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF8F96A3)),
          ),
        ),
        TextButton(
          onPressed: onOpenSettings,
          child: const Text(
            '去设置',
            style: TextStyle(color: Color(0xFF246BFD)),
          ),
        ),
      ],
    );
  }
}

/// 权限处理工具类
class PermissionHandler {
  /// 处理权限拒绝
  ///
  /// 如果是永久拒绝，显示引导对话框；否则返回错误信息
  static Future<void> handlePermissionDenied(
    BuildContext context, {
    required String permissionType,
    required bool isPermanentlyDenied,
    required String errorMessage,
  }) async {
    if (isPermanentlyDenied) {
      // 永久拒绝，显示引导对话框
      final shouldOpenSettings = await PermissionDeniedDialog.show(
        context,
        permissionType: permissionType,
      );

      if (shouldOpenSettings) {
        // 打开系统设置
        await openAppSettings();
      }
    } else {
      // 临时拒绝，显示 SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFE54D4F),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
