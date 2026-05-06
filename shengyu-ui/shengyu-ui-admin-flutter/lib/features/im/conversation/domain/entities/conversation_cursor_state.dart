class ConversationCursorState {
  const ConversationCursorState({
    required this.cursorVersion,
    required this.hasMore,
  });

  final String cursorVersion;
  final bool hasMore;
}
