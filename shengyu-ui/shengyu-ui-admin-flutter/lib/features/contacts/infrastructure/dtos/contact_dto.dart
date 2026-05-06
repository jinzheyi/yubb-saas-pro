class ContactDto {
  const ContactDto({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.departmentId,
    required this.departmentName,
    required this.postName,
  });

  final String userId;
  final String nickname;
  final String avatarUrl;
  final String departmentId;
  final String departmentName;
  final String postName;

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      userId: '${json['id'] ?? json['userId'] ?? ''}',
      nickname:
          '${json['nickname'] ?? json['remarkName'] ?? json['userName'] ?? json['realName'] ?? json['name'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? json['avatar'] ?? ''}',
      departmentId: '${json['deptId'] ?? json['departmentId'] ?? ''}',
      departmentName:
          '${json['deptName'] ?? json['departmentName'] ?? json['department'] ?? ''}',
      postName: '${json['postName'] ?? json['positionName'] ?? ''}',
    );
  }
}
