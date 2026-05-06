import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/infrastructure/datasources/message_remote_data_source.dart';

void main() {
  test('forward messages parses success count from list payload', () async {
    final dataSource = MessageRemoteDataSource(
      dio: _buildDioWithData({
        'code': 200,
        'msg': 'ok',
        'data': [
          {'messageId': '1'},
          {'messageId': '2'},
        ],
      }),
    );

    final count = await dataSource.forwardMessages(
      targetChatId: 'chat-1',
      messageIds: const ['m-1', 'm-2'],
    );

    expect(count, 2);
  });

  test(
    'forward messages parses success count from messageIds payload',
    () async {
      final dataSource = MessageRemoteDataSource(
        dio: _buildDioWithData({
          'code': 200,
          'msg': 'ok',
          'data': {
            'messageIds': ['1', '2', '3'],
          },
        }),
      );

      final count = await dataSource.forwardMessages(
        targetChatId: 'chat-1',
        messageIds: const ['m-1', 'm-2', 'm-3'],
        forwardType: 1,
      );

      expect(count, 3);
    },
  );

  test(
    'forward messages parses success count from scalar count payload',
    () async {
      final dataSource = MessageRemoteDataSource(
        dio: _buildDioWithData({
          'code': 200,
          'msg': 'ok',
          'data': {'count': 1},
        }),
      );

      final count = await dataSource.forwardMessages(
        targetChatId: 'chat-1',
        messageIds: const ['m-1', 'm-2'],
        forwardType: 2,
      );

      expect(count, 1);
    },
  );

  test(
    'forward messages returns null when backend payload has no count shape',
    () async {
      final dataSource = MessageRemoteDataSource(
        dio: _buildDioWithData({
          'code': 200,
          'msg': 'ok',
          'data': {'unexpected': true},
        }),
      );

      final count = await dataSource.forwardMessages(
        targetChatId: 'chat-1',
        messageIds: const ['m-1'],
      );

      expect(count, isNull);
    },
  );
}

Dio _buildDioWithData(Map<String, dynamic> payload) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: payload,
            statusCode: 200,
          ),
        );
      },
    ),
  );
  return dio;
}
