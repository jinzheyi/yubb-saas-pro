import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_purpose.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/upload_scope.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/services/upload_directory_resolver.dart';

void main() {
  test('resolves direct chat image directory', () {
    final directory = UploadDirectoryResolver.resolve(
      purpose: UploadPurpose.chatImage,
      scope: const UploadScope.directChat(chatId: 'c-100'),
    );

    expect(directory.value, 'im/chat/c-100/image');
  });

  test('resolves group chat file directory', () {
    final directory = UploadDirectoryResolver.resolve(
      purpose: UploadPurpose.chatFile,
      scope: const UploadScope.groupChat(groupId: 'g-9', chatId: 'c-9'),
    );

    expect(directory.value, 'im/group/g-9/file');
  });
}
