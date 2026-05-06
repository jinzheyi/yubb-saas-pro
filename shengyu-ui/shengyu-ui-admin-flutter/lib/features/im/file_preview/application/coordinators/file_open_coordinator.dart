import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_capability.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/resolved_file_open_plan.dart';

class FileOpenCoordinator {
  const FileOpenCoordinator();

  ResolvedFileOpenPlan resolve({
    required FilePreviewDescriptor descriptor,
    required FileCapability capability,
  }) {
    switch (descriptor.renderStrategy) {
      case FileRenderStrategy.nativePdf:
      case FileRenderStrategy.nativeImage:
      case FileRenderStrategy.nativeVideo:
      case FileRenderStrategy.nativeAudio:
      case FileRenderStrategy.nativeText:
      case FileRenderStrategy.nativeMarkdown:
      case FileRenderStrategy.serverConvertedPdf:
      case FileRenderStrategy.serverConvertedHtml:
        if (capability.canNativeRender || _isServerSideRender(descriptor)) {
          return ResolvedFileOpenPlan.inPage(
            renderStrategy: descriptor.renderStrategy,
            resolvedUrl:
                descriptor.previewUrl ??
                descriptor.convertedPdfUrl ??
                descriptor.downloadUrl,
          );
        }
        return ResolvedFileOpenPlan.downloadOnly(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl:
              descriptor.downloadUrl ??
              descriptor.previewUrl ??
              descriptor.convertedPdfUrl ??
              descriptor.viewerUrl,
          fallbackMessage: descriptor.message,
        );
      case FileRenderStrategy.embeddedOfficeViewer:
        return ResolvedFileOpenPlan.embedded(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl:
              descriptor.viewerUrl ??
              descriptor.previewUrl ??
              descriptor.convertedPdfUrl ??
              descriptor.downloadUrl,
        );
      case FileRenderStrategy.downloadOnly:
        return ResolvedFileOpenPlan.downloadOnly(
          renderStrategy: descriptor.renderStrategy,
          resolvedUrl:
              descriptor.downloadUrl ??
              descriptor.previewUrl ??
              descriptor.convertedPdfUrl ??
              descriptor.viewerUrl,
          fallbackMessage: descriptor.message,
        );
    }
  }

  bool _isServerSideRender(FilePreviewDescriptor descriptor) {
    return descriptor.renderStrategy == FileRenderStrategy.serverConvertedPdf ||
        descriptor.renderStrategy == FileRenderStrategy.serverConvertedHtml;
  }
}
