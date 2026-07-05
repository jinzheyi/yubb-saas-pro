import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.seed,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.borderRadius = 8,
    this.fontSize = 12,
  });

  final String seed;
  final String name;
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      name: name,
      avatarUrl: imageUrl,
      seed: seed,
      size: size,
      borderRadius: borderRadius,
      fontSize: fontSize,
    );
  }
}
