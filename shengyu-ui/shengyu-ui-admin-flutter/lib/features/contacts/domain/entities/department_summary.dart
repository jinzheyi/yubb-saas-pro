class DepartmentSummary {
  const DepartmentSummary({
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
}
