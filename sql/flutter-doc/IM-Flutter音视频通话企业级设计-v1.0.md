# IM Flutter 音视频通话企业级设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 多端 IM 音视频通话目标态设计  
> 适用范围：Web、Android、iOS、Windows、macOS  

---

## 1. 目标

构建一套不依赖付费大厂实时音视频 SDK 的企业级通话体系，采用 Flutter 自研客户端、IM 自有业务信令、自建 WebRTC 媒体基础设施。

本设计只描述新体系应该如何实现，不记录历史方案。

---

## 2. 技术路线

### 2.1 总体选型

- Flutter 客户端媒体层：`flutter_webrtc`
- Flutter 客户端通话业务层：自研 `call` feature
- 业务信令：复用 IM 自有 WebSocket 通道
- 媒体信令与媒体交换：自建 Janus SFU 集群
- NAT 穿透：自建 `coturn`
- 呼叫状态、通话记录、离线推送、多端裁决：IM 业务后端

### 2.2 为什么采用这条路线

1. 不受托管型大厂 SDK 计费和闭源能力边界限制。
2. Flutter 端可以统一使用开源 WebRTC 能力覆盖多端。
3. 1v1 音视频当前即可落地，后续多人会议、屏幕共享、录制也有可演进空间。
4. 业务状态和媒体状态分层，IM 团队可以稳定掌控“谁可以响铃、谁可接听、何时生成通话记录、何时结束会话”。

### 2.3 明确不采用

- 不采用托管式 RTC 平台 SDK 作为主方案。
- 不采用前端直连、弱业务约束的纯客户端裁决方案。
- 不采用 1v1 纯 P2P 作为长期默认方案。

---

## 3. 总体架构

### 3.1 架构分层

1. `presentation`
   - 来电页
   - 去电页
   - 通话中页面
   - 悬浮中控条
2. `application`
   - `CallCoordinator`
   - `CallController`
   - `CallMediaController`
   - `CallPermissionCoordinator`
3. `domain`
   - `CallSession`
   - `CallParticipant`
   - `CallInvite`
   - `CallMediaState`
   - `CallEndReason`
4. `infrastructure`
   - `CallRepository`
   - `CallSocketDataSource`
   - `CallHttpDataSource`
   - `RtcGatewayClient`
   - `TurnConfigProvider`

### 3.2 系统角色

- Flutter IM 客户端
- IM 业务后端
- Janus SFU
- coturn
- 推送网关

### 3.3 权责边界

#### IM 业务后端负责

- 发起呼叫权限校验
- 多端同时响铃与唯一接听裁决
- 忙线判定
- 超时结束
- 通话生命周期状态推进
- 通话记录生成
- 通知推送
- 媒体房间、token、publisher/subscriber 参数分发

#### Janus 负责

- WebRTC 媒体协商
- 音视频转发
- 上下行轨道管理
- 弱网适配基础能力
- 录制扩展能力

#### Flutter 客户端负责

- 权限申请
- 设备采集
- 渲染本地/远端流
- 音频路由切换
- 页面状态机与用户交互
- 断网重连后的页面恢复

---

## 4. 核心原则

### 4.1 业务状态机与媒体状态机分离

- 业务状态由 IM 后端权威推进。
- 媒体连接状态由客户端与 Janus 协同维护。
- 页面展示以业务状态为主，以媒体状态做补充。

### 4.2 多端只允许一个终端正式接听

- 同账号多设备允许同时收到来电。
- 只允许一个设备进入已接听态。
- 其余设备必须收到结束或转忙通知并立即退出响铃态。

### 4.3 先业务建会话，再发媒体凭证

- 呼叫先创建 `callSessionId`
- 完成业务校验后才签发 RTC 连接参数
- 客户端不可自行生成媒体会话主键

### 4.4 弱网场景下优先保留会话，不立即结束业务通话

- 短时媒体抖动先进入 `reconnecting`
- 重连窗口内维持通话页面
- 超过阈值才转业务结束

