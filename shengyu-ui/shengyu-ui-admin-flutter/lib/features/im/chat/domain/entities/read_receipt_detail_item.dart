class ReadReceiptDetailItem {
  const ReadReceiptDetailItem({
    required this.userId,
    required this.userName,
    required this.avatar,
    required this.readTime,
  });

  final String userId;
  final String userName;
  final String avatar;
  final DateTime? readTime;
}
