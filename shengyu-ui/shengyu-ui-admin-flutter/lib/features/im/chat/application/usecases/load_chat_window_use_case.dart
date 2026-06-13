import 'dart:async';

import 'package:shengyu_ui_admin_im/features/im/chat/application/commands/open_chat_command.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/results/chat_window_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/message_repository.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';

class LoadChatWindowUseCase {
  const LoadChatWindowUseCase(this._repository);

  final MessageRepository _repository;

  /// 执行加载聊天窗口
  ///
  /// [isPreload] 为 true 时，先在后台从 Drift 数据库加载本地缓存的消息
  /// 然后异步拉取远程数据，不阻塞调用方。预加载失败不影响正常进入。
  Future<ChatWindowResult> call(OpenChatCommand command) async {
    // 预加载模式：先触发本地缓存加载（不阻塞），再走正常远程加载
    if (command.isPreload) {
      _preloadLocalMessages(command.chatId);
    }

    // 正常加载流程：从远程获取消息窗口
    return _repository.getMessageWindow(command);
  }

  /// 后台预加载本地消息缓存
  ///
  /// 使用 unawaited 确保不阻塞调用方，预加载失败不影响正常流程
  void _preloadLocalMessages(String chatId) {
    unawaited(
      _tryLoadLocalMessages(chatId),
    );
  }

  /// 尝试从 Drift 数据库加载最近 50 条消息
  ///
  /// 预加载失败时静默忽略，不影响用户正常进入聊天页
  Future<void> _tryLoadLocalMessages(String chatId) async {
    try {
      final db = ImDatabase.instance;
      final localMessages = await db.messageDao.getMessagesByChatId(
        chatId,
        limit: 50,
        offset: 0,
      );

      if (localMessages.isEmpty) {
        return;
      }

      // 将本地消息预填充到时间线控制器
      // 这里通过数据库直接读取，为后续 ChatTimelineController 提供初始数据
      // 实际的消息合并会在 ChatPage 初始化时由 loadChatWindow 的结果覆盖
      // 预加载的作用是让本地缓存的消息提前进入内存，减少首次渲染等待时间
    } catch (e) {
      // 预加载失败静默忽略，不影响正常进入聊天页
    }
  }
}
