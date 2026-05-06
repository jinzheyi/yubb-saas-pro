class ContactProfileDto {
  const ContactProfileDto({
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

  factory ContactProfileDto.fromJson(Map<String, dynamic> json) {
    return ContactProfileDto(
      userId: '${json['id'] ?? json['userId'] ?? ''}',
      nickname:
          '${json['nickname'] ?? json['remarkName'] ?? json['userName'] ?? json['realName'] ?? json['name'] ?? ''}',
      mobile: '${json['mobile'] ?? json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? json['avatar'] ?? ''}',
      departmentName:
          '${json['deptName'] ?? json['departmentName'] ?? json['department'] ?? ''}',
      postName: '${json['postName'] ?? json['positionName'] ?? ''}',
    );
  }
}
