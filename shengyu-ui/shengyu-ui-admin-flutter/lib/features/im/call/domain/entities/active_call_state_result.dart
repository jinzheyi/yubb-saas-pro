import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

class ActiveCallStateResult {
  const ActiveCallStateResult({
    required this.pageStatus,
    this.elapsedSeconds = 0,
    this.callSessionId = '',
    this.chatId = '',
    this.callType,
    this.title,
    this.callerProfile,
    this.calleeProfile,
    this.acceptedDeviceId,
    this.roomBundle,
  });

  final CallPageStatus pageStatus;
  final int elapsedSeconds;
  final String callSessionId;
  final String chatId;
  final CallType? callType;
  final String? title;
  final CallParticipantProfile? callerProfile;
  final CallParticipantProfile? calleeProfile;
  final String? acceptedDeviceId;
  final RtcRoomBundle? roomBundle;
}
