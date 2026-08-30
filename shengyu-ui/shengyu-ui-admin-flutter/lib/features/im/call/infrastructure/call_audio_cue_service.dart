import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shengyu_ui_admin_im/app/config/app_config.dart';

/// Owns the non-media sounds of a call.
///
/// Ringtone and end cue use separate players so stopping a looping ringtone
/// can never cancel the one-shot end cue. LiveKit remains the only owner of
/// microphone capture and remote-call audio.
class CallAudioCueService {
  CallAudioCueService({AudioPlayer? ringtonePlayer, AudioPlayer? endPlayer})
    : _ringtonePlayer = ringtonePlayer ?? AudioPlayer(),
      _endPlayer = endPlayer ?? AudioPlayer();

  final AudioPlayer _ringtonePlayer;
  final AudioPlayer _endPlayer;
  Future<void> _ringOperation = Future<void>.value();
  int _ringGeneration = 0;
  bool _disposed = false;
  DateTime? _lastEndCueAt;

  Future<void> startRinging() {
    final generation = ++_ringGeneration;
    return _ringOperation = _ringOperation.then((_) async {
      if (_disposed || generation != _ringGeneration) return;
      try {
        await _ringtonePlayer.stop();
        await _ringtonePlayer.setAsset(AppConfig.callRingtoneAsset);
        await _ringtonePlayer.setLoopMode(LoopMode.one);
        if (_disposed || generation != _ringGeneration) return;
        unawaited(
          _ringtonePlayer.play().catchError((Object error) {
            debugPrint('[CallAudioCueService] 播放通话铃声失败: $error');
          }),
        );
      } catch (error) {
        debugPrint('[CallAudioCueService] 加载通话铃声失败: $error');
      }
    });
  }

  Future<void> stopRinging() {
    ++_ringGeneration;
    return _ringOperation = _ringOperation.then((_) async {
      if (_disposed) return;
      try {
        await _ringtonePlayer.stop();
      } catch (error) {
        debugPrint('[CallAudioCueService] 停止通话铃声失败: $error');
      }
    });
  }

  Future<void> playEndCue() async {
    await stopRinging();
    if (_disposed) return;
    final now = DateTime.now();
    final lastEndCueAt = _lastEndCueAt;
    if (lastEndCueAt != null &&
        now.difference(lastEndCueAt) < const Duration(seconds: 1)) {
      return;
    }
    _lastEndCueAt = now;
    try {
      await _endPlayer.stop();
      await _endPlayer.setAsset(AppConfig.callEndSoundAsset);
      await _endPlayer.setLoopMode(LoopMode.off);
      unawaited(
        _endPlayer.play().catchError((Object error) {
          debugPrint('[CallAudioCueService] 播放通话结束音失败: $error');
        }),
      );
    } catch (error) {
      debugPrint('[CallAudioCueService] 加载通话结束音失败: $error');
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    ++_ringGeneration;
    await Future.wait<void>([_ringtonePlayer.dispose(), _endPlayer.dispose()]);
  }
}
