class ContactProfile {
  const ContactProfile({
    required this.userId,
    required this.name,
    required this.sex,
    required this.departmentName,
    required this.postName,
    required this.phone,
    required this.email,
    required this.avatarUrl,
  });

  final String userId;
  final String name;
  final int? sex;
  final String departmentName;
  final String postName;
  final String phone;
  final String email;
  final String avatarUrl;
}
