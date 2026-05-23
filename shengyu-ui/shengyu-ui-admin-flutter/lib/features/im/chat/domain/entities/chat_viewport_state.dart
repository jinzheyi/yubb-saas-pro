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

  ChatViewportState copyWith({
    String? anchorMessageId,
    bool? hasMoreBefore,
    bool? hasMoreAfter,
    bool? anchorFound,
    String? oldestSequence,
    String? newestSequence,
  }) {
    return ChatViewportState(
      anchorMessageId: anchorMessageId ?? this.anchorMessageId,
      hasMoreBefore: hasMoreBefore ?? this.hasMoreBefore,
      hasMoreAfter: hasMoreAfter ?? this.hasMoreAfter,
      anchorFound: anchorFound ?? this.anchorFound,
      oldestSequence: oldestSequence ?? this.oldestSequence,
      newestSequence: newestSequence ?? this.newestSequence,
    );
  }
}
