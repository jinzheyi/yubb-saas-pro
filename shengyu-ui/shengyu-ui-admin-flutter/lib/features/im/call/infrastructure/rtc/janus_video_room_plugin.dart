import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'janus_client.dart';

/// Janus VideoRoom 插件封装
///
/// 负责管理 1v1 通话的发布/订阅逻辑，处理本地和远端媒体流。
class JanusVideoRoomPlugin {
  JanusVideoRoomPlugin({
    required this.janusClient,
    required this.roomId,
    required this.displayName,
  });

  final JanusClient janusClient;
  final int roomId;
  final String displayName;

  RTCPeerConnection? _publisherConnection;
  RTCPeerConnection? _subscriberConnection;
  StreamSubscription<Map<String, dynamic>>? _janusEventsSubscription;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final Set<String> _subscribedFeedIds = <String>{};
  
  final StreamController<MediaStream?> _remoteStreamController = 
      StreamController<MediaStream?>.broadcast();
  
  Stream<MediaStream?> get onRemoteStreamChanged => _remoteStreamController.stream;
  
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  
  /// 获取发布连接（用于网络质量监控）
  RTCPeerConnection? get publisherConnection => _publisherConnection;

  /// 初始化并发布本地媒体流
  Future<void> publish({
    required bool audioEnabled,
    required bool videoEnabled,
  }) async {
    // 获取本地媒体流
    _localStream = await _createLocalMediaStream(audioEnabled, videoEnabled);
    
    try {
      // 加入房间并发布
      final result = await janusClient.joinRoom(
        roomId: roomId,
        displayName: displayName,
        localStream: _localStream!,
      );
      
      _publisherConnection = result['peerConnection'] as RTCPeerConnection?;
      await _subscribeToPublishers(result['publishers']);
      _janusEventsSubscription = janusClient.events.listen((event) {
        unawaited(_subscribeToPublishers(_publishersFromEvent(event)));
      });
      
      // 监听远端流
      // 关键修复：移除 _remoteStream == null 的限制，允许远端流变化时更新
      // 这样可以处理网络重连、远端流重新建立等场景
      _publisherConnection?.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video' || event.track.kind == 'audio') {
          final newRemoteStream = event.streams.isNotEmpty 
              ? event.streams.first 
              : null;
          
          // 只有当远端流真正发生变化时才更新
          if (newRemoteStream != _remoteStream) {
            _remoteStream = newRemoteStream;
            _remoteStreamController.add(_remoteStream);
            debugPrint('[JanusVideoRoomPlugin] 远端流已更新: ${_remoteStream != null ? "有流" : "无流"}');
          }
        }
      };
      
