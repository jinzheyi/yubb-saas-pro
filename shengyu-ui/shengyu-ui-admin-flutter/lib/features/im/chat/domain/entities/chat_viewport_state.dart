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

  /// 序列化为 JSON（用于持久化）
  Map<String, dynamic> toJson() {
    return {
      'anchorMessageId': anchorMessageId,
      'hasMoreBefore': hasMoreBefore,
      'hasMoreAfter': hasMoreAfter,
      'anchorFound': anchorFound,
      'oldestSequence': oldestSequence,
      'newestSequence': newestSequence,
    };
  }

  /// 从 JSON 反序列化
  factory ChatViewportState.fromJson(Map<String, dynamic> json) {
    return ChatViewportState(
      anchorMessageId: json['anchorMessageId'] as String?,
      hasMoreBefore: json['hasMoreBefore'] as bool? ?? true,
      hasMoreAfter: json['hasMoreAfter'] as bool? ?? true,
      anchorFound: json['anchorFound'] as bool? ?? true,
      oldestSequence: json['oldestSequence'] as String?,
      newestSequence: json['newestSequence'] as String?,
    );
  }
}
