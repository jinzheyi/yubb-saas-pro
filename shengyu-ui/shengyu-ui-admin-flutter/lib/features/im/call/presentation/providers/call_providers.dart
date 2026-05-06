import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/accept_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/cancel_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/create_call_invite_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/hangup_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/reject_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/sync_active_call_state_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_socket_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/repositories/call_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/active_call_registry.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';

enum CallRepositoryMode { mock, remote }

final callRepositoryModeProvider = Provider<CallRepositoryMode>((ref) {
  return CallRepositoryMode.remote;
});

final callDtoMapperProvider = Provider<CallDtoMapper>((ref) {
  return const CallDtoMapper();
});

final callSocketPayloadResolverProvider = Provider<CallSocketPayloadResolver>((
  ref,
) {
  return const CallSocketPayloadResolver();
});

final callRemoteDataSourceProvider = Provider<CallRemoteDataSource>((ref) {
  return CallRemoteDataSource(dio: ref.read(dioProvider));
});

final callSocketDataSourceProvider = Provider<CallSocketDataSource>((ref) {
  final dataSource = CallSocketDataSource(
    ref.read(socketMessageDispatcherProvider).stream,
  );
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final callRepositoryImplProvider = Provider<CallRepository>((ref) {
  return CallRepositoryImpl(
    ref.read(callRemoteDataSourceProvider),
    ref.read(callSocketDataSourceProvider),
    ref.read(callDtoMapperProvider),
  );
});

final callRepositoryProvider = Provider<CallRepository>((ref) {
  switch (ref.watch(callRepositoryModeProvider)) {
    case CallRepositoryMode.mock:
      return ref.read(callRepositoryImplProvider);
    case CallRepositoryMode.remote:
      return ref.read(callRepositoryImplProvider);
  }
});

final callPermissionCoordinatorProvider = Provider<CallPermissionCoordinator>((
  ref,
) {
  return const CallPermissionCoordinator();
});

final callMediaControllerProvider = Provider<CallMediaController>((ref) {
  return CallMediaController(ref.read(callPermissionCoordinatorProvider));
});

final activeCallRegistryProvider = Provider<ActiveCallRegistry>((ref) {
  return const ActiveCallRegistry();
});

final callCoordinatorProvider = Provider<CallCoordinator>((ref) {
  return CallCoordinator(ref.read(appRouterProvider));
});

final createCallInviteUseCaseProvider = Provider<CreateCallInviteUseCase>((
  ref,
) {
  return CreateCallInviteUseCase(ref.read(callRepositoryProvider));
});

final acceptCallUseCaseProvider = Provider<AcceptCallUseCase>((ref) {
  return AcceptCallUseCase(ref.read(callRepositoryProvider));
});

final rejectCallUseCaseProvider = Provider<RejectCallUseCase>((ref) {
  return RejectCallUseCase(ref.read(callRepositoryProvider));
});

final cancelCallUseCaseProvider = Provider<CancelCallUseCase>((ref) {
  return CancelCallUseCase(ref.read(callRepositoryProvider));
});

final hangupCallUseCaseProvider = Provider<HangupCallUseCase>((ref) {
  return HangupCallUseCase(ref.read(callRepositoryProvider));
});

final syncActiveCallStateUseCaseProvider = Provider<SyncActiveCallStateUseCase>(
  (ref) {
    return SyncActiveCallStateUseCase(ref.read(callRepositoryProvider));
  },
);

final callControllerProvider =
    StateNotifierProvider.autoDispose<CallController, CallState>((ref) {
      final repository = ref.read(callRepositoryProvider);
      return CallController(
        ref.read(createCallInviteUseCaseProvider),
        ref.read(acceptCallUseCaseProvider),
        ref.read(rejectCallUseCaseProvider),
        ref.read(cancelCallUseCaseProvider),
        ref.read(hangupCallUseCaseProvider),
        ref.read(syncActiveCallStateUseCaseProvider),
        ref.read(callMediaControllerProvider),
        ref.read(callCoordinatorProvider),
        ref.read(activeCallRegistryProvider),
        ref.read(callSocketPayloadResolverProvider),
        repository.watchSocketEvents(),
      );
    });

final activeCallStateProvider = Provider<CallState>((ref) {
  return ref.watch(callControllerProvider);
});

final callElapsedSecondsProvider = Provider<int>((ref) {
  return ref.watch(
    callControllerProvider.select((state) => state.elapsedSeconds),
  );
});

final isCallConnectedProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.pageStatus == CallPageStatus.connected,
    ),
  );
});

final isCallVideoEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.callType == CallType.video || state.mediaState.cameraEnabled,
    ),
  );
});

final isCallReconnectingProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus == CallPageStatus.reconnecting ||
          state.mediaState.rtcConnectionStatus ==
              RtcConnectionStatus.reconnecting,
    ),
  );
});

final canToggleCallControlsProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus == CallPageStatus.connecting ||
          state.pageStatus == CallPageStatus.connected ||
          state.pageStatus == CallPageStatus.reconnecting,
    ),
  );
});

final canSwitchCallCameraProvider = Provider<bool>((ref) {
  final canToggle = ref.watch(canToggleCallControlsProvider);
  final isVideoEnabled = ref.watch(isCallVideoEnabledProvider);
  return canToggle && isVideoEnabled;
});

final isCallEndingProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.pageStatus == CallPageStatus.ending,
    ),
  );
});

final canHangupCallProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus != CallPageStatus.ending &&
          state.pageStatus != CallPageStatus.ended &&
          state.pageStatus != CallPageStatus.failed,
    ),
  );
});

final isCallFinishedProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus == CallPageStatus.ended ||
          state.pageStatus == CallPageStatus.failed,
    ),
  );
});

final canAcceptIncomingCallProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.pageStatus == CallPageStatus.ringing,
    ),
  );
});

final canRejectIncomingCallProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus == CallPageStatus.ringing ||
          state.pageStatus == CallPageStatus.accepting,
    ),
  );
});

final canCancelOutgoingCallProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) =>
          state.pageStatus == CallPageStatus.loading ||
          state.pageStatus == CallPageStatus.ringing ||
          state.pageStatus == CallPageStatus.connecting,
    ),
  );
});

final callSessionStatusTextProvider = Provider.family<String, CallLaunchArgs>((
  ref,
  args,
) {
  final state = ref.watch(activeCallStateProvider);
  final isConnected = ref.watch(isCallConnectedProvider);
  final isReconnecting = ref.watch(isCallReconnectingProvider);
  final isEnding = ref.watch(isCallEndingProvider);
  final elapsedSeconds = ref.watch(callElapsedSecondsProvider);
  final mediaState = state.mediaState;

  if (state.pageStatus == CallPageStatus.ended) {
    return _callEndReasonText(state.endReason);
  }
  if (state.pageStatus == CallPageStatus.failed) {
    return ref.watch(callFailureTextProvider);
  }
  if (isEnding) {
    return '正在结束通话...';
  }
  if (isReconnecting) {
    return '网络波动，正在恢复通话...';
  }
  if (state.pageStatus == CallPageStatus.connecting) {
    switch (mediaState.rtcConnectionStatus) {
      case RtcConnectionStatus.preparing:
        return '正在准备音视频设备...';
      case RtcConnectionStatus.joining:
        return args.callType == CallType.video ? '正在加入视频通话...' : '正在加入语音通话...';
      case RtcConnectionStatus.connected:
        return '连接已建立，等待远端加入...';
      case RtcConnectionStatus.reconnecting:
        return '通话重连中...';
      case RtcConnectionStatus.disconnected:
      case RtcConnectionStatus.idle:
        return '正在建立通话连接...';
    }
  }
  if (isConnected) {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    if (!mediaState.remoteTrackReady) {
      return args.callType == CallType.video
          ? '视频已接通，等待对方画面...'
          : '语音已接通，等待对方声音...';
    }
    final callLabel = args.callType == CallType.video ? '视频通话' : '语音通话';
    return '$callLabel  $minutes:$seconds';
  }
  return args.callType == CallType.video ? '视频通话骨架' : '语音通话骨架';
});

