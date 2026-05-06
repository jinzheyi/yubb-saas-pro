import 'package:shengyu_ui_admin_im/app/config/app_config.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_result.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/file_http_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/dtos/upload_request_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/mappers/upload_result_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/services/upload_directory_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_render_strategy.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/infrastructure/mappers/file_open_strategy_response_dto_mapper.dart';

class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl(this._httpDataSource);

  final FileHttpDataSource _httpDataSource;

  @override
  Future<UploadResult> uploadAndCreateFile({
    required String taskId,
    required UploadPurpose purpose,
    required UploadScope scope,
    required String localUri,
    required String displayName,
    required String mimeType,
  }) async {
    final directory = UploadDirectoryResolver.resolve(
      purpose: purpose,
      scope: scope,
    );
    final dto = await _httpDataSource.uploadAndCreateFile(
      request: UploadRequestDto(
        localUri: localUri,
        fileName: displayName,
        directory: directory.value,
        fieldName: AppConfig.fileUploadFieldName,
        mimeType: mimeType,
      ),
    );
    return UploadResultMapper.toEntity(
      taskId: taskId,
      purpose: purpose,
      scope: scope,
      dto: dto,
    );
  }

  @override
  Future<FilePreviewDescriptor> getFilePreviewDescriptor(
    FilePreviewArgs args,
  ) async {
    if (args.fileId.trim().isEmpty) {
      final directUrl = args.fileUrl?.trim() ?? '';
      if (directUrl.isEmpty) {
        throw StateError('Missing fileId and fileUrl for file preview');
      }
      return FilePreviewDescriptor(
        fileId: '',
        fileName: args.fileName,
        mimeType: args.mimeType,
        extension: _extensionOf(args.fileName, directUrl),
        fileSize: args.fileSize,
        renderStrategy: _resolveDirectStrategy(args),
        previewUrl: directUrl,
        downloadUrl: directUrl,
        viewerUrl: directUrl,
      );
    }
    final dto = await _httpDataSource.getFileOpenStrategy(fileId: args.fileId);
    return FileOpenStrategyResponseDtoMapper.toEntity(args: args, dto: dto);
  }

  @override
  Future<Uri> getPresignedGetUrl({
    required String fileId,
    int expirationSeconds = AppConfig.filePreviewExpirationSeconds,
  }) {
    return _httpDataSource.getPresignedGetUrl(
      fileId: fileId,
      expirationSeconds: expirationSeconds,
    );
  }

  FileRenderStrategy _resolveDirectStrategy(FilePreviewArgs args) {
    final mime = args.mimeType.trim().toLowerCase();
    final extension = _extensionOf(args.fileName, args.fileUrl ?? '');
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

  String _extensionOf(String fileName, String rawUrl) {
    final normalizedName = fileName.trim();
    final nameIndex = normalizedName.lastIndexOf('.');
    if (nameIndex >= 0 && nameIndex < normalizedName.length - 1) {
      return normalizedName.substring(nameIndex + 1).toLowerCase();
    }
    final url = rawUrl.trim();
    if (url.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final pathIndex = path.lastIndexOf('.');
    if (pathIndex >= 0 && pathIndex < path.length - 1) {
      return path.substring(pathIndex + 1).toLowerCase();
    }
    return '';
  }
}
