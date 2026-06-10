import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// 类型定义
// ============================================================

/// 当前正在查看的对话状态
class ActiveConversationState {
  const ActiveConversationState({
    this.currentChatId,
    this.isViewing = false,
  });

  /// 当前查看的对话 chatId
  final String? currentChatId;

  /// 是否正在查看对话页
  final bool isViewing;

  ActiveConversationState copyWith({
    String? currentChatId,
    bool? isViewing,
  }) {
    return ActiveConversationState(
      currentChatId: currentChatId ?? this.currentChatId,
      isViewing: isViewing ?? this.isViewing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveConversationState &&
        other.currentChatId == currentChatId &&
        other.isViewing == isViewing;
  }

  @override
  int get hashCode => currentChatId.hashCode ^ isViewing.hashCode;
}

// ============================================================
// ActiveConversationService — StateNotifier
// ============================================================

/// 当前活跃对话管理服务
///
/// 用于追踪用户当前是否正在查看某个对话页面，
/// 以便在推送消息时区分"已读"和"未读"状态。
class ActiveConversationService extends StateNotifier<ActiveConversationState> {
  ActiveConversationService() : super(const ActiveConversationState());

  /// 当前活跃对话的未读数（用于Tab角标计算时扣除）
  int _activeChatUnreadCount = 0;

  /// 激活对话（进入对话页时调用）
  void activateChat(String chatId, {int unreadCount = 0}) {
    _activeChatUnreadCount = unreadCount;
    state = ActiveConversationState(
      currentChatId: chatId,
      isViewing: true,
    );
  }

  /// 注销对话（离开对话页时调用）
  void deactivateChat() {
    _activeChatUnreadCount = 0;
    state = const ActiveConversationState(
      currentChatId: null,
      isViewing: false,
    );
  }

  /// 检查指定对话是否正在被查看
  bool isActive(String chatId) {
    return state.isViewing && state.currentChatId == chatId;
  }

  /// 获取当前活跃对话的未读数（用于Tab角标计算）
  int get activeChatUnreadCount => _activeChatUnreadCount;

  /// 更新活跃对话的未读数（当收到新消息时调用）
  void updateActiveChatUnreadCount(int unreadCount) {
    if (state.isViewing) {
      _activeChatUnreadCount = unreadCount;
    }
  }
}

// ============================================================
// Riverpod Provider
// ============================================================

/// 当前活跃对话状态 Provider
final activeConversationServiceProvider =
    StateNotifierProvider<ActiveConversationService, ActiveConversationState>((
  ref,
) {
  return ActiveConversationService();
});
