import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shengyu_ui_admin_im/app/router/route_args/call_launch_args.dart';
import 'package:shengyu_ui_admin_im/features/im/call/domain/entities/rtc_room_bundle.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/adaptive_bitrate_controller.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/audio_level_monitor.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/janus_client.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/janus_video_room_plugin.dart';
import 'package:shengyu_ui_admin_im/features/im/call/infrastructure/rtc/network_quality_monitor.dart';
import 'package:shengyu_ui_admin_im/features/im/call/presentation/states/call_media_state.dart';

class CallPermissionCoordinator {
  const CallPermissionCoordinator();

  Future<void> ensurePermissions({required CallType callType}) async {
    // 请求麦克风权限
    final micStatus = await Permission.microphone.request();
    if (micStatus.isPermanentlyDenied) {
      throw PermissionException(
        '麦克风权限被永久拒绝',
        isPermanentlyDenied: true,
        permissionType: 'microphone',
      );
    }
    if (micStatus.isDenied) {
      throw PermissionException(
        '麦克风权限被拒绝',
        isPermanentlyDenied: false,
        permissionType: 'microphone',
      );
    }

    // 如果是视频通话，请求摄像头权限
    if (callType == CallType.video) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isPermanentlyDenied) {
        throw PermissionException(
          '摄像头权限被永久拒绝',
          isPermanentlyDenied: true,
          permissionType: 'camera',
        );
      }
      if (cameraStatus.isDenied) {
        throw PermissionException(
          '摄像头权限被拒绝',
          isPermanentlyDenied: false,
          permissionType: 'camera',
        );
      }
    }
  }
}

/// 权限异常类
class PermissionException implements Exception {
  final String message;
  final bool isPermanentlyDenied;
  final String permissionType;
  
  const PermissionException(
    this.message, {
    required this.isPermanentlyDenied,
    required this.permissionType,
  });
  
  @override
  String toString() => message;
}

class CallMediaController {
  CallMediaController(this._permissionCoordinator);

  final CallPermissionCoordinator _permissionCoordinator;
  
  JanusClient? _janusClient;
  JanusVideoRoomPlugin? _videoRoomPlugin;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  
  // 网络质量监控
  NetworkQualityMonitor? _networkMonitor;
  StreamSubscription<NetworkQualityStats>? _networkStatsSubscription;
  
  // 音频级别监控（说话者检测）
  AudioLevelMonitor? _audioLevelMonitor;
  StreamSubscription<String?>? _speakingSubscription;
  
  // 弱网优化策略
  AdaptiveBitrateController? _adaptiveBitrateController;
  AutoDegradationStrategy? _autoDegradationStrategy;
  
  // 音频会话配置
  bool get isSpeakerEnabled => _speakerEnabled;
  bool _speakerEnabled = true;
  
  // 音频会话实例（使用 audio_session 包进行完整配置）
  AudioSession? _audioSession;
  CallType? _currentCallType;
  
  // 远端流变化通知
  final StreamController<MediaStream?> _remoteStreamController = 
      StreamController<MediaStream?>.broadcast();
  
  // 网络质量统计通知
  final StreamController<NetworkQualityStats> _networkStatsController = 
      StreamController<NetworkQualityStats>.broadcast();
  
  // 说话者 feed ID 通知（群组通话使用）
  final StreamController<String?> _speakingFeedController =
      StreamController<String?>.broadcast();
  
  /// 监听远端流变化
  Stream<MediaStream?> get onRemoteStreamChanged => _remoteStreamController.stream;
  
  /// 监听网络质量统计
  Stream<NetworkQualityStats> get onNetworkStatsChanged => _networkStatsController.stream;
  
  /// 监听当前说话者的 feed ID（群组通话使用）
  ///
  /// 发出说话者的 track/feed ID；无人说话时发出 null。
  Stream<String?> get onSpeakingFeedChanged => _speakingFeedController.stream;

