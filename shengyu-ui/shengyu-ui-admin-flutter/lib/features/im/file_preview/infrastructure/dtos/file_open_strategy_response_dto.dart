class FileOpenStrategyResponseDto {
  const FileOpenStrategyResponseDto({
    required this.renderStrategy,
    required this.contentType,
    this.previewUrl,
    this.downloadUrl,
    this.viewerUrl,
    this.convertedPdfUrl,
    this.expiresAt,
    this.unstable = false,
    this.message,
    this.action,
    this.url,
  });

  final String renderStrategy;
  final String contentType;
  final String? previewUrl;
  final String? downloadUrl;
  final String? viewerUrl;
  final String? convertedPdfUrl;
  final int? expiresAt;
  final bool unstable;
  final String? message;
  final String? action;
  final String? url;

  factory FileOpenStrategyResponseDto.fromJson(Map<String, dynamic> json) {
    return FileOpenStrategyResponseDto(
      renderStrategy:
          json['renderStrategy']?.toString() ??
          json['strategy']?.toString() ??
          '',
      contentType:
          json['contentType']?.toString() ??
          json['mimeType']?.toString() ??
          json['fileType']?.toString() ??
          '',
      previewUrl:
          json['previewUrl']?.toString() ?? json['previewLink']?.toString(),
      downloadUrl:
          json['downloadUrl']?.toString() ?? json['downloadLink']?.toString(),
      viewerUrl: json['viewerUrl']?.toString() ?? json['viewUrl']?.toString(),
      convertedPdfUrl:
          json['convertedPdfUrl']?.toString() ??
          json['pdfUrl']?.toString() ??
          json['convertedUrl']?.toString(),
      expiresAt: _toInt(json['expiresAt'] ?? json['expireAt']),
      unstable: _toBool(json['unstable'] ?? json['isUnstable']),
      message: json['message']?.toString(),
      action: json['action']?.toString(),
      url:
          json['url']?.toString() ??
          json['openUrl']?.toString() ??
          json['fileUrl']?.toString(),
    );
  }

  static int? _toInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('${value ?? ''}');
  }

  static bool _toBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1';
  }
}
