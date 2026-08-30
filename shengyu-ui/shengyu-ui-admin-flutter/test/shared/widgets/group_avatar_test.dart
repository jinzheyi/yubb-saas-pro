import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/shared/widgets/group_avatar.dart';

void main() {
  Widget subject(GroupAvatarWidget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('uses the configured group avatar before member composite', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        GroupAvatarWidget.fromMembers(
          avatarUrl: 'https://example.com/group.png',
          fallbackName: '项目群',
          fallbackSeed: 'group-1',
          members: const [GroupAvatarMember(userId: 'member-1', name: '成员甲')],
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://example.com/group.png');
  });

  testWidgets('uses stable group-name fallback when members are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        GroupAvatarWidget.fromMembers(
          fallbackName: '项目群',
          fallbackSeed: 'group-1',
          members: const [],
        ),
      ),
    );

    expect(find.text('项目'), findsOneWidget);
    expect(find.text('?'), findsNothing);
  });

  testWidgets(
    'renders the supplied member sequence as the composite identity',
    (tester) async {
      await tester.pumpWidget(
        subject(
          GroupAvatarWidget.fromMembers(
            fallbackName: '项目群',
            fallbackSeed: 'group-1',
            members: const [
              GroupAvatarMember(userId: 'member-1', name: '甲'),
              GroupAvatarMember(userId: 'member-2', name: '乙'),
            ],
          ),
        ),
      );

      expect(find.text('甲'), findsOneWidget);
      expect(find.text('乙'), findsOneWidget);
    },
  );
}
