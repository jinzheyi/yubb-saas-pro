import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class AcceptCallUseCase {
  const AcceptCallUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required String callSessionId}) {
    return _repository.accept(callSessionId: callSessionId);
  }
}
