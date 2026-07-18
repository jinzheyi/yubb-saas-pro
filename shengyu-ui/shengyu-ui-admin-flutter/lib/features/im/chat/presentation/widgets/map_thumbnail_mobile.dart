import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/services/map_service.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_icon.dart';

/// 移动端地图缩略图 - 使用 CachedNetworkImage 加载腾讯静态地图 API
Widget createMapThumbnail({
  required double latitude,
  required double longitude,
  required bool isOutgoing,
  double height = 100,
}) {
  final mapUrl = MapService.generateThumbnailUrl(
    latitude: latitude,
    longitude: longitude,
  );

  if (mapUrl.isEmpty) {
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
        color: isOutgoing
            ? Colors.white
            : const Color(0xFFFFA940),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(isOutgoing ? 10 : 5),
      bottomRight: Radius.circular(isOutgoing ? 5 : 10),
    ),
    child: CachedNetworkImage(
      imageUrl: mapUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isOutgoing
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFF4F7FC),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8F96A3)),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: isOutgoing
            ? Colors.white.withValues(alpha: 0.16)
            : const Color(0xFFF4F7FC),
        alignment: Alignment.center,
        child: AppIcon(
          AppIconKind.place,
          size: 34,
          color: isOutgoing
              ? Colors.white
              : const Color(0xFFFFA940),
        ),
      ),
    ),
  );
}
