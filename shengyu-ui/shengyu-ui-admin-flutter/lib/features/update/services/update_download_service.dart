import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/features/update/services/update_download_service_base.dart';
import 'package:shengyu_ui_admin_im/features/update/services/update_download_service_stub.dart'
    if (dart.library.io) 'package:shengyu_ui_admin_im/features/update/services/update_download_service_io.dart';

export 'package:shengyu_ui_admin_im/features/update/services/update_download_service_base.dart';

final updateDownloadServiceProvider = Provider<UpdateDownloadService>((ref) {
  return createUpdateDownloadService();
});
