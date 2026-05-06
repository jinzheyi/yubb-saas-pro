import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';

class CallInviteResult {
  const CallInviteResult({
    required this.callSessionId,
    this.inviteId,
    this.chatId = '',
    this.callType,
    this.title,
    this.callerProfile,
    this.calleeProfile,
  });

  final String callSessionId;
  final String? inviteId;
  final String chatId;
  final CallType? callType;
  final String? title;
  final CallParticipantProfile? callerProfile;
  final CallParticipantProfile? calleeProfile;
}
