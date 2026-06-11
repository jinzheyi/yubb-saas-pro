import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  _RecordingProfile? _preparedProfile;
  bool _isDisposed = false;
  bool _isRecordingActive = false;

  AudioEncoder get encoder => _preparedProfile?.encoder ?? AudioEncoder.aacLc;

  String get fileExtension => _preparedProfile?.fileExtension ?? 'm4a';

  String get mimeType => _preparedProfile?.mimeType ?? 'audio/mp4';

  String get formatLabel => fileExtension;

  bool get isRecordingActive => _isRecordingActive;

  Future<bool> ensurePermission() async {
    if (_isDisposed) return false;
    return _recorder.hasPermission();
  }

  Future<void> prepareProfile() async {
    if (_isDisposed) return;
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
    try {
      final supportsAac = await _recorder.isEncoderSupported(AudioEncoder.aacLc);
      if (_isDisposed) return;
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
    } catch (e) {
      debugPrint('AudioRecordingService.prepareProfile failed: $e');
      _preparedProfile = const _RecordingProfile(
        encoder: AudioEncoder.wav,
        fileExtension: 'wav',
        mimeType: 'audio/wav',
      );
    }
  }

  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    if (_isDisposed) return const Stream.empty();
    return _recorder.onAmplitudeChanged(interval);
  }

  Stream<RecordState> onStateChanged() {
    if (_isDisposed) return const Stream.empty();
    return _recorder.onStateChanged();
  }

  Future<void> start({required String path}) async {
    if (_isDisposed) return;
    if (_isRecordingActive) {
      try {
        await _recorder.stop();
      } catch (e) {
        debugPrint('AudioRecordingService.start: stop previous failed: $e');
      }
    }
    await prepareProfile();
    if (_isDisposed) return;
    final profile = _preparedProfile!;
    try {
      await _recorder.start(
        RecordConfig(
          encoder: profile.encoder,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 48000,
        ),
        path: path,
      );
      _isRecordingActive = true;
    } catch (e) {
      debugPrint('AudioRecordingService.start failed: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    return _recorder.pause();
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    return _recorder.resume();
  }

  Future<bool> isRecording() async {
    if (_isDisposed) return false;
    return _recorder.isRecording();
  }

  Future<bool> isPaused() async {
    if (_isDisposed) return false;
    return _recorder.isPaused();
  }

  Future<String?> stop() async {
    if (_isDisposed) return null;
    if (!_isRecordingActive) return null;
    try {
      final path = await _recorder.stop();
      _isRecordingActive = false;
      return path;
    } catch (e) {
      _isRecordingActive = false;
      debugPrint('AudioRecordingService.stop failed: $e');
      return null;
    }
  }

  Future<void> cancel() async {
    if (_isDisposed) return;
    _isRecordingActive = false;
    return _recorder.cancel();
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _isRecordingActive = false;
    try {
      await _recorder.dispose();
    } catch (e) {
      debugPrint('AudioRecordingService.dispose error: $e');
    }
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
