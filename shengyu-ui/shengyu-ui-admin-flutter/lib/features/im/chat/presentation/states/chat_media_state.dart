import 'package:shengyu_ui_admin_im/core/error/app_error.dart';

class ChatMediaState {
  const ChatMediaState({this.isPicking = false, this.error});

  final bool isPicking;
  final AppError? error;

  ChatMediaState copyWith({bool? isPicking, AppError? error}) {
    return ChatMediaState(isPicking: isPicking ?? this.isPicking, error: error);
  }
}
