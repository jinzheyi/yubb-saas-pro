class MessageSearchItemDto {
  const MessageSearchItemDto({
    required this.id,
    required this.messageId,
    required this.chatId,
    required this.sequence,
    required this.conversationName,
    required this.senderName,
    required this.content,
    required this.snippet,
    required this.highlight,
    required this.messageType,
    required this.timestamp,
    required this.conversationType,
    required this.targetId,
    required this.groupId,
  });

  final String id;
  final String messageId;
  final String chatId;
  final String sequence;
  final String conversationName;
  final String senderName;
  final String content;
  final String snippet;
  final String highlight;
  final String messageType;
  final DateTime? timestamp;
  final int? conversationType;
  final String targetId;
  final String groupId;

  factory MessageSearchItemDto.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString() ?? json['messageType']?.toString();
    return MessageSearchItemDto(
      id: '${json['id'] ?? json['messageId'] ?? ''}',
      messageId: '${json['messageId'] ?? json['id'] ?? ''}',
      chatId: '${json['chatId'] ?? json['sourceChatId'] ?? ''}',
      sequence: '${json['sequence'] ?? json['sortKey'] ?? ''}',
      conversationName: _pickFirstString(json, const [
        'conversationName',
        'chatName',
        'title',
        'sourceChatName',
        'targetName',
      ]),
      senderName: _pickFirstString(json, const [
        'senderName',
        'senderNickname',
        'nickname',
      ]),
      content: _buildContent(json, rawType),
      snippet: _pickFirstString(json, const ['snippet', 'contentSnippet']),
      highlight: _pickFirstString(json, const [
        'highlight',
        'highlightText',
        'matchedFragment',
      ]),
      messageType: rawType ?? '',
      timestamp: _parseDateTime(
        json['sendTime'] ?? json['timestamp'] ?? json['createTime'],
      ),
      conversationType: _parseConversationType(
        json['conversationType'] ?? json['conversation_type'],
      ),
      targetId:
          '${json['targetId'] ?? json['target_id'] ?? json['receiverId'] ?? ''}',
      groupId:
          '${json['groupId'] ?? json['group_id'] ?? json['targetGroupId'] ?? ''}',
    );
  }

  static String _buildContent(Map<String, dynamic> json, String? rawType) {
    final content = json['content']?.toString() ?? '';
    if (content.isNotEmpty) {
      return content;
    }
    return '';
  }

  static String _pickFirstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static int? _parseConversationType(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw.toString());
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? DateTime.fromMillisecondsSinceEpoch(value) : null;
    }
    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    final millis = int.tryParse(text);
    if (millis != null && millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final normalized = text.contains(' ') ? text.replaceFirst(' ', 'T') : text;
    return DateTime.tryParse(normalized);
  }
}