  /// 准备本地媒体（获取权限，创建本地流）
  Future<CallMediaState> prepare(
    CallMediaState state,
    CallType callType,
  ) async {
    await _permissionCoordinator.ensurePermissions(callType: callType);
    
    // 配置音频会话（微信风格：听筒/扬声器切换）
    await _configureAudioSession(callType);
    
    // 关键修复：用 try/catch 包裹资源创建过程，失败时清理已创建的资源（防止内存泄漏）
    MediaStream? localStream;
    RTCVideoRenderer? localVideoRenderer;
    try {
      // 创建本地媒体流
      localStream = await _createLocalMediaStream(
        audioEnabled: true,
        videoEnabled: callType == CallType.video,
      );
      
      // 创建本地视频渲染器
      if (callType == CallType.video && localStream.getVideoTracks().isNotEmpty) {
        localVideoRenderer = RTCVideoRenderer();
        await localVideoRenderer.initialize();
        localVideoRenderer.srcObject = localStream;
      }
      
      return state.copyWith(
        cameraEnabled: callType == CallType.video,
        speakerEnabled: callType == CallType.video, // 视频通话默认扬声器，语音通话默认听筒
        localTrackReady: true,
        localStream: localStream,
        localVideoRenderer: localVideoRenderer,
        rtcConnectionStatus: RtcConnectionStatus.preparing,
      );
    } catch (e) {
      // 失败时清理已创建的资源
      debugPrint('[CallMediaController] prepare 失败，清理已创建资源: $e');
      if (localVideoRenderer != null) {
        try {
          localVideoRenderer.srcObject = null;
          await localVideoRenderer.dispose();
        } catch (ignore) {
          // 忽略清理失败
        }
      }
      if (localStream != null) {
        for (final track in localStream.getTracks()) {
          track.stop();
        }
        try {
          await localStream.dispose();
        } catch (ignore) {
          // 忽略清理失败
        }
      }
      rethrow;
    }
  }
  
  /// 配置音频会话（微信风格）
  /// 
  /// - 语音通话：使用听筒模式（默认），可切换到扬声器
  /// - 视频通话：使用扬声器模式（默认）
  /// - 支持蓝牙耳机自动切换
  /// 
  /// 使用 audio_session 包进行完整配置，确保音频会话在页面切换/悬浮窗恢复时不丢失
  Future<void> _configureAudioSession(CallType callType) async {
    // 视频通话默认使用扬声器，语音通话默认使用听筒
    _speakerEnabled = callType == CallType.video;
    _currentCallType = callType;
    
    try {
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      
      // 应用扬声器/听筒设置
      if (!kIsWeb) {
        Helper.setSpeakerphoneOn(_speakerEnabled);
      }
      
      debugPrint('[CallMediaController] 配置音频会话: ${callType == CallType.video ? "视频通话-扬声器" : "语音通话-听筒"}');
    } catch (e) {
      debugPrint('[CallMediaController] 配置音频会话失败: $e');
    }
  }
  
  /// 恢复音频会话（从悬浮窗恢复时调用）
  /// 
  /// 重新应用音频会话配置和扬声器/听筒设置，确保音频输出与 UI 状态一致
  Future<void> restoreAudioSession() async {
    final callType = _currentCallType;
    if (callType == null) {
      debugPrint('[CallMediaController] 恢复音频会话: 无通话类型记录，跳过');
      return;
    }
    
    try {
      // 重新获取音频会话实例（页面切换后可能需要重新获取）
      _audioSession = await AudioSession.instance;
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      
      // 重新应用扬声器/听筒设置
      if (!kIsWeb) {
        Helper.setSpeakerphoneOn(_speakerEnabled);
      }
      
      debugPrint('[CallMediaController] 恢复音频会话: speaker=${_speakerEnabled ? "扬声器" : "听筒"}');
    } catch (e) {
      debugPrint('[CallMediaController] 恢复音频会话失败: $e');
    }
  }
  
