# IM Flutter 依赖与 Pubspec 建议 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 工程第一阶段依赖建议、用途说明、引入优先级  

---

## 1. 目标

为 Flutter IM 工程定义第一阶段推荐依赖，避免边开发边随意选型。

本文件只给出建议清单与职责，不直接改 `pubspec.yaml`。

---

## 2. 第一阶段核心依赖

### 2.1 状态管理

- `flutter_riverpod`
- `riverpod_annotation`

用途：

- provider 注入
- controller / state 生命周期
- feature 解耦

优先级：

- P0

### 2.2 路由

- `go_router`

用途：

- 应用主壳
- 类型化路由入口
- ShellRoute

优先级：

- P0

### 2.3 网络

- `dio`

用途：

- HTTP 客户端
- interceptor
- refresh token 队列重放

优先级：

- P0

### 2.4 模型与不可变对象

- `freezed_annotation`
- `json_annotation`

用途：

- state
- entity
- dto
- sealed/union 风格状态定义

优先级：

- P0

### 2.5 本地存储

- `flutter_secure_storage`
- `shared_preferences`

用途：

- token 安全存储
- 偏好、草稿、搜索历史

优先级：

- P0

### 2.6 本地数据库

建议二选一：

- `drift`
- 或 `isar`

建议倾向：

- `drift`

原因：

- 结构化消息/会话存储更明确
- 查询能力强
- 更适合 IM 这种索引型数据

优先级：

- P1

### 2.7 WebSocket

优先使用：

- `web_socket_channel`

用途：

- 构建 `ImSocketClient`

优先级：

- P0

### 2.8 日志

- `logger`

用途：

- 分类日志输出

优先级：

- P1

### 2.9 文件路径与系统目录

- `path`
- `path_provider`

用途：

- 文件缓存
- 临时目录

优先级：

- P1

### 2.10 工具依赖

- `collection`
- `uuid`
- `crypto`

用途：

- 集合辅助
- 临时 id
- 摘要能力

优先级：

- P0

---

## 3. 媒体与平台依赖建议

### 3.1 图片/文件选择

- `file_picker`
- `image_picker`

优先级：

- P1

### 3.2 音视频

- `just_audio`
- `video_player`
- `record`
- `flutter_webrtc`
- `permission_handler`
- `wakelock_plus`
- `audio_session`

优先级：

- 音频播放、视频播放、录音：P1
- 实时音视频通话相关依赖：P2

### 3.3 二维码

- `mobile_scanner`

优先级：

- P2

---

## 4. 代码生成依赖

### 4.1 dev_dependencies

- `build_runner`
- `freezed`
- `json_serializable`
- `riverpod_generator`
- `custom_lint`
- `riverpod_lint`

优先级：

- P0

---

## 5. 第一阶段建议依赖组合

### dependencies

- `flutter_riverpod`
- `go_router`
- `dio`
- `freezed_annotation`
- `json_annotation`
- `flutter_secure_storage`
- `shared_preferences`
- `web_socket_channel`
- `collection`
- `uuid`
- `crypto`

### dev_dependencies

- `build_runner`
- `freezed`
- `json_serializable`
- `riverpod_generator`
- `custom_lint`
- `riverpod_lint`

---

## 6. 第二阶段再引入的依赖

第二阶段再加：

- `drift`
- `path_provider`
- `file_picker`
- `image_picker`
- `just_audio`
- `video_player`
- `record`
- `logger`
- `flutter_webrtc`
- `permission_handler`
- `wakelock_plus`
- `audio_session`

原因：

- 第一阶段先跑通主链路，避免初始化阶段依赖过重

---

## 7. 禁止事项

1. 禁止为了单一页面临时引入大型状态管理方案
2. 禁止同时引入多个路由方案
3. 禁止同时引入多个网络方案
4. 禁止在未冻结存储方案时同时并行接入多种本地 DB
