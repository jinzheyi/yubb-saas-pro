# IM Flutter 通话对象代码模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：音视频通话模块核心对象、状态对象、路由参数对象的建议代码模板

---

## 1. `call_launch_args.dart` 模板

```dart
enum CallEntryMode {
  outgoing,
  incoming,
  restore,
}

enum CallType {
  audio,
  video,
}

class CallLaunchArgs {
  const CallLaunchArgs({
    required this.callSessionId,
    required this.chatId,
    required this.callType,
    required this.entryMode,
    this.inviteId,
    this.fromUserId,
    this.toUserId,
  });

  final String callSessionId;
  final String chatId;
  final CallType callType;
  final CallEntryMode entryMode;
  final String? inviteId;
  final String? fromUserId;
  final String? toUserId;
}
```

---

## 2. `call_participant_profile.dart` 模板

```dart
class CallParticipantProfile {
  const CallParticipantProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
}
```

---

## 3. `call_media_state.dart` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_media_state.freezed.dart';

enum RtcConnectionStatus {
  idle,
  preparing,
  joining,
  publishing,
  subscribing,
  connected,
  reconnecting,
  disconnected,
  failed,
}

@freezed
class CallMediaState with _$CallMediaState {
  const factory CallMediaState({
    @Default(true) bool microphoneEnabled,
    @Default(false) bool cameraEnabled,
    @Default(true) bool speakerEnabled,
    @Default(true) bool frontCamera,
    @Default(false) bool localTrackReady,
    @Default(false) bool remoteTrackReady,
    @Default(false) bool localVideoFirstFrameReady,
    @Default(false) bool remoteVideoFirstFrameReady,
    @Default(false) bool isPublishing,
    @Default(false) bool isSubscribing,
    @Default(0) int networkQualityLevel,
    @Default(RtcConnectionStatus.idle) RtcConnectionStatus rtcConnectionStatus,
    @Default(false) bool localRendererAttached,
    @Default(false) bool remoteRendererAttached,
  }) = _CallMediaState;
}
```

---

## 4. `call_state.dart` 模板

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_state.freezed.dart';

enum CallPageStatus {
  initial,
  loading,
  ringing,
  accepting,
  connecting,
  connected,
  reconnecting,
  minimized,
  ending,
  ended,
  failed,
}

enum CallEndReason {
  none,
  cancelledByCaller,
  rejectedByCallee,
  busy,
  noAnswer,
  hangupByLocal,
  hangupByRemote,
  kickedByOtherDevice,
  networkTimeout,
  rtcError,
  permissionDenied,
}

@freezed
class CallState with _$CallState {
  const factory CallState({
    @Default('') String callSessionId,
    @Default('') String chatId,
    CallType? callType,
    CallEntryMode? entryMode,
    @Default(CallPageStatus.initial) CallPageStatus pageStatus,
    @Default(CallEndReason.none) CallEndReason endReason,
    @Default(false) bool isIncoming,
    @Default(false) bool isOutgoing,
    @Default(false) bool hasAccepted,
    @Default(false) bool hasConnected,
    @Default(false) bool isMinimized,
    @Default(false) bool showPermissionBanner,
    @Default(false) bool showReconnectingBanner,
    @Default(0) int elapsedSeconds,
    CallParticipantProfile? callerProfile,
    CallParticipantProfile? calleeProfile,
    String? acceptedDeviceId,
    String? errorMessage,
    @Default(CallMediaState()) CallMediaState mediaState,
  }) = _CallState;
}
```

---

## 5. `rtc_room_bundle.dart` 模板

```dart
class RtcRoomBundle {
  const RtcRoomBundle({
    required this.callSessionId,
    required this.roomId,
    required this.publisherId,
    required this.displayName,
    required this.janusUrl,
    required this.turnUrls,
    required this.turnUsername,
    required this.turnCredential,
    required this.token,
  });

  final String callSessionId;
  final String roomId;
  final String publisherId;
  final String displayName;
  final String janusUrl;
  final List<String> turnUrls;
  final String turnUsername;
  final String turnCredential;
  final String token;
}
```

---

## 6. `call_summary_message.dart` 模板

```dart
class CallSummaryMessage {
  const CallSummaryMessage({
    required this.callSessionId,
    required this.callType,
    required this.endReason,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
  });

  final String callSessionId;
  final CallType callType;
  final CallEndReason endReason;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime endedAt;
}
```

---

## 7. `call_socket_event.dart` 模板

```dart
enum CallSocketEventType {
  invite,
  accepted,
  rejected,
  busy,
  cancelled,
  timeout,
  ended,
  deviceTerminated,
  stateSync,
  mediaTokenIssued,
}

class CallSocketEvent {
  const CallSocketEvent({
    required this.type,
    required this.callSessionId,
    this.payload = const <String, dynamic>{},
  });

  final CallSocketEventType type;
  final String callSessionId;
  final Map<String, dynamic> payload;
}
```

---

## 8. 结论

这些对象足以支撑：

1. 通话路由进入
2. 页面状态驱动
3. RTC 参数承接
4. 结束态消息记录
