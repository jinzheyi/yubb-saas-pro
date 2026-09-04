import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_record_message.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/models/call_record_display_text.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 兼容既有调用点；实际规则统一由 [callRecordDisplayText] 管理。
String groupCallRecordText({
  required AppLocalizations strings,
  required String callerName,
  required bool isVideo,
  required int status,
  required int durationSeconds,
}) => callRecordDisplayText(
  strings: strings,
  callType: isVideo ? CallType.video : CallType.audio,
  status: CallStatus.fromValue(status),
  durationSeconds: durationSeconds,
  isGroupCall: true,
  isOutgoing: false,
  callerName: callerName,
);
