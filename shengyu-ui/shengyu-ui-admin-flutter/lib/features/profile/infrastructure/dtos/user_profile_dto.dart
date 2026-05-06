class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.nickname,
    required this.mobile,
    required this.email,
    required this.avatarUrl,
    required this.departmentName,
    required this.postName,
  });

  final String userId;
  final String nickname;
  final String mobile;
  final String email;
  final String avatarUrl;
  final String departmentName;
  final String postName;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      userId: '${json['id'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: '${json['avatar'] ?? ''}',
      departmentName: '${json['deptName'] ?? ''}',
      postName: '${json['postName'] ?? ''}',
    );
  }
}