  /// 切换扬声器/听筒模式
  /// 
  /// 注意：
  /// - 移动端（Android/iOS）：通过 Helper.setSpeakerphoneOn 实现真实切换
  /// - Web 端：浏览器自动管理音频输出设备，此方法仅记录状态
  /// - 实际项目中应使用 audio_session 插件进行完整配置
  void setSpeakerEnabled(bool enabled) {
    _speakerEnabled = enabled;
    // Web 端不支持手动切换音频输出设备，仅记录状态
    if (!kIsWeb) {
      // 移动端：通过 flutter_webrtc 的 Helper 切换音频路由
      Helper.setSpeakerphoneOn(enabled);
    }
    debugPrint('[CallMediaController] 切换音频输出: ${enabled ? "扬声器" : "听筒"}${kIsWeb ? " (Web端仅记录状态)" : ""}');
  }

  /// 降低音频焦点（用于系统中断场景，如闹钟响起）
  /// 
  /// 将音频焦点从"独占"降级为"duck"模式，允许其他音频（如闹钟）播放，
  /// 同时保持通话音频可听但音量降低。
  Future<void> duckAudioFocus() async {
    if (_audioSession == null) {
      debugPrint('[CallMediaController] 降低音频焦点: 音频会话未初始化，跳过');
      return;
    }

    try {
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
      debugPrint('[CallMediaController] 已降低音频焦点（duck模式）');
    } catch (e) {
      debugPrint('[CallMediaController] 降低音频焦点失败: $e');
    }
  }

  /// 恢复音频焦点（用于系统中断结束后）
  /// 
  /// 将音频焦点从"duck"模式恢复为"独占"模式，恢复正常通话音量。
  Future<void> restoreAudioFocus() async {
    if (_audioSession == null) {
      debugPrint('[CallMediaController] 恢复音频焦点: 音频会话未初始化，跳过');
      return;
    }

    try {
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      debugPrint('[CallMediaController] 已恢复音频焦点（正常模式）');
    } catch (e) {
      debugPrint('[CallMediaController] 恢复音频焦点失败: $e');
    }
  }

  /// 降低视频质量（用于低电量或弱网场景）
  /// 
  /// 通过调整 WebRTC 发送端的编码参数，降低视频分辨率和帧率，减少功耗和带宽占用。
  /// 参数：
  /// - lowQuality: true 表示低质量（320x240, 15fps），false 表示恢复正常质量（1280x720, 30fps）
  Future<void> setVideoQuality({required bool lowQuality}) async {
    final peerConnection = _videoRoomPlugin?.publisherConnection;
    if (peerConnection == null) {
      debugPrint('[CallMediaController] 调整视频质量: 无 PeerConnection，跳过');
      return;
    }

    try {
      final senders = await peerConnection.senders;
      
      for (final sender in senders) {
        final track = sender.track;
        if (track != null && track.kind == 'video') {
          final parameters = sender.parameters;
          
          if (parameters.encodings != null && parameters.encodings!.isNotEmpty) {
            if (lowQuality) {
              // 低质量模式：降低分辨率和帧率
              parameters.encodings![0].maxFramerate = 15;
              // 注意：flutter_webrtc 不直接支持设置分辨率，需要通过约束调整
              // 这里只调整帧率和码率
              parameters.encodings![0].maxBitrate = 300000; // 300 kbps
              debugPrint('[CallMediaController] 已降低视频质量: 15fps, 300kbps');
            } else {
              // 恢复正常质量
              parameters.encodings![0].maxFramerate = 30;
              parameters.encodings![0].maxBitrate = 2000000; // 2 Mbps
              debugPrint('[CallMediaController] 已恢复正常视频质量: 30fps, 2Mbps');
            }
            
            await sender.setParameters(parameters);
          }
        }
      }
    } catch (e) {
      debugPrint('[CallMediaController] 调整视频质量失败: $e');
    }
  }

