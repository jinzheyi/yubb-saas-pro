import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/infrastructure/dtos/file_open_strategy_response_dto.dart';

abstract final class FileOpenStrategyResponseDtoMapper {
  static FilePreviewDescriptor toEntity({
    required FilePreviewArgs args,
    required FileOpenStrategyResponseDto dto,
  }) {
    final resolvedMimeType = args.mimeType.trim().isNotEmpty
        ? args.mimeType
        : dto.contentType;
    final fallbackUrl = dto.url;
    return FilePreviewDescriptor(
      fileId: args.fileId,
      fileName: args.fileName,
      mimeType: resolvedMimeType,
      extension: _extensionOf(args.fileName),
      fileSize: args.fileSize,
      renderStrategy: _resolveStrategy(dto: dto, args: args),
      previewUrl: dto.previewUrl ?? fallbackUrl,
      downloadUrl: dto.downloadUrl ?? fallbackUrl,
      viewerUrl: dto.viewerUrl ?? dto.previewUrl ?? fallbackUrl,
      convertedPdfUrl: dto.convertedPdfUrl ?? dto.previewUrl ?? fallbackUrl,
      expiresAt: dto.expiresAt,
      unstable: dto.unstable,
      message: dto.message,
    );
  }

  static String _extensionOf(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index < 0 || index == fileName.length - 1) {
      return '';
    }
    return fileName.substring(index + 1).toLowerCase();
  }

  static FileRenderStrategy _resolveStrategy({
    required FileOpenStrategyResponseDto dto,
    required FilePreviewArgs args,
  }) {
    switch (dto.renderStrategy.toLowerCase()) {
      case 'nativepdf':
      case 'native_pdf':
      case 'pdf':
        return FileRenderStrategy.nativePdf;
      case 'nativeimage':
      case 'native_image':
      case 'image':
        return FileRenderStrategy.nativeImage;
      case 'nativevideo':
      case 'native_video':
      case 'video':
        return FileRenderStrategy.nativeVideo;
      case 'nativeaudio':
      case 'native_audio':
      case 'audio':
        return FileRenderStrategy.nativeAudio;
      case 'nativetext':
      case 'native_text':
      case 'text':
        return FileRenderStrategy.nativeText;
      case 'nativemarkdown':
      case 'native_markdown':
      case 'markdown':
        return FileRenderStrategy.nativeMarkdown;
      case 'serverconvertedpdf':
      case 'server_converted_pdf':
        return FileRenderStrategy.serverConvertedPdf;
      case 'serverconvertedhtml':
      case 'server_converted_html':
        return FileRenderStrategy.serverConvertedHtml;
      case 'embeddedofficeviewer':
      case 'embedded_office_viewer':
        return FileRenderStrategy.embeddedOfficeViewer;
      case 'downloadonly':
      case 'download_only':
        return FileRenderStrategy.downloadOnly;
    }

    if ((dto.action ?? '').toUpperCase() == 'DOWNLOAD') {
      return FileRenderStrategy.downloadOnly;
    }

    final mime =
        (args.mimeType.trim().isNotEmpty ? args.mimeType : dto.contentType)
            .toLowerCase();
    final extension = _extensionOf(args.fileName);
    if (mime.contains('pdf') || extension == 'pdf') {
      return FileRenderStrategy.nativePdf;
    }
    if (mime.startsWith('image/')) {
      return FileRenderStrategy.nativeImage;
    }
    if (mime.startsWith('video/')) {
      return FileRenderStrategy.nativeVideo;
    }
    if (mime.startsWith('audio/')) {
      return FileRenderStrategy.nativeAudio;
    }
    if (extension == 'md' || extension == 'markdown') {
      return FileRenderStrategy.nativeMarkdown;
    }
    if (mime.startsWith('text/')) {
      return FileRenderStrategy.nativeText;
    }
    return FileRenderStrategy.downloadOnly;
  }
}
