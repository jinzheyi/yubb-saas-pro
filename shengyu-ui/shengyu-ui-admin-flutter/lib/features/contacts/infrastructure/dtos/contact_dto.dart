class ContactDto {
  const ContactDto({
    required this.userId,
    required this.nickname,
    required this.remarkName,
    required this.avatarUrl,
    required this.departmentId,
    required this.departmentName,
    required this.postName,
    required this.pinyin,
  });

  final String userId;
  final String nickname;
  final String remarkName;
  final String avatarUrl;
  final String departmentId;
  final String departmentName;
  final String postName;
  final String pinyin;

  factory ContactDto.fromJson(Map<String, dynamic> json) {
    return ContactDto(
      userId: '${json['id'] ?? json['userId'] ?? ''}',
      nickname:
          '${json['nickname'] ?? json['userName'] ?? json['realName'] ?? json['name'] ?? ''}',
      remarkName: '${json['remarkName'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? json['avatar'] ?? json['userAvatar'] ?? ''}',
      departmentId: '${json['deptId'] ?? json['departmentId'] ?? ''}',
      departmentName:
          '${json['deptName'] ?? json['departmentName'] ?? json['department'] ?? ''}',
      postName: '${json['postName'] ?? json['positionName'] ?? ''}',
      pinyin: '${json['pinyin'] ?? ''}',
    );
  }
}
