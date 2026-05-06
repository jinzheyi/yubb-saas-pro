import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/coordinators/file_open_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_capability.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';

void main() {
  test('returns in-page plan for native image preview', () {
    final plan = const FileOpenCoordinator().resolve(
      descriptor: const FilePreviewDescriptor(
        fileId: 'f-1',
        fileName: 'a.png',
        mimeType: 'image/png',
        extension: 'png',
        fileSize: 12,
        renderStrategy: FileRenderStrategy.nativeImage,
        previewUrl: 'https://example.com/a.png',
      ),
      capability: const FileCapability(
        canNativeRender: true,
        canSearchText: false,
        canPaginate: false,
        canShare: true,
        canDownload: true,
        canOpenExternal: true,
      ),
    );

    expect(plan.shouldOpenInPage, isTrue);
    expect(plan.resolvedUrl, 'https://example.com/a.png');
  });

  test('returns download-only plan when capability cannot render', () {
    final plan = const FileOpenCoordinator().resolve(
      descriptor: const FilePreviewDescriptor(
        fileId: 'f-2',
        fileName: 'a.bin',
        mimeType: 'application/octet-stream',
        extension: 'bin',
        fileSize: 12,
        renderStrategy: FileRenderStrategy.nativeText,
        downloadUrl: 'https://example.com/a.bin',
      ),
      capability: const FileCapability(
        canNativeRender: false,
        canSearchText: false,
        canPaginate: false,
        canShare: true,
        canDownload: true,
        canOpenExternal: true,
      ),
    );

    expect(plan.shouldDownloadOnly, isTrue);
    expect(plan.resolvedUrl, 'https://example.com/a.bin');
  });
}
