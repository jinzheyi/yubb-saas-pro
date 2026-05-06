class DepartmentSummaryDto {
  const DepartmentSummaryDto({
    required this.deptId,
    required this.name,
    required this.memberCount,
    this.parentDeptId,
    this.sort = 0,
  });

  final String deptId;
  final String name;
  final int memberCount;
  final String? parentDeptId;
  final int sort;

  factory DepartmentSummaryDto.fromJson(Map<String, dynamic> json) {
    return DepartmentSummaryDto(
      deptId: '${json['id'] ?? json['deptId'] ?? json['departmentId'] ?? ''}',
      name:
          '${json['name'] ?? json['deptName'] ?? json['departmentName'] ?? ''}',
      memberCount:
          _parseInt(
            json['memberCount'] ?? json['memberNum'] ?? json['userCount'],
          ) ??
          0,
      parentDeptId: _normalizeNullableId(
        json['parentId'] ?? json['parentDeptId'] ?? json['parentDeptID'],
      ),
      sort: _parseInt(json['sort'] ?? json['orderNum']) ?? 0,
    );
  }

  static String? _normalizeNullableId(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return int.tryParse(raw?.toString().trim() ?? '');
  }
}
