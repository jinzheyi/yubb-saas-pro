# IM Flutter OpenHarmony 适配器骨架模板 v1.0

> 文档日期：2026-04-29  
> 文档定位：OpenHarmony P0 原生能力适配器的接口约束、目录建议、代码骨架模板

---

## 1. 目标

本文件用于把 OpenHarmony 首轮必须补齐的原生能力收敛成可直接生成代码的模板层文档。

覆盖范围只包含 P0 能力：

1. file picker
2. image picker
3. permission
4. recorder
5. audio player
6. external opener

冻结原则：

1. 页面、feature、use case 不直接依赖 OpenHarmony SDK
2. 所有平台能力都先经过 `core/platform/*` 抽象
3. `OpenHarmony` 是首个移动端平台实现
4. `HarmonyOS` 后续优先复用同一抽象，必要时补独立实现

---

## 2. 目录建议

```text
lib/
  core/
    platform/
      picker/
        file_picker_service.dart
        image_picker_service.dart
      permission/
        permission_service.dart
      media/
        recorder_service.dart
        audio_player_service.dart
      file/
        external_opener_service.dart
      ohos/
        picker/
          ohos_file_picker_adapter.dart
          ohos_image_picker_adapter.dart
        permission/
          ohos_permission_adapter.dart
        media/
          ohos_recorder_adapter.dart
          ohos_audio_player_adapter.dart
        file/
          ohos_external_opener_adapter.dart
        bridge/
          ohos_method_channel_names.dart
          ohos_platform_bridge.dart
      provider/
        platform_service_providers.dart
```

说明：

1. service 文件定义跨平台 contract
2. `ohos/*adapter.dart` 放 OpenHarmony 具体实现
3. `bridge/` 只负责和平台通道通信，不承载业务规则

---

## 3. 通用约束

### 3.1 调用规则

1. UI 只调用 controller/use case
2. controller/use case 只调用 `*Service`
3. `*Service` 由 provider 注入具体平台 adapter
4. adapter 内部可使用 `MethodChannel`、`Pigeon` 或社区可用桥接
5. 首轮文档冻结为“service contract + adapter implementation”结构，不把平台通道对象直接散落在 feature 层

### 3.2 错误模型

所有平台错误统一映射为：

```dart
enum PlatformFailureCode {
  permissionDenied,
  permissionPermanentlyDenied,
  notSupported,
  cancelled,
  fileNotFound,
  invalidArgument,
  ioError,
  busy,
  timeout,
  unknown,
}

class PlatformFailure implements Exception {
  const PlatformFailure({
    required this.code,
    required this.message,
    this.cause,
  });

  final PlatformFailureCode code;
  final String message;
  final Object? cause;
}
```

### 3.3 URI 规则

1. Flutter 侧统一使用 `String uri`
2. 不在 feature 层区分 `file://`、`content://`、`ohos://`
3. 由 adapter 负责把平台侧路径转换成统一可消费 URI

---

## 4. 公共对象模板

### 4.1 `picked_file.dart`

```dart
enum PickedFileKind {
  image,
  video,
  genericFile,
  audio,
}

class PickedFile {
  const PickedFile({
    required this.uri,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.kind,
    this.width,
    this.height,
    this.durationMs,
    this.thumbnailUri,
  });

  final String uri;
  final String name;
  final int size;
  final String mimeType;
  final PickedFileKind kind;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? thumbnailUri;
}
```

### 4.2 `permission_models.dart`

```dart
enum AppPermission {
  camera,
  microphone,
  photos,
  storageRead,
  storageWrite,
  notification,
}

enum PermissionGrantState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

class PermissionGrantResult {
  const PermissionGrantResult({
    required this.permission,
    required this.state,
  });

  final AppPermission permission;
  final PermissionGrantState state;
}
```

### 4.3 `record_models.dart`

```dart
enum RecorderCodec {
  aac,
  opus,
  pcm16Wav,
}

class StartRecordRequest {
  const StartRecordRequest({
    required this.outputUri,
    required this.codec,
    this.maxDuration = const Duration(minutes: 2),
  });

  final String outputUri;
  final RecorderCodec codec;
  final Duration maxDuration;
}

class RecordSession {
  const RecordSession({
    required this.sessionId,
    required this.outputUri,
    required this.startedAt,
  });

  final String sessionId;
  final String outputUri;
  final DateTime startedAt;
}

class RecordedAudio {
  const RecordedAudio({
    required this.uri,
    required this.durationMs,
    required this.size,
    required this.mimeType,
  });

  final String uri;
  final int durationMs;
  final int size;
  final String mimeType;
}
```

