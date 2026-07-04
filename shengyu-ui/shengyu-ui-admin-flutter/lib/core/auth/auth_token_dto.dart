class AuthTokenDto {
  const AuthTokenDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tenantId,
    this.tenantName,
  });

  final String accessToken;
  final String refreshToken;
  final String tenantId;
  final String? tenantName;

  factory AuthTokenDto.fromJson(Map<String, dynamic> json) {
    return AuthTokenDto(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tenantId:
          json['tenantId']?.toString() ?? json['tenantID']?.toString() ?? '',
      tenantName: json['tenantName']?.toString(),
    );
  }
}
