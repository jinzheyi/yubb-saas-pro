# IM Flutter Pubspec 草案 v1.0

> 文档日期：2026-04-29  
> 文档定位：第一阶段 `pubspec.yaml` 建议草案  

---

## 1. 目标

给出第一阶段建议的 `pubspec.yaml` 依赖草案，供真正开工时直接落地。

---

## 2. 建议草案

```yaml
name: shengyu_ui_admin_im
description: Shengyu enterprise IM built with Flutter
publish_to: "none"

version: 1.0.0+1

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8

  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  go_router: ^15.1.2

  dio: ^5.9.0

  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

  flutter_secure_storage: ^9.2.4
  shared_preferences: ^2.5.3

  web_socket_channel: ^3.0.3

  collection: ^1.19.1
  uuid: ^4.5.1
  crypto: ^3.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

  build_runner: ^2.7.0
  freezed: ^3.2.0
  json_serializable: ^6.11.0
  riverpod_generator: ^2.6.5
  custom_lint: ^0.8.0
  riverpod_lint: ^2.6.5

flutter:
  uses-material-design: true
```

---

## 3. 第一阶段不建议直接加入的依赖

先不加：

- `drift`
- `file_picker`
- `image_picker`
- `just_audio`
- `video_player`
- `record`
- `mobile_scanner`
- `logger`
- `flutter_webrtc`
- `permission_handler`
- `wakelock_plus`
- `audio_session`

原因：

- 第一阶段先跑通主链路
- 避免初始化依赖过重

---

## 4. 第二阶段建议追加

```yaml
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.x
  path_provider: ^2.x
  file_picker: ^10.x
  image_picker: ^1.x
  just_audio: ^0.10.x
  video_player: ^2.x
  record: ^6.x
  flutter_webrtc: ^1.x
  permission_handler: ^12.x
  wakelock_plus: ^1.x
  audio_session: ^0.2.x
  logger: ^2.x
```

---

## 5. 说明

1. 版本号在真正开工时应再统一核对。
2. 若 Flutter SDK 升级，优先保证 `riverpod`、`go_router`、`dio` 兼容。
