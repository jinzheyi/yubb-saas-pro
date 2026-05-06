import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_capability.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';

class FilePreviewCapabilityService {
  const FilePreviewCapabilityService();

  FileCapability resolve(FilePreviewDescriptor descriptor) {
    final hasResolvableUrl =
        descriptor.downloadUrl != null ||
        descriptor.previewUrl != null ||
        descriptor.convertedPdfUrl != null ||
        descriptor.viewerUrl != null;
    final canNativeRender = switch (descriptor.renderStrategy) {
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.nativeImage ||
      FileRenderStrategy.nativeVideo ||
      FileRenderStrategy.nativeAudio ||
      FileRenderStrategy.nativeText ||
      FileRenderStrategy.nativeMarkdown => true,
      _ => false,
    };
    final canSearchText = switch (descriptor.renderStrategy) {
      FileRenderStrategy.nativeText ||
      FileRenderStrategy.nativeMarkdown ||
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.serverConvertedPdf => true,
      _ => false,
    };
    final canPaginate = switch (descriptor.renderStrategy) {
      FileRenderStrategy.nativePdf ||
      FileRenderStrategy.serverConvertedPdf => true,
      _ => false,
    };

    return FileCapability(
      canNativeRender: canNativeRender,
      canSearchText: canSearchText,
      canPaginate: canPaginate,
      canShare: true,
      canDownload: hasResolvableUrl,
      canOpenExternal: hasResolvableUrl,
    );
  }
}
