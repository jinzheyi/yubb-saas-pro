import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/network/api_exception.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/livekit_call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/providers/livekit_call_providers.dart';

void main() {
  Future<String> hangupEndpoint({required bool owner}) async {
    var path = '';
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            path = options.path;
            handler.resolve(
              Response<dynamic>(requestOptions: options, data: const {}),
            );
          },
        ),
      );
    final controller = LiveKitCallController(
      dio: dio,
      deviceInfoService: DeviceInfoService(),
      callEvents: const Stream<LiveKitCallEvent>.empty(),
      args: CallLaunchArgs(
        callSessionId: 'call-1',
        chatId: 'chat-1',
        callType: CallType.audio,
        entryMode: CallEntryMode.restore,
        isGroupCall: true,
        groupId: 'group-1',
        isGroupOwner: owner,
      ),
    );
    await controller.hangup();
    controller.dispose();
    return path;
  }

  test('restored group owner ends the whole call', () async {
    expect(await hangupEndpoint(owner: true), '/system/im/call/hangup');
  });

  test('restored invited member only leaves itself', () async {
    expect(await hangupEndpoint(owner: false), '/system/im/call/group/leave');
  });

  test('stable busy code returns to group member selection flow', () {
    expect(
      classifyCallLaunchFailure(
        const ApiException(code: 1002050003, message: '用户正在通话中'),
        isGroupCall: true,
      ),
      CallLaunchFailure.groupMemberBusy,
    );
    expect(
      classifyCallLaunchFailure(
        const ApiException(code: 1002050003, message: '用户正在通话中'),
        isGroupCall: false,
      ),
      CallLaunchFailure.other,
    );
  });

  test(
    'restored direct call uses actual local user for terminal actor',
    () async {
      final events = StreamController<LiveKitCallEvent>();
      final controller = LiveKitCallController(
        dio: Dio(),
        deviceInfoService: DeviceInfoService(),
        callEvents: events.stream,
        localUserId: 'caller',
        args: const CallLaunchArgs(
          callSessionId: 'call-restore',
          chatId: 'chat-restore',
          callType: CallType.audio,
          entryMode: CallEntryMode.restore,
          callerId: 'caller',
          fromUserId: 'caller',
        ),
      );

      events.add(
        const LiveKitCallEvent(
          type: 'call.ended',
          callId: 'call-restore',
          actorId: 'callee',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.endReason, CallEndDisplayReason.remoteHangup);
      await events.close();
      controller.dispose();
    },
  );

  test('empty route args fail safely before creating a call', () async {
    var requested = false;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested = true;
            handler.reject(DioException(requestOptions: options));
          },
        ),
      );
    final controller = LiveKitCallController(
      dio: dio,
      deviceInfoService: DeviceInfoService(),
      callEvents: const Stream<LiveKitCallEvent>.empty(),
      args: const CallLaunchArgs.empty(),
    );

    await expectLater(controller.startOutgoing(), throwsA(isA<StateError>()));
    expect(requested, isFalse);
    expect(controller.shouldClose, isTrue);
    expect(controller.endReason, CallEndDisplayReason.failed);
    controller.dispose();
  });
}
