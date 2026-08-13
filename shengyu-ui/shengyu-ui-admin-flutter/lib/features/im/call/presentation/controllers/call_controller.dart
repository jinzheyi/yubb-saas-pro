import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error.dart';
import 'package:shengyu_ui_admin_im/core/error/app_error_mapper.dart';
import 'package:shengyu_ui_admin_im/core/platform/device_info_service.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/accept_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/cancel_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/create_call_invite_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/hangup_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/reject_call_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/application/usecases/sync_active_call_state_use_case.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/active_call_state_result.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_participant_profile.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/call_socket_event.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/repositories/call_repository.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/interruption/system_interruption_handler.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/lifecycle/call_lifecycle_handler.dart';
import 'package:shengyu_ui_admin_im/core/lifecycle/app_lifecycle_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_dto_mapper.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/notification/call_notification_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/mappers/call_socket_payload_resolver.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/recovery/network_recovery_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/active_call_registry.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_coordinator.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_conflict_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_floating_window_manager.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/controllers/call_media_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/network_quality_monitor.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_state.dart';
import 'package:shengyu_ui_admin_im/core/auth/auth_session.dart';
import 'package:shengyu_ui_admin_im/features/im/chat/domain/entities/message.dart';

class CallController extends StateNotifier<CallState> {
  CallController(
    this._createCallInviteUseCase,
    this._acceptCallUseCase,
    this._rejectCallUseCase,
    this._cancelCallUseCase,
    this._hangupCallUseCase,
    this._syncActiveCallStateUseCase,
    this._callMediaController,
    this._callCoordinator,
    this._activeCallRegistry,
    this._callFloatingWindowManager,
    this._payloadResolver,
    this._deviceInfoService,
    this._callRepository,
    this._callConflictManager,
    Stream<CallSocketEvent> socketEvents, {
    AuthSession? initialAuthSession,
  }) : _authSession = initialAuthSession,
       super(const CallState()) {
    _socketSubscription = socketEvents.listen(_onSocketEvent);
  }

  final CreateCallInviteUseCase _createCallInviteUseCase;
  final AcceptCallUseCase _acceptCallUseCase;
  final RejectCallUseCase _rejectCallUseCase;
  final CancelCallUseCase _cancelCallUseCase;
  final HangupCallUseCase _hangupCallUseCase;
  final SyncActiveCallStateUseCase _syncActiveCallStateUseCase;
  final CallMediaController _callMediaController;
  final CallCoordinator _callCoordinator;
  final ActiveCallRegistry _activeCallRegistry;
  final CallFloatingWindowManager _callFloatingWindowManager;
  final CallSocketPayloadResolver _payloadResolver;
  final DeviceInfoService _deviceInfoService;
  final CallRepository _callRepository;
  final CallConflictManager _callConflictManager;
  
  /// 关键修复：保存本地用户ID，用于群组通话本地用户识别
  /// 从 authSessionProvider 注入，作为最终兜底
  final AuthSession? _authSession;

  StreamSubscription<CallSocketEvent>? _socketSubscription;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  StreamSubscription<NetworkQualityStats>? _networkStatsSubscription;
  StreamSubscription<String?>? _speakingFeedSubscription;
  Timer? _elapsedTimer;

  /// 无应答超时定时器（参考微信：发起通话后30秒无人接听自动挂断）
  Timer? _noAnswerTimer;

  /// 通话生命周期处理器（管理前后台切换）
  CallLifecycleHandler? _lifecycleHandler;

  /// 网络恢复管理器（管理网络断开重连）
  NetworkRecoveryManager? _networkRecoveryManager;

  /// 系统中断处理器（管理系统来电、闹钟等中断）
  SystemInterruptionHandler? _systemInterruptionHandler;

  /// 通话记录消息流控制器
  final StreamController<Message> _callRecordController =
      StreamController<Message>.broadcast();

  /// 发起通话的 Future（用于追踪 startOutgoing 的异步操作）
  Future<void>? _startOutgoingFuture;
  bool _outgoingStarted = false;

  /// 公开的通话状态访问器（供外部类使用）
  CallState get currentCallState => state;

  /// 通话记录消息流（供聊天页面监听）
  Stream<Message> get onCallRecordReceived => _callRecordController.stream;

  Future<void> initialize(CallLaunchArgs args) async {
    _activeCallRegistry.register(args);
    
    // 关键修复：设置通话结束回调，确保用户登出/被踢时能自动终止通话
    _activeCallRegistry.setOnCallEnd(_handleCallCleanup);
    
    // 关键修复：先取消旧订阅，防止重复 initialize 导致订阅泄漏
    _remoteStreamSubscription?.cancel();
    _networkStatsSubscription?.cancel();
    _speakingFeedSubscription?.cancel();
    
    // 监听远端流变化
    _remoteStreamSubscription = _callMediaController.onRemoteStreamChanged.listen(_onRemoteStreamChanged);

    // 监听网络质量统计
    _networkStatsSubscription = _callMediaController.onNetworkStatsChanged.listen(_onNetworkStatsChanged);

    // 监听说话者变化（群组通话使用）
    _speakingFeedSubscription = _callMediaController.onSpeakingFeedChanged.listen(_onSpeakingFeedChanged);
    
    state = state.copyWith(
      callSessionId: args.callSessionId,
      chatId: args.chatId,
      calleeId: args.toUserId,
      callType: args.callType,
      entryMode: args.entryMode,
      title: args.title,
      pageStatus: CallPageStatus.loading,
      isIncoming: args.entryMode == CallEntryMode.incoming,
      isOutgoing: args.entryMode == CallEntryMode.outgoing,
      isGroupCall: args.isGroupCall,
      groupId: args.groupId,
      inviteeIds: args.inviteeIds,
      error: null,
    );
    try {
      if (args.entryMode == CallEntryMode.restore) {
        final synced = await _syncActiveCallStateUseCase.execute(
          callSessionId: args.callSessionId,
        );
        _applySyncedState(synced);
        
        // 恢复保存的媒体状态（摄像头/麦克风/扬声器设置）
        final savedMediaState = _callFloatingWindowManager.takeSavedMediaState();
        if (savedMediaState != null) {
          state = state.copyWith(
            mediaState: state.mediaState.copyWith(
              microphoneEnabled: savedMediaState.microphoneEnabled,
              cameraEnabled: savedMediaState.cameraEnabled,
              speakerEnabled: savedMediaState.speakerEnabled,
              frontCamera: savedMediaState.frontCamera,
            ),
          );
          // 恢复音频会话（关键：重新配置音频会话，确保悬浮窗恢复后声音不丢失）
          await _callMediaController.restoreAudioSession();
        }
        
        if (synced.pageStatus == CallPageStatus.connected) {
          // 关键修复：从悬浮窗恢复时，如果通话已连接，必须重启所有处理器
          // 这些处理器在悬浮窗最小化时可能被停止，恢复时必须重新启动
          _startLifecycleHandler();
          _startNetworkRecoveryManager();
          _startSystemInterruptionHandler();
          // 关键修复：在所有处理器启动完成后再启动计时器
          _startElapsedTimer();
        }
      } else if (args.entryMode == CallEntryMode.incoming) {
        state = state.copyWith(pageStatus: CallPageStatus.ringing);
      } else {
        state = state.copyWith(pageStatus: CallPageStatus.ringing);
      }
      
      // 关键修复：群组通话初始化时，确保本地用户在参与者列表中
      // 本地用户加入群组通话时，可能不会收到自己的 groupJoin 事件
      _ensureLocalUserInParticipants();
    } catch (error, stackTrace) {
      state = state.copyWith(
        pageStatus: CallPageStatus.failed,
        error: AppErrorMapper.map(error, stackTrace),
      );
    }
  }
  
  /// 处理远端流到达事件
  Future<void> _onRemoteStreamChanged(MediaStream? remoteStream) async {
    if (remoteStream == null) return;
    
    // 关键修复：在更新状态之前保存旧状态，用于判断是否需要启动处理器
    final previousPageStatus = state.pageStatus;
    
    // 关键修复：保存旧的远端渲染器，在创建新的成功后再清理，避免闪烁
    final oldRemoteVideoRenderer = state.mediaState.remoteVideoRenderer;
    
    // 关键修复：将 renderer 声明移到 try 块外部，确保 catch 块可以访问并清理
    RTCVideoRenderer? remoteVideoRenderer;
    try {
      // 创建远端视频渲染器
      if (state.callType == CallType.video) {
        remoteVideoRenderer = RTCVideoRenderer();
        await remoteVideoRenderer.initialize();
        remoteVideoRenderer.srcObject = remoteStream;
      }
      
      // 更新状态
      final mediaState = state.mediaState.copyWith(
        remoteStream: remoteStream,
        remoteVideoRenderer: remoteVideoRenderer,
        remoteTrackReady: true,
      );

      state = state.copyWith(
        pageStatus: CallPageStatus.connected,
        hasConnected: true,
        mediaState: mediaState,
      );

      // 关键修复：新的 renderer 创建成功后，清理旧的 renderer（防止内存泄漏）
      // 这确保了远端流多次变化时（如网络不稳定）不会累积多个 renderer
      if (oldRemoteVideoRenderer != null && oldRemoteVideoRenderer != remoteVideoRenderer) {
        try {
          oldRemoteVideoRenderer.srcObject = null;
          await oldRemoteVideoRenderer.dispose();
          debugPrint('[CallController] 已清理旧的远端视频渲染器');
        } catch (ignore) {
          // 忽略清理失败
        }
      }

      // 停止无应答定时器（对方已接听）
      _stopNoAnswerTimer();
      
      // 注册活动通话
      final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
      _activeCallRegistry.register(args);

      // 关键修复：仅在首次进入 connected 状态时启动处理器，避免重复启动
      // 如果之前已经是 connected 状态，说明处理器已经启动过了
      if (previousPageStatus != CallPageStatus.connected) {
        _startLifecycleHandler();
        _startNetworkRecoveryManager();
        _startSystemInterruptionHandler();
      }
      
      // 关键修复：在所有状态更新和处理器启动完成后，再启动计时器
      // 确保计时器第一次 tick 时所有状态都已就绪
      _startElapsedTimer();
    } catch (error, stackTrace) {
      // 关键修复：清理刚创建的远端渲染器（使用局部变量，而非 state 中的旧值）
      // 防止异常发生在 renderer 创建后、state.copyWith 之前时 renderer 泄漏
      if (remoteVideoRenderer != null) {
        try {
          remoteVideoRenderer.srcObject = null;
          await remoteVideoRenderer.dispose();
        } catch (ignore) {
          // 忽略清理失败
        }
      }
      // 清理媒体资源
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterFailed(
        CallEndReason.rtcError,
        error: AppErrorMapper.map(error, stackTrace),
        mediaState: mediaState,
      );
    }
  }

