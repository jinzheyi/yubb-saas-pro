import 'package:flutter/foundation.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_socket_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_dto_mapper.dart';

class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(
    this._remoteDataSource,
    this._socketDataSource,
    this._mapper,
  );

  final CallRemoteDataSource _remoteDataSource;
  final CallSocketDataSource _socketDataSource;
  final CallDtoMapper _mapper;

  /// 校验 callSessionId 非空
  void _validateCallSessionId(String callSessionId, String method) {
    if (callSessionId.isEmpty) {
      debugPrint('[CallRepository] $method: callSessionId 为空，跳过调用');
      throw ArgumentError('callSessionId 不能为空');
    }
  }

  @override
  Future<void> accept({required String callSessionId, required String deviceId}) async {
    _validateCallSessionId(callSessionId, 'accept');
    return _remoteDataSource.accept(callSessionId: callSessionId, deviceId: deviceId);
  }

  @override
  Future<void> cancel({required String callSessionId}) async {
    _validateCallSessionId(callSessionId, 'cancel');
    return _remoteDataSource.cancel(callSessionId: callSessionId);
  }

  @override
  Future<CallInviteResult> createInvite({
    required String chatId,
    required CallType callType,
    required String calleeId,
  }) async {
    final dto = await _remoteDataSource.createInvite(
      chatId: chatId,
      callType: _mapper.callTypeToServer(callType),
      calleeId: calleeId,
    );
    return _mapper.toInviteResult(dto);
  }

  @override
  Future<void> hangup({required String callSessionId}) async {
    _validateCallSessionId(callSessionId, 'hangup');
    return _remoteDataSource.hangup(callSessionId: callSessionId);
  }

  @override
  Future<CallInviteResult> createGroupInvite({
    required String chatId,
    required String groupId,
    required CallType callType,
    required List<String> inviteeIds,
    String? deviceId,
  }) async {
    final dto = await _remoteDataSource.createGroupInvite(
      chatId: chatId,
      groupId: groupId,
      callType: _mapper.callTypeToServer(callType),
      inviteeIds: inviteeIds,
      deviceId: deviceId,
    );
    return _mapper.toInviteResult(dto);
  }

  @override
  Future<Map<String, dynamic>> inviteGroupMembers({
    required String callSessionId, required String groupId, required List<String> inviteeIds,
  }) => _remoteDataSource.inviteGroupMembers(
    callSessionId: callSessionId, groupId: groupId, inviteeIds: inviteeIds);

  @override
  Future<void> leaveGroupCall({required String callSessionId}) async {
    _validateCallSessionId(callSessionId, 'leaveGroupCall');
    return _remoteDataSource.leaveGroupCall(callSessionId: callSessionId);
  }

  @override
  Future<void> reject({required String callSessionId}) async {
    _validateCallSessionId(callSessionId, 'reject');
    return _remoteDataSource.reject(callSessionId: callSessionId);
  }

  @override
  Future<ActiveCallStateResult> syncState({
    required String callSessionId,
  }) async {
    _validateCallSessionId(callSessionId, 'syncState');
    final dto = await _remoteDataSource.syncState(callSessionId: callSessionId);
    return _mapper.toActiveStateResult(dto);
  }

  @override
  Stream<CallSocketEvent> watchSocketEvents() {
    return _socketDataSource.watchEvents().map(_mapper.toSocketEvent);
  }

  @override
  Future<List<CallRecord>> getCallRecords({
    int? callType,
    DateTime? startTime,
    DateTime? endTime,
    String? chatId,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    try {
      final dtos = await _remoteDataSource.getCallRecords(
        callType: callType,
        startTime: startTime,
        endTime: endTime,
        chatId: chatId,
        pageNo: pageNo,
        pageSize: pageSize,
      );
      return dtos.map(_mapper.toCallRecord).toList();
    } catch (e) {
      debugPrint('[CallRepository] getCallRecords 失败: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendMediaStateUpdate({
    required String callSessionId,
    required bool cameraEnabled,
    required bool microphoneEnabled,
  }) {
    return _remoteDataSource.sendMediaStateUpdate(
      callSessionId: callSessionId,
      cameraEnabled: cameraEnabled,
      microphoneEnabled: microphoneEnabled,
    );
  }
}
