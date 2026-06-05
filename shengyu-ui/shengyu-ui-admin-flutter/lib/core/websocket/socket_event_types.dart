abstract final class SocketEventTypes {
  static const connectRequested = 'connectRequested';
  static const connected = 'connected';
  static const disconnected = 'disconnected';
  static const authRequested = 'authRequested';
  static const authSucceeded = 'authSucceeded';
  static const authFailed = 'authFailed';
  static const tokenRefreshed = 'tokenRefreshed';
  static const tokenRenewSuggested = 'tokenRenewSuggested';
  static const reconnecting = 'reconnecting';
  static const closeByServer = 'closeByServer';
  static const heartbeatTimeout = 'heartbeatTimeout';
  static const systemNotify = 'systemNotify';
  static const badgeUpdated = 'badgeUpdated';
  static const sessionInvalidated = 'sessionInvalidated';
  static const sessionKicked = 'sessionKicked';
  static const sessionLoggedOut = 'sessionLoggedOut';
  static const sessionRevoked = 'sessionRevoked';
  static const sessionReauthRequired = 'sessionReauthRequired';

  static const conversationHint = 'conversationHint';
  static const conversationUpdated = 'conversationUpdated';
  static const conversationDeleted = 'conversationDeleted';

  static const messageReceived = 'messageReceived';
  static const messageRecalled = 'messageRecalled';
  static const readReceiptChanged = 'readReceiptChanged';
  static const typingReceived = 'typingReceived';

  /// 用户头像变更事件（由后端 SYSTEM_NOTIFY action=user_avatar_changed 触发）
  static const userAvatarChanged = 'userAvatarChanged';
}
