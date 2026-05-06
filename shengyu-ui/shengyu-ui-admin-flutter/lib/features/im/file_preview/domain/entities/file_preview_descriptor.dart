import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';

class FilePreviewDescriptor {
  const FilePreviewDescriptor({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.extension,
    required this.fileSize,
    required this.renderStrategy,
    this.previewUrl,
    this.downloadUrl,
    this.viewerUrl,
    this.convertedPdfUrl,
    this.expiresAt,
    this.unstable = false,
    this.message,
  });

  final String fileId;
  final String fileName;
  final String mimeType;
  final String extension;
  final int fileSize;
  final FileRenderStrategy renderStrategy;
  final String? previewUrl;
  final String? downloadUrl;
  final String? viewerUrl;
  final String? convertedPdfUrl;
  final int? expiresAt;
  final bool unstable;
  final String? message;
}
