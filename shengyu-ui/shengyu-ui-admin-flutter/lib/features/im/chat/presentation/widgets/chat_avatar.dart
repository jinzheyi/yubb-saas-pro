import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.seed,
    this.imageUrl,
    this.size = 40,
    this.borderRadius = 8,
    this.fontSize = 12,
  });

  final String seed;
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: seed,
      avatarUrl: imageUrl,
      size: size,
      borderRadius: borderRadius,
      fontSize: fontSize,
    );
  }
}
