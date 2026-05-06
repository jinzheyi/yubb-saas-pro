import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/bootstrap/app_bootstrap.dart';
import 'package:shengyu_ui_admin_im/features/login/presentation/pages/login_page.dart';

void main() {
  testWidgets('app bootstrap renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AppBootstrap()));

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
