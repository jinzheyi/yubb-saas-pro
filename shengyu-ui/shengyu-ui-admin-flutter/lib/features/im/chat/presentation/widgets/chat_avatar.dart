import 'package:flutter/material.dart';

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
    final initials = seed.isEmpty ? '?' : seed.substring(0, 1);
    final resolvedImage = imageUrl?.trim() ?? '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarColor(seed),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: resolvedImage.isNotEmpty
          ? Image.network(
              resolvedImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _ChatAvatarFallback(
                  initials: initials,
                  fontSize: fontSize,
                );
              },
            )
          : _ChatAvatarFallback(initials: initials, fontSize: fontSize),
    );
  }

  Color _avatarColor(String seed) {
    const colors = <Color>[
      Color(0xFFE97CAB),
      Color(0xFF93D3A8),
      Color(0xFFF6CFA9),
      Color(0xFF8FB8F7),
    ];
    return colors[seed.isEmpty ? 0 : seed.codeUnitAt(0) % colors.length];
  }
}

class _ChatAvatarFallback extends StatelessWidget {
  const _ChatAvatarFallback({required this.initials, required this.fontSize});

  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
