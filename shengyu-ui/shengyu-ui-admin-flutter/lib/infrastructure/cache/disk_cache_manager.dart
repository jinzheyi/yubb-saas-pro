import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/im_database.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/mappers/conversation_db_mapper.dart';
import 'package:shengyu_ui_admin_im/infrastructure/database/mappers/message_db_mapper.dart';
import 'package:shengyu_ui_admin_im/infrastructure/cache/cache_policy.dart';
import 'package:shengyu_ui_admin_im/features/im/conversation/domain/entities/conversation.dart' as conv;
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart' as msg;
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/chat_viewport_state.dart';

/// 磁盘缓存管理器
///
/// 职责：
/// 1. 从 Drift DB 读取缓存数据
/// 2. 将数据写入 Drift DB
/// 3. 清理过期数据
class DiskCacheManager {
  /// 获取会话列表缓存
  Future<List<conv.Conversation>?> getConversationList(String userId) async {
    try {
      final db = ImDatabase.instance;
      final rows = await db.conversationDao.getConversationListByUser(
        userId: userId,
      );

      if (rows.isEmpty) return null;

      return rows.map(ConversationDbMapper.toEntity).toList();
    } catch (e) {
      debugPrint('[DiskCache] getConversationList failed: $e');
      return null;
    }
  }

  /// 保存会话列表缓存
  Future<void> setConversationList(
    String userId,
    List<conv.Conversation> conversations,
  ) async {
    try {
      final db = ImDatabase.instance;
      final companions = conversations
          .map((c) => ConversationDbMapper.toCompanion(c, userId: userId))
          .toList();

      await db.conversationDao.upsertConversationsForUser(
        userId: userId,
        companions: companions,
      );
    } catch (e) {
      debugPrint('[DiskCache] setConversationList failed: $e');
    }
  }

  /// 获取消息缓存（包含 viewportState）
  Future<MessageCacheData?> getMessages(
    String userId,
    String chatId, {
    int limit = 500,
  }) async {
    try {
      final db = ImDatabase.instance;
      final rows = await db.messageDao.getMessagesByChatIdForUser(
        userId: userId,
        chatId: chatId,
        limit: limit,
      );

      if (rows.isEmpty) return null;

      final messages = rows.map(MessageDbMapper.toEntity).toList();

      // 从 SharedPreferences 读取 viewportState
      final viewportState = await _getViewportState(userId, chatId);

      return MessageCacheData(messages: messages, viewportState: viewportState);
    } catch (e) {
      debugPrint('[DiskCache] getMessages failed: $e');
      return null;
    }
  }

  /// 保存消息缓存（包含 viewportState）
  Future<void> setMessages(
    String userId,
    String chatId,
    List<msg.Message> messages, {
    ChatViewportState? viewportState,
  }) async {
    try {
      final db = ImDatabase.instance;
      final companions = messages
          .map((m) => MessageDbMapper.toCompanion(m, userId: userId))
          .toList();

      await db.messageDao.upsertMessagesForUser(companions);

      // 将 viewportState 保存到 SharedPreferences
      if (viewportState != null) {
        await _saveViewportState(userId, chatId, viewportState);
      }
    } catch (e) {
      debugPrint('[DiskCache] setMessages failed: $e');
    }
  }

  /// 从 SharedPreferences 读取 viewportState
  Future<ChatViewportState?> _getViewportState(String userId, String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'viewport_state:$userId:$chatId';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ChatViewportState.fromJson(json);
    } catch (e) {
      debugPrint('[DiskCache] _getViewportState failed: $e');
      return null;
    }
  }

  /// 将 viewportState 保存到 SharedPreferences
  Future<void> _saveViewportState(
    String userId,
    String chatId,
    ChatViewportState viewportState,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'viewport_state:$userId:$chatId';
      final jsonStr = jsonEncode(viewportState.toJson());
      await prefs.setString(key, jsonStr);
    } catch (e) {
      debugPrint('[DiskCache] _saveViewportState failed: $e');
    }
  }

  /// 清空指定会话的消息缓存（clearAll 时调用）
  Future<void> clearMessages(String userId, String chatId) async {
    try {
      final db = ImDatabase.instance;
      await db.messageDao.deleteMessagesByChatIdForUser(
        userId: userId,
        chatId: chatId,
      );
      // 同时清理 SharedPreferences 中的 viewportState
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('viewport_state:$userId:$chatId');
    } catch (e) {
      debugPrint('[DiskCache] clearMessages failed: $e');
    }
  }

  /// 清理过期缓存
  Future<void> cleanup(String userId) async {
    try {
      final db = ImDatabase.instance;
      final messageExpiry = DateTime.now().subtract(CachePolicy.messages.diskTtl);
      final conversationExpiry = DateTime.now().subtract(CachePolicy.conversationList.diskTtl);

      // 清理过期消息
      await db.messageDao.cleanExpiredMessagesForUser(
        userId: userId,
        before: messageExpiry,
      );

      // 清理过期会话
      await db.conversationDao.cleanExpiredConversations(
        userId: userId,
        before: conversationExpiry,
      );
    } catch (e) {
      debugPrint('[DiskCache] cleanup failed: $e');
    }
  }
}

/// 消息缓存数据（包含消息列表和视口状态）
class MessageCacheData {
  final List<msg.Message> messages;
  final ChatViewportState? viewportState;

  const MessageCacheData({
    required this.messages,
    this.viewportState,
  });
}
