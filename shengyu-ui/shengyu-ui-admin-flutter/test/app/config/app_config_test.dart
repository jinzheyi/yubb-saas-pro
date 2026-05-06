import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

void main() {
  group('AppConfig header policy', () {
    test('does not attach authorization header for public auth endpoints', () {
      expect(
        AppConfig.shouldAttachAuthorizationHeader('/system/auth/login'),
        isFalse,
      );
      expect(
        AppConfig.shouldAttachAuthorizationHeader(
          '/system/auth/refresh-token?refreshToken=abc',
        ),
        isFalse,
      );
    });

    test('attaches authorization header for protected endpoints', () {
      expect(
        AppConfig.shouldAttachAuthorizationHeader(
          '/system/auth/get-permission-info',
        ),
        isTrue,
      );
    });

    test(
      'does not attach tenant header for login but attaches for permission info',
      () {
        expect(
          AppConfig.shouldAttachTenantHeader('/system/auth/login'),
          isFalse,
        );
        expect(
          AppConfig.shouldAttachTenantHeader(
            '/system/auth/get-permission-info',
          ),
          isTrue,
        );
      },
    );
  });
}
