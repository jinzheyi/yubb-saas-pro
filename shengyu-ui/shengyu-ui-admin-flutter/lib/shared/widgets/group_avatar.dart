import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

/// 钉钉风格群组合头像组件
///
/// 规则：
/// - 1人：显示1个大头像
/// - 2人：显示2个半圆头像
/// - 3人：显示1个半圆 + 2个四分之一圆
/// - 4人及以上：显示4个四分之一圆
///
/// 支持两种构造方式：
/// 1. [GroupAvatarWidget.fromMembers] - 传入成员对象列表
/// 2. [GroupAvatarWidget.fromUrls] - 直接传入URL列表和名称种子
class GroupAvatarWidget extends StatelessWidget {
  const GroupAvatarWidget({
    super.key,
    required this.members,
    this.size = 48,
    this.borderRadius = 8,
  });

  /// 从成员对象列表创建
  factory GroupAvatarWidget.fromMembers({
    Key? key,
    required List<GroupAvatarMember> members,
    double size = 48,
    double borderRadius = 8,
  }) {
    return GroupAvatarWidget(
      key: key,
      members: members,
      size: size,
      borderRadius: borderRadius,
    );
  }

  /// 从URL列表和名称创建（适用于会话列表等只需URL的场景）
  ///
  /// [urls] - 成员头像URL列表（最多4个）
  /// [nameSeed] - 用于生成文字头像的名称/ID种子
  /// [memberCount] - 群成员总数（用于决定是否显示+N）
  factory GroupAvatarWidget.fromUrls({
    Key? key,
    required List<String?> urls,
    required String nameSeed,
    int? memberCount,
    double size = 48,
    double borderRadius = 8,
  }) {
    final members = urls.where((url) => url != null && url.trim().isNotEmpty).take(4).map((url) {
      return GroupAvatarMember(
        userId: nameSeed,
        name: nameSeed,
        avatarUrl: url,
      );
    }).toList();

    // 如果没有URL但有成员数量，显示+N占位
    if (members.isEmpty && memberCount != null && memberCount > 0) {
      return GroupAvatarWidget(
        key: key,
        members: [
          GroupAvatarMember(
            userId: nameSeed,
            name: memberCount > 4 ? '+${memberCount - 4}' : '$memberCount',
            avatarUrl: null,
          ),
        ],
        size: size,
        borderRadius: borderRadius,
      );
    }

    return GroupAvatarWidget(
      key: key,
      members: members,
      size: size,
      borderRadius: borderRadius,
    );
  }

  /// 群成员列表（按加入顺序排列）
  final List<GroupAvatarMember> members;

  /// 组件尺寸
  final double size;

  /// 圆角
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _buildSingleAvatar(
        avatarUrl: null,
        name: '?',
        seed: '',
        size: size,
      );
    }

    final displayMembers = members.take(4).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildAvatarGrid(displayMembers),
      ),
    );
  }

  Widget _buildAvatarGrid(List<GroupAvatarMember> displayMembers) {
    final count = displayMembers.length;

    switch (count) {
      case 1:
        return _buildSingleAvatar(
          avatarUrl: displayMembers[0].avatarUrl,
          name: displayMembers[0].name,
          seed: displayMembers[0].userId,
          size: size,
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: _buildHalfAvatar(
                displayMembers[0],
                isLeft: true,
              ),
            ),
            Expanded(
              child: _buildHalfAvatar(
                displayMembers[1],
                isLeft: false,
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(
              child: _buildHalfAvatarTop(displayMembers[0]),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuarterAvatar(displayMembers[1]),
                  ),
                  Expanded(
                    child: _buildQuarterAvatar(displayMembers[2], isRight: true),
                  ),
                ],
              ),
            ),
          ],
        );
      default: // 4人及以上
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuarterAvatar(displayMembers[0]),
                  ),
                  Expanded(
                    child: _buildQuarterAvatar(displayMembers[1], isRight: true),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuarterAvatarBottom(displayMembers[2]),
                  ),
                  Expanded(
                    child: _buildQuarterAvatarBottom(displayMembers[3], isRight: true),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHalfAvatar(GroupAvatarMember member, {required bool isLeft}) {
    return ClipRect(
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: 0.5,
        child: _buildSingleAvatar(
          avatarUrl: member.avatarUrl,
          name: member.name,
          seed: member.userId,
          size: size,
        ),
      ),
    );
  }

  Widget _buildHalfAvatarTop(GroupAvatarMember member) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.5,
        child: _buildSingleAvatar(
          avatarUrl: member.avatarUrl,
          name: member.name,
          seed: member.userId,
          size: size,
        ),
      ),
    );
  }

  Widget _buildQuarterAvatar(GroupAvatarMember member, {bool isRight = false}) {
    return ClipRect(
      child: Align(
        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: _buildSingleAvatar(
          avatarUrl: member.avatarUrl,
          name: member.name,
          seed: member.userId,
          size: size,
        ),
      ),
    );
  }

  Widget _buildQuarterAvatarBottom(GroupAvatarMember member, {bool isRight = false}) {
    return ClipRect(
      child: Align(
        alignment: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
        widthFactor: 0.5,
        heightFactor: 0.5,
        child: _buildSingleAvatar(
          avatarUrl: member.avatarUrl,
          name: member.name,
          seed: member.userId,
          size: size,
        ),
      ),
    );
  }

  Widget _buildSingleAvatar({
    required String? avatarUrl,
    required String name,
    required String seed,
    required double size,
  }) {
    final resolvedAvatar = normalizeAvatarUrl(avatarUrl);

    if (resolvedAvatar.isNotEmpty) {
      return Image.network(
        resolvedAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackAvatar(name, seed),
      );
    }

    return _buildFallbackAvatar(name, seed);
  }

  Widget _buildFallbackAvatar(String name, String seed) {
    final color = seed.isNotEmpty
        ? getUserAvatarColor(seed)
        : const Color(0xFF5FB6F7);
    final text = getAvatarText(name);

    return Container(
      width: size,
      height: size,
      color: color,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 群头像成员数据类
class GroupAvatarMember {
  const GroupAvatarMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
}
