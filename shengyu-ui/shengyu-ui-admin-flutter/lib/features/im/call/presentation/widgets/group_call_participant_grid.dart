import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群组通话参与者网格视图 - 1:1 复刻微信设计
///
/// 网格布局规则（微信）：
/// - 2 人（邀请人）：PIP模式 - 大远端视频全屏 + 小本地视频左下角
/// - 2 人（被邀请人）：分屏模式（1x2，各占50%宽度）
/// - 3-4 人：2x2
/// - 5-6 人：2x3
/// - 7-9 人：3x3
/// - 每个格子：圆角矩形头像 + 昵称
/// - 说话者指示器：绿色光环（语音）/ 绿色声波图标（视频）
/// - 支持"邀请好友加入"按钮（+ 号）
class GroupCallParticipantGrid extends StatefulWidget {
  const GroupCallParticipantGrid({
    super.key,
    required this.participants,
    this.localUserId,
    this.speakingUserId,
    this.onInviteTap,
    this.isInviter = false,
  });

  final List<CallParticipantProfile> participants;
  final String? localUserId;
  final String? speakingUserId;
  final VoidCallback? onInviteTap;
  
  /// 是否为邀请人（2人通话时使用PIP布局）
  final bool isInviter;

  @override
  State<GroupCallParticipantGrid> createState() =>
      _GroupCallParticipantGridState();
}