### 4.4 `audio_player_models.dart`

```dart
enum AudioOutputRoute {
  speaker,
  earpiece,
  bluetooth,
  systemDefault,
}

enum AudioPlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  failed,
}

class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot({
    required this.messageId,
    required this.state,
    required this.positionMs,
    required this.durationMs,
    required this.route,
  });

  final String messageId;
  final AudioPlaybackState state;
  final int positionMs;
  final int durationMs;
  final AudioOutputRoute route;
}
```

### 4.5 `external_open_request.dart`

```dart
class ExternalOpenRequest {
  const ExternalOpenRequest({
    required this.localPath,
    required this.mimeType,
    required this.displayName,
  });

  final String localPath;
  final String mimeType;
  final String displayName;
}
```

---

## 5. service contract 模板

### 5.1 `file_picker_service.dart`

```dart
abstract class FilePickerService {
  Future<PickedFile?> pickFile({
    List<String>? allowedExtensions,
    int? maxBytes,
  });
}
```

### 5.2 `image_picker_service.dart`

```dart
abstract class ImagePickerService {
  Future<PickedFile?> pickImageFromGallery();

  Future<PickedFile?> pickVideoFromGallery();

  Future<PickedFile?> captureImageFromCamera();
}
```

### 5.3 `permission_service.dart`

```dart
abstract class PermissionService {
  Future<PermissionGrantState> check(AppPermission permission);

  Future<PermissionGrantResult> request(AppPermission permission);

  Future<List<PermissionGrantResult>> requestBatch(
    List<AppPermission> permissions,
  );

  Future<void> openAppSettings();
}
```

### 5.4 `recorder_service.dart`

```dart
abstract class RecorderService {
  Future<bool> isRecording();

  Future<RecordSession> start(StartRecordRequest request);

  Future<void> pause();

  Future<void> resume();

  Future<RecordedAudio> stop();

  Future<void> cancel();

  Stream<int> amplitudeStream();
}
```

### 5.5 `audio_player_service.dart`

```dart
abstract class AudioPlayerService {
  Stream<AudioPlaybackSnapshot> playbackStream();

  Future<void> preload({
    required String messageId,
    required String sourceUri,
    required int? durationMs,
  });

  Future<void> play({
    required String messageId,
    required String sourceUri,
    required int? durationMs,
    AudioOutputRoute route = AudioOutputRoute.speaker,
  });

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> seekTo(int positionMs);

  Future<void> setOutputRoute(AudioOutputRoute route);
}
```

### 5.6 `external_opener_service.dart`

```dart
abstract class ExternalOpenerService {
  Future<bool> canOpen({
    required String mimeType,
    required String localPath,
  });

  Future<void> open(ExternalOpenRequest request);
}
```

---

## 6. OpenHarmony adapter 骨架

### 6.1 `ohos_method_channel_names.dart`

```dart
abstract final class OhosMethodChannelNames {
  static const picker = 'com.shengyu.im/ohos/picker';
  static const permission = 'com.shengyu.im/ohos/permission';
  static const recorder = 'com.shengyu.im/ohos/recorder';
  static const audioPlayer = 'com.shengyu.im/ohos/audio_player';
  static const externalOpener = 'com.shengyu.im/ohos/external_opener';
}
```

### 6.2 `ohos_platform_bridge.dart`

```dart
class OhosPlatformBridge {
  OhosPlatformBridge({
    MethodChannel? pickerChannel,
    MethodChannel? permissionChannel,
    MethodChannel? recorderChannel,
    MethodChannel? audioPlayerChannel,
    MethodChannel? externalOpenerChannel,
  })  : _pickerChannel =
            pickerChannel ?? const MethodChannel(OhosMethodChannelNames.picker),
        _permissionChannel = permissionChannel ??
            const MethodChannel(OhosMethodChannelNames.permission),
        _recorderChannel = recorderChannel ??
            const MethodChannel(OhosMethodChannelNames.recorder),
        _audioPlayerChannel = audioPlayerChannel ??
            const MethodChannel(OhosMethodChannelNames.audioPlayer),
        _externalOpenerChannel = externalOpenerChannel ??
            const MethodChannel(OhosMethodChannelNames.externalOpener);

  final MethodChannel _pickerChannel;
  final MethodChannel _permissionChannel;
  final MethodChannel _recorderChannel;
  final MethodChannel _audioPlayerChannel;
  final MethodChannel _externalOpenerChannel;

  Future<T?> invokePicker<T>(String method, [Object? arguments]) {
    return _pickerChannel.invokeMethod<T>(method, arguments);
  }

  Future<T?> invokePermission<T>(String method, [Object? arguments]) {
    return _permissionChannel.invokeMethod<T>(method, arguments);
  }

  Future<T?> invokeRecorder<T>(String method, [Object? arguments]) {
    return _recorderChannel.invokeMethod<T>(method, arguments);
  }

  Future<T?> invokeAudioPlayer<T>(String method, [Object? arguments]) {
    return _audioPlayerChannel.invokeMethod<T>(method, arguments);
  }

  Future<T?> invokeExternalOpener<T>(String method, [Object? arguments]) {
    return _externalOpenerChannel.invokeMethod<T>(method, arguments);
  }
}
```

