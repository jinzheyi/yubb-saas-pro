import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_call_member_select_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/config/call_config_provider.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/group_member_select_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/call_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/app_avatar.dart';

/// 群通话成员选择页 - 微信风格
///
/// 用于发起群通话前选择参与成员
/// 支持搜索、多选、显示已选成员头像
/// 发起者（当前用户）不在列表中显示，也不提供勾选操作
class GroupCallMemberSelectPage extends ConsumerStatefulWidget {
  const GroupCallMemberSelectPage({super.key, required this.args});

  final GroupCallMemberSelectArgs args;

  @override
  ConsumerState<GroupCallMemberSelectPage> createState() =>
      _GroupCallMemberSelectPageState();
}

class _GroupCallMemberSelectPageState
    extends ConsumerState<GroupCallMemberSelectPage> {
  late GroupMemberSelectController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final callConfig = ref.read(callConfigProvider);
    // maxGroupCallParticipants 包含发起人，这个页面只选择被邀请成员。
    // 预留发起人名额，才能和服务端的 9 人上限保持一致，避免不必要的创建失败。
    final maxInvitees =
        (callConfig.maxGroupCallParticipants - 1).clamp(1, 8).toInt();
    _controller = GroupMemberSelectController(
      existingMemberIds: widget.args.existingMemberIds,
      maxParticipants: maxInvitees,
      currentUserId: widget.args.currentUserId,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupMembersAsync = ref.watch(
      groupMembersFutureProvider(widget.args.groupId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '选择成员',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 确定按钮
          TextButton(
            onPressed: _onConfirmTap,
            child: Text(
              '确定(${_controller.currentState.selectedMembers.length})',
              style: const TextStyle(
                color: Color(0xFF07C160),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 已选成员头像行
          _buildSelectedMembersRow(),
          
          // 搜索框
          _buildSearchBar(),
          
          // 成员列表
          Expanded(
            child: groupMembersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF07C160)),
              ),
              error: (error, stack) => Center(
                child: Text(
                  '加载失败: $error',
                  style: const TextStyle(color: Color(0xFFE54D4F)),
                ),
              ),
              data: (members) {
                final filteredMembers = _controller.filterMembers(members);
                if (filteredMembers.isEmpty) {
                  return const Center(
                    child: Text(
                      '没有可选择的成员',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return _MemberItem(
                      member: member,
                      isSelected: _controller.isSelected(member),
                      onTap: () {
                        setState(() {
                          _controller.toggleMember(member);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 已选成员头像行
  Widget _buildSelectedMembersRow() {
    final selectedMembers = _controller.currentState.selectedMembers;
    
    return Container(
      // 增加高度避免 overflow：头像48 + 间距8 + 昵称12 + padding16 = 84
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: selectedMembers.isEmpty
                ? const Center(
                    child: Text(
                      '请选择通话成员',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedMembers.length,
                    itemBuilder: (context, index) {
                      final member = selectedMembers[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 使用项目统一的 AppAvatar 逻辑
                            // 不传 backgroundColor，由 AppAvatar 内部根据 seed 自动生成颜色
                            AppAvatar(
                              name: member.nickname,
                              avatarUrl: member.avatarUrl,
                              seed: member.userId,
                              size: 48,
                              borderRadius: 8,
                              fontSize: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.nickname,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 搜索框
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _controller.setSearchQuery(value);
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索',
          hintStyle: const TextStyle(color: Color(0xFF999999)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  /// 确定按钮点击
  void _onConfirmTap() {
    final selectedMembers = _controller.currentState.selectedMembers;
    if (selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个成员')),
      );
      return;
    }

    // 返回选择的成员ID列表
    context.pop(selectedMembers.map((m) => m.userId).toList());
  }
}

/// 成员列表项
class _MemberItem extends StatelessWidget {
  const _MemberItem({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final dynamic member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // 头像 - 使用项目统一的 AppAvatar 逻辑
            // 不传 backgroundColor，由 AppAvatar 内部根据 seed 自动生成颜色
            AppAvatar(
              name: member.nickname,
              avatarUrl: member.avatarUrl,
              seed: member.userId,
              size: 48,
              borderRadius: 8,
              fontSize: 18,
            ),
            const SizedBox(width: 12),
            // 昵称
            Expanded(
              child: Text(
                member.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            // 选择图标
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFF07C160)
                  : const Color(0xFF999999),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