### 4.5 端能力降级明确

- 无摄像头权限不可进入视频接通态
- Web 不支持的系统级来电体验采用页内全屏响铃替代
- Desktop 对移动原生来电弹框不做强依赖

---

## 5. 通话范围

### 5.1 第一阶段

- 单聊语音通话
- 单聊视频通话
- 来电响铃
- 去电等待
- 接听/拒绝/挂断
- 静音
- 扬声器切换
- 摄像头开关
- 前后摄切换
- 小窗悬浮态
- 弱网重连
- 通话记录消息

### 5.2 第二阶段

- 桌面端屏幕共享
- 移动端屏幕共享
- 通话中切语音/视频模式
- 通话质量诊断面板
- 录制
- 多人会议

---

## 6. 后端业务链路

### 6.1 发起呼叫

1. 调用 `CreateCallInvite` 接口创建呼叫。
2. 后端校验：
   - 用户在线状态
   - 会话合法性
   - 黑名单与权限
   - 被叫忙线状态
3. 后端创建 `callSessionId`
4. 后端推进业务状态到 `ringing`
5. 后端通过 IM WebSocket 向被叫在线设备广播来电事件
6. 如果被叫离线，触发离线推送

### 6.2 被叫接听

1. 被叫设备提交 `accept`
2. 后端以 `callSessionId` 做 CAS 裁决
3. 成功接听的设备成为 `acceptedDeviceId`
4. 后端向双方签发 RTC 房间参数
5. 其余设备收到 `terminated_elsewhere`
6. 页面进入 `connecting`

### 6.3 建立媒体连接

1. 客户端申请麦克风/摄像头权限
2. 创建本地媒体流
3. 连接 Janus
4. attach 对应 plugin handle
5. publish 本地轨道
6. subscribe 远端轨道
7. 首帧到达后状态转 `connected`

### 6.4 结束通话

任一方挂断、拒绝、超时、失联超窗、被踢下线时：

1. 后端推进业务状态到 `ended`
2. 后端广播结束事件
3. 客户端停止采集与渲染
4. 后端生成通话记录消息
5. 会话列表刷新最近消息与未读状态

---

## 7. 通话状态机

### 7.1 业务状态

- `idle`
- `outgoing`
- `incoming`
- `accepting`
- `connecting`
- `connected`
- `reconnecting`
- `ended`

### 7.2 结束原因

- `cancelled_by_caller`
- `rejected_by_callee`
- `busy`
- `no_answer`
- `hangup_by_local`
- `hangup_by_remote`
- `kicked_by_other_device`
- `network_timeout`
- `rtc_error`
- `permission_denied`

### 7.3 页面状态映射

#### `IncomingCallPage`

- `incoming`
- `accepting`
- `ended`

#### `OutgoingCallPage`

- `outgoing`
- `connecting`
- `ended`

#### `CallSessionPage`

- `connecting`
- `connected`
- `reconnecting`
- `ended`

---

## 8. Flutter 页面设计

### 8.1 `IncomingCallPage`

职责：

- 响铃展示
- 主叫信息展示
- 拒绝
- 接听
- 权限预检

关键组件：

- `IncomingCallAvatar`
- `IncomingCallTitle`
- `IncomingCallActionBar`
- `IncomingCallPermissionBanner`

### 8.2 `OutgoingCallPage`

职责：

- 展示呼叫中、等待接听
- 支持取消呼叫
- 展示早期媒体准备状态

关键组件：

- `OutgoingCallHeader`
- `OutgoingCallStatusText`
- `OutgoingCallActionBar`

### 8.3 `CallSessionPage`

职责：

- 本地/远端视频布局
- 语音模式布局
- 静音、摄像头、扬声器、切摄像头、最小化
- 网络重连提示
- 通话时长展示

关键组件：

- `CallVideoStage`
- `CallVoiceStage`
- `CallTopStatusBar`
- `CallBottomControlBar`
- `CallMiniOverlayEntry`

