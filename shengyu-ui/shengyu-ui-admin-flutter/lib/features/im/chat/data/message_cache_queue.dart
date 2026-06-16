import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// 待发送消息（本地缓存队列中的消息）
class PendingMessage {
  final String id;              // UUID
  final String chatId;          // 会话 ID
  final String clientMessageId; // 客户端消息 ID
  final String content;         // 消息内容
  final String? receiverId;     // 接收者 ID（单聊）
  final String? groupId;        // 群组 ID（群聊）
  final String? extraJson;      // 额外参数（引用、@等）
  final DateTime createdAt;     // 创建时间
  int retryCount;               // 已重试次数
  DateTime? lastRetryAt;        // 最后重试时间

  PendingMessage({
    required this.id,
    required this.chatId,
    required this.clientMessageId,
    required this.content,
    this.receiverId,
    this.groupId,
    this.extraJson,
    DateTime? createdAt,
    this.retryCount = 0,
    this.lastRetryAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 序列化为 JSON（用于持久化）
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'chatId': chatId,
      'clientMessageId': clientMessageId,
      'content': content,
      if (receiverId != null) 'receiverId': receiverId,
      if (groupId != null) 'groupId': groupId,
      if (extraJson != null) 'extraJson': extraJson,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      if (lastRetryAt != null) 'lastRetryAt': lastRetryAt!.millisecondsSinceEpoch,
    };
  }

  /// 从 JSON 反序列化
  factory PendingMessage.fromJson(Map<String, dynamic> json) {
    return PendingMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      clientMessageId: json['clientMessageId'] as String,
      content: json['content'] as String,
      receiverId: json['receiverId'] as String?,
      groupId: json['groupId'] as String?,
      extraJson: json['extraJson'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      retryCount: json['retryCount'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastRetryAt'] as int)
          : null,
    );
  }
}

/// 消息发送回调签名
typedef PendingMessageSendCallback = Future<bool> Function(PendingMessage message);

/// 消息状态变更回调（通知 UI 更新消息状态）
typedef MessageStatusChangeCallback = void Function(String clientMessageId, bool success);

/// 消息本地缓存队列
///
/// 核心功能：
/// 1. 断网时将发送失败的消息加入本地队列
/// 2. 网络恢复后自动重试发送
/// 3. 最多重试 5 次，指数退避（2s, 4s, 8s, 16s, 32s）
/// 4. 超过 24 小时的消息自动清理
class MessageCacheQueue {
  static final MessageCacheQueue _instance = MessageCacheQueue._internal();
  factory MessageCacheQueue() => _instance;
  MessageCacheQueue._internal();

  final Queue<PendingMessage> _queue = Queue<PendingMessage>();
  Timer? _retryTimer;
  bool _isProcessing = false;

  /// 最大重试次数
  static const int maxRetryCount = 5;

  /// 消息过期时间（24 小时）
  static const Duration messageExpiry = Duration(hours: 24);

  /// 消息发送回调（由外部注入实际发送逻辑）
  PendingMessageSendCallback? _sendCallback;

  /// 消息状态变更回调（通知 UI）
  MessageStatusChangeCallback? _statusChangeCallback;

  /// 注册发送回调
  void registerSendCallback(PendingMessageSendCallback callback) {
    _sendCallback = callback;
  }

  /// 注册状态变更回调
  void registerStatusChangeCallback(MessageStatusChangeCallback callback) {
    _statusChangeCallback = callback;
  }

  /// 队列中的消息（按创建时间排序）
  List<PendingMessage> get pendingMessages => _queue.toList();

  /// 是否有待发送消息
  bool get hasPendingMessages => _queue.isNotEmpty;

  /// 队列长度
  int get queueLength => _queue.length;

