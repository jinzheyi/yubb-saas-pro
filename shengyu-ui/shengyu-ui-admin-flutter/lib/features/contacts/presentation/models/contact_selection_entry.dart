class ContactSelectionEntry {
  const ContactSelectionEntry({
    required this.id,
    required this.name,
    required this.role,
    required this.avatarUrl,
    this.isCurrentUser = false,
  });

  final String id;
  final String name;
  final String role;
  final String avatarUrl;
  final bool isCurrentUser;
}
