class ChatViewportState {
  const ChatViewportState({
    required this.anchorMessageId,
    required this.hasMoreBefore,
    required this.hasMoreAfter,
    this.anchorFound = true,
    this.oldestSequence,
    this.newestSequence,
  });

  final String? anchorMessageId;
  final bool hasMoreBefore;
  final bool hasMoreAfter;
  final bool anchorFound;
  final String? oldestSequence;
  final String? newestSequence;
}
