import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/group_call_member_select_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/pages/group_call_member_select_page.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/domain/entities/group_member.dart';
import 'package:shengyu_ui_admin_im/features/im/group_settings/presentation/providers/group_settings_providers.dart';

void main() {
  const members = <GroupMember>[
    GroupMember(userId: 'self', userName: 'self', nickname: '我自己', role: 1),
    GroupMember(userId: '1', userName: 'zhangsan', nickname: '张三', role: 0),
    GroupMember(userId: '2', userName: 'lisi', nickname: '李四', role: 0),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    List<String> initialSelectedIds = const [],
    bool fails = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupMembersFutureProvider('group').overrideWith(
            (ref) => fails
                ? Future<List<GroupMember>>.error(StateError('raw error'))
                : Future.value(members),
          ),
        ],
        child: MaterialApp(
          home: GroupCallMemberSelectPage(
            args: GroupCallMemberSelectArgs(
              groupId: 'group',
              groupName: '项目群',
              callType: CallType.video,
              currentUserId: 'self',
              initialSelectedIds: initialSelectedIds,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('zero selection is disabled and current user is filtered', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('选择视频通话成员'), findsOneWidget);
    expect(find.text('确定(0)'), findsOneWidget);
    expect(find.text('我自己'), findsNothing);

    final memberRow = find.ancestor(
      of: find.text('张三').last,
      matching: find.byType(InkWell),
    );
    await tester.tap(memberRow.first);
    await tester.pump();
    expect(find.text('确定(1)'), findsOneWidget);
  });

  testWidgets('restores selection after busy launch returns', (tester) async {
    await pumpPage(tester, initialSelectedIds: const ['2']);
    expect(find.text('确定(1)'), findsOneWidget);
    expect(find.text('李四'), findsWidgets);
  });

  testWidgets('load failure hides raw error and offers retry', (tester) async {
    await pumpPage(tester, fails: true);
    expect(find.text('成员加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(find.textContaining('raw error'), findsNothing);
  });
}
