import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  AudioRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  AudioEncoder get encoder => kIsWeb ? AudioEncoder.wav : AudioEncoder.aacLc;

  String get fileExtension => kIsWeb ? 'wav' : 'm4a';

  String get mimeType => kIsWeb ? 'audio/wav' : 'audio/mp4';

  String get formatLabel => fileExtension;

  Future<bool> ensurePermission() {
    return _recorder.hasPermission();
  }

  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _recorder.onAmplitudeChanged(interval);
  }

  Future<void> start({required String path}) {
    return _recorder.start(
      RecordConfig(
        encoder: encoder,
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