说明：

1. 首轮模板用 `MethodChannel` 足够
2. 若后续 OpenHarmony 分支对 `Pigeon` 更稳定，可替换 bridge 实现，不影响上层 service contract

### 6.3 `ohos_file_picker_adapter.dart`

```dart
class OhosFilePickerAdapter implements FilePickerService {
  OhosFilePickerAdapter(this._bridge);

  final OhosPlatformBridge _bridge;

  @override
  Future<PickedFile?> pickFile({
    List<String>? allowedExtensions,
    int? maxBytes,
  }) async {
    final result = await _bridge.invokePicker<Map<dynamic, dynamic>>(
      'pickFile',
      {
        'allowedExtensions': allowedExtensions,
        'maxBytes': maxBytes,
      },
    );

    if (result == null) {
      return null;
    }

    return PickedFile(
      uri: result['uri'] as String,
      name: result['name'] as String,
      size: result['size'] as int,
      mimeType: result['mimeType'] as String,
      kind: PickedFileKind.genericFile,
    );
  }
}
```

### 6.4 `ohos_image_picker_adapter.dart`

```dart
class OhosImagePickerAdapter implements ImagePickerService {
  OhosImagePickerAdapter(this._bridge);

  final OhosPlatformBridge _bridge;

  @override
  Future<PickedFile?> pickImageFromGallery() {
    return _pick('pickImageFromGallery', PickedFileKind.image);
  }

  @override
  Future<PickedFile?> pickVideoFromGallery() {
    return _pick('pickVideoFromGallery', PickedFileKind.video);
  }

  @override
  Future<PickedFile?> captureImageFromCamera() {
    return _pick('captureImageFromCamera', PickedFileKind.image);
  }

  Future<PickedFile?> _pick(String method, PickedFileKind kind) async {
    final result = await _bridge.invokePicker<Map<dynamic, dynamic>>(method);
    if (result == null) {
      return null;
    }

    return PickedFile(
      uri: result['uri'] as String,
      name: result['name'] as String,
      size: result['size'] as int,
      mimeType: result['mimeType'] as String,
      kind: kind,
      width: result['width'] as int?,
      height: result['height'] as int?,
      durationMs: result['durationMs'] as int?,
      thumbnailUri: result['thumbnailUri'] as String?,
    );
  }
}
```

### 6.5 `ohos_permission_adapter.dart`

```dart
class OhosPermissionAdapter implements PermissionService {
  OhosPermissionAdapter(this._bridge);

  final OhosPlatformBridge _bridge;

  @override
  Future<PermissionGrantState> check(AppPermission permission) async {
    final raw = await _bridge.invokePermission<String>(
      'checkPermission',
      {'permission': permission.name},
    );
    return _mapState(raw);
  }

  @override
  Future<PermissionGrantResult> request(AppPermission permission) async {
    final raw = await _bridge.invokePermission<Map<dynamic, dynamic>>(
      'requestPermission',
      {'permission': permission.name},
    );

    return PermissionGrantResult(
      permission: permission,
      state: _mapState(raw?['state'] as String?),
    );
  }

  @override
  Future<List<PermissionGrantResult>> requestBatch(
    List<AppPermission> permissions,
  ) async {
    final raw = await _bridge.invokePermission<List<dynamic>>(
      'requestPermissions',
      {
        'permissions': permissions.map((e) => e.name).toList(),
      },
    );

    return (raw ?? const <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(
          (item) => PermissionGrantResult(
            permission: AppPermission.values.byName(item['permission'] as String),
            state: _mapState(item['state'] as String?),
          ),
        )
        .toList();
  }

  @override
  Future<void> openAppSettings() {
    return _bridge.invokePermission<void>('openAppSettings');
  }

  PermissionGrantState _mapState(String? raw) {
    switch (raw) {
      case 'granted':
        return PermissionGrantState.granted;
      case 'permanentlyDenied':
        return PermissionGrantState.permanentlyDenied;
      case 'restricted':
        return PermissionGrantState.restricted;
      case 'limited':
        return PermissionGrantState.limited;
      case 'denied':
      default:
        return PermissionGrantState.denied;
    }
  }
}
```

