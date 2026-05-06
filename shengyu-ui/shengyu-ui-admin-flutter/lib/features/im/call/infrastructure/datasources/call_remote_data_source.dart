import 'package:dio/dio.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_session_dto.dart';

class CallRemoteDataSource {
  CallRemoteDataSource({required this.dio});

  final Dio dio;

  Future<CallSessionDto> createInvite({
    required String chatId,
    required String callType,
  }) async {
    final response = await dio.post(
      '/system/im/call/create-invite',
      data: {'chatId': chatId, 'callType': callType},
    );
    final result = ApiResult.fromJson<CallSessionDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return CallSessionDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }

  Future<void> accept({required String callSessionId}) async {
    await dio.post(
      '/system/im/call/accept',
      data: {'callSessionId': callSessionId},
    );
  }

  Future<void> reject({required String callSessionId}) async {
    await dio.post(
      '/system/im/call/reject',
      data: {'callSessionId': callSessionId},
    );
  }

  Future<void> cancel({required String callSessionId}) async {
    await dio.post(
      '/system/im/call/cancel',
      data: {'callSessionId': callSessionId},
    );
  }

  Future<void> hangup({required String callSessionId}) async {
    await dio.post(
      '/system/im/call/hangup',
      data: {'callSessionId': callSessionId},
    );
  }

  Future<CallSessionDto> syncState({required String callSessionId}) async {
    final response = await dio.get(
      '/system/im/call/state',
      queryParameters: {'callSessionId': callSessionId},
    );
    final result = ApiResult.fromJson<CallSessionDto>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        return CallSessionDto.fromJson(
          raw as Map<String, dynamic>? ?? const {},
        );
      },
    );
    return result.requireData();
  }
}
