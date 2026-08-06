import 'dart:async';

import 'package:shengyu_ui_admin_im/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session_provider.dart';
import 'package:shengyu_ui_admin_im/core/network/dio_client.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/core/websocket/im_socket_client.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/accept_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/cancel_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/create_call_invite_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/hangup_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/reject_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/sync_active_call_state_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/transfer_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/record_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_remote_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/datasources/call_socket_data_source.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/repositories/call_repository_impl.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/notification/call_notification_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/active_call_registry.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_conflict_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/group_call_state.dart';
export 'package:shengyu_ui_admin_im/features/im/call/infrastructure/config/call_config_provider.dart';

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
  final controller = CallMediaController(ref.read(callPermissionCoordinatorProvider));
  // 关键修复：ref.onDispose 是同步回调，不能 await 异步操作
  // 使用 unawaited 明确标记不等待，但确保资源最终会被清理
  ref.onDispose(() {
    // ignore: discarded_futures
    unawaited(controller.dispose().catchError((e) {
      // 忽略 dispose 失败，避免未捕获异常
    }));
  });
  return controller;
});

final activeCallRegistryProvider = Provider<ActiveCallRegistry>((ref) {
  final registry = const ActiveCallRegistry();
  // 关键修复：设置通话结束回调，确保用户登出/被踢时能自动终止通话
  // 回调会在 CallController 初始化时设置
  return registry;
});

// 关键修复：添加通话冲突管理器 Provider
// 用于处理多通话冲突场景（通话等待机制）
final callConflictManagerProvider = Provider<CallConflictManager>((ref) {
  return CallConflictManager(ref.read(activeCallRegistryProvider));
});



// 关键修复：添加通话通知管理器 Provider
// 虽然是单例，但需要在 provider 中初始化并管理生命周期
final callNotificationManagerProvider = Provider<CallNotificationManager>((ref) {
  final manager = CallNotificationManager.instance;
  // 异步初始化通知管理器（不阻塞 provider 创建）
  manager.initialize();
  return manager;
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

final transferCallUseCaseProvider = Provider<TransferCallUseCase>((ref) {
  return TransferCallUseCase(ref.read(callRepositoryProvider));
});

final recordCallUseCaseProvider = Provider<RecordCallUseCase>((ref) {
  return RecordCallUseCase(ref.read(callRepositoryProvider));
});

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) {
      final repository = ref.read(callRepositoryProvider);
      // 关键修复：注入当前登录用户信息，用于群组通话本地用户识别
      final authSession = ref.read(authSessionProvider);
      return CallController(
        ref.read(createCallInviteUseCaseProvider),
        ref.read(acceptCallUseCaseProvider),
        ref.read(rejectCallUseCaseProvider),
        ref.read(cancelCallUseCaseProvider),
        ref.read(hangupCallUseCaseProvider),
        ref.read(syncActiveCallStateUseCaseProvider),
        ref.read(transferCallUseCaseProvider),
        ref.read(recordCallUseCaseProvider),
        ref.read(callMediaControllerProvider),
        ref.read(callCoordinatorProvider),
        ref.read(activeCallRegistryProvider),
        ref.read(callFloatingWindowManagerProvider),
        ref.read(callSocketPayloadResolverProvider),
        ref.read(deviceInfoServiceProvider),
        repository,
        ref.read(callConflictManagerProvider),
        repository.watchSocketEvents(),
        initialAuthSession: authSession,
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

final isScreenShareEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.mediaState.screenShareEnabled,
    ),
  );
});

final canToggleScreenShareProvider = Provider<bool>((ref) {
  final canToggle = ref.watch(canToggleCallControlsProvider);
  final isVideoEnabled = ref.watch(isCallVideoEnabledProvider);
  return canToggle && isVideoEnabled;
});

final isRecordingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.mediaState.recordingEnabled,
    ),
  );
});

final canToggleRecordingProvider = Provider<bool>((ref) {
  final canToggle = ref.watch(canToggleCallControlsProvider);
  return canToggle;
});

final callTransferStatusProvider = Provider<CallTransferStatus>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.transferStatus,
    ),
  );
});

final canInitiateTransferProvider = Provider<bool>((ref) {
  final canToggle = ref.watch(canToggleCallControlsProvider);
  final transferStatus = ref.watch(callTransferStatusProvider);
  return canToggle && transferStatus == CallTransferStatus.none;
});

final networkQualityProvider = Provider<NetworkQuality>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.mediaState.networkQuality,
    ),
  );
});

final roundTripTimeProvider = Provider<int?>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.mediaState.roundTripTime,
    ),
  );
});

final packetLossRateProvider = Provider<double?>((ref) {
  return ref.watch(
    callControllerProvider.select(
      (state) => state.mediaState.packetLossRate,
    ),
  );
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
  // 兜底：返回初始化状态文本
  return args.callType == CallType.video ? '正在初始化视频通话...' : '正在初始化语音通话...';
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
      return '准备接听...';
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

/// 群通话状态 Provider
/// 
/// 根据当前通话状态判断指定群组是否有正在进行的通话
/// 用于在群聊页面顶部显示通话状态栏
final groupCallStateProvider = Provider.family<GroupCallState, String>((ref, groupId) {
  final callState = ref.watch(activeCallStateProvider);
  
  // 检查当前是否有正在进行的群通话
  final isGroupCall = callState.isGroupCall;
  final isGroupCallActive = isGroupCall && 
      callState.groupId == groupId &&
      (callState.pageStatus == CallPageStatus.connected ||
       callState.pageStatus == CallPageStatus.connecting ||
       callState.pageStatus == CallPageStatus.ringing);
  
  if (!isGroupCallActive) {
    return const GroupCallState(hasActiveCall: false);
  }
  
  // 构建群通话状态
  return GroupCallState(
    groupId: groupId,
    hasActiveCall: true,
    callType: callState.callType == CallType.video ? 'video' : 'voice',
    participantCount: callState.participants.length,
    participants: callState.participants,
    elapsedSeconds: callState.elapsedSeconds,
  );
});
