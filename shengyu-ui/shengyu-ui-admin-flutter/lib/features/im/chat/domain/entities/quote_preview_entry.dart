/// 引用链预览条目（用于消息气泡中的引用预览展示）
/// 从 widget 层移到 domain 层，以便 controller 可以预计算引用链数据
class QuotePreviewEntry {
  const QuotePreviewEntry({
    required this.messageId,
    required this.senderName,
    required this.preview,
    required this.missing,
  });

  final String messageId;
  final String senderName;
  final String preview;
  final bool missing;
}