  /// 准备加入通话（连接 Janus，发布本地流）
  Future<CallMediaState> prepareJoin(
    CallMediaState state, {
    required CallType callType,
    required RtcRoomBundle roomBundle,
  }) async {
    // 关键修复：在创建新连接前，先清理旧的连接资源（防止重连场景下的资源泄漏）
    // 例如网络断开重连时，旧的 Janus 连接可能还存在
    if (_janusClient != null || _videoRoomPlugin != null) {
      debugPrint('[CallMediaController] prepareJoin: 检测到旧连接，先清理');
      await _cleanupExistingConnection();
    }
    
    // 如果本地流已经准备好（startOutgoing 或 accept 时已创建），则复用
    // 否则重新准备
    CallMediaState prepared;
    if (state.localStream != null && state.localTrackReady) {
      prepared = state;
      debugPrint('[CallMediaController] 复用已存在的本地媒体流');
    } else {
      prepared = await prepare(state, callType);
    }
    
    try {
      // 创建 Janus 客户端
      _janusClient = JanusClient(
        janusUrl: roomBundle.janusUrl,
        turnUrls: roomBundle.turnUrls,
        turnUsername: roomBundle.turnUsername,
        turnCredential: roomBundle.turnCredential,
        token: roomBundle.token,
      );
      
      // 连接到 Janus
      await _janusClient!.connect();
      
      // 创建 VideoRoom 插件
      _videoRoomPlugin = JanusVideoRoomPlugin(
        janusClient: _janusClient!,
        roomId: int.tryParse(roomBundle.roomId) ?? 0,
        displayName: roomBundle.displayName,
      );
      
      // 发布本地流
      await _videoRoomPlugin!.publish(
        audioEnabled: true,
        videoEnabled: callType == CallType.video,
      );
      
      // 监听远端流
      _remoteStreamSubscription = _videoRoomPlugin!.onRemoteStreamChanged.listen((remoteStream) {
        // 远端流变化时，通知监听者
        _remoteStreamController.add(remoteStream);
      });
      
      // 启动网络质量监控
      _startNetworkQualityMonitor();
      
      // 启动音频级别监控（说话者检测）
      _startAudioLevelMonitor();
      
      return prepared.copyWith(
        localTrackReady: true,
        remoteTrackReady: false,
        localStream: _videoRoomPlugin!.localStream,
        rtcConnectionStatus: RtcConnectionStatus.joining,
      );
    } catch (e) {
      await disposeSession(prepared);
      throw Exception('加入通话失败: $e');
    }
  }

  /// 清理已存在的 Janus 连接（不释放本地媒体流）
  ///
  /// 关键修复：用于重连场景，旧连接需要被替换但本地流需要保留
  Future<void> _cleanupExistingConnection() async {
    await _remoteStreamSubscription?.cancel();
    _remoteStreamSubscription = null;
    
    _stopNetworkQualityMonitor();
    _stopAudioLevelMonitor();
    
    await _videoRoomPlugin?.dispose();
    _videoRoomPlugin = null;
    
    await _janusClient?.destroy();
    _janusClient = null;
    
    debugPrint('[CallMediaController] 已清理旧的 Janus 连接');
  }