  /// 处理网络质量统计变化
  void _onNetworkStatsChanged(NetworkQualityStats stats) {
    final mediaState = state.mediaState.copyWith(
      networkQuality: stats.quality,
      roundTripTime: stats.roundTripTime,
      packetLossRate: stats.packetLossRate,
      availableOutgoingBitrate: stats.availableOutgoingBitrate,
      availableIncomingBitrate: stats.availableIncomingBitrate,
    );

    state = state.copyWith(mediaState: mediaState);
  }

  /// 处理说话者变化事件（群组通话使用）
  ///
  /// 将音频监控检测到的 feed ID 转换为参与者 userId，
  /// 并更新 [CallState.speakingUserId]。
  void _onSpeakingFeedChanged(String? feedId) {
    if (!state.isGroupCall) return;

    // feedId 为 'local' 表示本地用户正在说话
    if (feedId == 'local') {
      // 关键修复：使用更可靠的本地用户ID获取方式
      // 优先级：ActiveCallRegistry.fromUserId > calleeId > 从参与者列表推断
      final localUserId = _getLocalUserId();
      if (state.speakingUserId != localUserId) {
        state = state.copyWith(speakingUserId: localUserId);
      }
      return;
    }

    // 远端 feedId：尝试匹配参与者列表中的 userId
    if (feedId != null && feedId.isNotEmpty) {
      final matchedParticipant = state.participants.where((p) {
        return p.userId == feedId || p.userId.endsWith(feedId);
      }).firstOrNull;

      final newSpeakingUserId = matchedParticipant?.userId;
      if (state.speakingUserId != newSpeakingUserId) {
        state = state.copyWith(speakingUserId: newSpeakingUserId);
      }
      return;
    }

    // feedId 为 null：无人说话
    if (state.speakingUserId != null) {
      state = state.copyWith(speakingUserId: null);
    }
  }

  /// 获取本地用户ID（群组通话使用）
  ///
  /// 优先级：
  /// 1. ActiveCallRegistry.fromUserId（最可靠，来自通话发起时的参数）
  /// 2. state.calleeId（对于被邀请者，这是自己的ID）
  /// 3. 从参与者列表中排除发起人后的第一个用户（兜底逻辑）
  /// 4. 从 _resolveLocalUserId() 获取（主叫/被叫场景）
  String? _getLocalUserId() {
    // 1. 优先使用 ActiveCallRegistry 中的 fromUserId
    final fromUserId = _activeCallRegistry.current?.fromUserId;
    if (fromUserId != null && fromUserId.isNotEmpty) {
      return fromUserId;
    }

    // 2. 对于被邀请者，calleeId 可能是自己的ID
    // 注意：这个逻辑需要后端在创建邀请时正确设置 calleeId 为被邀请者
    final calleeId = state.calleeId;
    if (calleeId != null && calleeId.isNotEmpty) {
      // 如果 calleeId 不是发起人，那么它可能是本地用户（被邀请者场景）
      final callerId = state.callerProfile?.userId;
      if (callerId == null || callerId.isEmpty || calleeId != callerId) {
        return calleeId;
      }
    }

    // 3. 兜底：从参与者列表中推断
    // 如果参与者列表中只有一个用户，且不是发起人，那可能是本地用户
    if (state.participants.length == 1) {
      final participant = state.participants.first;
      final callerId = state.callerProfile?.userId;
      if (callerId == null || callerId.isEmpty || participant.userId != callerId) {
        return participant.userId;
      }
    }

    // 4. 最终兜底：使用 _resolveLocalUserId()
    // 这会在主叫场景下返回 callerProfile.userId
    return _resolveLocalUserId();
  }

  /// 确保本地用户在参与者列表中（群组通话使用）
  ///
  /// 本地用户加入群组通话时，可能不会收到自己的 groupJoin 事件，
  /// 因此需要在初始化或连接建立时主动将本地用户添加到参与者列表。
  void _ensureLocalUserInParticipants() {
    if (!state.isGroupCall) return;

    final localUserId = _getLocalUserId();
    if (localUserId == null || localUserId.isEmpty) {
      debugPrint('[CallController] 无法获取本地用户ID，跳过添加到参与者列表');
      return;
    }

    // 检查本地用户是否已在参与者列表中
    final alreadyInList = state.participants.any((p) => p.userId == localUserId);
    if (alreadyInList) {
      debugPrint('[CallController] 本地用户已在参与者列表中');
      return;
    }

    // 关键修复：使用真实的用户信息而非硬编码
    // 优先使用 callerProfile（主叫场景）或从后端获取的用户信息
    String displayName = '我';
    String? avatarUrl;
    
    // 主叫场景：callerProfile 是本地用户
    if (state.callerProfile?.userId == localUserId) {
      displayName = state.callerProfile!.displayName.isNotEmpty
          ? '${state.callerProfile!.displayName}(我)'
          : '我';
      avatarUrl = state.callerProfile!.avatarUrl;
    }
    // 被叫场景：尝试从 calleeProfile 获取
    else if (state.calleeProfile?.userId == localUserId) {
      displayName = state.calleeProfile!.displayName.isNotEmpty
          ? '${state.calleeProfile!.displayName}(我)'
          : '我';
      avatarUrl = state.calleeProfile!.avatarUrl;
    }

    // 将本地用户添加到参与者列表
    final localUser = CallParticipantProfile(
      userId: localUserId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      cameraEnabled: state.mediaState.cameraEnabled,
      microphoneEnabled: state.mediaState.microphoneEnabled,
    );

    final updatedParticipants = List<CallParticipantProfile>.from(state.participants)
      ..insert(0, localUser); // 将本地用户放在列表首位

    state = state.copyWith(participants: updatedParticipants);
    debugPrint('[CallController] 已将本地用户添加到参与者列表, userId=$localUserId, displayName=$displayName');
  }

  Future<void> startOutgoing() async {
    debugPrint('[CallController] startOutgoing 被调用, pageStatus=${state.pageStatus}, isOutgoing=${state.isOutgoing}');
    // 路由重建、双击或悬浮窗恢复时，都不能为同一个可见通话重复创建邀请。
    if (_startOutgoingFuture != null) {
      return _startOutgoingFuture!;
    }
    if (_outgoingStarted) {
      return;
    }
    _outgoingStarted = true;
    _startOutgoingFuture = _startOutgoingInternal();
    try {
      await _startOutgoingFuture;
    } finally {
      _startOutgoingFuture = null;
    }
  }

  Future<void> _startOutgoingInternal() async {
    try {
      var effectiveSessionId = state.callSessionId;
      if (state.callSessionId.isEmpty && state.chatId.isNotEmpty && state.callType != null &&
          (state.isGroupCall ? state.groupId != null && state.inviteeIds.isNotEmpty : state.calleeId != null)) {
        debugPrint('[CallController] startOutgoing 开始创建通话邀请, chatId=${state.chatId}');
        final deviceInfo = await _deviceInfoService.getOrCreate();
        final invite = state.isGroupCall
            ? await _callRepository.createGroupInvite(
                chatId: state.chatId,
                groupId: state.groupId!,
                callType: state.callType!,
                inviteeIds: state.inviteeIds,
                deviceId: deviceInfo.deviceId,
              )
            : await _createCallInviteUseCase.execute(
                chatId: state.chatId,
                callType: state.callType!,
                calleeId: state.calleeId!,
              );
        effectiveSessionId = invite.callSessionId;
        debugPrint('[CallController] startOutgoing 创建通话邀请成功, callSessionId=$effectiveSessionId');
        state = state.copyWith(
          callSessionId: effectiveSessionId,
          chatId: invite.chatId.isEmpty ? state.chatId : invite.chatId,
          callType: invite.callType ?? state.callType,
          title: invite.title ?? state.title,
          callerProfile: invite.callerProfile ?? state.callerProfile,
          calleeProfile: invite.calleeProfile ?? state.calleeProfile,
          error: null,
        );
      }
      
      // 准备媒体（获取本地音视频流）
      final mediaState = await _callMediaController.prepare(
        state.mediaState,
        state.callType ?? CallType.audio,
      );
      state = state.copyWith(mediaState: mediaState);
      
      _activeCallRegistry.register(
        _buildLaunchArgs(callSessionId: effectiveSessionId),
      );
      state = state.copyWith(
        pageStatus: CallPageStatus.ringing,
        isOutgoing: true,
      );
      
      debugPrint('[CallController] startOutgoing 即将启动定时器, mounted=$mounted, isOutgoing=${state.isOutgoing}, pageStatus=${state.pageStatus}');
      // 启动30秒无应答自动挂断定时器（参考微信机制）
      _startNoAnswerTimer();
      
      // 注意：发起通话时不立即加入 Janus 房间
      // 等待后端下发 call.media-token-issued 事件时再加入房间
      // 这样可以确保对方接听后才建立 RTC 连接，避免资源浪费
    } catch (error, stackTrace) {
      _outgoingStarted = false;
      // 清理已创建的媒体资源（防止内存泄漏）
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterFailed(
        CallEndReason.rtcError,
        error: AppErrorMapper.map(error, stackTrace),
        mediaState: mediaState,
      );
    }
  }

