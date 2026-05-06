import 'dart:async';

import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> ensurePermission() {
    return _recorder.hasPermission();
  }

  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _recorder.onAmplitudeChanged(interval);
  }

  Future<void> start({required String path}) {
    return _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 48000,
      ),
      path: path,
    );
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
