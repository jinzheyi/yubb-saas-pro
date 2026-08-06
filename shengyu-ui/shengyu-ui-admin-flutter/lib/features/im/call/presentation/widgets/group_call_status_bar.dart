import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/group_call_state.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群聊通话状态栏
/// 
/// 显示在群聊页面顶部，当群内正在进行通话时显示
/// 支持收起/展开两种模式
class GroupCallStatusBar extends ConsumerStatefulWidget {
  final String groupId;
  final VoidCallback? onTap;
  final VoidCallback? onJoinTap;

  const GroupCallStatusBar({
    super.key,
    required this.groupId,
    this.onTap,
    this.onJoinTap,
  });

  @override
  ConsumerState<GroupCallStatusBar> createState() => _GroupCallStatusBarState();
}

class _GroupCallStatusBarState extends ConsumerState<GroupCallStatusBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(groupCallStateProvider(widget.groupId));

    // 没有通话或不在当前群聊，不显示
    if (!callState.hasActiveCall || callState.groupId != widget.groupId) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 收起模式：标题栏
          _buildCollapsedBar(callState),
          
          // 展开模式：参与者列表 + 加入按钮
          if (_isExpanded) _buildExpandedContent(callState),
        ],
      ),
    );
  }

  /// 收起模式标题栏
  Widget _buildCollapsedBar(GroupCallState callState) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 通话图标
            const Icon(
              Icons.phone_in_talk,
              color: Color(0xFF07C160),
              size: 20,
            ),
            const SizedBox(width: 8),
            
            // 通话信息
            Expanded(
              child: Text(
                '${callState.participantCount}人正在${callState.callType == 'video' ? '视频' : '语音'}通话',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // 展开/收起按钮
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 24,
              ),
              onPressed: _toggleExpand,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// 展开模式内容
  Widget _buildExpandedContent(GroupCallState callState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 参与者头像行
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: callState.participants.length,
                    itemBuilder: (context, index) {
                      final participant = callState.participants[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppAvatar(
                          name: participant.displayName,
                          avatarUrl: participant.avatarUrl,
                          seed: participant.userId,
                          size: 48,
                          borderRadius: 8,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 分隔线
        Container(
          height: 1,
          color: const Color(0xFF3A3A3A),
        ),
        
        // 加入按钮
        InkWell(
          onTap: widget.onJoinTap,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF07C160),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '加入',
                  style: TextStyle(
                    color: Color(0xFF07C160),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
