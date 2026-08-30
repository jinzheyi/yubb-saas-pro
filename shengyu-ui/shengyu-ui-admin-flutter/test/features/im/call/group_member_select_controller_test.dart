import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/group_member_select_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';

void main() {
  GroupMember member(int id) => GroupMember(
    userId: '$id',
    userName: 'user$id',
    nickname: '成员$id',
    role: 0,
  );

  test('uses user id and reports the eight member limit', () {
    final controller = GroupMemberSelectController(
      existingMemberIds: const [],
      maxParticipants: 8,
      currentUserId: 'self',
    );
    for (var index = 0; index < 8; index++) {
      expect(
        controller.toggleMember(member(index)),
        GroupMemberToggleResult.selected,
      );
    }
    expect(
      controller.toggleMember(member(8)),
      GroupMemberToggleResult.limitReached,
    );
    expect(controller.currentState.selectedMembers, hasLength(8));
    expect(
      controller.toggleMember(member(0)),
      GroupMemberToggleResult.unselected,
    );
  });

  test('search does not change selection and filters current user', () {
    final controller = GroupMemberSelectController(
      existingMemberIds: const [],
      maxParticipants: 8,
      currentUserId: '1',
    );
    controller.toggleMember(member(2));
    controller.setSearchQuery('成员2');
    expect(
      controller
          .filterMembers([member(1), member(2)])
          .map((item) => item.userId),
      ['2'],
    );
    expect(controller.currentState.selectedMembers, hasLength(1));
  });
}
