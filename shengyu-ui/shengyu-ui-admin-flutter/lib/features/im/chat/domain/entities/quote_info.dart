class QuoteInfo {
  const QuoteInfo({
    required this.messageId,
    required this.senderName,
    required this.preview,
  });

  final String messageId;
  final String senderName;
  final String preview;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'messageId': messageId,
      'senderName': senderName,
      'preview': preview,
    };
  }

  factory QuoteInfo.fromJson(Map<String, dynamic> json) {
    return QuoteInfo(
      messageId: json['messageId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
    );
  }
}
