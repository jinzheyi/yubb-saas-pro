import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/im_cache_manager.dart';
import 'package:shengyu_ui_admin_im/shared/utils/im_avatar.dart';

/// 钉钉风格群组合头像组件
///
/// 规则：
/// - 群已设置头像：始终显示群头像，不因成员列表同步而切换为拼图
/// - 1人：显示1个大头像
/// - 2人：显示2个头像（左右排列）
/// - 3人：上1个 + 下2个
/// - 4人及以上：显示4个头像（2x2网格）
/// - 无成员资料：按群名显示文字头像，颜色由群 ID 固定生成
///
/// 性能优化：
/// - 使用 const 构造函数，确保相同输入产生相同输出
/// - 头像渲染稳定，不随刷新/重新登录变化
/// - 成员按加入顺序取前4个，不重复查询
class GroupAvatarWidget extends StatelessWidget {
  const GroupAvatarWidget({
    super.key,
    required this.members,
    this.avatarUrl,
    this.fallbackName = '',
    this.fallbackSeed = '',
    this.size = 48,
    this.borderRadius = 8,
  });

  /// 从成员对象列表创建
  factory GroupAvatarWidget.fromMembers({
    Key? key,
    required List<GroupAvatarMember> members,
    String? avatarUrl,
    String fallbackName = '',
    String fallbackSeed = '',
    double size = 48,
    double borderRadius = 8,
  }) {
    return GroupAvatarWidget(
      key: key,
      members: members,
      avatarUrl: avatarUrl,
      fallbackName: fallbackName,
      fallbackSeed: fallbackSeed,
      size: size,
      borderRadius: borderRadius,
    );
  }

  /// 群成员列表（按加入顺序排列）
  final List<GroupAvatarMember> members;

  /// 群自定义头像；存在时优先于成员组合头像。
  final String? avatarUrl;

  /// 成员资料尚未就绪时的群名称回退。
  final String fallbackName;

  /// 群 ID，用于生成跨刷新稳定的文字头像背景色。
  final String fallbackSeed;

  /// 组件尺寸
  final double size;

  /// 圆角
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedGroupAvatar = normalizeAvatarUrl(avatarUrl);
    if (resolvedGroupAvatar.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: resolvedGroupAvatar,
          cacheManager: ImCacheManager.instance,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _buildAvatarComposite(),
        ),
      );
    }
    return _buildAvatarComposite();
  }

  Widget _buildAvatarComposite() {
    if (members.isEmpty) {
      return _buildSingleAvatar(
        avatarUrl: null,
        name: fallbackName.isNotEmpty ? fallbackName : '?',
        seed: fallbackSeed,
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
    final halfSize = size / 2;

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
            SizedBox(
              width: halfSize,
              height: size,
              child: _buildCellAvatar(
                avatarUrl: displayMembers[0].avatarUrl,
                name: displayMembers[0].name,
                seed: displayMembers[0].userId,
                cellWidth: halfSize,
                cellHeight: size,
              ),
            ),
            SizedBox(
              width: halfSize,
              height: size,
              child: _buildCellAvatar(
                avatarUrl: displayMembers[1].avatarUrl,
                name: displayMembers[1].name,
                seed: displayMembers[1].userId,
                cellWidth: halfSize,
                cellHeight: size,
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            SizedBox(
              width: size,
              height: halfSize,
              child: _buildCellAvatar(
                avatarUrl: displayMembers[0].avatarUrl,
                name: displayMembers[0].name,
                seed: displayMembers[0].userId,
                cellWidth: size,
                cellHeight: halfSize,
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[1].avatarUrl,
                    name: displayMembers[1].name,
                    seed: displayMembers[1].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[2].avatarUrl,
                    name: displayMembers[2].name,
                    seed: displayMembers[2].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
              ],
            ),
          ],
        );
      default: // 4人及以上
        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[0].avatarUrl,
                    name: displayMembers[0].name,
                    seed: displayMembers[0].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[1].avatarUrl,
                    name: displayMembers[1].name,
                    seed: displayMembers[1].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[2].avatarUrl,
                    name: displayMembers[2].name,
                    seed: displayMembers[2].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
                SizedBox(
                  width: halfSize,
                  height: halfSize,
                  child: _buildCellAvatar(
                    avatarUrl: displayMembers[3].avatarUrl,
                    name: displayMembers[3].name,
                    seed: displayMembers[3].userId,
                    cellWidth: halfSize,
                    cellHeight: halfSize,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  /// 构建单个单元格头像（已知单元格精确尺寸）
  Widget _buildCellAvatar({
    required String? avatarUrl,
    required String name,
    required String seed,
    required double cellWidth,
    required double cellHeight,
  }) {
    final resolvedAvatar = normalizeAvatarUrl(avatarUrl);

    if (resolvedAvatar.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resolvedAvatar,
        cacheManager: ImCacheManager.instance,
        width: cellWidth,
        height: cellHeight,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) =>
            _buildFallbackAvatar(name, seed, cellWidth, cellHeight),
      );
    }

    return _buildFallbackAvatar(name, seed, cellWidth, cellHeight);
  }

  Widget _buildSingleAvatar({
    required String? avatarUrl,
    required String name,
    required String seed,
    required double size,
  }) {
    final resolvedAvatar = normalizeAvatarUrl(avatarUrl);

    if (resolvedAvatar.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resolvedAvatar,
        cacheManager: ImCacheManager.instance,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _buildFallbackAvatar(name, seed, size, size),
      );
    }

    return _buildFallbackAvatar(name, seed, size, size);
  }

  Widget _buildFallbackAvatar(
    String name,
    String seed,
    double width,
    double height,
  ) {
    final color = seed.isNotEmpty
        ? getUserAvatarColor(seed)
        : const Color(0xFF5FB6F7);
    final text = getAvatarText(name);
    final minDim = width < height ? width : height;

    return Container(
      width: width,
      height: height,
      color: color,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: minDim * 0.35,
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