class _GroupCallParticipantGridState extends State<GroupCallParticipantGrid>
    with SingleTickerProviderStateMixin {
  /// 说话者光环呼吸动画控制器
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '等待参与者加入...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            if (widget.onInviteTap != null) ...[
              const SizedBox(height: 16),
              _InviteButton(onTap: widget.onInviteTap!),
            ],
          ],
        ),
      );
    }

    // 2人通话：区分邀请人（PIP）和被邀请人（分屏）
    if (widget.participants.length == 2) {
      if (widget.isInviter) {
        // 邀请人视图：PIP模式（大远端 + 小本地）
        return _buildPipLayout();
      } else {
        // 被邀请人视图：分屏模式（1x2，各占50%）
        return _buildSplitLayout();
      }
    }

    // 3人以上：网格布局
    final layout = _calculateGridLayout(widget.participants.length);

    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.crossAxisCount,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: layout.childAspectRatio,
          ),
          itemCount:
              widget.participants.length + (widget.onInviteTap != null ? 1 : 0),
          itemBuilder: (context, index) {
            // 最后一个格子是邀请按钮
            if (index == widget.participants.length) {
              return _InviteButton(onTap: widget.onInviteTap!);
            }

            final participant = widget.participants[index];
            final isLocal = participant.userId == widget.localUserId;
            final isSpeaking = participant.userId == widget.speakingUserId;

            return _ParticipantTile(
              participant: participant,
              isLocal: isLocal,
              isSpeaking: isSpeaking,
              breathValue: _breathAnimation.value,
            );
          },
        );
      },
    );
  }

  /// 邀请人视图：PIP布局（大远端视频全屏 + 小本地视频左下角）
  Widget _buildPipLayout() {
    // 找到本地用户和远端用户
    final localParticipant = widget.participants.firstWhere(
      (p) => p.userId == widget.localUserId,
      orElse: () => widget.participants[0],
    );
    final remoteParticipant = widget.participants.firstWhere(
      (p) => p.userId != widget.localUserId,
      orElse: () => widget.participants[1],
    );

    return Stack(
      children: [
        // 大远端视频（全屏）
        _buildRemoteTile(remoteParticipant),
        
        // 小本地视频（左下角，可拖拽）
        Positioned(
          left: 16,
          bottom: 16,
          child: _buildLocalPipTile(localParticipant),
        ),
      ],
    );
  }

  /// 被邀请人视图：分屏布局（1x2，各占50%）
  Widget _buildSplitLayout() {
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, _) {
        return Row(
          children: widget.participants.map((participant) {
            final isLocal = participant.userId == widget.localUserId;
            final isSpeaking = participant.userId == widget.speakingUserId;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _ParticipantTile(
                  participant: participant,
                  isLocal: isLocal,
                  isSpeaking: isSpeaking,
                  breathValue: _breathAnimation.value,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// 构建远端视频大视图（全屏）
  Widget _buildRemoteTile(CallParticipantProfile participant) {
    final isSpeaking = participant.userId == widget.speakingUserId;
    
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: isSpeaking
                ? Border.all(
                    color: const Color(0xFF07C160)
                        .withValues(alpha: _breathAnimation.value),
                    width: 2.5,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // 远端头像
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: participant.displayName,
                      avatarUrl: participant.avatarUrl,
                      seed: participant.userId,
                      size: 120,
                      borderRadius: 12,
                      fontSize: 48,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      participant.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 说话者指示器
              if (isSpeaking)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07C160)
                          .withValues(alpha: _breathAnimation.value),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建本地视频小视图（PIP）
  Widget _buildLocalPipTile(CallParticipantProfile participant) {
    final isSpeaking = participant.userId == widget.speakingUserId;
    
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, _) {
        return Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: isSpeaking
                ? Border.all(
                    color: const Color(0xFF07C160)
                        .withValues(alpha: _breathAnimation.value),
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 本地头像
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppAvatar(
                      name: participant.displayName,
                      avatarUrl: participant.avatarUrl,
                      seed: participant.userId,
                      size: 60,
                      borderRadius: 8,
                      fontSize: 24,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${participant.displayName}(我)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 说话者指示器
              if (isSpeaking)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07C160)
                          .withValues(alpha: _breathAnimation.value),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 根据参与者数量计算网格布局（微信规范）
  _GridLayout _calculateGridLayout(int participantCount) {
    if (participantCount <= 2) {
      // 2人：1x2 左右分屏
      return _GridLayout(crossAxisCount: 2, childAspectRatio: 0.75);
    }
    if (participantCount <= 4) {
      // 3-4人：2x2
      return _GridLayout(crossAxisCount: 2, childAspectRatio: 0.85);
    }
    if (participantCount <= 6) {
      // 5-6人：2x3（2列3行）
      return _GridLayout(crossAxisCount: 2, childAspectRatio: 0.7);
    }
    if (participantCount <= 9) {
      // 7-9人：3x3
      return _GridLayout(crossAxisCount: 3, childAspectRatio: 0.75);
    }
    return _GridLayout(crossAxisCount: 3, childAspectRatio: 0.75);
  }
}

class _GridLayout {
  final int crossAxisCount;
  final double childAspectRatio;

  _GridLayout({required this.crossAxisCount, required this.childAspectRatio});
}

/// 邀请按钮（+ 号）- 微信风格
class _InviteButton extends StatelessWidget {
  const _InviteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '邀请',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 参与者格子 - 微信风格
///
/// 圆角矩形头像 + 昵称 + 说话者绿色光环
/// 头像大小根据网格自适应
class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    this.isLocal = false,
    this.isSpeaking = false,
    this.breathValue = 1.0,
  });

  final CallParticipantProfile participant;
  final bool isLocal;
  final bool isSpeaking;
  final double breathValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据容器大小自适应头像尺寸
        final avatarSize = math.min(constraints.maxWidth, constraints.maxHeight) * 0.45;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            // 说话者绿色光环（带呼吸动画透明度）
            border: isSpeaking
                ? Border.all(
                    color: const Color(0xFF07C160)
                        .withValues(alpha: breathValue),
                    width: 2.5,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // 主内容：头像 + 昵称
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 圆角矩形头像（微信风格）
                    AppAvatar(
                      name: participant.displayName,
                      avatarUrl: participant.avatarUrl,
                      seed: participant.userId,
                      size: avatarSize.clamp(40.0, 72.0),
                      borderRadius: 10,
                      fontSize: avatarSize.clamp(16.0, 28.0),
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    // 昵称 12px
                    Text(
                      participant.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 本地用户标记"我"
                    if (isLocal)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '(我)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 说话者指示器：右上角绿色声波图标
              if (isSpeaking)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF07C160)
                          .withValues(alpha: breathValue),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
