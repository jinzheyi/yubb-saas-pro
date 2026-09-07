import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shengyu_ui_admin_im/features/update/data/update_api.dart';
import 'package:shengyu_ui_admin_im/features/update/domain/app_update_info.dart';
import 'package:shengyu_ui_admin_im/features/update/services/update_download_service.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final updateControllerProvider =
    StateNotifierProvider<UpdateController, AsyncValue<AppUpdateInfo?>>((ref) {
      return UpdateController(
        api: ref.read(updateApiProvider),
        downloadService: ref.read(updateDownloadServiceProvider),
      );
    });

final updateDownloadProgressProvider = StateProvider<double?>((ref) => null);

class UpdateController extends StateNotifier<AsyncValue<AppUpdateInfo?>> {
  UpdateController({
    required UpdateApi api,
    required UpdateDownloadService downloadService,
  }) : _api = api,
       _downloadService = downloadService,
       super(const AsyncValue.data(null));

  final UpdateApi _api;
  final UpdateDownloadService _downloadService;

  Future<AppUpdateInfo> check() async {
    state = const AsyncValue.loading();
    try {
      final info = await _api.checkUpdate();
      state = AsyncValue.data(info);
      return info;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> install(
    AppUpdateInfo info, {
    void Function(int received, int total)? onProgress,
  }) async {
    final url = info.packageUrl;
    if (url == null || url.trim().isEmpty) {
      throw StateError('未配置更新地址');
    }
    await _downloadService.openOrInstall(
      url: url,
      sha256: info.sha256,
      onProgress: onProgress,
    );
  }
}
