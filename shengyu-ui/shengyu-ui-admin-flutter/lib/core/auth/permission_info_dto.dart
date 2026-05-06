class PermissionInfoDto {
  const PermissionInfoDto({required this.userId, required this.nickname});

  final String userId;
  final String nickname;

  factory PermissionInfoDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return PermissionInfoDto(
      userId:
          user['id']?.toString() ??
          user['userId']?.toString() ??
          json['userId']?.toString() ??
          '',
      nickname:
          user['nickname']?.toString() ?? user['username']?.toString() ?? '',
    );
  }
}