### 6.6 `ohos_recorder_adapter.dart`

```dart
class OhosRecorderAdapter implements RecorderService {
  OhosRecorderAdapter(this._bridge);

  final OhosPlatformBridge _bridge;
  final StreamController<int> _amplitudeController =
      StreamController<int>.broadcast();

  @override
  Future<bool> isRecording() async {
    return await _bridge.invokeRecorder<bool>('isRecording') ?? false;
  }

  @override
  Future<RecordSession> start(StartRecordRequest request) async {
    final raw = await _bridge.invokeRecorder<Map<dynamic, dynamic>>(
      'start',
      {
        'outputUri': request.outputUri,
        'codec': request.codec.name,
        'maxDurationMs': request.maxDuration.inMilliseconds,
      },
    );

    return RecordSession(
      sessionId: raw?['sessionId'] as String,
      outputUri: raw?['outputUri'] as String,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<void> pause() {
    return _bridge.invokeRecorder<void>('pause');
  }

  @override
  Future<void> resume() {
    return _bridge.invokeRecorder<void>('resume');
  }

  @override
  Future<RecordedAudio> stop() async {
    final raw = await _bridge.invokeRecorder<Map<dynamic, dynamic>>('stop');
    return RecordedAudio(
      uri: raw?['uri'] as String,
      durationMs: raw?['durationMs'] as int,
      size: raw?['size'] as int,
      mimeType: raw?['mimeType'] as String,
    );
  }

  @override
  Future<void> cancel() {
    return _bridge.invokeRecorder<void>('cancel');
  }

  @override
  Stream<int> amplitudeStream() => _amplitudeController.stream;
}
```

### 6.7 `ohos_audio_player_adapter.dart`

```dart
class OhosAudioPlayerAdapter implements AudioPlayerService {
  OhosAudioPlayerAdapter(this._bridge);

  final OhosPlatformBridge _bridge;
  final StreamController<AudioPlaybackSnapshot> _controller =
      StreamController<AudioPlaybackSnapshot>.broadcast();

  @override
  Stream<AudioPlaybackSnapshot> playbackStream() => _controller.stream;

  @override
  Future<void> preload({
    required String messageId,
    required String sourceUri,
    required int? durationMs,
  }) {
    return _bridge.invokeAudioPlayer<void>(
      'preload',
      {
        'messageId': messageId,
        'sourceUri': sourceUri,
        'durationMs': durationMs,
      },
    );
  }

  @override
  Future<void> play({
    required String messageId,
    required String sourceUri,
    required int? durationMs,
    AudioOutputRoute route = AudioOutputRoute.speaker,
  }) {
    return _bridge.invokeAudioPlayer<void>(
      'play',
      {
        'messageId': messageId,
        'sourceUri': sourceUri,
        'durationMs': durationMs,
        'route': route.name,
      },
    );
  }

  @override
  Future<void> pause() {
    return _bridge.invokeAudioPlayer<void>('pause');
  }

  @override
  Future<void> resume() {
    return _bridge.invokeAudioPlayer<void>('resume');
  }

  @override
  Future<void> stop() {
    return _bridge.invokeAudioPlayer<void>('stop');
  }

  @override
  Future<void> seekTo(int positionMs) {
    return _bridge.invokeAudioPlayer<void>(
      'seekTo',
      {'positionMs': positionMs},
    );
  }

  @override
  Future<void> setOutputRoute(AudioOutputRoute route) {
    return _bridge.invokeAudioPlayer<void>(
      'setOutputRoute',
      {'route': route.name},
    );
  }
}
```

### 6.8 `ohos_external_opener_adapter.dart`