  /// 销毁会话（清理所有媒体资源）
  Future<CallMediaState> disposeSession(CallMediaState state) async {
    await _remoteStreamSubscription?.cancel();
    _remoteStreamSubscription = null;
    
    // 停止网络质量监控
    _stopNetworkQualityMonitor();
    
    // 停止音频级别监控
    _stopAudioLevelMonitor();
    
    await _videoRoomPlugin?.dispose();
    _videoRoomPlugin = null;
    
    await _janusClient?.destroy();
    _janusClient = null;
    
    // 停止屏幕共享流（防止屏幕共享资源泄漏）
    if (state.screenShareStream != null) {
      // 先停止所有轨道，再释放流
      for (final track in state.screenShareStream!.getTracks()) {
        track.stop();
      }
      await state.screenShareStream!.dispose();
    }
    
    // 停止远端流轨道（防止远端流轨道泄漏）
    if (state.remoteStream != null) {
      for (final track in state.remoteStream!.getTracks()) {
        track.stop();
      }
    }
    
    // 停止本地流（先停止轨道，再释放流）
    if (state.localStream != null) {
      for (final track in state.localStream!.getTracks()) {
        track.stop();
      }
      await state.localStream!.dispose();
    }
    
    // 清理远端视频渲染器（先解除绑定，再释放）
    if (state.remoteVideoRenderer != null) {
      state.remoteVideoRenderer!.srcObject = null;
      await state.remoteVideoRenderer!.dispose();
    }
    
    // 清理本地视频渲染器（先解除绑定，再释放）
    if (state.localVideoRenderer != null) {
      state.localVideoRenderer!.srcObject = null;
      await state.localVideoRenderer!.dispose();
    }
    
    // 关键修复：正确释放音频会话（释放音频焦点，避免影响其他应用）
    if (_audioSession != null) {
      try {
        await _audioSession!.setActive(false);
        debugPrint('[CallMediaController] 音频会话已释放');
      } catch (e) {
        debugPrint('[CallMediaController] 释放音频会话失败: $e');
      }
    }
    _audioSession = null;
    _currentCallType = null;
    _speakerEnabled = true;
    
    return state.copyWith(
      localTrackReady: false,
      remoteTrackReady: false,
      localStream: null,
      remoteStream: null,
      localVideoRenderer: null,
      remoteVideoRenderer: null,
      screenShareEnabled: false,
      screenShareStream: null,
      rtcConnectionStatus: RtcConnectionStatus.disconnected,
    );
  }

  /// 彻底销毁控制器（释放所有资源，包括 StreamController）
  /// 
  /// 注意：此方法调用后，控制器将不可再用
  Future<void> dispose() async {
    // 先清理会话资源
    // 注意：这里不能直接调用 disposeSession，因为需要传入 state
    // 由 CallController 在 dispose 时负责调用 disposeSession
    
    // 关键修复：检查 StreamController 是否已关闭，防止重复关闭导致异常
    if (!_remoteStreamController.isClosed) {
      await _remoteStreamController.close();
    }
    if (!_networkStatsController.isClosed) {
      await _networkStatsController.close();
    }
    if (!_speakingFeedController.isClosed) {
      await _speakingFeedController.close();
    }
    
    debugPrint('[CallMediaController] 控制器已彻底销毁');
  }

