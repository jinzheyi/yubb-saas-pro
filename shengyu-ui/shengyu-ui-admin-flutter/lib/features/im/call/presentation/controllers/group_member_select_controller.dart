import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';

/// 群通话成员选择控制器
///
/// 管理成员选择状态，包括：
/// - 已选成员列表
/// - 搜索过滤
/// - 选择/取消选择逻辑
/// - 过滤发起者（当前用户不在列表中显示）
class GroupMemberSelectController extends StateNotifier<GroupMemberSelectState> {
  GroupMemberSelectController({
    required List<String> existingMemberIds,
    required int maxParticipants,
    String currentUserId = '',
  }) : super(GroupMemberSelectState(
          existingMemberIds: existingMemberIds,
          maxParticipants: maxParticipants,
          currentUserId: currentUserId,
        ));

  /// 获取当前状态（供外部访问）
  GroupMemberSelectState get currentState => state;

  /// 切换成员选择状态
  void toggleMember(GroupMember member) {
    final isSelected = state.selectedMembers.contains(member);
    
    if (isSelected) {
      // 取消选择
      state = state.copyWith(
        selectedMembers: state.selectedMembers
            .where((m) => m.userId != member.userId)
            .toList(),
      );
    } else {
      // 检查是否超过最大人数
      if (state.selectedMembers.length >= state.maxParticipants) {
        return; // 已达上限，不再添加
      }
      
      // 添加选择
      state = state.copyWith(
        selectedMembers: [...state.selectedMembers, member],
      );
    }
  }

  /// 检查成员是否已选中
  bool isSelected(GroupMember member) {
    return state.selectedMembers.any((m) => m.userId == member.userId);
  }

  /// 检查成员是否可选（不在通话中）
  bool isSelectable(GroupMember member) {
    return !state.existingMemberIds.contains(member.userId);
  }

  /// 设置搜索关键词
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 过滤成员列表
  /// 
  /// 过滤规则：
  /// 1. 排除已在通话中的成员（existingMemberIds）
  /// 2. 排除发起者（currentUserId）- 发起者不需要勾选自己
  /// 3. 按搜索关键词过滤
  List<GroupMember> filterMembers(List<GroupMember> members) {
    var filtered = members.where((m) {
      // 排除已在通话中的成员
      if (state.existingMemberIds.contains(m.userId)) return false;
      // 排除发起者（当前用户）
      if (state.currentUserId.isNotEmpty && m.userId == state.currentUserId) return false;
      return true;
    });
    
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = m.nickname.toLowerCase();
        final query = state.searchQuery.toLowerCase();
        return name.contains(query);
      });
    }
    
    return filtered.toList();
  }

  /// 清空选择
  void clearSelection() {
    state = state.copyWith(
      selectedMembers: [],
    );
  }
}

/// 群通话成员选择状态
class GroupMemberSelectState {
  const GroupMemberSelectState({
    required this.existingMemberIds,
    required this.maxParticipants,
    this.selectedMembers = const [],
    this.searchQuery = '',
    this.currentUserId = '',
  });

  /// 已在通话中的成员ID列表
  final List<String> existingMemberIds;

  /// 最大参与人数
  final int maxParticipants;

  /// 已选成员列表
  final List<GroupMember> selectedMembers;

  /// 搜索关键词
  final String searchQuery;

  /// 当前用户ID（发起者）
  final String currentUserId;

  GroupMemberSelectState copyWith({
    List<String>? existingMemberIds,
    int? maxParticipants,
    List<GroupMember>? selectedMembers,
    String? searchQuery,
    String? currentUserId,
  }) {
    return GroupMemberSelectState(
      existingMemberIds: existingMemberIds ?? this.existingMemberIds,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      selectedMembers: selectedMembers ?? this.selectedMembers,
      searchQuery: searchQuery ?? this.searchQuery,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
