import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/presentation/providers/chat_providers.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/coordinators/file_open_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_download_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_external_opener_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_preview_capability_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/controllers/file_preview_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/states/file_preview_state.dart';

final fileOpenCoordinatorProvider = Provider<FileOpenCoordinator>((ref) {
  return const FileOpenCoordinator();
});

final filePreviewCapabilityServiceProvider =
    Provider<FilePreviewCapabilityService>((ref) {
      return const FilePreviewCapabilityService();
    });

final fileExternalOpenerServiceProvider = Provider<FileExternalOpenerService>((
  ref,
) {
  return const UrlLauncherFileExternalOpenerService();
});

final fileDownloadServiceProvider = Provider<FileDownloadService>((ref) {
  return DioFileDownloadService(ref.read(dioProvider));
});

final filePreviewControllerProvider =
    StateNotifierProvider.autoDispose<FilePreviewController, FilePreviewState>((
      ref,
    ) {
      return FilePreviewController(
        ref.read(fileRepositoryProvider),
        ref.read(fileOpenCoordinatorProvider),
        ref.read(filePreviewCapabilityServiceProvider),
        ref.read(fileExternalOpenerServiceProvider),
        ref.read(fileDownloadServiceProvider),
      );
    });
