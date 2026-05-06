class FileCapability {
  const FileCapability({
    required this.canNativeRender,
    required this.canSearchText,
    required this.canPaginate,
    required this.canShare,
    required this.canDownload,
    required this.canOpenExternal,
  });

  final bool canNativeRender;
  final bool canSearchText;
  final bool canPaginate;
  final bool canShare;
  final bool canDownload;
  final bool canOpenExternal;
}