### 8.4 多端布局约束

#### Mobile

- 全屏沉浸式通话页
- 最小化后回到聊天页显示悬浮条

#### Web/Desktop

- 独立通话页或模态工作区
- 视频窗口可拉伸
- 语音模式优先信息面板布局

---

## 9. Flutter 领域模型

### 9.1 `CallSession`

字段：

- `callSessionId`
- `chatId`
- `callType`
- `callerUserId`
- `calleeUserId`
- `acceptedDeviceId`
- `status`
- `endReason`
- `startedAt`
- `answeredAt`
- `endedAt`
- `durationSeconds`
- `rtcRoomId`
- `rtcPublisherToken`
- `rtcSubscriberToken`

### 9.2 `CallParticipant`

- `userId`
- `deviceId`
- `displayName`
- `avatar`
- `role`
- `mediaState`

### 9.3 `CallMediaState`

- `microphoneEnabled`
- `cameraEnabled`
- `speakerEnabled`
- `frontCamera`
- `localVideoFirstFrameReady`
- `remoteVideoFirstFrameReady`
- `networkQualityLevel`

### 9.4 `CallLaunchArgs`

- `callSessionId`
- `entryMode`
- `callType`
- `fromChatId`

---

## 10. 客户端模块拆分

### 10.1 `call` feature 目录建议

```text
lib/features/im/call/
  application/
    controller/
    coordinator/
    usecase/
  domain/
    entity/
    enum/
    service/
  infrastructure/
    datasource/
    dto/
    mapper/
    repository/
    rtc/
  presentation/
    args/
    controller/
    page/
    state/
    widgets/
```

### 10.2 核心对象

- `CallController`
- `CallState`
- `CallCoordinator`
- `ActiveCallRegistry`
- `RtcSessionController`
- `JanusSignalingClient`
- `CallRepository`
- `CreateCallInviteUseCase`
- `AcceptCallUseCase`
- `RejectCallUseCase`
- `HangupCallUseCase`
- `ReconnectCallUseCase`

---

## 11. 信令设计

### 11.1 业务信令

通过 IM WebSocket 下发，建议事件：

- `call.invite`
- `call.ringing`
- `call.accepted`
- `call.rejected`
- `call.busy`
- `call.cancelled`
- `call.ended`
- `call.timeout`
- `call.media-token-issued`
- `call.device-terminated`
- `call.state-sync`

### 11.2 媒体信令

通过 Janus WebSocket/HTTP API 交互：

- session create
- plugin attach
- publish
- subscribe
- trickle
- unpublish
- detach

### 11.3 关键规则

1. 业务信令必须幂等。
2. 所有事件以 `callSessionId` 为主键。
3. 页面恢复必须可以由 `call.state-sync` 重建状态。
4. 媒体异常不能直接推翻业务状态，必须走后端确认结束。

---

## 12. Janus 集成策略

### 12.1 采用方式

- 采用自建 Janus 集群作为 SFU
- Flutter 侧直接实现 Janus 协议客户端
- 不依赖托管会议服务

### 12.2 插件策略

第一阶段建议基于现成视频房间能力抽象 1v1 房间模型。

约束：

- 一个 `callSessionId` 对应一个 RTC 房间
- 仅允许两名业务参与者有效发布
- 房间销毁由 IM 后端驱动

### 12.3 房间与用户映射

- `rtcRoomId = callSessionId`
- `publisherId = userId + deviceId`
- `display = json(userId, deviceId, tenantId, role)`

### 12.4 集群策略

- Janus 无状态化部署
- 前置负载均衡
- 按地域就近接入
- 会话节点映射写入 Redis

---

## 13. TURN / NAT 穿透设计

### 13.1 基础方案

- 自建 `coturn`
- 同时提供 STUN/TURN
- 使用短期凭证
- 通过后端动态签发 TURN 用户名和密码

### 13.2 必须规则

- 客户端不可内置固定 TURN 密钥
- 多租户环境下 TURN 配置要可隔离
- 国内外网络环境分池

