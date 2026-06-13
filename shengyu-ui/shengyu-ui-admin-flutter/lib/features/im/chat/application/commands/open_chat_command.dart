import 'package:shengyu_ui_admin_im/app/router/route_args/chat_entry_args.dart';
import 'package:shengyu_ui_admin_im/shared/enums/conversation_type.dart';

class OpenChatCommand {
  const OpenChatCommand({
    required this.chatId,
    required this.conversationType,
    required this.entryMode,
    this.title,
    this.anchorSequence,
    this.anchorMessageId,
    this.isPreload = false,
    this.windowLimitOverride,
  });

  final String chatId;
  final ConversationType conversationType;
  final ChatEntryMode entryMode;
  final String? title;
  final String? anchorSequence;
  final String? anchorMessageId;
  /// 是否为预加载模式（后台加载消息，不阻塞UI）
  final bool isPreload;
  /// windowLimit 覆盖值（用于 confirmPendingMessages 等场景，传入则优先使用此值）
  final int? windowLimitOverride;

  String? get windowMode {
    return switch (entryMode) {
      ChatEntryMode.latest => 'latest',
      ChatEntryMode.anchor || ChatEntryMode.restore => null,
    };
  }

  int? get windowLimit {
    // 优先使用覆盖值
    if (windowLimitOverride != null && windowLimitOverride! > 0) {
      return windowLimitOverride;
    }
    return switch (entryMode) {
      ChatEntryMode.latest => 30,
      ChatEntryMode.anchor || ChatEntryMode.restore => null,
    };
  }

  int? get beforeLimit {
    return switch (entryMode) {
      ChatEntryMode.latest => null,
      ChatEntryMode.anchor || ChatEntryMode.restore => 15,
    };
  }

  int? get afterLimit {
    return switch (entryMode) {
      ChatEntryMode.latest => null,
      ChatEntryMode.anchor || ChatEntryMode.restore => 10,
    };
  }

  factory OpenChatCommand.fromArgs(ChatEntryArgs args) {
    return OpenChatCommand(
      chatId: args.chatId,
      conversationType: args.conversationType,
      entryMode: args.entryMode,
      title: args.title,
      anchorSequence: args.anchorSequence,
      anchorMessageId: args.anchorMessageId,
    );
  }
}
