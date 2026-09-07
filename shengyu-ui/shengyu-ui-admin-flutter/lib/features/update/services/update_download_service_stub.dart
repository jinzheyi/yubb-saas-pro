import 'package:url_launcher/url_launcher.dart';
import 'package:shengyu_ui_admin_im/features/update/services/update_download_service_base.dart';

UpdateDownloadService createUpdateDownloadService() {
  return const BrowserUpdateDownloadService();
}

class BrowserUpdateDownloadService implements UpdateDownloadService {
  const BrowserUpdateDownloadService();

  @override
  Future<void> openOrInstall({
    required String url,
    String? sha256,
    void Function(int received, int total)? onProgress,
  }) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw StateError('无法打开更新地址');
    }
  }
}