final callFailureTextProvider = Provider<String>((ref) {
  final state = ref.watch(activeCallStateProvider);
  if (state.error?.message case final message?) {
    if (message.isNotEmpty) {
      return message;
    }
  }
  return switch (state.endReason) {
    CallEndReason.permissionDenied => '通话权限不足',
    CallEndReason.rtcError => '通话连接失败',
    CallEndReason.networkTimeout => '网络重连超时',
    CallEndReason.busy => '对方忙线中',
    CallEndReason.noAnswer => '无人接听',
    _ => '通话暂时不可用',
  };
});

final incomingCallStatusTextProvider = Provider<String>((ref) {
  final state = ref.watch(activeCallStateProvider);
  switch (state.pageStatus) {
    case CallPageStatus.ringing:
      return '邀请你加入通话';
    case CallPageStatus.accepting:
      return '正在接听...';
    case CallPageStatus.connected:
      return '通话已接通';
    case CallPageStatus.ended:
      return '来电已结束';
    case CallPageStatus.failed:
      return '接听失败';
    default:
      return '来电骨架已接通';
  }
});

final outgoingCallStatusTextProvider = Provider<String>((ref) {
  final state = ref.watch(activeCallStateProvider);
  final failureText = ref.watch(callFailureTextProvider);
  switch (state.pageStatus) {
    case CallPageStatus.loading:
      return '正在初始化通话...';
    case CallPageStatus.ringing:
      return state.callType == CallType.video
          ? '等待对方接受视频邀请...'
          : '等待对方接听语音邀请...';
    case CallPageStatus.connecting:
      return '正在建立连接...';
    case CallPageStatus.connected:
      return '通话已接通';
    case CallPageStatus.ended:
      switch (state.endReason) {
        case CallEndReason.cancelledByCaller:
          return '通话已取消';
        case CallEndReason.rejectedByCallee:
          return '对方已拒绝';
        case CallEndReason.busy:
          return '对方忙线中';
        case CallEndReason.noAnswer:
          return '对方暂时未接听';
        default:
          return '通话已结束';
      }
    case CallPageStatus.failed:
      return failureText;
    default:
      return state.callType == CallType.video ? '正在发起视频通话...' : '正在发起语音通话...';
  }
});

final callSessionBannerTextProvider = Provider<String?>((ref) {
  final isReconnecting = ref.watch(isCallReconnectingProvider);
  final isEnding = ref.watch(isCallEndingProvider);
  final isFinished = ref.watch(isCallFinishedProvider);
  final state = ref.watch(activeCallStateProvider);
  final failureText = ref.watch(callFailureTextProvider);

  if (isReconnecting) {
    return '通话未结束，恢复成功后将继续当前会话';
  }
  if (isEnding) {
    return '正在结束通话...';
  }
  if (state.pageStatus == CallPageStatus.connecting &&
      state.mediaState.localTrackReady &&
      !state.mediaState.remoteTrackReady) {
    return '本地设备已就绪，正在等待远端媒体加入';
  }
  if (state.pageStatus == CallPageStatus.failed) {
    return failureText;
  }
  if (isFinished) {
    return null;
  }
  return null;
});

String _callEndReasonText(CallEndReason reason) {
  switch (reason) {
    case CallEndReason.cancelledByCaller:
      return '主叫已取消';
    case CallEndReason.rejectedByCallee:
      return '通话已拒绝';
    case CallEndReason.busy:
      return '对方忙线中';
    case CallEndReason.noAnswer:
      return '无人接听';
    case CallEndReason.hangupByLocal:
      return '你已挂断通话';
    case CallEndReason.hangupByRemote:
      return '对方已挂断通话';
    case CallEndReason.networkTimeout:
      return '网络重连超时';
    case CallEndReason.rtcError:
      return '通话连接失败';
    case CallEndReason.permissionDenied:
      return '通话权限不足';
    default:
      return '通话已结束';
  }
}
