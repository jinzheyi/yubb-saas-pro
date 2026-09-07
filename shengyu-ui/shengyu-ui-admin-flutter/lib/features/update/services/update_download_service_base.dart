abstract interface class UpdateDownloadService {
  Future<void> openOrInstall({
    required String url,
    String? sha256,
    void Function(int received, int total)? onProgress,
  });
}
