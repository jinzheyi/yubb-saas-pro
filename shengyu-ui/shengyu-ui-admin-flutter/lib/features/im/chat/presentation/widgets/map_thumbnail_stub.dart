import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 地图缩略图 - 平台适配入口
///
/// Web 使用 HtmlElementView + iframe 渲染静态地图（绕过 CORS）
/// 移动端使用 WebView 渲染腾讯地图 JS SDK
Widget createMapThumbnail({
  required double latitude,
  required double longitude,
  required bool isOutgoing,
  double height = 100,
}) {
  // Stub: 未适配平台降级显示默认图标
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: isOutgoing
          ? Colors.white.withValues(alpha: 0.16)
          : const Color(0xFFF4F7FC),
    ),
    alignment: Alignment.center,
    child: AppIcon(
      AppIconKind.place,
      size: 34,
      color: isOutgoing ? Colors.white : const Color(0xFFFFA940),
    ),
  );
}
