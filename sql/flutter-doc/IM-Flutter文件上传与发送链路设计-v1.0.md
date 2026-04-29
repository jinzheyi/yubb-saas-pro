# IM Flutter 文件上传与发送链路设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 的文件上传、媒体发送、`fileId` 权威规则、后端协同链路设计  

---

## 1. 目标

为 Flutter IM 冻结一套可直接开工的上传链路设计，覆盖：

- 图片上传与发送
- 视频上传与发送
- 普通文件上传与发送
- 语音上传与发送
- 头像、贴纸等非聊天上传
- 上传失败、重试、取消、恢复

本设计只描述 Flutter 目标态如何实现，不记录旧页面行为。

---

## 2. 冻结结论

### 2.1 核心规则

1. 聊天媒体与文件消息统一采用“**先上传，再发消息**”。
2. 上传成功后的权威标识是 `fileId`，不是 `url`。
3. 消息体允许携带 `url` 作为当前链路回显兜底，但后续读取、预览、下载都必须优先走 `fileId`。
4. 文件预览、播放、下载统一通过：
   - `open-strategy`
   - `presigned-get-url`
5. 上传目录必须由客户端按业务规则标准化生成，禁止页面层手写目录字符串。

### 2.2 首期主方案

首期 Flutter 主链路采用：

- `POST /infra/file/upload-and-return-id`
- 服务端代理上传并直接返回 `fileId`
- 上传完成后立刻发送消息

### 2.3 保留扩展方案

保留但首期不落地：

- `GET /infra/file/presigned-url`
- 客户端直传对象存储
- `POST /infra/file/create` 回写文件记录

该方案只用于后续大文件、高并发、弱后端流量压力场景。

---

## 3. 统一上传分层

```text
features/im/chat/
  application/
    coordinators/
      chat_upload_coordinator.dart
    usecases/
      upload_chat_asset_use_case.dart
      send_uploaded_message_use_case.dart
  domain/
    entities/
      upload_task.dart
      upload_result.dart
      upload_policy.dart
    value_objects/
      upload_purpose.dart
      upload_scope.dart
      upload_directory.dart
  infrastructure/
    repositories/
      file_repository_impl.dart
    datasources/
      file_http_data_source.dart
```

页面层只触发：

- `pickImage`
- `pickVideo`
- `pickFile`
- `startVoiceUpload`

上传编排一律收口到 `ChatUploadCoordinator`。

---

## 4. 上传业务模型

### 4.1 `UploadPurpose`

建议固定：

- `chatImage`
- `chatVideo`
- `chatFile`
- `chatVoice`
- `avatar`
- `stickerOriginal`
- `stickerThumb`

### 4.2 `UploadScope`

用于约束目录与归属：

- `directChat(chatId)`
- `groupChat(groupId, chatId)`
- `profile(userId)`
- `sticker(userId)`

### 4.3 `UploadTask`

字段建议：

- `taskId`
- `purpose`
- `scope`
- `localUri`
- `displayName`
- `mimeType`
- `fileSize`
- `status`
- `progress`
- `uploadedFileId`
- `uploadedUrl`
- `checksum`
- `error`
- `createdAt`

### 4.4 `UploadStatus`

- `queued`
- `preparing`
- `uploading`
- `uploaded`
- `sending`
- `sent`
- `failed`
- `cancelled`

---

## 5. 目录规则

### 5.1 冻结目录策略

聊天上传目录统一标准化，不允许页面自由拼接：

#### 单聊

- 图片：`im/chat/{chatId}/image`
- 视频：`im/chat/{chatId}/video`
- 文件：`im/chat/{chatId}/file`
- 语音：`im/chat/{chatId}/voice`

#### 群聊

- 图片：`im/group/{groupId}/image`
- 视频：`im/group/{groupId}/video`
- 文件：`im/group/{groupId}/file`
- 语音：`im/group/{groupId}/voice`

#### 其他

- 头像：`profile/avatar/{userId}`
- 贴纸：`im/sticker/{userId}`

### 5.2 目录规则的价值

1. 服务端可做归属校验。
2. 语音、文件、安全审计更容易治理。
3. 后续清理、迁移、限额统计有统一口径。
4. 避免不同端各自生成风格不一的目录。

---

## 6. 聊天上传主链路

### 6.1 图片 / 视频 / 文件

1. 用户选择本地资源。
2. 客户端做本地校验：
   - 大小
   - MIME / 扩展名
   - 平台权限
3. `ChatUploadCoordinator` 生成标准化 `UploadDirectory`。
4. 调用 `upload-and-return-id` 上传。
5. 服务端返回：
   - `fileId`
   - `url`
   - `name`
   - `size`
   - `mimeType`
   - `md5`
6. 客户端构造发送消息：
   - `fileId` 必填
   - `url` 可带回显兜底
   - 类型相关元数据必填
7. 调用消息发送链路。
8. 发送成功后由服务端消息最终态回补 `sequence / rev`。

### 6.2 语音

1. 客户端先录音并生成本地草稿消息。
2. 草稿消息进入 `uploading`。
3. 上传目录必须是当前会话作用域下的 `voice` 目录。
4. 上传成功后返回 `fileId`、`size`、`mimeType`、`md5`。
5. 发送语音消息时必须同时携带：
   - `fileId`
   - `duration`
   - `durationMs`
   - `size`
   - `format`
   - `md5`
6. 服务端按 `fileId + senderId + scope directory` 校验归属。

