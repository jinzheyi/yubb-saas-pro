class ReadReceiptRouteArgs {
  const ReadReceiptRouteArgs({
    required this.messageId,
    required this.chatTitle,
    required this.messagePreview,
  });

  final String messageId;
  final String chatTitle;
  final String messagePreview;
}