### 13.3 安全要求

- TURN 凭证短时有效
- 统一 TLS
- 服务器 IP 不直接暴露在业务文档常量中

---

## 14. 权限与系统能力

### 14.1 Android / iOS

- 麦克风权限
- 摄像头权限
- 蓝牙音频路由权限
- 前台通话服务
- 锁屏来电唤起

### 14.2 Web

- 浏览器麦克风/摄像头权限
- 标签页可见性监听
- 权限被拒绝时立即回落到失败态说明

### 14.3 Desktop

- 摄像头/麦克风权限
- 窗口置顶能力按平台适配

---

## 15. 多端一致性设计

### 15.1 同账号多设备

- 来电广播到全部在线设备
- 仅一个设备可正式接听
- 其他设备立即退出响铃界面

### 15.2 已有通话占线

- 当前用户已有 `connected` 或 `connecting` 通话时，新来电默认返回 `busy`
- 后续若要支持排队或保持，单独扩展状态机

### 15.3 重登与挤下线

- 登录态失效或被其他设备挤下线时，通话直接结束
- 结束原因为 `kicked_by_other_device`

---

## 16. 与聊天域协同

### 16.1 聊天页入口

- 单聊输入区更多面板提供：
  - 语音通话
  - 视频通话

### 16.2 会话列表展示

- 通话结束后生成一条通话记录消息
- 预览文案由 `CallRecordRenderer` 统一生成

### 16.3 页面跳转规则

- 从聊天页发起：`/call/outgoing`
- 收到来电：`/call/incoming`
- 接通后：`/call/session`

---

## 17. 可观测性

### 17.1 日志主键

- `callSessionId`
- `chatId`
- `userId`
- `deviceId`
- `rtcRoomId`
- `janusSessionId`

### 17.2 客户端指标

- 来电展示耗时
- 接听成功率
- 首帧耗时
- 重连次数
- 平均通话时长
- 权限拒绝率
- 弱网断开率

### 17.3 服务端指标

- 呼叫创建成功率
- 忙线率
- 超时率
- 接听率
- Janus 节点负载
- TURN 中继占比

---

## 18. 安全设计

1. RTC token 必须短时有效。
2. 房间进入权限必须绑定 `userId + deviceId + callSessionId`。
3. 客户端不得信任本地传入的主叫/被叫身份。
4. 通话记录查询必须遵守原会话授权。
5. 生产环境默认不在客户端日志输出完整 SDP/ICE 明文。

---

## 19. 依赖建议

### 19.1 第一阶段必需

- `flutter_webrtc`
- `permission_handler`
- `wakelock_plus`
- `audio_session`

### 19.2 第二阶段可选

- 系统来电 UI 插件
- 悬浮窗或画中画插件
- 通话质量检测辅助插件

原则：

- 插件只用于平台能力补齐
- 媒体主链路必须掌握在自研层

---

## 20. 开发顺序

1. 冻结业务状态机和接口契约
2. 完成 `call` feature 的实体、枚举、路由参数
3. 完成通话页三页结构
4. 打通 IM 业务信令
5. 接入 `flutter_webrtc`
6. 完成 Janus 协议客户端
7. 完成 1v1 语音
8. 完成 1v1 视频
9. 完成悬浮态和后台恢复
10. 完成弱网重连与埋点

---

## 21. 验收标准

### 21.1 功能验收

- 单聊语音可稳定呼出、接听、挂断
- 单聊视频可稳定首帧建立
- 多端同账号只允许一个终端接听
- 来电、去电、通话中三类页面状态正确
- 通话记录消息正常入会话

### 21.2 工程验收

- 页面、控制器、RTC 适配层分离
- 不在页面直接操作 WebRTC 原始对象
- 所有异常路径都有结束态
- 可通过日志完整回放一次通话链路

### 21.3 性能验收

- 常规网络下首帧耗时可观测
- 重连策略可触发且不死循环
- 挂断后资源释放完整