---

## 7. 消息体规则

### 7.1 图片消息

必带：

- `fileId`
- `url`
- `thumbnailUrl`
- `size`

可选：

- `width`
- `height`

### 7.2 视频消息

必带：

- `fileId`
- `url`
- `coverUrl`
- `size`

可选：

- `duration`
- `width`
- `height`

### 7.3 文件消息

必带：

- `fileId`
- `url`
- `fileName`
- `size`
- `fileType`

### 7.4 语音消息

必带：

- `fileId`
- `url`
- `duration`
- `durationMs`
- `size`
- `format`

建议：

- `md5`

---

## 8. `fileId` 与 `url` 的权责边界

### 8.1 `fileId`

权威用途：

- 文件归属
- 打开策略
- 下载鉴权
- 预签名读取
- 服务端审计
- 消息长期可用性

### 8.2 `url`

非权威用途：

- 当前发送链路即时回显
- 上传成功后首屏短时预览兜底

### 8.3 明确禁止

1. 新版 Flutter 不允许只发 `url` 不发 `fileId`。
2. 页面层不允许把永久访问建立在上传返回 `url` 上。
3. 不允许在消息渲染层自行拼接静态文件域名。

---

## 9. 上传状态机

### 9.1 通用状态流

`queued -> preparing -> uploading -> uploaded -> sending -> sent`

失败分支：

- `preparing/uploading/sending -> failed`

取消分支：

- `queued/uploading -> cancelled`

### 9.2 失败恢复规则

#### 上传前失败

- 允许重新选择文件

#### 上传中失败

- 保留本地任务
- 支持用户点击重试

#### 上传成功但消息发送失败

- 不重新上传文件
- 直接基于已拿到的 `fileId` 重发消息

这条规则必须冻结，否则会造成重复文件记录与无意义流量浪费。

---

## 10. 群文件链路整顿建议

### 10.1 冻结结论

群聊发送文件时，不应为了“群文件列表”再重复上传一份二进制。

### 10.2 推荐目标态

采用单次上传，多处消费：

1. 聊天发送先上传拿 `fileId`
2. 消息发送成功后
3. 由业务层根据 `fileId` 建立群文件索引或异步入库

### 10.3 不推荐

1. 聊天消息上传一份
2. 群文件模块再上传一份
3. 造成两个不同 `fileId`
4. 造成存储重复、统计混乱、权限治理复杂

---

## 11. Flutter 端接口设计

### 11.1 `FileRepository`

建议方法：

- `uploadAndCreateFile(UploadRequest request)`
- `getFileOpenStrategy(String fileId, {int expirationSeconds = 600})`
- `getPresignedGetUrl(String fileId, {int expirationSeconds = 600})`

预留：

- `createUploadTicket(UploadTicketRequest request)`
- `completeDirectUpload(CompleteUploadRequest request)`

### 11.2 `ChatUploadCoordinator`

建议动作：

- `uploadImage(ChatUploadInput input)`
- `uploadVideo(ChatUploadInput input)`
- `uploadFile(ChatUploadInput input)`
- `uploadVoice(ChatVoiceUploadInput input)`
- `retryTask(String taskId)`
- `cancelTask(String taskId)`

### 11.3 `SendUploadedMessageUseCase`

职责：

- 把 `UploadResult` 转换成对应消息发送命令
- 统一注入 `fileId`
- 保障重试时不重复上传

---

## 12. 后端协同要求

### 12.1 P0

1. `upload-and-return-id` 继续稳定提供。
2. 返回体必须稳定包含：
   - `fileId`
   - `url`
   - `name`
   - `size`
   - `mimeType`
3. `fileId` 相关出口最终按 Flutter 侧 `String` 消费。

### 12.2 P1

1. 上传接口增加更清晰的业务用途表达：
   - `purpose`
   - `chatId`
   - `groupId`
2. 服务端按用途校验目录而不是只信任前端目录字符串。
3. 群文件索引支持基于已上传 `fileId` 建立关联。

### 12.3 P2

1. 大文件直传模式标准化。
2. 分片上传协议化。
3. 秒传 / 去重策略平台化。

---

## 13. 非聊天上传

### 13.1 头像上传

头像上传不走聊天上传协调器，单独走 `ProfileUploadFacade`，但仍复用统一底层上传接口。

### 13.2 贴纸上传

贴纸上传建议返回：

- `fileId`
- `thumbFileId`
- `md5`

贴纸收藏、去重、复用应优先依赖 `md5 + fileId` 组合。

---

## 14. AI 开工最小落地集

如果 AI 直接开始实现上传链路，先读：

1. `IM-Flutter核心协议与事件契约-v1.0.md`
2. `IM-Flutter聊天页详细设计-v1.0.md`
3. `IM-Flutter文件上传与发送链路设计-v1.0.md`
4. `IM-Flutter文件上传对象模板-v1.0.md`
5. `IM-Flutter文件上传代码骨架模板-v1.0.md`
6. `IM-Flutter文件预览与多格式渲染设计-v1.0.md`
7. `IM-Flutter后端协同约束与接口整顿建议-v1.0.md`

---

## 15. 验收标准

1. 图片、视频、文件、语音都走统一上传编排。
2. 所有聊天媒体消息都以 `fileId` 为权威。
3. 上传成功但发送失败时可以不重复上传直接重发。
4. 文件打开、播放、下载都不直连历史上传 URL。
5. 群文件链路不重复上传同一二进制。
