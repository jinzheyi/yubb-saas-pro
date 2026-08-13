import 'package:flutter_webrtc/flutter_webrtc.dart';

enum RtcConnectionStatus {
  idle,
  preparing,
  joining,
  connected,
  reconnecting,
  disconnected,
}

enum NetworkQuality {
  excellent, // 优秀：丢包率 < 1%，RTT < 100ms
  good, // 良好：丢包率 < 5%，RTT < 300ms
  fair, // 一般：丢包率 < 10%，RTT < 500ms
  poor, // 较差：丢包率 >= 10% 或 RTT >= 500ms
  unknown, // 未知
}

class CallMediaState {
  const CallMediaState({
    this.microphoneEnabled = true,
    this.cameraEnabled = false,
    this.speakerEnabled = true,
    this.frontCamera = true,
    this.localTrackReady = false,
    this.remoteTrackReady = false,
    this.rtcConnectionStatus = RtcConnectionStatus.idle,
    this.localStream,
    this.remoteStream,
    this.localVideoRenderer,
    this.remoteVideoRenderer,
    this.screenShareEnabled = false,
    this.screenShareStream,
    this.networkQuality = NetworkQuality.unknown,
    this.roundTripTime,
    this.packetLossRate,
    this.availableOutgoingBitrate,
    this.availableIncomingBitrate,
  });

  final bool microphoneEnabled;
  final bool cameraEnabled;
  final bool speakerEnabled;
  final bool frontCamera;
  final bool localTrackReady;
  final bool remoteTrackReady;
  final RtcConnectionStatus rtcConnectionStatus;
  
  // WebRTC 媒体流
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  
  // 视频渲染器
  final RTCVideoRenderer? localVideoRenderer;
  final RTCVideoRenderer? remoteVideoRenderer;
  
  // 屏幕共享
  final bool screenShareEnabled;
  final MediaStream? screenShareStream;
  
  // 网络质量监控
  final NetworkQuality networkQuality;
  final int? roundTripTime; // RTT (ms)
  final double? packetLossRate; // 丢包率 (0-1)
  final int? availableOutgoingBitrate; // 可用上行码率 (bps)
  final int? availableIncomingBitrate; // 可用下行码率 (bps)

  /// 哨兵值，用来区分“未提供”和“显式传入 null”。
  static const Object _sentinel = Object();

  CallMediaState copyWith({
    bool? microphoneEnabled,
    bool? cameraEnabled,
    bool? speakerEnabled,
    bool? frontCamera,
    bool? localTrackReady,
    bool? remoteTrackReady,
    RtcConnectionStatus? rtcConnectionStatus,
    Object? localStream = _sentinel,
    Object? remoteStream = _sentinel,
    Object? localVideoRenderer = _sentinel,
    Object? remoteVideoRenderer = _sentinel,
    bool? screenShareEnabled,
    Object? screenShareStream = _sentinel,
    NetworkQuality? networkQuality,
    int? roundTripTime,
    double? packetLossRate,
    int? availableOutgoingBitrate,
    int? availableIncomingBitrate,
  }) {
    return CallMediaState(
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      localTrackReady: localTrackReady ?? this.localTrackReady,
      remoteTrackReady: remoteTrackReady ?? this.remoteTrackReady,
      rtcConnectionStatus: rtcConnectionStatus ?? this.rtcConnectionStatus,
      localStream: identical(localStream, _sentinel) ? this.localStream : localStream as MediaStream?,
      remoteStream: identical(remoteStream, _sentinel) ? this.remoteStream : remoteStream as MediaStream?,
      localVideoRenderer: identical(localVideoRenderer, _sentinel) ? this.localVideoRenderer : localVideoRenderer as RTCVideoRenderer?,
      remoteVideoRenderer: identical(remoteVideoRenderer, _sentinel) ? this.remoteVideoRenderer : remoteVideoRenderer as RTCVideoRenderer?,
      screenShareEnabled: screenShareEnabled ?? this.screenShareEnabled,
      screenShareStream: identical(screenShareStream, _sentinel) ? this.screenShareStream : screenShareStream as MediaStream?,
      networkQuality: networkQuality ?? this.networkQuality,
      roundTripTime: roundTripTime ?? this.roundTripTime,
      packetLossRate: packetLossRate ?? this.packetLossRate,
      availableOutgoingBitrate: availableOutgoingBitrate ?? this.availableOutgoingBitrate,
      availableIncomingBitrate: availableIncomingBitrate ?? this.availableIncomingBitrate,
    );
  }
}
