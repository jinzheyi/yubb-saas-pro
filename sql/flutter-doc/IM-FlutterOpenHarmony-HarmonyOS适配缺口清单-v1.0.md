# IM Flutter OpenHarmony / HarmonyOS 适配缺口清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：OpenHarmony / HarmonyOS 平台落地时需要补齐的 adapter、自研桥接与分阶段实施清单  

---

## 1. 目标

在插件兼容矩阵之外，再明确：

- 哪些是立即阻塞项
- 哪些可以降级
- 哪些要单独建平台适配任务

---

## 2. P0 阻塞缺口

这些缺口不补，OpenHarmony 移动端主链路无法宣告完成。

### P0-1 文件选择 adapter

需要：

- `FilePickerService`
- `ImagePickerService`

覆盖：

- 选择图片
- 选择视频
- 选择普通文件
- 相机拍照入口

### P0-2 权限 adapter

需要：

- `PermissionService`

覆盖：

- 相机
- 麦克风
- 相册 / 文件读取

### P0-3 文件打开 adapter

需要：

- `ExternalOpenerService`

覆盖：

- 文件下载后外部打开
- 打开失败回退

### P0-4 音频基础 adapter

需要：

- `AudioPlayerService`
- `RecorderService`

覆盖：

- 语音播放
- 暂停
- 续播
- 录音上传

---

## 3. P1 高价值缺口

### P1-1 secure storage 替代实现

需要验证：

- token 安全存储
- refreshToken 安全存储

若标准插件不可用，则要落平台特定安全存储桥接。

### P1-2 路径与缓存目录

需要：

- `PathProviderAdapter`

否则：

- 文件下载缓存
- 预览缓存
- 上传临时文件

会不稳定。

### P1-3 视频播放

需要：

- `VideoPlayerService`

优先只保：

- 基础播放
- 暂停
- 进度

### P1-4 系统分享

需要：

- `ShareService`

可在主链路完成后补。

---

## 4. P2 后补缺口

### P2-1 地图与位置

可先降级为：

- 文本地址
- 文件化位置卡片
- 外部地图跳转

### P2-2 扫码

不是 IM 主链路阻塞项，后补。

### P2-3 音视频通话

这是 OpenHarmony / HarmonyOS 的高风险项。

要求：

1. 单独验证 `flutter_webrtc` 或替代桥接路径
2. 若平台不成熟，不纳入首轮完成标准

### P2-4 离线推送

必须后补，不作为首轮 OpenHarmony 完成阻塞项。

---

## 5. adapter 自研建议

### 5.1 统一目录

```text
core/platform/ohos/
  picker/
  permission/
  media/
  file/
  share/
  notification/
  rtc/
```

### 5.2 统一命名

- `OhosFilePickerAdapter`
- `OhosImagePickerAdapter`
- `OhosPermissionAdapter`
- `OhosRecorderAdapter`
- `OhosAudioPlayerAdapter`
- `OhosExternalOpenerAdapter`

HarmonyOS 如需单独实现，沿同样命名策略：

- `HarmonyFilePickerAdapter`
- `HarmonyPermissionAdapter`

---

## 6. 分阶段落地建议

### M1 平台基线

- secure storage
- shared preferences
- websocket
- dio

### M2 文件与上传

- file picker
- image picker
- permission
- external opener
- upload/download

### M3 语音

- recorder
- audio player
- audio focus

### M4 丰富能力

- video player
- share
- map
- scan

### M5 高风险原生能力

- rtc
- push

---

## 7. 与当前文档体系的关系

需要重点联动：

- `IM-Flutter多端平台兼容落地设计-v1.0.md`
- `IM-FlutterOpenHarmony适配器骨架模板-v1.0.md`
- `IM-Flutter文件上传与发送链路设计-v1.0.md`
- `IM-Flutter文件预览与多格式渲染设计-v1.0.md`
- `IM-Flutter音视频通话企业级设计-v1.0.md`
- `IM-Flutter移动端离线推送设计-v1.0.md`

---

## 8. 当前 readiness 结论

截至 2026-04-29：

1. OpenHarmony 可以进入正式交付目标
2. 但要宣告“可开工”只代表架构和业务文档已准备好
3. P0 适配器骨架模板已经形成，但要宣告“可落地完成”仍取决于 P0/P1 adapter 真正实现与验证
4. HarmonyOS 当前继续跟随同一缺口体系，但优先级更靠后
