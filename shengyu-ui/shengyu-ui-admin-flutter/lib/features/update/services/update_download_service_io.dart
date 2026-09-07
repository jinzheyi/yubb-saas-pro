import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shengyu_ui_admin_im/features/update/services/update_download_service_base.dart';

UpdateDownloadService createUpdateDownloadService() {
  return IoUpdateDownloadService();
}

class IoUpdateDownloadService implements UpdateDownloadService {
  IoUpdateDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<void> openOrInstall({
    required String url,
    String? sha256,
    void Function(int received, int total)? onProgress,
  }) async {
    if (!Platform.isAndroid || !url.toLowerCase().contains('.apk')) {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw StateError('无法打开更新地址');
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final filename = _filenameFromUrl(url);
    final savePath = p.join(dir.path, filename);
    await _dio.download(url, savePath, onReceiveProgress: onProgress);
    if (sha256 != null && sha256.trim().isNotEmpty) {
      await _verifySha256(savePath, sha256);
    }
    final result = await OpenFilex.open(
      savePath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }

  String _filenameFromUrl(String url) {
    final uri = Uri.parse(url);
    final segment = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (segment.toLowerCase().endsWith('.apk')) return segment;
    return 'yuxin-update.apk';
  }

  Future<void> _verifySha256(String path, String expected) async {
    final file = File(path);
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() != expected.trim().toLowerCase()) {
      try {
        await file.delete();
      } catch (_) {
        // Ignore cleanup failures; checksum mismatch is the real user-facing error.
      }
      throw StateError('安装包校验失败，请重试');
    }
  }
}