  /// 添加消息到队列
  void enqueue(PendingMessage message) {
    // 检查是否已存在相同的 clientMessageId
    final exists = _queue.any((m) => m.clientMessageId == message.clientMessageId);
    if (exists) {
      debugPrint('[MessageCacheQueue] duplicate skipped: ${message.clientMessageId}');
      return;
    }

    _queue.add(message);
    debugPrint('[MessageCacheQueue] enqueued: ${message.clientMessageId}, queue size: ${_queue.length}');
    _startProcessing();
  }

  /// 网络恢复时触发重发
  void onNetworkRecovered() {
    debugPrint('[MessageCacheQueue] network recovered, retrying ${_queue.length} pending messages');
    _processQueue();
  }

  /// WebSocket 重连成功后触发重发
  void onSocketReconnected() {
    debugPrint('[MessageCacheQueue] socket reconnected, retrying ${_queue.length} pending messages');
    _processQueue();
  }

  /// 手动触发重试
  void triggerRetry() {
    _processQueue();
  }

  /// 开始处理
  void _startProcessing() {
    if (_isProcessing) return;
    _processQueue();
  }

  /// 处理队列
  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final message = _queue.first;

      // 检查过期
      if (DateTime.now().difference(message.createdAt) > messageExpiry) {
        _queue.removeFirst();
        debugPrint('[MessageCacheQueue] expired message removed: ${message.clientMessageId}');
        _notifyStatusChange(message.clientMessageId, false);
        continue;
      }

      // 检查是否应该重试（指数退避）
      final waitDuration = _getRetryDelay(message.retryCount);
      if (message.lastRetryAt != null &&
          DateTime.now().difference(message.lastRetryAt!) < waitDuration) {
        break; // 还没到重试时间，等待
      }

      // 尝试发送
      final success = await _trySendMessage(message);
      if (success) {
        _queue.removeFirst();
        debugPrint('[MessageCacheQueue] message sent: ${message.clientMessageId}');
        _notifyStatusChange(message.clientMessageId, true);
      } else {
        message.retryCount++;
        message.lastRetryAt = DateTime.now();

        if (message.retryCount >= maxRetryCount) {
          _queue.removeFirst();
          debugPrint('[MessageCacheQueue] max retries reached, message failed: ${message.clientMessageId}');
          _notifyStatusChange(message.clientMessageId, false);
        } else {
          debugPrint('[MessageCacheQueue] send failed, will retry (attempt ${message.retryCount + 1}): ${message.clientMessageId}');
          break; // 等待下次重试
        }
      }
    }

    _isProcessing = false;

    // 如果队列中还有消息，设置定时器继续处理
    if (_queue.isNotEmpty) {
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 2), () => _processQueue());
    }
  }

  /// 获取重试延迟时间（指数退避）
  Duration _getRetryDelay(int retryCount) {
    // 2s, 4s, 8s, 16s, 32s
    return Duration(seconds: 2 * (1 << retryCount));
  }

  /// 尝试发送消息
  Future<bool> _trySendMessage(PendingMessage message) async {
    final callback = _sendCallback;
    if (callback == null) {
      debugPrint('[MessageCacheQueue] no send callback registered');
      return false;
    }

    try {
      return await callback(message);
    } catch (e) {
      debugPrint('[MessageCacheQueue] send error: $e');
      return false;
    }
  }

  /// 通知 UI 消息状态变更
  void _notifyStatusChange(String clientMessageId, bool success) {
    final callback = _statusChangeCallback;
    if (callback != null) {
      callback(clientMessageId, success);
    }
  }

  /// 清理指定会话的所有待发送消息
  void clearByChatId(String chatId) {
    _queue.removeWhere((m) => m.chatId == chatId);
    debugPrint('[MessageCacheQueue] cleared messages for chat: $chatId');
  }

  /// 移除指定消息
  void remove(String clientMessageId) {
    _queue.removeWhere((m) => m.clientMessageId == clientMessageId);
  }

  /// 销毁
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _queue.clear();
    _sendCallback = null;
    _statusChangeCallback = null;
  }
}
