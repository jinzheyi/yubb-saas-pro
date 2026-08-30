import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

class CallIdentityPanel extends StatelessWidget {
  const CallIdentityPanel({
    super.key,
    required this.name,
    required this.status,
    this.avatarUrl,
    this.avatar,
    this.compact = false,
  });

  final String name;
  final String status;
  final String? avatarUrl;
  final Widget? avatar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          avatar ??
              AppAvatar(
                name: name,
                avatarUrl: avatarUrl,
                seed: name,
                size: 96,
                borderRadius: 48,
                fontSize: 34,
              ),
          const SizedBox(height: 20),
        ],
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (status.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 15),
          ),
        ],
      ],
    );
  }
}
