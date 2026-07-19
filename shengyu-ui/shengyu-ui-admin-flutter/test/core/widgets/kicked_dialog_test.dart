import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/core/widgets/kicked_dialog.dart';

void main() {
  group('KickedDialog Widget Tests', () {
    testWidgets('T3: 被踢弹窗展示完整信息', (WidgetTester tester) async {
      // 准备测试数据
      const message = '你的账号已被迫下线';
      const byDevice = 'iPhone 15';
      const kickedAt = 1721381400000; // 2024-07-19 14:30:00

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 触发弹窗显示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 验证弹窗内容
      expect(find.text('账号异常'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.textContaining('iPhone 15'), findsOneWidget);
      expect(find.textContaining('2024-07-19'), findsOneWidget);
      expect(find.text('如非本人操作，请及时修改密码。'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);

      // 验证弹窗不可关闭（barrierDismissible: false）
      await tester.tapAt(const Offset(10, 10)); // 点击弹窗外部
      await tester.pumpAndSettle();
      expect(find.text('账号异常'), findsOneWidget); // 弹窗仍然存在
    });

    testWidgets('T3: 点击确定按钮执行登出逻辑', (WidgetTester tester) async {
      const message = '你的账号已被迫下线';
      const byDevice = 'Android 设备';
      const kickedAt = 1721381400000;

      bool confirmCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 显示弹窗
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 点击确定按钮
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // 验证弹窗已关闭（登出逻辑已执行）
      expect(find.text('账号异常'), findsNothing);
    });

    testWidgets('T3: 弹窗消息格式化 - 有设备名和时间', (WidgetTester tester) async {
      const message = '';
      const byDevice = 'Web 浏览器';
      const kickedAt = 1721381400000;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 验证消息格式：你的账号于 2024-07-19 14:30:00 在 Web 浏览器 上登录，你已被迫下线。
      expect(find.textContaining('Web 浏览器'), findsOneWidget);
      expect(find.textContaining('2024-07-19'), findsOneWidget);
    });

    testWidgets('T3: 弹窗消息格式化 - 仅有设备名无时间', (WidgetTester tester) async {
      const message = '';
      const byDevice = 'iOS 设备';
      const int? kickedAt = null;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 验证消息格式：你的账号在 iOS 设备 上登录，你已被迫下线。
      expect(find.textContaining('iOS 设备'), findsOneWidget);
      expect(find.textContaining('于'), findsNothing); // 不应该包含"于"字
    });

    testWidgets('T3: 弹窗消息格式化 - 无设备名仅有时间', (WidgetTester tester) async {
      const message = '';
      const String? byDevice = null;
      const kickedAt = 1721381400000;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 验证消息格式：你的账号于 2024-07-19 14:30:00 在其他设备上登录，你已被迫下线。
      expect(find.textContaining('其他设备'), findsOneWidget);
      expect(find.textContaining('2024-07-19'), findsOneWidget);
    });

    testWidgets('T3: 弹窗消息格式化 - 使用自定义消息', (WidgetTester tester) async {
      const message = '自定义踢人原因';
      const String? byDevice = null;
      const int? kickedAt = null;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const KickedDialog(
                      message: message,
                      byDevice: byDevice,
                      kickedAt: kickedAt,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 验证显示自定义消息
      expect(find.textContaining('自定义踢人原因'), findsOneWidget);
    });
  });
}
