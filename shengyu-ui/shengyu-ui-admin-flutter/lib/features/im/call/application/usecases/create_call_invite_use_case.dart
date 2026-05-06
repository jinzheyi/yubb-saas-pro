import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_invite_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';

class CreateCallInviteUseCase {
  const CreateCallInviteUseCase(this._repository);

  final CallRepository _repository;

  Future<CallInviteResult> execute({
    required String chatId,
    required CallType callType,
  }) {
    return _repository.createInvite(chatId: chatId, callType: callType);
  }
}
