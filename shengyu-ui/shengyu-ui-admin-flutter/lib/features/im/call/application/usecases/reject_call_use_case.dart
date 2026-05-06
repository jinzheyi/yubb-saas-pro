import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class RejectCallUseCase {
  const RejectCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required String callSessionId}) {
    return _repository.reject(callSessionId: callSessionId);
  }
}
