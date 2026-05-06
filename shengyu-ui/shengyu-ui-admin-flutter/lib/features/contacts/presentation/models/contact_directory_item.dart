class ContactDirectoryItem {
  const ContactDirectoryItem({
    required this.userId,
    required this.name,
    required this.departmentName,
    required this.chatId,
    required this.avatarUrl,
    required this.postName,
    required this.email,
    required this.officeLocation,
  });

  final String userId;
  final String name;
  final String departmentName;
  final String chatId;
  final String avatarUrl;
  final String postName;
  final String email;
  final String officeLocation;
}
