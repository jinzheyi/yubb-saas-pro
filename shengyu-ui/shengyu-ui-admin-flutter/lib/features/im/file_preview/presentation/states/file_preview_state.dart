import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_capability.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_action.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_args.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_descriptor.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/file_preview_status.dart';
import 'package:shengyu_ui_admin_im/features/im/file_preview/domain/entities/resolved_file_open_plan.dart';

class FilePreviewState {
  const FilePreviewState({
    this.args,
    this.status = FilePreviewStatus.initial,
    this.descriptor,
    this.openPlan,
    this.capability,
    this.pendingAction = FilePreviewAction.none,
    this.error,
  });

  final FilePreviewArgs? args;
  final FilePreviewStatus status;
  final FilePreviewDescriptor? descriptor;
  final ResolvedFileOpenPlan? openPlan;
  final FileCapability? capability;
  final FilePreviewAction pendingAction;
  final AppError? error;

  FilePreviewState copyWith({
    FilePreviewArgs? args,
    FilePreviewStatus? status,
    FilePreviewDescriptor? descriptor,
    ResolvedFileOpenPlan? openPlan,
    FileCapability? capability,
    FilePreviewAction? pendingAction,
    AppError? error,
  }) {
    return FilePreviewState(
      args: args ?? this.args,
      status: status ?? this.status,
      descriptor: descriptor ?? this.descriptor,
      openPlan: openPlan ?? this.openPlan,
      capability: capability ?? this.capability,
      pendingAction: pendingAction ?? this.pendingAction,
      error: error ?? this.error,
    );
  }
}
