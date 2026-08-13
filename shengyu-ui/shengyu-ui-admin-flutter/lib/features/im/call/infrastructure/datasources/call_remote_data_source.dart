import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/core/network/api_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_record_dto.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_session_dto.dart';

class CallRemoteDataSource {
  CallRemoteDataSource({required this.dio});

  final Dio dio;

  Future<CallSessionDto> createInvite({
    required String chatId,
    required String callType,
    required String calleeId,
  }) async {
    try {
      final response = await dio.post(
        '/system/im/call/create-invite',
        data: {
          'chatId': chatId,
          'callType': callType,
          'calleeId': calleeId,
        },
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
    } catch (e) {
      debugPrint('[CallRemoteDataSource] createInvite 失败: $e');
      rethrow;
    }
  }

  Future<void> accept({required String callSessionId, required String deviceId}) async {
    try {
      await dio.post(
        '/system/im/call/accept',
        data: {'callSessionId': callSessionId, 'deviceId': deviceId},
      );
    } catch (e) {
      debugPrint('[CallRemoteDataSource] accept 失败: $e');
      rethrow;
    }
  }

  Future<void> reject({required String callSessionId}) async {
    try {
      await dio.post(
        '/system/im/call/reject',
        data: {'callSessionId': callSessionId},
      );
    } catch (e) {
      debugPrint('[CallRemoteDataSource] reject 失败: $e');
      rethrow;
    }
  }

  Future<void> cancel({required String callSessionId}) async {
    // 防护性检查：如果 callSessionId 为空，不调用后端 API
    if (callSessionId.isEmpty) {
      debugPrint('[CallRemoteDataSource] cancel: callSessionId is empty, skip API call');
      return;
    }
    try {
      await dio.post(
        '/system/im/call/cancel',
        data: {'callSessionId': callSessionId},
      );
    } catch (e) {
      debugPrint('[CallRemoteDataSource] cancel 失败: $e');
      rethrow;
    }
  }

  Future<void> hangup({required String callSessionId}) async {
    try {
      await dio.post(
        '/system/im/call/hangup',
        data: {'callSessionId': callSessionId},
      );
    } catch (e) {
      debugPrint('[CallRemoteDataSource] hangup 失败: $e');
      rethrow;
    }
  }

  Future<CallSessionDto> createGroupInvite({
    required String chatId,
    required String groupId,
    required String callType,
    required List<String> inviteeIds,
    String? deviceId,
  }) async {
    final response = await dio.post('/system/im/call/group/create-invite', data: {
      'chatId': chatId,
      'groupId': groupId,
      'callType': callType,
      'inviteeIds': inviteeIds,
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
    });
    return ApiResult.fromJson<CallSessionDto>(response.data as Map<String, dynamic>,
      dataParser: (raw) => CallSessionDto.fromJson(raw as Map<String, dynamic>? ?? const {}),
    ).requireData();
  }

  Future<Map<String, dynamic>> inviteGroupMembers({
    required String callSessionId, required String groupId, required List<String> inviteeIds,
  }) async {
    final response = await dio.post('/system/im/call/group/invite', data: {
      'callSessionId': callSessionId, 'groupId': groupId, 'inviteeIds': inviteeIds,
    });
    return ApiResult.fromJson<Map<String, dynamic>>(response.data as Map<String, dynamic>,
      dataParser: (raw) => raw as Map<String, dynamic>? ?? const {},
    ).requireData();
  }

  Future<void> leaveGroupCall({required String callSessionId}) async {
    await dio.post(
      '/system/im/call/group/leave',
      data: {'callSessionId': callSessionId},
    );
  }

  Future<CallSessionDto> syncState({required String callSessionId}) async {
    try {
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
    } catch (e) {
      debugPrint('[CallRemoteDataSource] syncState 失败: $e');
      rethrow;
    }
  }

  /// 分页查询通话记录
  Future<List<CallRecordDto>> getCallRecords({
    int? callType,
    DateTime? startTime,
    DateTime? endTime,
    String? chatId,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNo': pageNo,
      'pageSize': pageSize,
    };

    if (callType != null) {
      queryParameters['callType'] = callType;
    }
    if (startTime != null) {
      queryParameters['startTime'] = startTime.toIso8601String();
    }
    if (endTime != null) {
      queryParameters['endTime'] = endTime.toIso8601String();
    }
    if (chatId != null && chatId.isNotEmpty) {
      queryParameters['chatId'] = chatId;
    }

    final response = await dio.get(
      '/system/im/call/records/page',
      queryParameters: queryParameters,
    );

    final result = ApiResult.fromJson<List<CallRecordDto>>(
      response.data as Map<String, dynamic>,
      dataParser: (raw) {
        final list = raw as List<dynamic>? ?? [];
        return list
            .map((e) => CallRecordDto.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
    return result.requireData();
  }

  /// 发送媒体状态更新（摄像头/麦克风开关状态）
  ///
  /// 用于通知对端当前用户的媒体状态变化
  Future<void> sendMediaStateUpdate({
    required String callSessionId,
    required bool cameraEnabled,
    required bool microphoneEnabled,
  }) async {
    await dio.post(
      '/system/im/call/media-state/update',
      data: {
        'callSessionId': callSessionId,
        'cameraEnabled': cameraEnabled,
        'microphoneEnabled': microphoneEnabled,
      },
    );
  }
}

