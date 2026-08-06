import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/dtos/call_record_dto.dart';

class CallSocketPayloadSnapshot {
  const CallSocketPayloadSnapshot({
    this.title,
    this.acceptedDeviceId,
    this.callerProfile,
    this.calleeProfile,
    this.roomBundle,
  });

  final String? title;
  final String? acceptedDeviceId;
  final CallParticipantProfile? callerProfile;
  final CallParticipantProfile? calleeProfile;
  final RtcRoomBundle? roomBundle;
}

class CallSocketPayloadResolver {
  const CallSocketPayloadResolver();

  CallSocketPayloadSnapshot resolve(
    Map<String, Object?> payload, {
    required String fallbackCallSessionId,
  }) {
    return CallSocketPayloadSnapshot(
      title: payload['title']?.toString(),
      acceptedDeviceId: payload['acceptedDeviceId']?.toString(),
      callerProfile: _participantFromPayload(payload['callerProfile']),
      calleeProfile: _participantFromPayload(payload['calleeProfile']),
      roomBundle: _roomBundleFromPayload(
        payload,
        fallbackCallSessionId: fallbackCallSessionId,
      ),
    );
  }

  CallParticipantProfile? _participantFromPayload(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final userId = raw['userId']?.toString() ?? '';
    if (userId.isEmpty) {
      return null;
    }
    return CallParticipantProfile(
      userId: userId,
      displayName:
          raw['displayName']?.toString() ?? raw['nickname']?.toString() ?? '',
      avatarUrl: raw['avatarUrl']?.toString(),
    );
  }

  RtcRoomBundle? _roomBundleFromPayload(
    Map<String, Object?> payload, {
    required String fallbackCallSessionId,
  }) {
    Object? raw = payload['rtcRoom'];
    raw ??= payload['roomBundle'];
    raw ??= payload['payload'];
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final roomId = raw['roomId']?.toString() ?? '';
    if (roomId.isEmpty) {
      return null;
    }
    final turnUrlsRaw = raw['turnUrls'];
    final turnUrls = turnUrlsRaw is List
        ? turnUrlsRaw.map((item) => item.toString()).toList()
        : const <String>[];
    return RtcRoomBundle(
      callSessionId: raw['callSessionId']?.toString().isNotEmpty == true
          ? raw['callSessionId']!.toString()
          : fallbackCallSessionId,
      roomId: roomId,
      publisherId: raw['publisherId']?.toString() ?? '',
      displayName: raw['displayName']?.toString() ?? '',
      janusUrl: raw['janusUrl']?.toString() ?? '',
      turnUrls: turnUrls,
      turnUsername: raw['turnUsername']?.toString() ?? '',
      turnCredential: raw['turnCredential']?.toString() ?? '',
      token: raw['token']?.toString() ?? '',
    );
  }

  /// 解析通话记录事件的 payload
  ///
  /// 用于将 call.record 事件的 payload 转换为 CallRecordDto
  CallRecordDto resolveCallRecord(Map<String, Object?> payload) {
    // 安全转换：创建新的 Map 而不是使用 cast，避免运行时类型异常
    final converted = <String, dynamic>{};
    payload.forEach((key, value) {
      converted[key] = value;
    });
    return CallRecordDto.fromJson(converted);
  }
}
