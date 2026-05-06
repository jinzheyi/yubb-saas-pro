import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/coordinators/file_open_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_download_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_external_opener_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_preview_capability_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_status.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/controllers/file_preview_controller.dart';

void main() {
  test('initialize resolves descriptor and rendering plan', () async {
    final controller = FilePreviewController(
      _FakeFileRepository(),
      const FileOpenCoordinator(),
      const FilePreviewCapabilityService(),
      const _FakeExternalOpenerService(),
      const _FakeFileDownloadService(),
    );

    await controller.initialize(
      const FilePreviewArgs(
        fileId: 'f-1',
        fileName: 'a.png',
        mimeType: 'image/png',
        fileSize: 100,
      ),
    );

    expect(controller.state.status, FilePreviewStatus.rendering);
    expect(controller.state.descriptor?.fileId, 'f-1');
    expect(controller.state.openPlan?.shouldOpenInPage, isTrue);
  });
}

class _FakeFileRepository implements FileRepository {
  @override
  Future<FilePreviewDescriptor> getFilePreviewDescriptor(
    FilePreviewArgs args,
  ) async {
    return FilePreviewDescriptor(
      fileId: args.fileId,
      fileName: args.fileName,
      mimeType: args.mimeType,
      extension: 'png',
      fileSize: args.fileSize,
      renderStrategy: FileRenderStrategy.nativeImage,
      previewUrl: 'https://example.com/a.png',
      downloadUrl: 'https://example.com/a.png',
    );
  }

  @override
  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = 600,
  }) async {
    return Uri.parse('https://example.com/$fileId');
  }

  @override
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
  }) {
    throw UnimplementedError();
  }
}

class _FakeExternalOpenerService implements FileExternalOpenerService {
  const _FakeExternalOpenerService();

  @override
  Future<void> open(Uri uri) async {}
}

class _FakeFileDownloadService implements FileDownloadService {
  const _FakeFileDownloadService();

  @override
  Future<File> download(Uri uri) {
    throw UnimplementedError();
  }
}
