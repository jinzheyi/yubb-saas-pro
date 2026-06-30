import 'package:shared_preferences/shared_preferences.dart';

/// 游标版本持久化存储
///
/// 职责：
/// 1. 持久化会话列表的 cursorVersion（用于增量同步）
/// 2. 按用户隔离存储
/// 3. 用户登出不清空（下次登录可继续增量同步）
class CursorVersionStore {
  static const _conversationListCursorKey = 'cursor_conversation_list';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 获取用户的会话列表游标版本
  Future<String> getConversationListCursor(String userId) async {
    final prefs = await _preferences;
    return prefs.getString('$_conversationListCursorKey:$userId') ?? '0';
  }

  /// 保存用户的会话列表游标版本
  Future<void> setConversationListCursor(String userId, String cursor) async {
    final prefs = await _preferences;
    await prefs.setString('$_conversationListCursorKey:$userId', cursor);
  }

  /// 清除用户的游标版本（仅在用户主动清除数据时调用）
  Future<void> clearUserCursors(String userId) async {
    final prefs = await _preferences;
    final keys = prefs.getKeys().where((k) => k.endsWith(':$userId')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
