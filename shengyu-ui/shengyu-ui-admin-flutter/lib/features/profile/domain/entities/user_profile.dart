class UserProfile {
  const UserProfile({
    required this.userId,
    required this.nickname,
    required this.mobile,
    required this.email,
    required this.avatarUrl,
    required this.departmentName,
    required this.postName,
  });

  const UserProfile.empty()
      : userId = '',
        nickname = '',
        mobile = '',
        email = '',
        avatarUrl = '',
        departmentName = '',
        postName = '';

  final String userId;
  final String nickname;
  final String mobile;
  final String email;
  final String avatarUrl;
  final String departmentName;
  final String postName;
}
