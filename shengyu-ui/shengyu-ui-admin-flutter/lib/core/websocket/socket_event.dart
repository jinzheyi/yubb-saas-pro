class ImSocketEvent {
  const ImSocketEvent({
    required this.type,
    this.chatId,
    this.messageId,
    this.payload = const <String, Object?>{},
  });

  final String type;
  final String? chatId;
  final String? messageId;
  final Map<String, Object?> payload;
}