  Future<void> accept() async {
    if (state.callSessionId.isEmpty) {
      debugPrint('[CallController] accept: callSessionId is empty, cannot accept call');
      _enterFailed(
        CallEndReason.rtcError,
        error: const AppError(message: '通话会话ID无效'),
      );
      return;
    }
    state = state.copyWith(
      pageStatus: CallPageStatus.accepting,
      hasAccepted: true,
    );
    try {
      final deviceInfo = await _deviceInfoService.getOrCreate();
      await _acceptCallUseCase.execute(
        callSessionId: state.callSessionId,
        deviceId: deviceInfo.deviceId,
      );
      final mediaState = await _callMediaController.prepare(
        state.mediaState,
        state.callType ?? CallType.audio,
      );
      state = state.copyWith(
        pageStatus: CallPageStatus.connecting,
        mediaState: mediaState,
      );
      final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
      _activeCallRegistry.register(args);
      // 根据是否是群组通话选择正确的页面
      if (state.isGroupCall) {
        _callCoordinator.openGroupCallSession(args);
      } else {
        _callCoordinator.openCallSession(args);
      }
    } catch (error, stackTrace) {
      // 清理已创建的媒体资源（防止内存泄漏）
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterFailed(
        CallEndReason.permissionDenied,
        error: AppErrorMapper.map(error, stackTrace),
        mediaState: mediaState,
      );
    }
  }

  Future<void> reject() async {
    // 只有当 callSessionId 有效时才调用后端 API
    // 如果通话邀请还没创建成功就拒绝，不需要调用后端
    if (state.callSessionId.isNotEmpty) {
      await _rejectCallUseCase.execute(callSessionId: state.callSessionId);
    }
    // 清理媒体资源（防止内存泄漏）
    final mediaState = await _callMediaController.disposeSession(state.mediaState);
    _enterEnded(CallEndReason.rejectedByCallee, mediaState: mediaState);
  }

  Future<void> cancel() async {
    // 等待 startOutgoing() 完成（如果还在执行中）
    // 这样可以确保 callSessionId 已经被设置
    if (_startOutgoingFuture != null) {
      debugPrint('[CallController] cancel: 等待 startOutgoing 完成...');
      await _startOutgoingFuture;
      debugPrint('[CallController] cancel: startOutgoing 已完成, callSessionId=${state.callSessionId}');
    }
    
    // 只有当 callSessionId 有效时才调用后端 API
    // 如果通话邀请还没创建成功就取消，不需要调用后端
    if (state.callSessionId.isNotEmpty) {
      await _cancelCallUseCase.execute(callSessionId: state.callSessionId);
    }
    // 清理媒体资源（防止内存泄漏）
    final mediaState = await _callMediaController.disposeSession(state.mediaState);
    _enterEnded(CallEndReason.cancelledByCaller, mediaState: mediaState);
  }

