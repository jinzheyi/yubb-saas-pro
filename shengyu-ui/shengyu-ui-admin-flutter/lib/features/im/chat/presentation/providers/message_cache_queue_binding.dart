import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/network_monitor_service.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/data/message_cache_queue.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/application/usecases/send_message_use_case.dart';

/// 消息缓存队列 provider
final messageCacheQueueProvider = Provider<MessageCacheQueue>((ref) {
  final queue = MessageCacheQueue();
  ref.onDispose(queue.dispose);
  return queue;
});

/// 消息缓存队列初始化绑定
///
/// 职责：
/// 1. 注册发送回调（使用 SendMessageUseCase 实际发送）
/// 2. 注册状态变更回调（通知 UI 更新消息状态）
/// 3. 监听网络状态变化，网络恢复时触发重发
final messageCacheQueueInitBindingProvider =
    Provider.autoDispose.family<void, SendMessageUseCase>((ref, sendUseCase) {
  final queue = ref.read(messageCacheQueueProvider);

  // 注册发送回调
  queue.registerSendCallback((message) async {
    try {
      await sendUseCase(
        chatId: message.chatId,
        text: message.content,
        clientMessageId: message.clientMessageId,
        receiverId: message.receiverId,
        groupId: message.groupId,
      );
      return true;
    } catch (_) {
      return false;
    }
  });

  // 监听网络状态变化
  final networkService = NetworkMonitorService();
  networkService.statusStream.listen((status) {
    if (networkService.isNetworkAvailable && queue.hasPendingMessages) {
      queue.onNetworkRecovered();
    }
  });
});
