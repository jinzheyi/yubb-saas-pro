import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  _RecordingProfile? _preparedProfile;

  AudioEncoder get encoder => _preparedProfile?.encoder ?? AudioEncoder.aacLc;

  String get fileExtension => _preparedProfile?.fileExtension ?? 'm4a';

  String get mimeType => _preparedProfile?.mimeType ?? 'audio/mp4';

  String get formatLabel => fileExtension;

  Future<bool> ensurePermission() {
    return _recorder.hasPermission();
  }

  Future<void> prepareProfile() async {
    if (!kIsWeb) {
      _preparedProfile ??= const _RecordingProfile(
        encoder: AudioEncoder.aacLc,
        fileExtension: 'm4a',
        mimeType: 'audio/mp4',
      );
      return;
    }
    if (_preparedProfile != null) {
      return;
    }
    final supportsAac = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
    _preparedProfile = supportsAac
        ? const _RecordingProfile(
            encoder: AudioEncoder.aacLc,
            fileExtension: 'm4a',
            mimeType: 'audio/mp4',
          )
        : const _RecordingProfile(
            encoder: AudioEncoder.wav,
            fileExtension: 'wav',
            mimeType: 'audio/wav',
          );
  }

  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _recorder.onAmplitudeChanged(interval);
  }

  Stream<RecordState> onStateChanged() {
    return _recorder.onStateChanged();
  }

  Future<void> start({required String path}) async {
    await prepareProfile();
    final profile = _preparedProfile!;
    return _recorder.start(
      RecordConfig(
        encoder: profile.encoder,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 48000,
      ),
      path: path,
    );
  }

  Future<void> pause() {
    return _recorder.pause();
  }

  Future<void> resume() {
    return _recorder.resume();
  }

  Future<bool> isRecording() {
    return _recorder.isRecording();
  }

  Future<bool> isPaused() {
    return _recorder.isPaused();
  }

  Future<String?> stop() {
    return _recorder.stop();
  }

  Future<void> cancel() {
    return _recorder.cancel();
  }

  Future<void> dispose() {
    return _recorder.dispose();
  }
}

class _RecordingProfile {
  const _RecordingProfile({
    required this.encoder,
    required this.fileExtension,
    required this.mimeType,
  });

  final AudioEncoder encoder;
  final String fileExtension;
  final String mimeType;
}