  Future<void> hangup() async {
      // 只有当 callSessionId 有效时才调用后端 API。
      // 如果通话还没成功建立就挂断，就不需要调用后端。
    if (state.callSessionId.isEmpty) {
      debugPrint('[CallController] hangup: callSessionId is empty, skip backend API call');
      // 即使 callSessionId 为空，也要清理可能已经创建的媒体资源。
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterEnded(CallEndReason.hangupByLocal, mediaState: mediaState);
      return;
    }
    state = state.copyWith(pageStatus: CallPageStatus.ending);
    if (state.isGroupCall) {
      await _callRepository.leaveGroupCall(callSessionId: state.callSessionId);
    } else {
      await _hangupCallUseCase.execute(callSessionId: state.callSessionId);
    }
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.hangupByLocal, mediaState: mediaState);
  }

  void markConnected() {
    _stopNoAnswerTimer();
    
    // 关键修复：仅在首次进入 connected 状态时启动处理器，避免重复启动
    final wasConnected = state.pageStatus == CallPageStatus.connected;
    
    // 关键修复：先更新状态，再启动计时器
    // 确保计时器第一次 tick 时 pageStatus 已经是 connected
    state = state.copyWith(
      pageStatus: CallPageStatus.connected,
      hasConnected: true,
      mediaState: _callMediaController.markConnected(state.mediaState),
    );
    
    _startElapsedTimer();
    
    // 如果之前已经是 connected 状态，不重复启动处理器
    if (!wasConnected) {
      _startLifecycleHandler();
      _startNetworkRecoveryManager();
      _startSystemInterruptionHandler();
    }
  }

  /// 恢复音频会话（应用从后台恢复时调用）
  ///
  /// 当应用从后台恢复到前台时，音频会话可能已被系统回收或重新配置，
  /// 恢复音频会话（从后台恢复时调用）
  Future<void> restoreAudioSessionFromForeground() async {
    await _callMediaController.restoreAudioSession();
  }

  /// 降低音频焦点（用于系统中断场景，如闹钟响起）
  Future<void> duckAudioFocus() async {
    await _callMediaController.duckAudioFocus();
  }

  /// 恢复音频焦点（用于系统中断结束后）
  Future<void> restoreAudioFocus() async {
    await _callMediaController.restoreAudioFocus();
  }

  /// 调整视频质量（用于低电量或弱网场景）
  Future<void> setVideoQuality({required bool lowQuality}) async {
    await _callMediaController.setVideoQuality(lowQuality: lowQuality);
  }

  void toggleMute() {
    final newMediaState = _callMediaController.toggleMute(state.mediaState);
    state = state.copyWith(mediaState: newMediaState);
    
    // 发送媒体状态更新信令给对端
    _sendMediaStateUpdate(
      cameraEnabled: newMediaState.cameraEnabled,
      microphoneEnabled: newMediaState.microphoneEnabled,
    );
  }

  void toggleSpeaker() {
    state = state.copyWith(
      mediaState: _callMediaController.toggleSpeaker(state.mediaState),
    );
  }

  void toggleCamera() {
    final newMediaState = _callMediaController.toggleCamera(state.mediaState);
    state = state.copyWith(mediaState: newMediaState);
    
    // 发送媒体状态更新信令给对端
    _sendMediaStateUpdate(
      cameraEnabled: newMediaState.cameraEnabled,
      microphoneEnabled: newMediaState.microphoneEnabled,
    );
  }

  void switchCamera() {
    state = state.copyWith(
      mediaState: _callMediaController.switchCamera(state.mediaState),
    );
  }

  /// 发送媒体状态更新信令给对端
  ///
  /// 通过 HTTP API 通知后端，后端再通过 WebSocket 广播给所有参与者
  void _sendMediaStateUpdate({
    required bool cameraEnabled,
    required bool microphoneEnabled,
  }) {
    if (state.callSessionId.isEmpty) return;
    
    _callRepository.sendMediaStateUpdate(
      callSessionId: state.callSessionId,
      cameraEnabled: cameraEnabled,
      microphoneEnabled: microphoneEnabled,
    ).catchError((error, stackTrace) {
      debugPrint('[CallController] 发送媒体状态更新失败: $error');
      return null;
    });
  }

  /// 切换屏幕共享
  Future<void> toggleScreenShare() async {
    try {
      final newMediaState = await _callMediaController.toggleScreenShare(state.mediaState);
      state = state.copyWith(mediaState: newMediaState);
    } catch (e) {
      debugPrint('[CallController] 切换屏幕共享失败: $e');
      state = state.copyWith(
        error: AppError(message: '屏幕共享失败: $e'),
      );
    }
  }

  Future<void> _onSocketEvent(CallSocketEvent event) async {
    // 来电邀请事件：state.callSessionId 可能为空，不能用 callSessionId 过滤
    // 其他事件：必须匹配当前通话会话ID
    final isInviteEvent = event.type == CallSocketEventType.invite ||
        event.type == CallSocketEventType.groupInvite ||
        event.type == CallSocketEventType.missed;
    if (!isInviteEvent && event.callSessionId != state.callSessionId) {
      return;
    }
    // 服务端会拒绝忙线邀请；此处仅处理网络乱序/旧服务端重放的兜底。
    if (isInviteEvent &&
        state.pageStatus != CallPageStatus.initial &&
        state.pageStatus != CallPageStatus.ended &&
        state.pageStatus != CallPageStatus.failed) {
      debugPrint('[CallController] 当前已有活跃通话，拒绝额外来电 event.callSessionId=${event.callSessionId}');
      await _rejectCallUseCase.execute(callSessionId: event.callSessionId);
      return;
    }
    switch (event.type) {
      case CallSocketEventType.accepted:
        await onAccepted(event);
        break;
      case CallSocketEventType.busy:
        await onBusy();
        break;
      case CallSocketEventType.ended:
        await onEnded();
        break;
      case CallSocketEventType.cancelled:
        await onCancelled();
        break;
      case CallSocketEventType.rejected:
        await onRejected();
        break;
      case CallSocketEventType.timeout:
        await onTimeout();
        break;
      case CallSocketEventType.stateSync:
        await onStateSync();
        break;
      case CallSocketEventType.deviceTerminated:
        await onDeviceTerminated();
        break;
      case CallSocketEventType.mediaTokenIssued:
        await onMediaTokenIssued(event);
        break;
      case CallSocketEventType.invite:
        onInviteReceived(event);
        break;
      case CallSocketEventType.callRecord:
        await _handleCallRecord(event);
        break;
      case CallSocketEventType.missed:
        // 未接来电通知，由通知模块处理
        await _handleMissedCall(event);
        break;
      case CallSocketEventType.groupInvite:
        await onGroupInvite(event);
        break;
      case CallSocketEventType.groupJoin:
        await onGroupJoin(event);
        break;
      case CallSocketEventType.groupLeave:
        await onGroupLeave(event);
        break;
      case CallSocketEventType.groupParticipantUpdate:
        await onGroupParticipantUpdate(event);
        break;
      case CallSocketEventType.mediaStateUpdate:
        onMediaStateUpdate(event);
        break;
    }
  }

  /// 处理通话等待（当前通话中收到新来电）
  ///
  /// 参考微信通话等待机制：
  /// 1. 当前通话保持不挂断
  /// 2. 新来电保存为 pendingIncomingCall
  /// 3. UI 层显示通话等待横幅，用户可选择：
  ///    - 保持当前通话（拒绝新来电）
  ///    - 切换到新来电（挂断当前通话，接听新来电）
  Future<void> _handleCallWaiting(CallSocketEvent event) async {
    // 关键修复：支持 1v1 invite 和 groupInvite 两种通话等待场景
    if (event.type != CallSocketEventType.invite &&
        event.type != CallSocketEventType.groupInvite) {
      debugPrint('[CallController] 通话等待：不支持的事件类型（type=${event.type}），忽略');
      return;
    }

    final isGroupInvite = event.type == CallSocketEventType.groupInvite;
    final resolved = _payloadResolver.resolve(
      event.payload,
      fallbackCallSessionId: event.callSessionId,
    );

    // 关键修复：从事件 payload 中提取新来电的 callType，而非使用当前通话类型
    // 新来电可能是音频或视频，与当前通话类型可能不同
    final callTypeStr = event.payload['callType']?.toString() ?? 'audio';
    final newCallType = callTypeStr == 'video' || callTypeStr == '2'
        ? CallType.video : CallType.audio;

    // 群组通话：从 payload 中提取群组相关信息
    final groupId = event.payload['groupId']?.toString();

    // 构建新来电的启动参数
    final newCallArgs = CallLaunchArgs(
      callSessionId: event.callSessionId,
      chatId: event.payload['chatId']?.toString() ?? '',
      callType: newCallType,
      entryMode: CallEntryMode.incoming,
      title: isGroupInvite
          ? (event.payload['callerName']?.toString() ?? '群组通话')
          : resolved.title,
      isGroupCall: isGroupInvite,
      groupId: groupId,
      fromUserId: event.payload['callerId']?.toString() ?? '',
    );

    // 关键修复：使用 CallConflictManager 处理通话冲突
    // 根据冲突结果决定是显示等待界面、自动接受还是自动拒绝
    final conflictResult = await _callConflictManager.handleIncomingCall(newCallArgs);
    
    switch (conflictResult.action) {
      case CallConflictAction.showWaitingUI:
        // 显示通话等待界面，让用户选择
        final pendingCall = PendingIncomingCall(
          callSessionId: event.callSessionId,
          callType: newCallType,
          callerProfile: resolved.callerProfile ?? CallParticipantProfile(
            userId: event.payload['callerId']?.toString() ?? '',
            displayName: event.payload['callerName']?.toString() ?? '未知来电',
            avatarUrl: event.payload['callerAvatar']?.toString(),
          ),
          title: isGroupInvite
              ? (event.payload['callerName']?.toString() ?? '群组通话')
              : resolved.title,
          isGroupCall: isGroupInvite,
          groupId: groupId,
        );

        state = state.copyWith(pendingIncomingCall: pendingCall);
        debugPrint('[CallController] 通话等待：显示等待界面, callSessionId=${pendingCall.callSessionId}, '
            'callType=$newCallType, isGroupCall=$isGroupInvite, caller=${pendingCall.callerProfile.displayName}');
        break;

      case CallConflictAction.accept:
        // 无当前通话，直接处理来电（不保存为 pending）
        debugPrint('[CallController] 通话等待：无当前通话，直接处理来电');
        if (event.type == CallSocketEventType.invite) {
          onInviteReceived(event);
        } else {
          await onGroupInvite(event);
        }
        break;

      case CallConflictAction.reject:
        // 冲突解决策略要求拒绝新来电
        debugPrint('[CallController] 通话等待：冲突解决拒绝新来电, reason=${conflictResult.reason}');
        await _rejectCallUseCase.execute(callSessionId: event.callSessionId);
        break;

      case CallConflictAction.ignore:
        // 重复通知，忽略
        debugPrint('[CallController] 通话等待：重复通知，忽略');
        break;
    }
  }

  /// 处理通话清理（用户登出/被踢时自动终止通话）
  ///
  /// 由 ActiveCallRegistry 在用户登出或设备被踢时调用，
  /// 确保通话资源被正确释放，避免通话泄漏。
  Future<void> _handleCallCleanup(CallCleanupReason reason) async {
    debugPrint('[CallController] 处理通话清理, reason=$reason, callSessionId=${state.callSessionId}');

    // 如果通话已经结束或失败，无需清理
    if (state.pageStatus == CallPageStatus.ended ||
        state.pageStatus == CallPageStatus.failed) {
      debugPrint('[CallController] 通话已结束，跳过清理');
      return;
    }

    // 根据清理原因选择结束原因
    final endReason = switch (reason) {
      CallCleanupReason.userLogout => CallEndReason.hangupByLocal,
      CallCleanupReason.deviceKicked => CallEndReason.kickedByOtherDevice,
      CallCleanupReason.tokenExpired => CallEndReason.networkTimeout,
      CallCleanupReason.tenantSwitch => CallEndReason.hangupByLocal,
      CallCleanupReason.newCallPreempt => CallEndReason.hangupByLocal,
      CallCleanupReason.normalHangup => CallEndReason.hangupByLocal,
    };

    // 清理媒体资源
    final mediaState = await _callMediaController.disposeSession(state.mediaState);

    // 结束通话
    _enterEnded(endReason, mediaState: mediaState);

    debugPrint('[CallController] 通话清理完成');
  }

  /// 通话等待：拒绝待处理来电（保持当前通话）
  Future<void> rejectPendingCall() async {
    final pendingCall = state.pendingIncomingCall;
    if (pendingCall == null) {
      debugPrint('[CallController] 无待处理来电，跳过');
      return;
    }

    try {
      await _rejectCallUseCase.execute(callSessionId: pendingCall.callSessionId);
      debugPrint('[CallController] 通话等待：已拒绝待处理来电, callSessionId=${pendingCall.callSessionId}');
    } catch (e) {
      debugPrint('[CallController] 通话等待：拒绝待处理来电失败: $e');
    }

    state = state.copyWith(pendingIncomingCall: null);
  }

  /// 通话等待：切换到待处理来电（挂断当前通话，接听新来电）
  ///
  /// 流程：
  /// 1. 挂断当前通话
  /// 2. 接听待处理来电
  /// 3. 导航到新来电界面
  Future<void> switchToPendingCall() async {
    final pendingCall = state.pendingIncomingCall;
    if (pendingCall == null) {
      debugPrint('[CallController] 无待处理来电，跳过');
      return;
    }

    debugPrint('[CallController] 通话等待：切换到待处理来电, callSessionId=${pendingCall.callSessionId}');

    // 1. 挂断当前通话
    final currentCallSessionId = state.callSessionId;
    if (currentCallSessionId.isNotEmpty) {
      try {
        await _hangupCallUseCase.execute(callSessionId: currentCallSessionId);
        debugPrint('[CallController] 通话等待：已挂断当前通话');
      } catch (e) {
        debugPrint('[CallController] 通话等待：挂断当前通话失败: $e');
      }
    }

    // 2. 清理当前通话状态（彻底清理，包括悬浮窗）
    // 关键修复：在清理注册表之前，先保存本地用户 ID
    final localUserIdBeforeClear = _getLocalUserId();
    
    final mediaState = await _callMediaController.disposeSession(state.mediaState);
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _activeCallRegistry.clear(currentCallSessionId);
    // 彻底清理悬浮窗状态（防止切换通话时悬浮窗残留）
    _callFloatingWindowManager.forceCleanup();
    
    // 关键修复：取消旧的订阅，防止切换通话后收到旧通话的事件
    _remoteStreamSubscription?.cancel();
    _remoteStreamSubscription = null;
    _networkStatsSubscription?.cancel();
    _networkStatsSubscription = null;
    _speakingFeedSubscription?.cancel();
    _speakingFeedSubscription = null;

    // 3. 接听待处理来电
    try {
      final deviceInfo = await _deviceInfoService.getOrCreate();
      await _acceptCallUseCase.execute(
        callSessionId: pendingCall.callSessionId,
        deviceId: deviceInfo.deviceId,
      );
      debugPrint('[CallController] 通话等待：已接听待处理来电');
    } catch (e) {
      debugPrint('[CallController] 通话等待：接听待处理来电失败: $e');
      // 接听失败时清理已释放的媒体状态
      state = state.copyWith(
        pendingIncomingCall: null,
        mediaState: mediaState,
      );
      return;
    }

    // 4. 重置状态并初始化新通话（使用清理后的 mediaState）
    // 关键修复：完整设置所有必要字段，包括 calleeId（本地用户）、isIncoming、callerProfile
    // 使用清理前保存的 localUserIdBeforeClear，因为此时注册表已被清空
    state = CallState(
      callSessionId: pendingCall.callSessionId,
      callType: pendingCall.callType,
      pageStatus: CallPageStatus.connecting,
      isIncoming: true,
      isOutgoing: false,
      hasAccepted: true,
      callerProfile: pendingCall.callerProfile,
      title: pendingCall.title,
      mediaState: mediaState,
      // 关键修复：使用清理前保存的本地用户 ID
      calleeId: localUserIdBeforeClear,
      // 关键修复：传递群组通话字段，确保导航到正确的通话界面
      isGroupCall: pendingCall.isGroupCall,
      groupId: pendingCall.groupId,
    );

    // 5. 准备媒体并导航到新通话界面
    try {
      final newMediaState = await _callMediaController.prepare(
        state.mediaState,
        pendingCall.callType,
      );
      state = state.copyWith(
        pageStatus: CallPageStatus.connecting,
        mediaState: newMediaState,
      );

      final args = _buildLaunchArgs(
        callSessionId: pendingCall.callSessionId,
        entryMode: CallEntryMode.restore,
      );
      _activeCallRegistry.register(args);
      // 关键修复：根据待处理来电是否是群组通话选择正确的页面
      if (pendingCall.isGroupCall) {
        _callCoordinator.openGroupCallSession(args);
      } else {
        _callCoordinator.openCallSession(args);
      }

      // 6. 重新建立订阅（关键修复：之前取消了旧订阅，需要重新建立）
      _remoteStreamSubscription = _callMediaController.onRemoteStreamChanged.listen(_onRemoteStreamChanged);
      _networkStatsSubscription = _callMediaController.onNetworkStatsChanged.listen(_onNetworkStatsChanged);
      _speakingFeedSubscription = _callMediaController.onSpeakingFeedChanged.listen(_onSpeakingFeedChanged);

      // 7. 重新启动生命周期和网络恢复
      _startLifecycleHandler();
      _startNetworkRecoveryManager();
      _startSystemInterruptionHandler();
    } catch (e) {
      debugPrint('[CallController] 通话等待：准备媒体失败: $e');
      // 准备媒体失败时清理已创建的资源
      final failedMediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterFailed(
        CallEndReason.rtcError,
        error: AppError(message: '切换通话失败: $e'),
        mediaState: failedMediaState,
      );
    }
  }

  /// 处理未接来电通知
  Future<void> _handleMissedCall(CallSocketEvent event) async {
    final callerId = event.payload['callerId']?.toString() ?? '';
    final callerName = event.payload['callerName']?.toString() ?? '';
    final callId = event.payload['callId']?.toString() ?? '';
    final callTypeStr = event.payload['callType']?.toString() ?? 'audio';
    final callType = callTypeStr == 'video' || callTypeStr == '2' ? '视频' : '语音';
    
    debugPrint('[CallController] 收到未接来电通知, callId=$callId, callerId=$callerId, callerName=$callerName');
    
    // 关键修复：当应用不在前台时，使用 CallNotificationManager 显示来电通知
    // 这确保了用户在应用后台时也能收到来电提醒
    // 同时检查通话状态，避免在通话中显示未接来电通知
    final isAppInForeground = AppLifecycleManager().isResumed;
    final isCallIdle = state.pageStatus == CallPageStatus.initial || 
        state.pageStatus == CallPageStatus.ended ||
        state.pageStatus == CallPageStatus.failed;
    
    if (!isAppInForeground && isCallIdle) {
      try {
        await CallNotificationManager.instance.showIncomingCallNotification(
          callType: callType,
          callerName: callerName,
          callSessionId: event.callSessionId,
        );
      } catch (e) {
        debugPrint('[CallController] 显示未接来电通知失败: $e');
      }
    }
  }

  /// 处理群组通话邀请
  Future<void> onGroupInvite(CallSocketEvent event) async {
    debugPrint('[CallController] 收到群组通话邀请');
    
    final groupId = event.payload['groupId']?.toString() ?? '';
    final rawInvitees = event.payload['inviteeIds'];
    final inviteeIds = rawInvitees is List
        ? rawInvitees.map((id) => id.toString()).toList(growable: false)
        : const <String>[];
    
    // 解析发起人信息
    final callerId = event.payload['callerId']?.toString() ?? '';
    final callerName = event.payload['callerName']?.toString();
    final callerAvatar = event.payload['callerAvatar']?.toString();
    final callTypeStr = event.payload['callType']?.toString() ?? 'audio';
    final callType = callTypeStr == 'video' || callTypeStr == '2'
        ? CallType.video : CallType.audio;
    
    final callerProfile = CallParticipantProfile(
      userId: callerId,
      displayName: callerName ?? '未知用户',
      avatarUrl: callerAvatar,
    );
    
    // 构建 CallLaunchArgs
    final args = CallLaunchArgs(
      callSessionId: event.callSessionId,
      chatId: event.payload['chatId']?.toString() ?? '',
      callType: callType,
      entryMode: CallEntryMode.incoming,
      title: callerName ?? '群组通话',
      isGroupCall: true,
      groupId: groupId,
      inviteeIds: inviteeIds,
    );
    
    // 注册到 ActiveCallRegistry
    _activeCallRegistry.register(args);
    
    // 更新状态
    state = state.copyWith(
      callSessionId: event.callSessionId,
      chatId: args.chatId,
      callType: callType,
      entryMode: CallEntryMode.incoming,
      isIncoming: true,
      isOutgoing: false,
      pageStatus: CallPageStatus.ringing,
      endReason: CallEndReason.none,
      title: callerName ?? '群组通话',
      callerProfile: callerProfile,
      isGroupCall: true,
      groupId: groupId,
      inviteeIds: inviteeIds,
    );
    
    // 导航到群聊来电界面
    _callCoordinator.openIncomingCall(args);
  }

  /// 处理群组通话加入
  Future<void> onGroupJoin(CallSocketEvent event) async {
    debugPrint('[CallController] 参与者加入群组通话');
    
    final userId = event.payload['userId']?.toString() ?? '';
    final userName = event.payload['userName']?.toString() ?? '';
    final avatarUrl = event.payload['avatarUrl']?.toString();
    
    final newParticipant = CallParticipantProfile(
      userId: userId,
      displayName: userName,
      avatarUrl: avatarUrl,
    );
    
    final currentParticipants = List<CallParticipantProfile>.from(state.participants);
    if (!currentParticipants.any((p) => p.userId == userId)) {
      currentParticipants.add(newParticipant);
      state = state.copyWith(participants: currentParticipants);
    }
  }

  /// 处理群组通话离开
  ///
  /// 关键修复：使用统一的 _getLocalUserId() 方法判断本地用户，
  /// 而不是使用不可靠的 callerProfile/calleeProfile 推断
  Future<void> onGroupLeave(CallSocketEvent event) async {
    debugPrint('[CallController] 参与者离开通群组通话');
    
    final userId = event.payload['userId']?.toString() ?? '';
    
    // 关键修复：使用统一的 _getLocalUserId() 方法判断本地用户
    final localUserId = _getLocalUserId() ?? '';
    
    final isLocalUserLeft = userId.isNotEmpty && 
                           localUserId.isNotEmpty && 
                           userId == localUserId;
    
    final currentParticipants = List<CallParticipantProfile>.from(state.participants);
    currentParticipants.removeWhere((p) => p.userId == userId);
    state = state.copyWith(participants: currentParticipants);
    
    // 关键修复：如果是本地用户离开，或者所有人都离开了，结束通话并彻底清理资源
    if (isLocalUserLeft || currentParticipants.isEmpty) {
      debugPrint('[CallController] 群聊通话结束: ${isLocalUserLeft ? "本地用户离开" : "所有人离开"}');
      
      // 清理媒体资源后直接调用 _enterEnded，由其统一处理所有清理逻辑
      // 避免重复清理和竞态条件
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterEnded(
        isLocalUserLeft ? CallEndReason.hangupByLocal : CallEndReason.hangupByRemote,
        mediaState: mediaState,
      );
    }
  }

  /// 处理群组通话参与者更新
  ///
  /// 关键修复：后端推送的参与者列表可能不包含本地用户（因为本地用户加入时
  /// 不会收到自己的 groupJoin 事件），需要确保本地用户始终在参与者列表中。
  Future<void> onGroupParticipantUpdate(CallSocketEvent event) async {
    debugPrint('[CallController] 群组通话参与者更新');
    
    final participantsList = event.payload['participants'] as List? ?? [];
    final participants = participantsList.map((p) {
      return CallParticipantProfile(
        userId: p['userId']?.toString() ?? '',
        displayName: p['userName']?.toString() ?? '',
        avatarUrl: p['avatarUrl']?.toString(),
        cameraEnabled: p['cameraEnabled'] as bool? ?? true,
        microphoneEnabled: p['microphoneEnabled'] as bool? ?? true,
      );
    }).toList();
    
    state = state.copyWith(participants: participants);
    
    // 关键修复：确保本地用户始终在参与者列表中
    // 后端推送的参与者列表可能不包含本地用户
    _ensureLocalUserInParticipants();
  }

  /// 处理媒体状态更新事件（1:1 通话和群组通话）
  ///
  /// 当对端切换摄像头/麦克风开关时，后端会广播此事件
  /// 需要更新对端的媒体状态，以便 UI 显示正确的图标
  void onMediaStateUpdate(CallSocketEvent event) {
    final fromUserId = event.payload['fromUserId']?.toString() ?? '';
    final cameraEnabled = event.payload['cameraEnabled'] as bool? ?? true;
    final microphoneEnabled = event.payload['microphoneEnabled'] as bool? ?? true;
    
    debugPrint('[CallController] 收到媒体状态更新, fromUserId=$fromUserId, cameraEnabled=$cameraEnabled, microphoneEnabled=$microphoneEnabled');
    
    // 群组通话场景：更新参与者列表中的媒体状态
    if (state.isGroupCall) {
      final updatedParticipants = state.participants.map((p) {
        if (p.userId == fromUserId) {
          return p.copyWith(
            cameraEnabled: cameraEnabled,
            microphoneEnabled: microphoneEnabled,
          );
        }
        return p;
      }).toList();
      
      state = state.copyWith(participants: updatedParticipants);
      debugPrint('[CallController] 已更新群组通话参与者媒体状态, userId=$fromUserId');
      return;
    }
    
    // 1:1 通话场景：更新 callerProfile 或 calleeProfile
    // 如果当前用户是 caller，则对方是 callee；反之亦然
    if (state.isIncoming) {
      // 当前用户是被叫，对方是主叫（callerProfile）
      if (state.callerProfile != null) {
        final updatedCallerProfile = state.callerProfile!.copyWith(
          cameraEnabled: cameraEnabled,
          microphoneEnabled: microphoneEnabled,
        );
        state = state.copyWith(callerProfile: updatedCallerProfile);
      }
    } else {
      // 当前用户是主叫，对方是被叫（calleeProfile）
      if (state.calleeProfile != null) {
        final updatedCalleeProfile = state.calleeProfile!.copyWith(
          cameraEnabled: cameraEnabled,
          microphoneEnabled: microphoneEnabled,
        );
        state = state.copyWith(calleeProfile: updatedCalleeProfile);
      }
    }
  }

  void onInviteReceived(CallSocketEvent event) {
    final resolved = _payloadResolver.resolve(
      event.payload,
      fallbackCallSessionId: event.callSessionId,
    );
    final args = _buildLaunchArgs(
      callSessionId: event.callSessionId,
      entryMode: CallEntryMode.incoming,
    );
    _activeCallRegistry.register(args);
    state = state.copyWith(
      callSessionId: event.callSessionId,
      entryMode: CallEntryMode.incoming,
      isIncoming: true,
      isOutgoing: false,
      pageStatus: CallPageStatus.ringing,
      endReason: CallEndReason.none,
      title: resolved.title ?? state.title,
      callerProfile: resolved.callerProfile ?? state.callerProfile,
      calleeProfile: resolved.calleeProfile ?? state.calleeProfile,
      acceptedDeviceId: resolved.acceptedDeviceId,
      roomBundle: resolved.roomBundle,
    );
    // 导航到来电界面
    _callCoordinator.openIncomingCall(args);
  }

  /// 处理接听事件
  /// 
  /// 多设备场景：当任一设备接听后，其他设备收到 call.accepted 事件，
  /// 需要判断是否是当前设备接听的，如果不是，则关闭来电界面。
  Future<void> onAccepted(CallSocketEvent event) async {
    // 获取接听设备ID
    final acceptedDeviceId = event.payload['acceptedDeviceId']?.toString();
    
    // 获取当前设备ID
    final deviceInfo = await _deviceInfoService.getOrCreate();
    final currentDeviceId = deviceInfo.deviceId;
    
    // 多设备场景：如果接听设备不是当前设备，关闭来电界面
    if (!state.isOutgoing &&
        acceptedDeviceId != null &&
        acceptedDeviceId.isNotEmpty &&
        acceptedDeviceId != currentDeviceId) {
      debugPrint('[CallController] 通话已在其他设备接听, acceptedDeviceId=$acceptedDeviceId, currentDeviceId=$currentDeviceId');
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterEnded(CallEndReason.kickedByOtherDevice, mediaState: mediaState);
      return;
    }
    
    // 当前设备接听，进入通话
    _enterConnecting();
    if (state.entryMode != CallEntryMode.restore) {
      final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
      _activeCallRegistry.register(args);
      // 关键修复：群组通话被叫方接听后，由 GroupCallSessionPage 自行处理初始化
      // 避免重复导航（被叫方已经在 GroupCallSessionPage 中）
      // 1v1 通话需要导航到通话界面
      if (!state.isGroupCall) {
        _callCoordinator.openCallSession(args);
      }
    }
    // 注意：不在这里启动处理器，等待远端流到达时在 _onRemoteStreamChanged 中统一启动
    // 这样可以避免重复启动，并确保在通话真正建立后才启动处理器
  }

  Future<void> onRejected() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.rejectedByCallee, mediaState: mediaState);
  }

  Future<void> onBusy() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.busy, mediaState: mediaState);
  }

  Future<void> onCancelled() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.cancelledByCaller, mediaState: mediaState);
  }

  Future<void> onEnded() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.hangupByRemote, mediaState: mediaState);
  }

  Future<void> onTimeout() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.noAnswer, mediaState: mediaState);
  }

  Future<void> onStateSync() async {
    final synced = await _syncActiveCallStateUseCase.execute(
      callSessionId: state.callSessionId,
    );
    _applySyncedState(synced);
    if (synced.pageStatus == CallPageStatus.connected) {
      _activeCallRegistry.register(
        _buildLaunchArgs(entryMode: CallEntryMode.restore),
      );
      // 确保处理器在连接状态下运行
      _startLifecycleHandler();
      _startNetworkRecoveryManager();
      _startSystemInterruptionHandler();
      // 关键修复：在所有状态更新和处理器启动完成后，再启动计时器
      _startElapsedTimer();
    } else if (synced.pageStatus == CallPageStatus.reconnecting ||
        synced.pageStatus == CallPageStatus.connecting) {
      _stopElapsedTimer();
    } else if (synced.pageStatus == CallPageStatus.ended ||
        synced.pageStatus == CallPageStatus.failed) {
      // 关键修复：服务端说通话已结束/失败时，客户端必须彻底清理所有资源
      // 之前只清理了 activeCallRegistry 和 timer，遗漏了处理器和媒体资源
      _stopElapsedTimer();
      _stopNoAnswerTimer();
      _stopLifecycleHandler();
      _stopNetworkRecoveryManager();
      _stopSystemInterruptionHandler();
      _activeCallRegistry.clear(state.callSessionId);
      _callFloatingWindowManager.forceCleanup();

      // 清理媒体资源（防止内存泄漏）
      final mediaState = await _callMediaController.disposeSession(state.mediaState);
      state = state.copyWith(mediaState: mediaState);
    }
  }

  Future<void> onDeviceTerminated() async {
    final mediaState = await _callMediaController.disposeSession(
      state.mediaState,
    );
    _enterEnded(CallEndReason.kickedByOtherDevice, mediaState: mediaState);
  }

  Future<void> onMediaTokenIssued(CallSocketEvent event) async {
    // 关键修复：添加状态守卫，如果通话已结束/失败，不再处理媒体令牌
    if (state.pageStatus == CallPageStatus.ended ||
        state.pageStatus == CallPageStatus.failed) {
      debugPrint('[CallController] onMediaTokenIssued: 通话已结束/失败，忽略媒体令牌');
      return;
    }

    final resolved = _payloadResolver.resolve(
      event.payload,
      fallbackCallSessionId: state.callSessionId,
    );
    final roomBundle = resolved.roomBundle ?? state.roomBundle;
    final acceptedDeviceId =
        resolved.acceptedDeviceId ?? state.acceptedDeviceId;
    var mediaState = state.mediaState;
    try {
      if (roomBundle != null) {
        mediaState = await _callMediaController.prepareJoin(
          state.mediaState,
          callType: state.callType ?? CallType.audio,
          roomBundle: roomBundle,
        );
      }
    } catch (error, stackTrace) {
      // 关键修复：prepareJoin 失败时清理已创建的媒体资源（防止内存泄漏）
      // prepareJoin 内部失败时会调用 disposeSession，但保险起见再次确保清理
      final failedMediaState = await _callMediaController.disposeSession(state.mediaState);
      _enterFailed(
        CallEndReason.rtcError,
        error: AppErrorMapper.map(error, stackTrace),
        mediaState: failedMediaState,
      );
      return;
    }
    if (state.pageStatus == CallPageStatus.accepting ||
        state.pageStatus == CallPageStatus.ringing ||
        state.pageStatus == CallPageStatus.connecting) {
      _enterConnecting(
        acceptedDeviceId: acceptedDeviceId,
        roomBundle: roomBundle,
        mediaState: mediaState,
      );
      
      // 关键修复：主叫方收到媒体令牌后，需要导航到通话界面
      // 但群组通话主叫方已经在 GroupOutgoingCallPage，不需要重复导航
      // 1v1 通话主叫方需要导航到 CallSessionPage
      if (state.isOutgoing && state.entryMode != CallEntryMode.restore) {
        final args = _buildLaunchArgs(entryMode: CallEntryMode.restore);
        _activeCallRegistry.register(args);
        if (!state.isGroupCall) {
          _callCoordinator.openCallSession(args);
        }
      }
    }
  }

  void markReconnecting() {
    _stopElapsedTimer();
    state = state.copyWith(
      pageStatus: CallPageStatus.reconnecting,
      mediaState: _callMediaController.markReconnecting(state.mediaState),
    );
  }

  void restoreConnected() {
    // 关键修复：先更新状态，再启动计时器
    // 确保计时器第一次 tick 时 pageStatus 已经是 connected
    state = state.copyWith(
      pageStatus: CallPageStatus.connected,
      hasConnected: true,
      mediaState: _callMediaController.markConnected(state.mediaState),
    );
    _startElapsedTimer();
  }

  Future<void> markRtcFailure({
    CallEndReason endReason = CallEndReason.rtcError,
  }) async {
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _activeCallRegistry.clear(state.callSessionId);
    _callFloatingWindowManager.forceCleanup();
    
    // 清理媒体资源（防止内存泄漏）
    final mediaState = await _callMediaController.disposeSession(state.mediaState);
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: endReason,
      mediaState: mediaState,
    );
  }

  Future<void> markPermissionDenied() async {
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _activeCallRegistry.clear(state.callSessionId);
    _callFloatingWindowManager.forceCleanup();
    
    // 清理媒体资源（防止内存泄漏）
    final mediaState = await _callMediaController.disposeSession(state.mediaState);
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: CallEndReason.permissionDenied,
      mediaState: mediaState,
    );
  }

  void markRemoteTrackReady() {
    if (state.pageStatus == CallPageStatus.connecting ||
        state.pageStatus == CallPageStatus.reconnecting) {
      restoreConnected();
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    debugPrint('[CallController] 启动通话计时器, mounted=$mounted, pageStatus=${state.pageStatus}');
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final shouldTick = mounted && state.pageStatus == CallPageStatus.connected;
      if (shouldTick) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  /// 启动30秒无应答自动挂断定时器
  ///
  /// 参考微信机制：发起通话后30秒内对方未接听，自动取消通话
  /// 仅在发起方（outgoing）的 ringing/connecting 阶段生效
  ///
  /// 关键修复：在定时器启动时捕获状态快照（isOutgoingAtStart、statusAtStart），
  /// 而不是在回调中读取 state 的最新值。因为 state 是不可变对象，
  /// 30秒内可能被 copyWith 重建，导致 isOutgoing 等字段被意外覆盖。
  void _startNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    // 捕获启动时的状态快照，避免回调时 state 已被重建导致字段变化
    final isOutgoingAtStart = state.isOutgoing;
    final statusAtStart = state.pageStatus;
    debugPrint('[CallController] 启动30秒无应答定时器, isOutgoing=$isOutgoingAtStart, pageStatus=$statusAtStart');
    _noAnswerTimer = Timer(const Duration(seconds: 30), () {
      final currentStatus = state.pageStatus;
      debugPrint('[CallController] 30秒定时器触发, '
          'capturedIsOutgoing=$isOutgoingAtStart, currentIsOutgoing=${state.isOutgoing}, '
          'capturedStatus=$statusAtStart, currentStatus=$currentStatus');

      // 使用启动时捕获的 isOutgoing 快照判断方向
      // 只要通话尚未接通（非 connected/ended/failed），都应该触发自动取消
      if (isOutgoingAtStart &&
          currentStatus != CallPageStatus.connected &&
          currentStatus != CallPageStatus.ended &&
          currentStatus != CallPageStatus.failed) {
        debugPrint('[CallController] 30秒无应答，自动取消通话 (currentStatus=$currentStatus)');
        // 使用 Future.microtask 确保在同步上下文中启动异步操作
        Future.microtask(() async {
          try {
            await cancel();
            debugPrint('[CallController] 30秒自动取消通话成功');
          } catch (e, stackTrace) {
            debugPrint('[CallController] 30秒自动取消通话失败: $e\n$stackTrace');
          }
        });
      } else {
        debugPrint('[CallController] 30秒定时器触发但状态不满足: capturedIsOutgoing=$isOutgoingAtStart, currentStatus=$currentStatus');
      }
    });
  }

  /// 停止无应答定时器
  void _stopNoAnswerTimer() {
    debugPrint('[CallController] 停止30秒无应答定时器, isActive=${_noAnswerTimer?.isActive}');
    _noAnswerTimer?.cancel();
    _noAnswerTimer = null;
  }

  /// 启动通话生命周期管理器
  ///
  /// [forceRestart] 为 true 时强制重启（用于重连后恢复监听），
  /// 为 false 时仅在未启动时启动（幂等，避免中断已有监听）。
  void _startLifecycleHandler({bool forceRestart = false}) {
    if (!forceRestart && _lifecycleHandler != null) {
      debugPrint('[CallController] 通话生命周期管理器已在运行，跳过启动');
      return;
    }
    _lifecycleHandler?.stop();
    _lifecycleHandler = CallLifecycleHandler(callController: this);
    _lifecycleHandler!.start();
    debugPrint('[CallController] 通话生命周期管理器已启动');
  }

  /// 停止通话生命周期管理器
  void _stopLifecycleHandler() {
    _lifecycleHandler?.stop();
    _lifecycleHandler = null;
    debugPrint('[CallController] 通话生命周期管理器已停止');
  }

  /// 启动网络恢复管理器
  ///
  /// [forceRestart] 为 true 时强制重启（用于重连后恢复监听），
  /// 为 false 时仅在未启动时启动（幂等，避免中断已有监听）。
  void _startNetworkRecoveryManager({bool forceRestart = false}) {
    if (!forceRestart && _networkRecoveryManager != null) {
      debugPrint('[CallController] 网络恢复管理器已在运行，跳过启动');
      return;
    }
    _networkRecoveryManager?.dispose();
    _networkRecoveryManager = NetworkRecoveryManager(
      callController: this,
      syncActiveCallStateUseCase: _syncActiveCallStateUseCase,
      callMediaController: _callMediaController,
    );
    _networkRecoveryManager!.startNetworkMonitoring();
    debugPrint('[CallController] 网络恢复管理器已启动');
  }

  /// 停止网络恢复管理器
  void _stopNetworkRecoveryManager() {
    _networkRecoveryManager?.dispose();
    _networkRecoveryManager = null;
    debugPrint('[CallController] 网络恢复管理器已停止');
  }

  /// 启动系统中断处理器
  ///
  /// [forceRestart] 为 true 时强制重启（用于重连后恢复监听），
  /// 为 false 时仅在未启动时启动（幂等，避免中断已有监听）。
  void _startSystemInterruptionHandler({bool forceRestart = false}) {
    if (!forceRestart && _systemInterruptionHandler != null) {
      debugPrint('[CallController] 系统中断处理器已在运行，跳过启动');
      return;
    }
    _systemInterruptionHandler?.dispose();
    _systemInterruptionHandler = SystemInterruptionHandler(callController: this);
    debugPrint('[CallController] 系统中断处理器已启动');
  }

  /// 停止系统中断处理器
  void _stopSystemInterruptionHandler() {
    _systemInterruptionHandler?.dispose();
    _systemInterruptionHandler = null;
    debugPrint('[CallController] 系统中断处理器已停止');
  }

  /// 网络重连成功后重启处理器
  ///
  /// 关键修复：NetworkRecoveryManager 在重连成功后需要重启生命周期处理器和系统中断处理器，
  /// 因为进入重连状态时这些处理器被停止了，但重连成功后必须恢复它们的监听。
  /// 使用 forceRestart=true 强制重启，确保监听被重新建立。
  void restartHandlersAfterReconnect() {
    _startLifecycleHandler(forceRestart: true);
    _startSystemInterruptionHandler(forceRestart: true);
    debugPrint('[CallController] 网络重连成功后重启处理器');
  }

  /// 记录通话结束信息
  ///
  /// 通话记录由后端在 hangup/accept/reject/cancel 等操作时自动创建并持久化，
  /// 客户端无需单独调用保存 API。此方法仅用于日志记录和清理本地状态。
  void _logCallEnd(CallEndReason endReason) {
    if (state.callSessionId.isEmpty) {
      debugPrint('[CallController] 通话会话ID为空，跳过记录');
      return;
    }

    final duration = state.elapsedSeconds;
    debugPrint('[CallController] 通话结束: callSessionId=${state.callSessionId}, '
        'duration=${duration}s, endReason=$endReason');
  }

  void _enterEnded(CallEndReason endReason, {CallMediaState? mediaState}) {
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _activeCallRegistry.clear(state.callSessionId);
    // 通话结束时彻底清理悬浮窗状态（包括保存的媒体状态）
    _callFloatingWindowManager.forceCleanup();
    
    // 关键修复：取消所有订阅，防止通话结束后仍接收事件导致内存泄漏
    // 这些订阅在 initialize() 中创建，在通话结束时应该被取消
    _remoteStreamSubscription?.cancel();
    _remoteStreamSubscription = null;
    _networkStatsSubscription?.cancel();
    _networkStatsSubscription = null;
    _speakingFeedSubscription?.cancel();
    _speakingFeedSubscription = null;
    
    // 关键修复：通话结束时清理所有通知（包括后台通话通知和来电通知）
    // 确保通话结束后不会残留任何通话相关通知
    CallNotificationManager.instance.cancelAllNotifications();
    
    // 记录通话结束信息
    _logCallEnd(endReason);
    
    state = state.copyWith(
      pageStatus: CallPageStatus.ended,
      endReason: endReason,
      mediaState: mediaState ?? state.mediaState,
    );
  }

  void _enterFailed(CallEndReason endReason, {required AppError error, CallMediaState? mediaState}) {
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _activeCallRegistry.clear(state.callSessionId);
    // 通话失败时彻底清理悬浮窗状态（包括保存的媒体状态）
    _callFloatingWindowManager.forceCleanup();
    
    // 关键修复：取消所有订阅，防止通话失败后仍接收事件导致内存泄漏
    // 这些订阅在 initialize() 中创建，在通话失败时应该被取消
    _remoteStreamSubscription?.cancel();
    _remoteStreamSubscription = null;
    _networkStatsSubscription?.cancel();
    _networkStatsSubscription = null;
    _speakingFeedSubscription?.cancel();
    _speakingFeedSubscription = null;
    
    // 关键修复：通话失败时也要清理所有通知
    CallNotificationManager.instance.cancelAllNotifications();
    
    // 记录通话结束信息（即使是失败的通话也要记录）
    _logCallEnd(endReason);
    
    state = state.copyWith(
      pageStatus: CallPageStatus.failed,
      endReason: endReason,
      error: error,
      mediaState: mediaState ?? state.mediaState,
    );
  }

  void _applySyncedState(ActiveCallStateResult synced) {
    final nextPageStatus = synced.pageStatus;
    state = state.copyWith(
      pageStatus: nextPageStatus,
      elapsedSeconds: synced.elapsedSeconds,
      callSessionId: synced.callSessionId.isEmpty
          ? state.callSessionId
          : synced.callSessionId,
      chatId: synced.chatId.isEmpty ? state.chatId : synced.chatId,
      callType: synced.callType ?? state.callType,
      title: synced.title ?? state.title,
      callerProfile: synced.callerProfile ?? state.callerProfile,
      calleeProfile: synced.calleeProfile ?? state.calleeProfile,
      acceptedDeviceId: synced.acceptedDeviceId ?? state.acceptedDeviceId,
      roomBundle: synced.roomBundle ?? state.roomBundle,
      mediaState: _syncMediaStateWithPageStatus(
        state.mediaState,
        nextPageStatus,
      ),
      error: nextPageStatus == CallPageStatus.failed ? state.error : null,
    );
  }

  CallMediaState _syncMediaStateWithPageStatus(
    CallMediaState current,
    CallPageStatus pageStatus,
  ) {
    switch (pageStatus) {
      case CallPageStatus.connected:
        return _callMediaController.markConnected(current);
      case CallPageStatus.reconnecting:
        return _callMediaController.markReconnecting(current);
      case CallPageStatus.connecting:
      case CallPageStatus.accepting:
      case CallPageStatus.loading:
        return current.copyWith(
          rtcConnectionStatus: current.localTrackReady
              ? RtcConnectionStatus.joining
              : RtcConnectionStatus.preparing,
        );
      case CallPageStatus.ended:
      case CallPageStatus.failed:
        return _callMediaController.markFailed(current);
      case CallPageStatus.initial:
      case CallPageStatus.ringing:
      case CallPageStatus.ending:
        return current;
    }
  }

  void _enterConnecting({
    String? acceptedDeviceId,
    RtcRoomBundle? roomBundle,
    CallMediaState? mediaState,
  }) {
    state = state.copyWith(
      pageStatus: CallPageStatus.connecting,
      acceptedDeviceId: acceptedDeviceId ?? state.acceptedDeviceId,
      roomBundle: roomBundle ?? state.roomBundle,
      mediaState: mediaState ?? state.mediaState,
    );
  }

  CallLaunchArgs _buildLaunchArgs({
    String? callSessionId,
    CallEntryMode? entryMode,
  }) {
    // 关键修复：正确设置 fromUserId（本地用户ID），用于群组通话本地用户识别
    // 优先级：callerProfile.userId（主叫方）> calleeId（被叫方场景）
    final localUserId = _resolveLocalUserId();
    
    return CallLaunchArgs(
      callSessionId: callSessionId ?? state.callSessionId,
      chatId: state.chatId,
      callType: state.callType ?? CallType.audio,
      entryMode: entryMode ?? state.entryMode ?? CallEntryMode.outgoing,
      title: state.title,
      inviteId: null,
      fromUserId: localUserId,
      toUserId: null,
      // 关键修复：传递群组通话字段，防止恢复/导航时丢失群组信息
      isGroupCall: state.isGroupCall,
      groupId: state.groupId,
      inviteeIds: state.inviteeIds,
    );
  }

  /// 解析本地用户ID
  ///
  /// 根据通话方向判断本地用户：
  /// - 主叫（isOutgoing）：本地用户是 callerProfile.userId
  /// - 被叫（isIncoming）：本地用户是 calleeId
  /// - 兜底：从 authSession 获取当前登录用户ID
  String? _resolveLocalUserId() {
    // 主叫场景：本地用户是发起方（callerProfile.userId）
    if (state.isOutgoing && state.callerProfile?.userId != null &&
        state.callerProfile!.userId.isNotEmpty) {
      return state.callerProfile!.userId;
    }
    // 被叫场景：本地用户是接听方（calleeId）
    if (state.isIncoming && state.calleeId != null && state.calleeId!.isNotEmpty) {
      return state.calleeId;
    }
    // 最终兜底：从 authSession 获取当前登录用户ID
    // 用于群组通话等场景，当 state 中的用户信息不完整时
    if (_authSession != null && _authSession.userId.isNotEmpty) {
      return _authSession.userId;
    }
    return null;
  }

  /// 处理通话记录事件
  ///
  /// 将后端下发的通话记录转换为 Message 对象，并通过 Stream 暴露给聊天页面
  Future<void> _handleCallRecord(CallSocketEvent event) async {
    try {
      // 解析通话记录 DTO
      final dto = _payloadResolver.resolveCallRecord(event.payload);

      // 关键修复：改进当前用户 ID 获取逻辑，过滤空字符串
      // 1. 优先从事件 payload 中获取（如果后端有提供）
      // 2. 从 state 中获取，过滤空字符串
      // 3. 从 ActiveCallRegistry 获取，过滤空字符串
      String? currentUserId = event.payload['currentUserId']?.toString();

      if (currentUserId == null || currentUserId.isEmpty) {
        // 从 state 中获取，优先使用非空字符串
        final candidates = [
          state.callerProfile?.userId,
          state.calleeProfile?.userId,
          _activeCallRegistry.current?.fromUserId,
        ].where((id) => id != null && id.isNotEmpty).toList();

        currentUserId = candidates.isNotEmpty ? candidates.first : null;
      }

      if (currentUserId == null || currentUserId.isEmpty) {
        debugPrint('[CallController] 无法获取当前用户 ID，跳过通话记录处理');
        return;
      }

      // 转换为 Message 对象
      const mapper = CallDtoMapper();
      final message = mapper.toCallRecordMessage(dto, currentUserId);

      // 通过 Stream 发送
      if (!_callRecordController.isClosed) {
        _callRecordController.add(message);
        debugPrint('[CallController] 通话记录已发送: ${dto.callId}, chatId=${dto.chatId}');
      }
    } catch (e, stackTrace) {
      debugPrint('[CallController] 处理通话记录失败: $e\n$stackTrace');
    }
  }

  /// 异步清理资源（在 dispose 前调用）
  ///
  /// 关键修复：在 super.dispose() 前捕获状态快照，避免异步回调中访问已销毁的 state
  Future<void> _disposeAsync(CallPageStatus currentPageStatus, CallMediaState currentMediaState) async {
    debugPrint('[CallController] _disposeAsync 开始, pageStatus=$currentPageStatus');

    // 如果通话还在进行中（非 ended/failed），先清理媒体会话资源
    if (currentPageStatus != CallPageStatus.ended &&
        currentPageStatus != CallPageStatus.failed &&
        currentPageStatus != CallPageStatus.initial) {
      debugPrint('[CallController] _disposeAsync: 通话仍在进行中，清理媒体资源');
      try {
        await _callMediaController.disposeSession(currentMediaState);
        debugPrint('[CallController] _disposeAsync: 媒体会话清理完成');
      } catch (e) {
        debugPrint('[CallController] _disposeAsync: 媒体会话清理失败: $e');
      }
    }

    // 彻底销毁媒体控制器（关闭 StreamController）
    try {
      await _callMediaController.dispose();
      debugPrint('[CallController] _disposeAsync: 媒体控制器销毁完成');
    } catch (e) {
      debugPrint('[CallController] _disposeAsync: 媒体控制器销毁失败: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('[CallController] dispose 被调用, pageStatus=${state.pageStatus}');
    
    // 关键修复：在 super.dispose() 前捕获状态快照，避免异步回调中访问已销毁的 state
    final currentPageStatus = state.pageStatus;
    final currentMediaState = state.mediaState;
    
    _stopElapsedTimer();
    _stopNoAnswerTimer();
    _stopLifecycleHandler();
    _stopNetworkRecoveryManager();
    _stopSystemInterruptionHandler();
    _socketSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _networkStatsSubscription?.cancel();
    _speakingFeedSubscription?.cancel();
    _callRecordController.close();

    // 关键修复：异步清理不能在 dispose() 中等待
    // StateNotifier.dispose() 是同步方法，不能等待异步操作
    // 解决方案：使用 unawaited 明确标记不等待，但确保资源最终会被清理
    // 注意：在 super.dispose() 后不能再访问 state，所以必须传入快照
    unawaited(_disposeAsync(currentPageStatus, currentMediaState).then((_) {
      debugPrint('[CallController] dispose: 异步清理完成');
    }).catchError((e) {
      debugPrint('[CallController] dispose: 异步清理失败: $e');
    }));

    super.dispose();
  }
}
