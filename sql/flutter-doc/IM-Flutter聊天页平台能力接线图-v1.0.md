# IM Flutter 聊天页平台能力接线图 v1.0

> 文档日期：2026-04-29  
> 文档定位：把聊天页高频交互与 `core/platform/*`、上传链路、预览链路的接线关系明确冻结

---

## 1. 目标

聊天页是最容易在实现时把平台能力直接写进页面的地方。

本文件用于冻结：

1. 聊天页哪些动作会触发平台能力
2. 这些动作经过哪些 controller / coordinator / service
3. 各端差异允许出现在哪一层

---

## 2. 总原则

聊天页任何依赖原生能力的动作都必须遵守以下链路：

```text
Page Widget
  -> ChatController / ChatComposerController / ChatMediaController
  -> application coordinator / use case
  -> core/platform/* service
  -> platform adapter
```

禁止：

1. 页面直接调用图片选择插件
2. 页面直接处理权限弹窗细节
3. 页面直接处理本地文件路径与外部打开

---

## 3. `+` 号面板接线图

### 3.1 相册发图

```text
MorePanelAction.album
  -> ChatMediaController.pickAndUploadImage()
  -> PermissionService.request(photos)
  -> ImagePickerService.pickImageFromGallery()
  -> ChatUploadCoordinator.uploadImage()
  -> SendUploadedMessageUseCase.sendImage()
```

### 3.2 拍照发图

```text
MorePanelAction.camera
  -> ChatMediaController.captureAndUploadImage()
  -> PermissionService.request(camera)
  -> ImagePickerService.captureImageFromCamera()
  -> ChatUploadCoordinator.uploadImage()
  -> SendUploadedMessageUseCase.sendImage()
```

### 3.3 选视频发送

```text
MorePanelAction.video
  -> ChatMediaController.pickAndUploadVideo()
  -> PermissionService.request(photos)
  -> ImagePickerService.pickVideoFromGallery()
  -> ChatUploadCoordinator.uploadVideo()
  -> SendUploadedMessageUseCase.sendVideo()
```

### 3.4 选文件发送

```text
MorePanelAction.file
  -> ChatMediaController.pickAndUploadFile()
  -> PermissionService.request(storageRead)
  -> FilePickerService.pickFile()
  -> ChatUploadCoordinator.uploadFile()
  -> SendUploadedMessageUseCase.sendFile()
```

### 3.5 发位置

```text
MorePanelAction.location
  -> MorePanelActionCoordinator.openLocationPicker()
  -> MapFacade / LocationPickerCoordinator
  -> provider adapter or degraded text address
  -> SendMessageUseCase.sendLocation()
```

### 3.6 发名片

```text
MorePanelAction.contact
  -> MorePanelActionCoordinator.openContactPicker()
  -> ContactRepository.loadPickableContacts()
  -> SendMessageUseCase.sendContactCard()
```

### 3.7 发起音视频

```text
MorePanelAction.call
  -> MorePanelActionCoordinator.startCallEntry()
  -> CallCoordinator.openOutgoingCall()
```

---

## 4. 语音录制接线图

### 4.1 开始录音

```text
VoiceComposer.pressDown()
  -> ChatComposerController.startVoiceRecord()
  -> PermissionService.request(microphone)
  -> RecorderService.start()
```

### 4.2 取消录音

```text
VoiceComposer.slideCancel()
  -> ChatComposerController.cancelVoiceRecord()
  -> RecorderService.cancel()
```

### 4.3 结束录音并发送

```text
VoiceComposer.release()
  -> ChatComposerController.finishVoiceRecord()
  -> RecorderService.stop()
  -> ChatUploadCoordinator.uploadVoice()
  -> SendUploadedMessageUseCase.sendVoice()
```

---

## 5. 语音播放接线图

### 5.1 播放

```text
VoiceMessageBubble.tapPlay()
  -> ChatMediaController.playVoice(message)
  -> AudioPlaybackCoordinator.play(message)
  -> AudioPlayerService.play()
  -> ChatReceiptController.markVoicePlayed(messageId)
```

### 5.2 暂停

```text
VoiceMessageBubble.tapPause()
  -> ChatMediaController.pauseVoice(message)
  -> AudioPlaybackCoordinator.pause()
  -> AudioPlayerService.pause()
```

### 5.3 续播

```text
VoiceMessageBubble.tapResume()
  -> ChatMediaController.resumeVoice(message)
  -> AudioPlaybackCoordinator.resume()
  -> AudioPlayerService.resume()
```

---

## 6. 文件预览与外部打开接线图

### 6.1 图片预览

```text
ImageMessageBubble.tap()
  -> ChatMediaController.previewImage(message)
  -> router -> FilePreviewPage
  -> FilePreviewController.initialize()
```

### 6.2 视频播放

```text
VideoMessageBubble.tap()
  -> ChatMediaController.playVideo(message)
  -> router -> FilePreviewPage
  -> FilePreviewController.initialize()
```

### 6.3 文件打开

```text
FileMessageBubble.tap()
  -> ChatMediaController.openFile(message)
  -> FileOpenCoordinator.resolve()
  -> if in-page preview:
       router -> FilePreviewPage
     else if download/external:
       DownloadService.download()
       -> ExternalOpenerService.open()
```

---

## 7. 消息菜单接线图

### 7.1 通用菜单动作

```text
MessageMenuAction.copy
  -> MessageActionCoordinator.copyText()

MessageMenuAction.quote
  -> ChatComposerController.enterQuote(message)

MessageMenuAction.forward
  -> MessageActionCoordinator.openForwardPicker()
  -> ForwardMessagesUseCase.execute()

MessageMenuAction.favorite
  -> AddFavoriteUseCase.execute()

MessageMenuAction.delete
  -> DeleteMessageUseCase.execute()

MessageMenuAction.recall
  -> RecallMessageUseCase.execute()
```

### 7.2 类型相关动作

```text
MessageMenuAction.openFile
  -> ChatMediaController.openFile(message)

MessageMenuAction.playVoice
  -> ChatMediaController.playVoice(message)

MessageMenuAction.saveImage
  -> FileDownloadCoordinator.downloadToGalleryOrFile()
```

---

## 8. 多端差异边界

### 8.1 Mobile

允许差异：

1. 长按触发菜单
2. 权限弹窗时机
3. 拍照、录音、外部打开的 adapter 实现

### 8.2 Web / Desktop

允许差异：

1. 右键菜单
2. 拖拽上传
3. 浏览器文件选择
4. 下载而非外部打开

### 8.3 OpenHarmony / HarmonyOS

允许差异：

1. picker / permission / recorder / opener adapter 实现
2. 能力降级提示文案

不允许差异：

1. 消息发送协议
2. 上传结果对象
3. 页面状态机
4. 业务动作集合

---

## 9. 聊天页实现红线

以下写法都视为不合格：

1. `ChatPage` 里直接调用平台插件
2. `MessageBubble` 里直接写下载和文件路径逻辑
3. `ChatComposer` 里直接判断 OpenHarmony / Android / iOS 去分支调用 SDK
4. 上传成功后只依赖 `url` 发送，不依赖 `fileId`

---

## 10. 当前结论

截至 2026-04-29：

1. 聊天页和平台能力的接线关系已经可以冻结
2. 聊天页后续代码生成应严格以这份接线图为边界
3. OpenHarmony / HarmonyOS 的差异只能落在 adapter 层，不允许反向污染聊天页
