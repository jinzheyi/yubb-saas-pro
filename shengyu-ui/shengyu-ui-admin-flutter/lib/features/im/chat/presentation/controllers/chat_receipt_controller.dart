class ChatReceiptController {
  String? _lastReadChatId;

  String? get lastReadChatId => _lastReadChatId;

  void markVisible(String chatId) {
    _lastReadChatId = chatId;
  }
}
