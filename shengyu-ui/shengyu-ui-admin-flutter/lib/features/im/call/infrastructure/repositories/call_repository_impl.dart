import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
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

  @override
  Future<void> accept({required String callSessionId}) {
    return _remoteDataSource.accept(callSessionId: callSessionId);
  }

  @override
  Future<void> cancel({required String callSessionId}) {
    return _remoteDataSource.cancel(callSessionId: callSessionId);
  }

  @override
  Future<CallInviteResult> createInvite({
    required String chatId,
    required CallType callType,
  }) async {
    final dto = await _remoteDataSource.createInvite(
      chatId: chatId,
      callType: _mapper.callTypeToServer(callType),
    );
    return _mapper.toInviteResult(dto);
  }

  @override
  Future<void> hangup({required String callSessionId}) {
    return _remoteDataSource.hangup(callSessionId: callSessionId);
  }

  @override
  Future<void> reject({required String callSessionId}) {
    return _remoteDataSource.reject(callSessionId: callSessionId);
  }

  @override
  Future<ActiveCallStateResult> syncState({
    required String callSessionId,
  }) async {
    final dto = await _remoteDataSource.syncState(callSessionId: callSessionId);
    return _mapper.toActiveStateResult(dto);
  }

  @override
  Stream<CallSocketEvent> watchSocketEvents() {
    return _socketDataSource.watchEvents().map(_mapper.toSocketEvent);
  }
}
