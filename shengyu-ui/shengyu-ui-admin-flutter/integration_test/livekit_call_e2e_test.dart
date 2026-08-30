import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:livekit_client/livekit_client.dart';

/// Real end-to-end test for the call control plane and LiveKit media plane.
///
/// Credentials are injected at runtime and are never committed:
///
/// flutter test integration_test/livekit_call_e2e_test.dart -d `device-id` \
///   --dart-define=CALL_E2E_ACCOUNT_A=... \
///   --dart-define=CALL_E2E_ACCOUNT_B=... \
///   --dart-define=CALL_E2E_PASSWORD=...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const accountA = String.fromEnvironment('CALL_E2E_ACCOUNT_A');
  const accountB = String.fromEnvironment('CALL_E2E_ACCOUNT_B');
  const password = String.fromEnvironment('CALL_E2E_PASSWORD');
  const apiBaseUrl = String.fromEnvironment(
    'CALL_E2E_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:48080/app-api',
  );
  const directChatId = String.fromEnvironment(
    'CALL_E2E_DIRECT_CHAT_ID',
    defaultValue: '2070386922573291520',
  );
  const groupChatId = String.fromEnvironment(
    'CALL_E2E_GROUP_CHAT_ID',
    defaultValue: '2071839038592602112',
  );
  const groupId = String.fromEnvironment(
    'CALL_E2E_GROUP_ID',
    defaultValue: '2071839038156394498',
  );

  final configured =
      accountA.isNotEmpty && accountB.isNotEmpty && password.isNotEmpty;

  test('bundled ringtone and end cue load and play on the device', () async {
    final player = just_audio.AudioPlayer();
    try {
      expect(
        await player.setAsset('assets/sounds/call_ringtone.mp3'),
        isNotNull,
      );
      await player.setLoopMode(just_audio.LoopMode.one);
      unawaited(player.play());
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(player.playing, isTrue);

      await player.stop();
      expect(await player.setAsset('assets/sounds/call_end.mp3'), isNotNull);
      await player.setLoopMode(just_audio.LoopMode.off);
      unawaited(player.play());
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(player.playing, isTrue);
    } finally {
      await player.dispose();
    }
  });

  for (final scope in const ['direct', 'group']) {
    for (final callType in const ['audio', 'video']) {
      test(
        'two accounts complete a real $scope $callType call through LiveKit',
        () async {
          final client = Dio(
            BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );
          final caller = await _login(client, accountA, password, 'caller');
          final callee = await _login(client, accountB, password, 'callee');
          expect(caller.tenantId, callee.tenantId);

          final callerApi = _authorizedClient(apiBaseUrl, caller);
          final calleeApi = _authorizedClient(apiBaseUrl, callee);
          final callerRoom = Room();
          final calleeRoom = Room();
          String callId = '';
          try {
            // These stage markers intentionally contain no credentials or tokens.
            // They make failures actionable in CI and local device runs.
            // ignore: avoid_print
            print('CALL_E2E[$scope/$callType] creating invite');
            final create = _data(
              (await callerApi.post<Object?>(
                scope == 'group'
                    ? '/system/im/call/group/create-invite'
                    : '/system/im/call/create-invite',
                data: scope == 'group'
                    ? <String, Object?>{
                        'chatId': groupChatId,
                        'groupId': groupId,
                        'inviteeIds': <String>[callee.userId],
                        'callType': callType,
                        'deviceId': caller.deviceId,
                      }
                    : <String, Object?>{
                        'chatId': directChatId,
                        'calleeId': callee.userId,
                        'callType': callType,
                        'deviceId': caller.deviceId,
                      },
              )).data,
            );
            callId = create['callSessionId']?.toString() ?? '';
            expect(callId, isNotEmpty);
            final callerCredentials = Map<String, dynamic>.from(
              create['rtcRoom']! as Map,
            );

            // ignore: avoid_print
            print('CALL_E2E[$scope/$callType] accepting invite');
            final accepted = _data(
              (await calleeApi.post<Object?>(
                '/system/im/call/accept',
                data: <String, Object?>{
                  'callSessionId': callId,
                  'deviceId': callee.deviceId,
                },
              )).data,
            );

            // ignore: avoid_print
            print(
              'CALL_E2E[$scope/$callType] connecting both LiveKit participants',
            );
            await Future.wait<void>([
              _connect(callerRoom, callerCredentials),
              _connect(calleeRoom, accepted),
            ]).timeout(const Duration(seconds: 20));
            // ignore: avoid_print
            print('CALL_E2E[$scope/$callType] both participants connected');
            await _waitUntil(
              () =>
                  callerRoom.remoteParticipants.isNotEmpty &&
                  calleeRoom.remoteParticipants.isNotEmpty,
              reason: 'both users did not become visible in the LiveKit room',
            );

            if (callType == 'video') {
              // ignore: avoid_print
              print('CALL_E2E[$scope/$callType] publishing camera');
              await callerRoom.localParticipant!.setCameraEnabled(true);
              await _waitUntil(
                () => _remoteHasTrack(calleeRoom, TrackType.VIDEO),
                reason: 'callee did not subscribe to caller video',
              );
            } else {
              // ignore: avoid_print
              print('CALL_E2E[$scope/$callType] publishing microphone');
              await callerRoom.localParticipant!.setMicrophoneEnabled(true);
              await _waitUntil(
                () => _remoteHasTrack(calleeRoom, TrackType.AUDIO),
                reason: 'callee did not subscribe to caller audio',
              );
            }
          } finally {
            if (callId.isNotEmpty) {
              try {
                await callerApi.post<Object?>(
                  '/system/im/call/hangup',
                  data: <String, Object?>{'callSessionId': callId},
                );
              } catch (_) {
                // The assertion failure is more useful than cleanup noise.
              }
            }
            await Future.wait<void>([
              _disposeRoom(callerRoom),
              _disposeRoom(calleeRoom),
            ]);
          }
        },
        skip: configured ? false : 'CALL_E2E credentials are not configured',
        timeout: const Timeout(Duration(minutes: 2)),
      );
    }
  }
}

