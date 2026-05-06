import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AudioPlaybackService {
  AudioPlaybackService() : _player = AudioPlayer();

  final AudioPlayer _player;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Future<void> setUrl(String url) {
    return _player.setUrl(url);
  }

  Future<void> play() {
    return _player.play();
  }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() {
    return _player.stop();
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
