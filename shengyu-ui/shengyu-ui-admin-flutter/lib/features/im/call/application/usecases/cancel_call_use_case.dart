import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class CancelCallUseCase {
  const CancelCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required String callSessionId}) {
    return _repository.cancel(callSessionId: callSessionId);
  }
}
