import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/repositories/file_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/coordinators/file_open_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_download_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_external_opener_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/application/services/file_preview_capability_service.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_action.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_status.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/presentation/states/file_preview_state.dart';

class FilePreviewController extends StateNotifier<FilePreviewState> {
  FilePreviewController(
    this._fileRepository,
    this._fileOpenCoordinator,
    this._capabilityService,
    this._externalOpenerService,
    this._downloadService,
  ) : super(const FilePreviewState());

  final FileRepository _fileRepository;
  final FileOpenCoordinator _fileOpenCoordinator;
  final FilePreviewCapabilityService _capabilityService;
  final FileExternalOpenerService _externalOpenerService;
  final FileDownloadService _downloadService;

  Future<void> initialize(FilePreviewArgs args) async {
    state = FilePreviewState(
      args: args,
      status: FilePreviewStatus.loadingStrategy,
    );

    try {
      final descriptor = await _fileRepository.getFilePreviewDescriptor(args);
      final capability = _capabilityService.resolve(descriptor);
      final openPlan = _fileOpenCoordinator.resolve(
        descriptor: descriptor,
        capability: capability,
      );

      state = state.copyWith(
        descriptor: descriptor,
        capability: capability,
        openPlan: openPlan,
        status: openPlan.shouldDownloadOnly
            ? FilePreviewStatus.downloadOnly
            : FilePreviewStatus.rendering,
      );
    } catch (error, stackTrace) {
      state = state.copyWith(
        status: FilePreviewStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }

  Future<void> retry() async {
    final args = state.args;
    if (args == null) {
      return;
    }
    state = state.copyWith(pendingAction: FilePreviewAction.retrying);
    await initialize(args);
    state = state.copyWith(pendingAction: FilePreviewAction.none);
  }

  Future<void> download() async {
    final uri = await _resolveDownloadUri();
    if (uri == null) {
      return;
    }

    state = state.copyWith(pendingAction: FilePreviewAction.downloading);
    try {
      await _downloadService.download(uri);
    } finally {
      state = state.copyWith(pendingAction: FilePreviewAction.none);
    }
  }

  Future<void> openExternal() async {
    final rawUrl = _resolveBestUrl();
    if (rawUrl == null || rawUrl.isEmpty) {
      return;
    }

    state = state.copyWith(pendingAction: FilePreviewAction.openingExternal);
    try {
      await _externalOpenerService.open(Uri.parse(rawUrl));
    } finally {
      state = state.copyWith(pendingAction: FilePreviewAction.none);
    }
  }

  Future<Uri?> _resolveDownloadUri() async {
    final descriptor = state.descriptor;
    if (descriptor == null) {
      return null;
    }
    final directUrl =
        descriptor.downloadUrl ??
        descriptor.previewUrl ??
        descriptor.convertedPdfUrl ??
        descriptor.viewerUrl;
    if (directUrl != null && directUrl.isNotEmpty) {
      return Uri.parse(directUrl);
    }
    return _fileRepository.getPresignedGetUrl(fileId: descriptor.fileId);
  }

  String? _resolveBestUrl() {
    final descriptor = state.descriptor;
    return state.openPlan?.resolvedUrl ??
        descriptor?.downloadUrl ??
        descriptor?.previewUrl ??
        descriptor?.convertedPdfUrl ??
        descriptor?.viewerUrl;
  }
}
