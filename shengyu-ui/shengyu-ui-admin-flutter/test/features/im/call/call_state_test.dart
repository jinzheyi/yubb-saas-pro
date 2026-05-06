import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

void main() {
  test('copyWith can clear error explicitly', () {
    const original = CallState(
      error: AppError(message: 'call failed'),
      pageStatus: CallPageStatus.failed,
    );

    final next = original.copyWith(
      error: null,
      pageStatus: CallPageStatus.loading,
    );

    expect(next.error, isNull);
    expect(next.pageStatus, CallPageStatus.loading);
  });
}