Future<_Session> _login(
  Dio client,
  String account,
  String password,
  String role,
) async {
  final deviceId = 'call-e2e-$role-${DateTime.now().microsecondsSinceEpoch}';
  final data = _data(
    (await client.post<Object?>(
      '/system/auth/login',
      data: <String, Object?>{
        'username': account,
        'password': password,
        'deviceType': 4,
        'deviceId': deviceId,
        'clientVersion': 'call-e2e',
      },
    )).data,
  );
  return _Session(
    accessToken: data['accessToken']?.toString() ?? '',
    tenantId: data['tenantId']?.toString() ?? '',
    userId: data['userId']?.toString() ?? '',
    deviceId: deviceId,
  );
}

Dio _authorizedClient(String baseUrl, _Session session) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: <String, Object?>{
      'Authorization': 'Bearer ${session.accessToken}',
      'tenant-id': session.tenantId,
    },
  ),
);

Map<String, dynamic> _data(Object? response) {
  final envelope = Map<String, dynamic>.from(response! as Map);
  expect(envelope['code'], 0, reason: envelope['msg']?.toString());
  return Map<String, dynamic>.from(envelope['data']! as Map);
}

Future<void> _connect(Room room, Map<String, dynamic> credentials) {
  const urlOverride = String.fromEnvironment('CALL_E2E_LIVEKIT_URL');
  final url = urlOverride.isNotEmpty
      ? urlOverride
      : credentials['livekitUrl']?.toString() ?? '';
  final token =
      (credentials['accessToken'] ?? credentials['token'])?.toString() ?? '';
  expect(url, isNotEmpty);
  expect(token, isNotEmpty);
  return room.connect(url, token);
}

bool _remoteHasTrack(Room room, TrackType type) {
  for (final participant in room.remoteParticipants.values) {
    final publications = type == TrackType.VIDEO
        ? participant.videoTrackPublications
        : participant.audioTrackPublications;
    if (publications.any((publication) => publication.track != null)) {
      return true;
    }
  }
  return false;
}

Future<void> _waitUntil(
  bool Function() predicate, {
  required String reason,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _disposeRoom(Room room) async {
  try {
    await room.disconnect().timeout(const Duration(seconds: 3));
  } catch (_) {
    // A failed connection can leave the SDK waiting for a disconnect ack.
  }
  try {
    await room.dispose().timeout(const Duration(seconds: 3));
  } catch (_) {
    // Cleanup must not hide the original signaling/media assertion failure.
  }
}

class _Session {
  const _Session({
    required this.accessToken,
    required this.tenantId,
    required this.userId,
    required this.deviceId,
  });

  final String accessToken;
  final String tenantId;
  final String userId;
  final String deviceId;
}
