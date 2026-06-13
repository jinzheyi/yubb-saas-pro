import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.backgroundColor,
    this.seed,
    this.size = 40,
    this.borderRadius = 10,
    this.fontSize = 16,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w700,
    this.fit = BoxFit.cover,
    this.fallbackChild,
    this.onImageError,
  });

  final String name;
  final String? avatarUrl;
  final Color? backgroundColor;
  final String? seed;
  final double size;
  final double borderRadius;
  final double fontSize;
  final Color textColor;
  final FontWeight fontWeight;
  final BoxFit fit;
  final Widget? fallbackChild;
  final VoidCallback? onImageError;

  @override
  Widget build(BuildContext context) {
    final resolvedAvatar = normalizeAvatarUrl(avatarUrl);
    if (resolvedAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: resolvedAvatar,
          cacheManager: ImCacheManager.instance,
          width: size,
          height: size,
          fit: fit,
          // 使用圆形加载指示器作为占位符
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: backgroundColor ?? getUserAvatarColor(seed ?? name),
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor.withOpacity(0.6)),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            if (onImageError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onImageError!.call();
              });
            }
            return _buildFallback();
          },
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? getUserAvatarColor(seed ?? name),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child:
          fallbackChild ??
          Text(
            getAvatarText(name),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
    );
  }
}
