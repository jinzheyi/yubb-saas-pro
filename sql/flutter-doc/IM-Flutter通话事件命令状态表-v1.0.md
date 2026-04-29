# IM Flutter 通话事件命令状态表 v1.0

> 文档日期：2026-04-29  
> 文档定位：音视频通话模块的事件、命令、状态流转总表  

---

## 1. 目标

把通话模块所有关键事件统一成“来源 -> 当前状态 -> 命令 -> 下一状态 -> 副作用”的标准表，供 AI 编码时直接落状态机。

---

## 2. 状态集合

- `idle`
- `outgoing`
- `incoming`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `ended`
- `failed`

---

## 3. 用户动作事件表

| 事件 | 当前状态 | 命令 | 下一状态 | 副作用 |
|---|---|---|---|---|
| `startOutgoing` | `idle` | `CreateCallInviteUseCase` | `outgoing` | 建立活动通话、跳转去电页 |
| `accept` | `incoming` | `AcceptCallUseCase` | `accepting` | 权限校验、请求 RTC 参数 |
| `reject` | `incoming` | `RejectCallUseCase` | `ended` | 停止响铃、关闭来电页 |
| `cancel` | `outgoing` | `CancelCallUseCase` | `ended` | 取消呼叫、关闭去电页 |
| `hangup` | `connecting` / `connected` / `reconnecting` | `HangupCallUseCase` | `ended` | 释放媒体、关闭通话页 |
| `toggleMute` | `connecting` / `connected` / `reconnecting` | `CallMediaController.toggleMute` | 原状态保持 | 更新本地音频轨道 |
| `toggleSpeaker` | `connecting` / `connected` / `reconnecting` | `CallMediaController.toggleSpeaker` | 原状态保持 | 切换音频路由 |
| `toggleCamera` | `connecting` / `connected` / `reconnecting` | `CallMediaController.toggleCamera` | 原状态保持 | 开关视频轨道 |
| `switchCamera` | `connecting` / `connected` / `reconnecting` | `CallMediaController.switchCamera` | 原状态保持 | 切换前后摄 |
| `minimize` | `connecting` / `connected` / `reconnecting` | `CallCoordinator.showMiniOverlay` | 原状态保持 | 进入悬浮态 |
| `restore` | `connecting` / `connected` / `reconnecting` | `CallCoordinator.restoreFromMiniOverlay` | 原状态保持 | 回到通话页 |
| `retryReconnect` | `reconnecting` | `ReconnectCallUseCase` | `connecting` | 重建 RTC 连接 |

---

## 4. 业务信令事件表

| 事件 | 当前状态 | 命令 | 下一状态 | 副作用 |
|---|---|---|---|---|
| `call.invite` | `idle` | `onInviteReceived` | `incoming` | 注册活动通话、打开来电页 |
| `call.accepted` | `outgoing` / `accepting` | `onAccepted` | `connecting` | 发起媒体连接 |
| `call.rejected` | `outgoing` | `onRejected` | `ended` | 展示拒绝结果、关闭页面 |
| `call.busy` | `outgoing` | `onBusy` | `ended` | 展示忙线结果 |
| `call.cancelled` | `incoming` | `onCancelled` | `ended` | 停止响铃 |
| `call.timeout` | `outgoing` / `incoming` / `connecting` | `onTimeout` | `ended` | 展示超时结果 |
| `call.ended` | `accepting` / `connecting` / `connected` / `reconnecting` | `onEnded` | `ended` | 释放媒体资源 |
| `call.device-terminated` | `incoming` / `accepting` | `onDeviceTerminated` | `ended` | 结束本端来电竞争 |
| `call.state-sync` | 任意非终态 | `onStateSync` | 由服务端状态决定 | 修正本地状态 |
| `call.media-token-issued` | `accepting` / `outgoing` | `onMediaTokenIssued` | `connecting` | 准备加入 RTC 房间 |

---

## 5. 媒体事件表

| 事件 | 当前状态 | 命令 | 下一状态 | 副作用 |
|---|---|---|---|---|
| `permissionGranted` | `accepting` / `connecting` | `CallMediaController.prepareLocalMedia` | 原状态保持 | 创建本地流 |
| `permissionDenied` | `accepting` / `connecting` | `buildPermissionFailureReason` | `ended` / `failed` | 标记 `permission_denied` |
| `rtcJoining` | `connecting` | `RtcGatewayClient.join` | `connecting` | 建立 Janus session |
| `localPublished` | `connecting` | `publishLocalTracks` | `connecting` | 等待远端轨道 |
| `remoteTrackReady` | `connecting` | `attachRemoteRenderer` | `connected` | 展示远端首帧 |
| `rtcReconnecting` | `connecting` / `connected` | `markReconnecting` | `reconnecting` | 显示重连提示 |
| `rtcRecovered` | `reconnecting` | `restoreRtcSession` | `connected` | 隐藏重连提示 |
| `rtcFailed` | `reconnecting` / `connecting` | `markRtcFailure` | `ended` / `failed` | 清理资源并结束 |
| `localTrackClosed` | `connected` | `updateMediaState` | 原状态保持 | 更新本地 UI 状态 |
| `remoteTrackRemoved` | `connected` | `updateMediaState` | `reconnecting` / 原状态保持 | 等待远端恢复 |

---

## 6. 页面生命周期事件表

| 事件 | 当前状态 | 命令 | 下一状态 | 副作用 |
|---|---|---|---|---|
| `pageOpened` | `idle` | `initialize` | `loading` / 业务导向状态 | 订阅 socket、读取参数 |
| `pageDisposed` | 任意 | `dispose` | 终止订阅 | 非挂断场景不强制结束业务态 |
| `appBackgrounded` | `connecting` / `connected` | `CallCoordinator.persistForegroundState` | 原状态保持 | 准备恢复信息 |
| `appForegrounded` | `connecting` / `connected` / `reconnecting` | `SyncActiveCallStateUseCase` | 服务端状态决定 | 恢复页面 |
| `authInvalidated` | 任意非终态 | `forceTerminate` | `ended` | 清理登录态相关通话资源 |

---

## 7. 状态进入约束

### 7.1 `outgoing`

只允许从：

- `idle`

### 7.2 `incoming`

只允许从：

- `idle`

### 7.3 `accepting`

只允许从：

- `incoming`

### 7.4 `connecting`

只允许从：

- `outgoing`
- `accepting`
- `reconnecting`

### 7.5 `connected`

只允许从：

- `connecting`
- `reconnecting`

### 7.6 `reconnecting`

只允许从：

- `connecting`
- `connected`

### 7.7 `ended`

允许从任意非终态进入。

---

## 8. 结束原因映射

| 触发源 | 结束原因 |
|---|---|
| 主叫取消 | `cancelled_by_caller` |
| 被叫拒绝 | `rejected_by_callee` |
| 对端忙线 | `busy` |
| 响铃超时 | `no_answer` |
| 本端挂断 | `hangup_by_local` |
| 对端挂断 | `hangup_by_remote` |
| 其他设备抢接/终止 | `kicked_by_other_device` |
| 重连超时 | `network_timeout` |
| RTC 不可恢复异常 | `rtc_error` |
| 权限不足 | `permission_denied` |

---

## 9. 控制器实现要求

1. 所有事件都必须通过显式 handler 进入状态机。
2. 所有状态迁移都必须是不可变对象更新。
3. 所有副作用必须集中在 use case、coordinator、media controller 中。
4. 页面层只能发动作，不能手写状态流转。

