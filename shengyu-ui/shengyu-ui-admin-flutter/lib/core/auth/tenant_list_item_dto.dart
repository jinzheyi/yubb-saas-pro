/// 租户列表项 DTO（对应后端 MyTenantRespVO）
///
/// 注意：id 必须使用 String 类型，因为后端返回的是雪花算法生成的
/// 大数字（如 2038793695253614593），超过 JS 安全整数范围（2^53-1），
/// 转为 int 会丢失精度。
class TenantListItemDto {
  const TenantListItemDto({
    required this.id,
    required this.tenantName,
    required this.status,
    this.loginDate,
  });

  final String id;
  final String tenantName;
  final String status; // "正常"=开启，"禁用"=关闭
  final DateTime? loginDate;

  factory TenantListItemDto.fromJson(Map<String, dynamic> json) {
    // id 后端返回的是 String 类型的大数字，必须保持 String 避免精度丢失
    final String id = json['id']?.toString() ?? '';

    // loginDate 后端返回的是毫秒时间戳
    DateTime? parsedLoginDate;
    final rawLoginDate = json['loginDate'];
    if (rawLoginDate is num) {
      parsedLoginDate = DateTime.fromMillisecondsSinceEpoch(rawLoginDate.toInt());
    } else if (rawLoginDate != null) {
      parsedLoginDate = DateTime.tryParse(rawLoginDate.toString());
    }

    return TenantListItemDto(
      id: id,
      tenantName: json['tenantName']?.toString().trim() ?? '',
      status: json['status']?.toString() ?? '',
      loginDate: parsedLoginDate,
    );
  }

  /// 是否可切换（基于租户状态判断）
  bool get isSwitchable => status == '正常' || status == '0';
}
