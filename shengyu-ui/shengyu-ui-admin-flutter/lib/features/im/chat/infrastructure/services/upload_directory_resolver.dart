import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_directory.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';

abstract final class UploadDirectoryResolver {
  static UploadDirectory resolve({
    required UploadPurpose purpose,
    required UploadScope scope,
  }) {
    return switch (scope.kind) {
      UploadScopeKind.directChat => UploadDirectory(
        'im/chat/${scope.requireChatId()}/${_leaf(purpose)}',
      ),
      UploadScopeKind.groupChat => UploadDirectory(
        'im/group/${scope.groupId ?? ''}/${_leaf(purpose)}',
      ),
      UploadScopeKind.profile => UploadDirectory(
        'profile/avatar/${scope.userId ?? ''}',
      ),
      UploadScopeKind.sticker => UploadDirectory(
        'im/sticker/${scope.userId ?? ''}',
      ),
    };
  }

  static String _leaf(UploadPurpose purpose) {
    return switch (purpose) {
      UploadPurpose.chatImage => 'image',
      UploadPurpose.chatVideo => 'video',
      UploadPurpose.chatFile => 'file',
      UploadPurpose.chatVoice => 'voice',
      UploadPurpose.avatar => 'avatar',
      UploadPurpose.stickerOriginal || UploadPurpose.stickerThumb => 'sticker',
    };
  }
}
