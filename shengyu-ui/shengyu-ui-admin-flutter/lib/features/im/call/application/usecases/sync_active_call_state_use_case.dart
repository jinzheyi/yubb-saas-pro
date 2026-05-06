import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class SyncActiveCallStateUseCase {
  const SyncActiveCallStateUseCase(this._repository);

  final CallRepository _repository;

  Future<ActiveCallStateResult> execute({required String callSessionId}) {
    return _repository.syncState(callSessionId: callSessionId);
  }
}
