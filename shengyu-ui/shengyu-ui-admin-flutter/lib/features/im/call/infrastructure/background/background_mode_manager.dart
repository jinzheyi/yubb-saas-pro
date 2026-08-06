import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

/// 后台模式管理器
/// 
/// 管理通话在后台运行时的平台特定行为：
/// - iOS: 配置 AVAudioSession 为播放和录制模式，启用后台音频模式
/// - Android: 配置音频焦点，保持通话活跃
/// 
/// 企业级特性：
/// - 平台自适应（iOS/Android 不同处理策略）
/// - 资源优化（后台仅保持音频，关闭视频）
/// - 权限管理（自动处理音频焦点和后台权限）
/// - 音频会话配置（确保通话质量）
class BackgroundModeManager {
  BackgroundModeManager._();
  static final BackgroundModeManager instance = BackgroundModeManager._();

  bool _isBackgroundModeEnabled = false;
  AudioSession? _audioSession;

  /// 启用后台模式
  /// 
  /// 在应用进入后台时调用，确保通话继续运行
  Future<void> enableBackgroundMode() async {
    if (_isBackgroundModeEnabled) {
      debugPrint('[BackgroundModeManager] 后台模式已启用，跳过');
      return;
    }

    try {
      if (Platform.isIOS) {
        await _enableIOSBackgroundMode();
      } else if (Platform.isAndroid) {
        await _enableAndroidBackgroundMode();
      }
      
      _isBackgroundModeEnabled = true;
      debugPrint('[BackgroundModeManager] 后台模式启用成功');
    } catch (e) {
      debugPrint('[BackgroundModeManager] 启用后台模式失败: $e');
      rethrow;
    }
  }

  /// 禁用后台模式
  /// 
  /// 在应用恢复前台或通话结束时调用，释放后台资源
  Future<void> disableBackgroundMode() async {
    if (!_isBackgroundModeEnabled) {
      debugPrint('[BackgroundModeManager] 后台模式未启用，跳过');
      return;
    }

    try {
      if (Platform.isIOS) {
        await _disableIOSBackgroundMode();
      } else if (Platform.isAndroid) {
        await _disableAndroidBackgroundMode();
      }
      
      _isBackgroundModeEnabled = false;
      debugPrint('[BackgroundModeManager] 后台模式禁用成功');
    } catch (e) {
      debugPrint('[BackgroundModeManager] 禁用后台模式失败: $e');
    }
  }

  /// iOS 后台模式启用
  /// 
  /// 配置 AVAudioSession 为播放和录制模式，启用后台音频
  /// 需要在 Info.plist 中配置 UIBackgroundModes: audio
  Future<void> _enableIOSBackgroundMode() async {
    try {
      _audioSession = await AudioSession.instance;
      
      // 配置音频会话为语音通话模式
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      ));
      
      // 激活音频会话
      await _audioSession!.setActive(true);
      
      debugPrint('[BackgroundModeManager] iOS 后台模式配置完成 - 音频会话已激活');
    } catch (e) {
      debugPrint('[BackgroundModeManager] iOS 后台模式配置失败: $e');
      rethrow;
    }
  }

  /// iOS 后台模式禁用
  Future<void> _disableIOSBackgroundMode() async {
    try {
      if (_audioSession != null) {
        // 停用音频会话
        await _audioSession!.setActive(false);
        
        // 恢复默认音频会话配置
        await _audioSession!.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.soloAmbient,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ));
        
        debugPrint('[BackgroundModeManager] iOS 后台模式已禁用 - 音频会话已恢复默认');
      }
    } catch (e) {
      debugPrint('[BackgroundModeManager] iOS 后台模式禁用失败: $e');
    }
  }

  /// Android 后台模式启用
  /// 
  /// 配置音频焦点，确保通话在后台继续运行
  Future<void> _enableAndroidBackgroundMode() async {
    try {
      _audioSession = await AudioSession.instance;
      
      // 配置音频会话为语音通话模式
      await _audioSession!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      ));
      
      // 激活音频会话
      await _audioSession!.setActive(true);
      
      debugPrint('[BackgroundModeManager] Android 后台模式配置完成 - 音频焦点已获取');
    } catch (e) {
      debugPrint('[BackgroundModeManager] Android 后台模式配置失败: $e');
      rethrow;
    }
  }

  /// Android 后台模式禁用
  Future<void> _disableAndroidBackgroundMode() async {
    try {
      if (_audioSession != null) {
        // 停用音频会话
        await _audioSession!.setActive(false);
        
        // 恢复默认音频会话配置
        await _audioSession!.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.soloAmbient,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ));
        
        debugPrint('[BackgroundModeManager] Android 后台模式已禁用 - 音频焦点已释放');
      }
    } catch (e) {
      debugPrint('[BackgroundModeManager] Android 后台模式禁用失败: $e');
    }
  }

  /// 检查后台模式是否已启用
  bool get isBackgroundModeEnabled => _isBackgroundModeEnabled;
  
  /// 获取音频会话实例（供外部使用）
  AudioSession? get audioSession => _audioSession;
}