  /// 标记为重连状态
  CallMediaState markReconnecting(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.reconnecting,
    );
  }

  /// 标记为已连接状态
  CallMediaState markConnected(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.connected,
      remoteTrackReady: true,
      remoteStream: _videoRoomPlugin?.remoteStream,
    );
  }

  /// 标记为失败状态
  CallMediaState markFailed(CallMediaState state) {
    return state.copyWith(
      rtcConnectionStatus: RtcConnectionStatus.disconnected,
      remoteTrackReady: false,
    );
  }

  /// 启动网络质量监控
  void _startNetworkQualityMonitor() {
    final peerConnection = _videoRoomPlugin?.publisherConnection;
    if (peerConnection == null) {
      return;
    }

    // 关键修复：先停止旧的监控，防止重复启动导致订阅泄漏
    _stopNetworkQualityMonitor();

    // 初始化网络质量监控器
    _networkMonitor = NetworkQualityMonitor(peerConnection: peerConnection);
    
    // 初始化自适应码率控制器
    _adaptiveBitrateController = AdaptiveBitrateController(
      peerConnection: peerConnection,
      minBitrate: 100000, // 100 kbps
      maxBitrate: 2000000, // 2 Mbps
      startBitrate: 500000, // 500 kbps
    );
    
    // 初始化自动降级策略
    _autoDegradationStrategy = AutoDegradationStrategy(
      peerConnection: peerConnection,
      poorQualityThreshold: 3,
      degradationInterval: const Duration(seconds: 5),
    );
    
    // 监听网络质量统计
    _networkStatsSubscription = _networkMonitor!.statsStream.listen((stats) {
      // 将网络质量统计信息暴露给上层
      _networkStatsController.add(stats);
      
      // 应用自适应码率控制
      _adaptiveBitrateController?.onNetworkQualityChanged(stats);
      
      // 应用自动降级策略
      _autoDegradationStrategy?.onNetworkQualityChanged(stats);
    });
    
    _networkMonitor!.start();
  }

  /// 停止网络质量监控
  void _stopNetworkQualityMonitor() {
    _networkStatsSubscription?.cancel();
    _networkStatsSubscription = null;
    _networkMonitor?.stop();
    _networkMonitor = null;
    
    // 清理弱网优化策略资源
    _adaptiveBitrateController?.dispose();
    _adaptiveBitrateController = null;
    _autoDegradationStrategy?.dispose();
    _autoDegradationStrategy = null;
  }

  /// 启动音频级别监控（说话者检测）
  ///
  /// 通过 WebRTC getStats() 定期采集音频级别，检测当前说话者。
  /// 检测到说话者变化时，通过 [onSpeakingFeedChanged] 流通知上层。
  void _startAudioLevelMonitor() {
    final peerConnection = _videoRoomPlugin?.publisherConnection;
    if (peerConnection == null) {
      return;
    }

    // 关键修复：先停止旧的监控，防止重复启动导致订阅泄漏
    _stopAudioLevelMonitor();

    _audioLevelMonitor = AudioLevelMonitor(peerConnection: peerConnection);
    _speakingSubscription = _audioLevelMonitor!.speakingStream.listen((feedId) {
      if (!_speakingFeedController.isClosed) {
        _speakingFeedController.add(feedId);
      }
    });
    _audioLevelMonitor!.start();
  }

  /// 停止音频级别监控
  void _stopAudioLevelMonitor() {
    _speakingSubscription?.cancel();
    _speakingSubscription = null;
    // 关键修复：先停止监控，再释放资源，防止内存泄漏
    _audioLevelMonitor?.stop();
    _audioLevelMonitor?.dispose();
    _audioLevelMonitor = null;
  }

  /// 切换麦克风静音
  CallMediaState toggleMute(CallMediaState state) {
    final newMuted = !state.microphoneEnabled;
    _videoRoomPlugin?.toggleMute(newMuted);
    return state.copyWith(microphoneEnabled: !state.microphoneEnabled);
  }

  /// 切换扬声器
  CallMediaState toggleSpeaker(CallMediaState state) {
    final newEnabled = !state.speakerEnabled;
    _videoRoomPlugin?.toggleSpeaker(newEnabled);
    
    // 同步切换音频会话配置（听筒/扬声器）
    setSpeakerEnabled(newEnabled);
    
    return state.copyWith(speakerEnabled: newEnabled);
  }

  /// 切换摄像头开关
  CallMediaState toggleCamera(CallMediaState state) {
    final newEnabled = !state.cameraEnabled;
    _videoRoomPlugin?.toggleCamera(newEnabled);
    return state.copyWith(cameraEnabled: !state.cameraEnabled);
  }

  /// 切换前后摄像头
  CallMediaState switchCamera(CallMediaState state) {
    _videoRoomPlugin?.switchCamera();
    return state.copyWith(frontCamera: !state.frontCamera);
  }

  /// 开始屏幕共享
  /// 
  /// Web 端使用 getDisplayMedia()，Android 端使用 MediaProjection API
  /// 屏幕共享会替换本地视频流，将摄像头视频替换为屏幕内容
  Future<CallMediaState> startScreenShare(CallMediaState state) async {
    try {
      // 获取屏幕媒体流
      final screenStream = await _getDisplayMedia();
      
      if (screenStream == null) {
        throw Exception('无法获取屏幕媒体流');
      }
      
      // 停止当前的摄像头视频轨道
      if (state.localStream != null) {
        final videoTracks = state.localStream!.getVideoTracks();
        for (final track in videoTracks) {
          await track.stop();
          state.localStream!.removeTrack(track);
        }
      }
      
      // 将屏幕共享轨道添加到本地流
      final screenVideoTracks = screenStream.getVideoTracks();
      if (screenVideoTracks.isNotEmpty) {
        state.localStream?.addTrack(screenVideoTracks.first);
      }
      
      // 通知 Janus 更换视频源
      _videoRoomPlugin?.replaceVideoTrack(screenVideoTracks.first);
      
      return state.copyWith(
        screenShareEnabled: true,
        screenShareStream: screenStream,
        cameraEnabled: true,
      );
    } catch (e) {
      throw Exception('启动屏幕共享失败: $e');
    }
  }

  /// 停止屏幕共享
  /// 
  /// 恢复摄像头视频流
  /// 
  /// 关键修复：即使恢复摄像头失败，也要返回清理后的状态（screenShareStream 已 dispose）
  Future<CallMediaState> stopScreenShare(CallMediaState state) async {
    // 先停止屏幕共享流并移除轨道（无论后续是否成功，这部分都要清理）
    if (state.screenShareStream != null) {
      // 移除屏幕共享轨道
      if (state.localStream != null) {
        final screenTracks = state.screenShareStream!.getVideoTracks();
        for (final track in screenTracks) {
          await track.stop();
          state.localStream!.removeTrack(track);
        }
      }
      // 停止屏幕共享流
      await state.screenShareStream!.dispose();
    }
    
    // 尝试恢复摄像头视频
    try {
      final cameraStream = await _createLocalMediaStream(
        audioEnabled: false,
        videoEnabled: true,
      );
      
      final cameraVideoTracks = cameraStream.getVideoTracks();
      if (cameraVideoTracks.isNotEmpty) {
        state.localStream?.addTrack(cameraVideoTracks.first);
        _videoRoomPlugin?.replaceVideoTrack(cameraVideoTracks.first);
      }
      
      return state.copyWith(
        screenShareEnabled: false,
        screenShareStream: null,
      );
    } catch (e) {
      // 关键修复：恢复摄像头失败时，仍返回清理后的状态
      // 防止 state.screenShareStream 指向已 dispose 的流
      debugPrint('[CallMediaController] 停止屏幕共享后恢复摄像头失败: $e');
      return state.copyWith(
        screenShareEnabled: false,
        screenShareStream: null,
      );
    }
  }

  /// 切换屏幕共享状态
  Future<CallMediaState> toggleScreenShare(CallMediaState state) async {
    if (state.screenShareEnabled) {
      return await stopScreenShare(state);
    } else {
      return await startScreenShare(state);
    }
  }

  /// 获取屏幕媒体流
  /// 
  /// Web 端使用 getDisplayMedia()
  /// 移动端需要使用平台特定的 API（Android: MediaProjection, iOS: ReplayKit）
  Future<MediaStream?> _getDisplayMedia() async {
    try {
      final constraints = <String, dynamic>{
        'video': {
          'cursor': 'always', // 显示鼠标光标
        },
        'audio': false, // 不捕获系统音频
      };
      
      // 使用 getDisplayMedia 获取屏幕
      return await navigator.mediaDevices.getDisplayMedia(constraints);
    } catch (e) {
      throw Exception('获取屏幕媒体失败: $e');
    }
  }

  /// 创建本地媒体流
  Future<MediaStream> _createLocalMediaStream({
    required bool audioEnabled,
    required bool videoEnabled,
  }) async {
    final constraints = <String, dynamic>{
      'audio': audioEnabled,
      'video': videoEnabled ? {
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      } : false,
    };
    
    return await navigator.mediaDevices.getUserMedia(constraints);
  }
}