```dart
class OhosExternalOpenerAdapter implements ExternalOpenerService {
  OhosExternalOpenerAdapter(this._bridge);

  final OhosPlatformBridge _bridge;

  @override
  Future<bool> canOpen({
    required String mimeType,
    required String localPath,
  }) async {
    return await _bridge.invokeExternalOpener<bool>(
          'canOpen',
          {
            'mimeType': mimeType,
            'localPath': localPath,
          },
        ) ??
        false;
  }

  @override
  Future<void> open(ExternalOpenRequest request) async {
    final canOpenResult = await canOpen(
      mimeType: request.mimeType,
      localPath: request.localPath,
    );

    if (!canOpenResult) {
      throw const PlatformFailure(
        code: PlatformFailureCode.notSupported,
        message: 'No external app available to open this file.',
      );
    }

    await _bridge.invokeExternalOpener<void>(
      'open',
      {
        'localPath': request.localPath,
        'mimeType': request.mimeType,
        'displayName': request.displayName,
      },
    );
  }
}
```

---

## 7. provider 模板

### 7.1 `platform_service_providers.dart`

```dart
final ohosPlatformBridgeProvider = Provider<OhosPlatformBridge>((ref) {
  return OhosPlatformBridge();
});

final filePickerServiceProvider = Provider<FilePickerService>((ref) {
  return OhosFilePickerAdapter(ref.watch(ohosPlatformBridgeProvider));
});

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return OhosImagePickerAdapter(ref.watch(ohosPlatformBridgeProvider));
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return OhosPermissionAdapter(ref.watch(ohosPlatformBridgeProvider));
});

final recorderServiceProvider = Provider<RecorderService>((ref) {
  return OhosRecorderAdapter(ref.watch(ohosPlatformBridgeProvider));
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return OhosAudioPlayerAdapter(ref.watch(ohosPlatformBridgeProvider));
});

final externalOpenerServiceProvider = Provider<ExternalOpenerService>((ref) {
  return OhosExternalOpenerAdapter(ref.watch(ohosPlatformBridgeProvider));
});
```

说明：

1. 上层只依赖 service provider
2. 后续如果 Android/iOS/Web/Desktop 需要不同实现，只替换 provider 装配，不改 feature 逻辑

---

## 8. 页面接入规则

### 8.1 聊天输入区

调用顺序建议：

1. 先检查权限
2. 再选择图片/视频/文件
3. 产出 `PickedFile`
4. 交给上传 coordinator
5. 上传成功后走 `fileId` 发送消息

### 8.2 语音录制

调用顺序建议：

1. 检查麦克风权限
2. `RecorderService.start`
3. 实时监听 amplitude
4. `stop` 返回 `RecordedAudio`
5. 把 `RecordedAudio.uri` 交给上传链路

### 8.3 文件预览与外部打开

调用顺序建议：

1. 先走服务端 `open-strategy`
2. 若策略结果要求下载到本地外部打开
3. 下载完成后调用 `ExternalOpenerService.open`
4. 打开失败时回退到“已下载文件列表 + 错误提示”

---

## 9. OpenHarmony 首轮降级规则

### 9.1 可以接受的降级

1. 暂不支持多选文件
2. 暂不支持拍视频
3. 暂不支持听筒/蓝牙复杂路由切换，只先保扬声器稳定
4. 外部打开失败时允许只保下载成功提示

### 9.2 不可接受的缺口

以下能力不完整，则 OpenHarmony 不能算首轮主链路完成：

1. 图片选择
2. 普通文件选择
3. 录音发送
4. 语音播放暂停续播
5. 权限申请
6. 文件下载后外部打开

---

## 10. HarmonyOS 跟随策略

HarmonyOS 当前不单独定义第二套 service contract。

规则：

1. 先复用 `core/platform/*` 同一套抽象
2. 优先尝试复用 OpenHarmony adapter
3. 若必须分叉，只新增 `core/platform/harmony/*adapter.dart`
4. 禁止因为 HarmonyOS 差异把业务逻辑散落回 feature 层

---

## 11. 当前结论

截至 2026-04-29，OpenHarmony 首轮 P0 适配器模板已经可以冻结为：

1. `FilePickerService` / `OhosFilePickerAdapter`
2. `ImagePickerService` / `OhosImagePickerAdapter`
3. `PermissionService` / `OhosPermissionAdapter`
4. `RecorderService` / `OhosRecorderAdapter`
5. `AudioPlayerService` / `OhosAudioPlayerAdapter`
6. `ExternalOpenerService` / `OhosExternalOpenerAdapter`

这份文档的作用不是证明插件已经可用，而是先把 Flutter 侧架构壳、对象模型、依赖边界、平台通道收口方式冻结下来，确保后续实现不会污染主工程结构。