      _publisherConnection?.onIceConnectionState = (state) {
        debugPrint('[JanusVideoRoomPlugin] ICE 连接状态变化: $state');
        
        switch (state) {
          case RTCIceConnectionState.RTCIceConnectionStateConnected:
            // 连接成功，可以订阅远端流
            debugPrint('[JanusVideoRoomPlugin] ICE 连接成功');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
            // 连接断开，可能是网络波动
            debugPrint('[JanusVideoRoomPlugin] ICE 连接断开');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateFailed:
            // 连接失败，需要重连
            debugPrint('[JanusVideoRoomPlugin] ICE 连接失败');
            break;
          case RTCIceConnectionState.RTCIceConnectionStateClosed:
            // 连接关闭
            debugPrint('[JanusVideoRoomPlugin] ICE 连接关闭');
            break;
          default:
            // 其他状态（checking, new, completed 等）
            break;
        }
      };
    } catch (e) {
      // 关键修复：publish 失败时清理已创建的本地流，防止资源泄漏
      debugPrint('[JanusVideoRoomPlugin] publish 失败，清理本地流: $e');
      await _cleanupLocalStream();
      rethrow;
    }
  }
  
  /// 清理本地媒体流
  Future<void> _cleanupLocalStream() async {
    if (_localStream != null) {
      // 停止所有轨道
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      // 释放流资源
      await _localStream?.dispose();
      _localStream = null;
    }
  }

  /// 订阅远端媒体流
  Future<void> subscribe(String feedId) async {
    if (!_subscribedFeedIds.add(feedId)) return;
    _subscriberConnection = await janusClient.subscribeToFeed(
      roomId: roomId,
      feedId: feedId,
      onRemoteStream: (stream) {
        _remoteStream = stream;
        _remoteStreamController.add(stream);
      },
    );
  }

  Future<void> _subscribeToPublishers(Object? rawPublishers) async {
    if (rawPublishers is! List) return;
    for (final publisher in rawPublishers) {
      if (publisher is! Map) continue;
      final feedId = publisher['id']?.toString();
      if (feedId == null || feedId.isEmpty) continue;
      try {
        await subscribe(feedId);
      } catch (e) {
        // 对端可能在订阅前离开；保留日志但不让本地发布失败。
        debugPrint('[JanusVideoRoomPlugin] 订阅远端发布者失败, feedId=$feedId, error=$e');
        _subscribedFeedIds.remove(feedId);
      }
    }
  }

  List<dynamic>? _publishersFromEvent(Map<String, dynamic> event) {
    final pluginData = event['plugindata'];
    if (pluginData is! Map) return null;
    final data = pluginData['data'];
    return data is Map && data['publishers'] is List ? data['publishers'] as List<dynamic> : null;
  }

  /// 切换摄像头
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    }
  }

  /// 切换麦克风静音
  Future<void> toggleMute(bool muted) async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !muted;
      }
    }
  }

  /// 切换扬声器（音频路由切换）
  ///
  /// 使用 Helper.setSpeakerphoneOn 实现真实的听筒/扬声器切换
  /// enabled=true: 扬声器模式（外放）
  /// enabled=false: 听筒模式
  Future<void> toggleSpeaker(bool enabled) async {
    try {
      // 使用 flutter_webrtc 的 Helper 方法切换音频输出设备
      await Helper.setSpeakerphoneOn(enabled);
      debugPrint('[JanusVideoRoomPlugin] 音频路由切换: ${enabled ? "扬声器" : "听筒"}');
    } catch (e) {
      debugPrint('[JanusVideoRoomPlugin] 切换音频路由失败: $e');
    }
  }

  /// 切换摄像头
  Future<void> toggleCamera(bool enabled) async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = enabled;
      }
    }
  }

  /// 替换视频轨道（用于屏幕共享等场景）
  ///
  /// 将当前本地流中的视频轨道替换为新的轨道，并通过 RTCRtpSender 的
  /// replaceTrack 方法通知对端，避免重新协商（negotiation）。
  Future<void> replaceVideoTrack(MediaStreamTrack newTrack) async {
    if (_publisherConnection == null) {
      return;
    }
    final senders = await _publisherConnection!.getSenders();
    for (final sender in senders) {
      final track = sender.track;
      if (track != null && track.kind == 'video') {
        await sender.replaceTrack(newTrack);
        // 同时更新本地流中的视频轨道
        if (_localStream != null) {
          final oldTracks = _localStream!.getVideoTracks();
          for (final old in oldTracks) {
            _localStream!.removeTrack(old);
          }
          _localStream!.addTrack(newTrack);
        }
        return;
      }
    }
    // 如果没有找到现有的视频 sender，将新轨道添加到本地流
    if (_localStream != null) {
      _localStream!.addTrack(newTrack);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    // 关键修复：先停止所有媒体轨道，再释放资源
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
    }
    
    if (_remoteStream != null) {
      for (final track in _remoteStream!.getTracks()) {
        track.stop();
      }
    }
    
    await _janusEventsSubscription?.cancel();
    _janusEventsSubscription = null;
    await _publisherConnection?.close();
    await _subscriberConnection?.close();
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    
    // 关键修复：检查 StreamController 是否已关闭，避免重复关闭
    if (!_remoteStreamController.isClosed) {
      await _remoteStreamController.close();
    }
    
    _publisherConnection = null;
    _subscriberConnection = null;
    _localStream = null;
    _remoteStream = null;
    _subscribedFeedIds.clear();
  }

  /// 获取本地媒体流
  Future<MediaStream> _createLocalMediaStream(
    bool audioEnabled,
    bool videoEnabled,
  ) async {
    final constraints = <String, dynamic>{
      'audio': audioEnabled,
      'video': videoEnabled ? {
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      } : false,
    };
    
    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    return stream;
  }
}
