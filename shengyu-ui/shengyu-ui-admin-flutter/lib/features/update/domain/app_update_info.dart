class AppUpdateInfo {
  const AppUpdateInfo({
    required this.hasUpdate,
    required this.updateType,
    required this.forceUpdate,
    this.versionName,
    this.versionCode,
    this.minSupportedVersionCode,
    this.title,
    this.changelog,
    this.packageUrl,
    this.packageSize,
    this.sha256,
    this.patchProvider,
    this.patchReleaseId,
    this.patchNo,
    this.promptStrategy,
  });

  final bool hasUpdate;
  final String updateType;
  final bool forceUpdate;
  final String? versionName;
  final int? versionCode;
  final int? minSupportedVersionCode;
  final String? title;
  final String? changelog;
  final String? packageUrl;
  final int? packageSize;
  final String? sha256;
  final String? patchProvider;
  final String? patchReleaseId;
  final int? patchNo;
  final String? promptStrategy;

  bool get isFullUpdate => updateType.toUpperCase() == 'FULL';

  bool get isPatchUpdate => updateType.toUpperCase() == 'PATCH';

  factory AppUpdateInfo.none() {
    return const AppUpdateInfo(
      hasUpdate: false,
      updateType: 'NONE',
      forceUpdate: false,
    );
  }

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      hasUpdate: json['hasUpdate'] == true,
      updateType: json['updateType']?.toString() ?? 'NONE',
      forceUpdate: json['forceUpdate'] == true,
      versionName: json['versionName']?.toString(),
      versionCode: _intValue(json['versionCode']),
      minSupportedVersionCode: _intValue(json['minSupportedVersionCode']),
      title: json['title']?.toString(),
      changelog: json['changelog']?.toString(),
      packageUrl: json['packageUrl']?.toString(),
      packageSize: _intValue(json['packageSize']),
      sha256: json['sha256']?.toString(),
      patchProvider: json['patchProvider']?.toString(),
      patchReleaseId: json['patchReleaseId']?.toString(),
      patchNo: _intValue(json['patchNo']),
      promptStrategy: json['promptStrategy']?.toString(),
    );
  }

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
