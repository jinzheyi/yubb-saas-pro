class ContactCardSharePayload {
  const ContactCardSharePayload({
    required this.userId,
    required this.displayName,
    required this.departmentName,
    required this.postName,
    required this.avatar,
  });

  final String userId;
  final String displayName;
  final String departmentName;
  final String postName;
  final String avatar;
}
