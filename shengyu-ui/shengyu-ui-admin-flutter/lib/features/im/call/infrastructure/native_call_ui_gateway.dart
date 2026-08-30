import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';

enum NativeCallActionType { accept, decline, ended, timeout }

class NativeCallAction {
  const NativeCallAction(this.type, this.args);
  final NativeCallActionType type;
  final CallLaunchArgs args;
}

/// Android 全屏来电与 iOS CallKit 的唯一适配器。
/// 推送只负责唤醒并提供 callId，业务接听/拒绝仍必须回到 REST API 裁决。
class NativeCallUiGateway {
  NativeCallUiGateway() {
    if (supported) {
      _eventSubscription = FlutterCallkitIncoming.onEvent.listen(_onEvent);
    }
  }

  final _actions = StreamController<NativeCallAction>.broadcast();
  final Map<String, CallLaunchArgs> _calls = <String, CallLaunchArgs>{};
  StreamSubscription<CallEvent?>? _eventSubscription;

  Stream<NativeCallAction> get actions => _actions.stream;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> showIncoming(CallLaunchArgs args) async {
    if (!supported || args.callSessionId.isEmpty) return;
    final nativeId = _nativeId(args.callSessionId);
    _calls[nativeId] = args;
    await FlutterCallkitIncoming.showCallkitIncoming(
      CallKitParams(
        id: nativeId,
        nameCaller: args.isGroupCall
            ? args.conversationTitle ?? '${args.callerName ?? '成员'} · 群通话'
            : args.conversationTitle ?? args.callerName ?? args.title ?? '来电',
        appName: '圣钰 IM',
        handle: args.fromUserId ?? args.callSessionId,
        type: args.callType == CallType.video ? 1 : 0,
        duration: 30000,
        extra: encodeArgs(args),
        missedCallNotification: const NotificationParams(
          showNotification: true,
          isShowCallback: false,
          subtitle: '未接来电',
        ),
        android: const AndroidParams(
          isCustomNotification: true,
          isShowFullLockedScreen: true,
          isFullScreen: true,
          isImportant: true,
          ringtonePath: 'call_ringtone',
          incomingCallNotificationChannelName: '音视频来电',
          missedCallNotificationChannelName: '未接来电',
          textAccept: '接听',
          textDecline: '拒绝',
        ),
        ios: IOSParams(
          handleType: 'generic',
          supportsVideo: args.callType == CallType.video,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          supportsDTMF: false,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
          configureAudioSession: true,
        ),
      ),
    );
  }

  Future<void> setConnected(String callId) async {
    if (supported) {
      await FlutterCallkitIncoming.setCallConnected(_nativeId(callId));
    }
  }

  Future<void> end(String callId) async {
    if (!supported || callId.isEmpty) return;
    final id = _nativeId(callId);
    _calls.remove(id);
    await FlutterCallkitIncoming.endCall(id);
  }

  void _onEvent(CallEvent? event) {
    if (event == null) return;
    CallKitParams? params;
    NativeCallActionType? type;
    if (event is CallEventActionCallAccept) {
      params = event.callKitParams;
      type = NativeCallActionType.accept;
    } else if (event is CallEventActionCallDecline) {
      params = event.callKitParams;
      type = NativeCallActionType.decline;
    } else if (event is CallEventActionCallEnded) {
      params = event.callKitParams;
      type = NativeCallActionType.ended;
    } else if (event is CallEventActionCallTimeout) {
      final args = _calls.remove(event.id);
      if (args != null) {
        _actions.add(NativeCallAction(NativeCallActionType.timeout, args));
      }
      return;
    }
    if (params == null || type == null) return;
    final args = _calls[params.id] ?? decodeArgs(params.extra);
    if (args == null) return;
    if (type != NativeCallActionType.accept) _calls.remove(params.id);
    _actions.add(NativeCallAction(type, args));
  }

  @visibleForTesting
  Map<String, dynamic> encodeArgs(CallLaunchArgs args) => <String, dynamic>{
    'callId': args.callSessionId,
    'chatId': args.chatId,
    'callType': args.callType.name,
    'fromUserId': args.fromUserId,
    'title': args.title,
    'conversationTitle': args.conversationTitle,
    'callerName': args.callerName,
    'callerAvatarUrl': args.callerAvatarUrl,
    'peerAvatarUrl': args.peerAvatarUrl,
    'callerId': args.callerId,
    'isGroupOwner': args.isGroupOwner,
    'isGroupCall': args.isGroupCall,
    'groupId': args.groupId,
    'inviteeIds': args.inviteeIds,
  };

  @visibleForTesting
  CallLaunchArgs? decodeArgs(Map<String, dynamic>? raw) {
    if (raw == null || raw['callId'] == null) return null;
    return CallLaunchArgs(
      callSessionId: raw['callId'].toString(),
      chatId: raw['chatId']?.toString() ?? '',
      callType: raw['callType']?.toString() == 'video'
          ? CallType.video
          : CallType.audio,
      entryMode: CallEntryMode.incoming,
      fromUserId: raw['fromUserId']?.toString(),
      title: raw['title']?.toString(),
      conversationTitle: raw['conversationTitle']?.toString(),
      callerName: raw['callerName']?.toString(),
      callerAvatarUrl: raw['callerAvatarUrl']?.toString(),
      peerAvatarUrl: raw['peerAvatarUrl']?.toString(),
      callerId: raw['callerId']?.toString(),
      isGroupOwner: raw['isGroupOwner'] as bool?,
      isGroupCall: raw['isGroupCall'] == true,
      groupId: raw['groupId']?.toString(),
      inviteeIds:
          (raw['inviteeIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  String _nativeId(String callId) {
    final compact = callId.replaceAll('-', '');
    if (compact.length == 32) {
      return '${compact.substring(0, 8)}-${compact.substring(8, 12)}-'
          '${compact.substring(12, 16)}-${compact.substring(16, 20)}-${compact.substring(20)}';
    }
    return callId;
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _actions.close();
  }
}
