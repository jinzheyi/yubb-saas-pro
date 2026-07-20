# 圣钰 IM 企业级实时音视频通话系统设计文档

**版本**: v2.2  
**日期**: 2026-07-20  
**状态**: 设计阶段（基于源码深度验证 + 边界场景完善 + 微信/大厂经验对标）

---

## 目录

1. [背景与目标](#1-背景与目标)
2. [技术选型与架构决策](#2-技术选型与架构决策)
3. [微信功能对标与业务场景](#3-微信功能对标与业务场景)
4. [系统架构设计](#4-系统架构设计)
5. [协议设计](#5-协议设计)
6. [后端实现方案](#6-后端实现方案)
7. [Flutter 客户端实现](#7-flutter-客户端实现)
8. [通话记录与消息气泡](#8-通话记录与消息气泡)
9. [数据库设计](#9-数据库设计)
10. [API 接口设计](#10-api-接口设计)
11. [配置管理与国际化](#11-配置管理与国际化)
12. [安全与性能优化](#12-安全与性能优化)
13. [实施路线图](#13-实施路线图)
14. [边界场景处理](#14-边界场景处理)

---

## 1. 背景与目标

### 1.1 背景

圣钰 IM 系统已完成基础 IM 功能（文本、图片、语音、视频、文件消息等），现需扩展企业级实时音视频通话能力。

**现有基础**（基于源码验证）：
- ✅ WebSocket 中间件（Netty）已实现消息处理器模式（MessageProcessor）
- ✅ Proto 协议已定义 CALL_SIGNAL = 206 消息类型
- ✅ Flutter 端已搭建通话模块基础架构（call_controller、call_repository 等）
- ✅ 后端已有 ImCallRecordDO 实体类和 ImCallRecordMapper
- ✅ 已实现多设备管理、消息推送等核心能力

### 1.2 设计目标

| 目标维度 | 具体要求 |
|---------|---------|
| **功能完整性** | 覆盖微信 90% 以上通话功能（1v1、群组、屏幕共享等） |
| **多端兼容** | Web、Android、iOS、Windows、macOS 全平台 |
| **性能指标** | 端到端延迟 < 300ms，抗丢包率 > 80% |
| **可扩展性** | 支持 100+ 人视频会议，水平扩展 |
| **自主可控** | 基于开源方案，可私有化部署 |
| **安全性** | 端到端加密，符合等保三级要求 |

---

## 2. 技术选型与架构决策

### 2.1 媒体服务器选型

**实际选型：Janus Gateway**（基于源码验证）

从 Flutter 端 `RtcRoomBundle` 实体可见：
```dart
// shengyu-ui-admin-flutter/lib/features/im/call/domain/entities/rtc_room_bundle.dart
class RtcRoomBundle {
  final String callSessionId;
  final String roomId;
  final String publisherId;
  final String displayName;
  final String janusUrl;        // ← Janus 服务器地址
  final List<String> turnUrls;  // ← TURN 服务器列表
  final String turnUsername;
  final String turnCredential;
  final String token;
}
```

**Janus vs LiveKit 对比**：

| 维度 | Janus | LiveKit | 选型理由 |
|-----|-------|---------|---------|
| **语言** | C | Go | Janus 性能更优，内存占用更低 |
| **协议** | GPL | Apache 2.0 | Janus 插件模式灵活，适合深度定制 |
| **架构** | 插件化 | 单体 | Janus 可按需加载插件（videoroom、textroom 等） |
| **信令** | 自定义 JSON | 内置 | Janus 信令灵活，可与现有 WebSocket 中间件深度集成 |
| **录制** | 插件支持 | 内置 | 两者均支持 |
| **社区** | 成熟稳定 | 新兴活跃 | Janus 在企业级场景验证更充分 |

**结论**：项目已选择 Janus，符合企业级稳定性要求。

### 2.2 客户端技术栈

**已验证的技术栈**（基于源码）：

```yaml
# pubspec.yaml（现有依赖）
dependencies:
  flutter_webrtc: ^1.4.0      # WebRTC 核心能力
  permission_handler: ^11.3.1 # 权限管理
  # 注：项目使用原生 WebRTC + Janus SDK，未使用 LiveKit Client SDK
```

**架构分层**：
```
┌─────────────────────────────────────────┐
│         Flutter 业务层                   │
│  - CallController (状态管理)             │
│  - CallRepository (数据访问)             │
│  - CallMediaController (媒体控制)        │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         WebRTC 抽象层                    │
│  - RtcRoomBundle (房间配置)              │
│  - Janus Client (信令交互)               │
│  - MediaStream (媒体流管理)              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         flutter_webrtc 插件              │
│  - RTCPeerConnection                    │
│  - MediaStream / MediaTrack             │
│  - RTCVideoView                         │
└─────────────────────────────────────────┘
```

### 2.3 信令通道设计

**实际信令通道**（基于源码验证）：

通话信令通过 **SYSTEM_NOTIFY (200)** 消息类型的 `call.` 前缀事件传输，而非直接使用 CALL_SIGNAL (206)。

```dart
// call_socket_data_source.dart（实际实现）
void _onSocketEvent(ImSocketEvent event) {
  if (event.type != SocketEventTypes.systemNotify) {
    return;
  }
  final dto = _toCallSignalEvent(event.payload);
  if (dto == null || _controller.isClosed) {
    return;
  }
  _controller.add(dto);
}

CallSignalEventDto? _toCallSignalEvent(Map<String, Object?> payload) {
  final eventType = payload['type']?.toString() ?? '';
  if (!eventType.startsWith('call.')) {
    return null;
  }
  // 解析 callSessionId 和 payload
  final callSessionId = payload['callSessionId']?.toString() ?? '';
  return CallSignalEventDto(
    type: eventType,
    callSessionId: callSessionId,
    payload: payload,
  );
}
```

**信令事件类型**：
- `call.invite` - 发起呼叫
- `call.accepted` - 接听
- `call.rejected` - 拒绝
- `call.busy` - 忙线
- `call.cancelled` - 取消
- `call.timeout` - 超时
- `call.ended` - 通话结束
- `call.deviceTerminated` - 设备被踢出
- `call.mediaTokenIssued` - 媒体令牌下发
- `call.stateSync` - 状态同步

**优势**：
- ✅ 复用现有 SYSTEM_NOTIFY 通道，无需新增消息类型
- ✅ 通过 `call.` 前缀区分通话信令，便于扩展
- ✅ 支持多设备广播（已有 sendToUser 方法）

---

## 3. 微信功能对标与业务场景

### 3.1 核心功能清单

| 功能类别 | 微信功能 | 优先级 | 实现方案 |
|---------|---------|--------|---------|
| **基础通话** | 1v1 语音通话 | P0 | Janus videoroom 插件 |
| | 1v1 视频通话 | P0 | Janus videoroom 插件 |
| | 群组语音通话 | P0 | Janus videoroom（多人房间） |
| | 群组视频会议 | P1 | Janus videoroom + Simulcast |
| **通话控制** | 来电提醒（铃声+震动） | P0 | 本地通知 + 系统铃声 |
| | 多设备同时响铃 | P0 | WebSocket 广播 CALL_INITIATE |
| | 接听/拒绝/挂断 | P0 | 信令控制 |
| | 通话中静音 | P0 | MediaStream track 控制 |
| | 切换听筒/扬声器 | P0 | AudioManager（Android）/ AVAudioSession（iOS） |
| | 切换前后摄像头 | P0 | CameraEnumerator |
| | 通话时长显示 | P0 | 本地计时器 |
| **高级功能** | 屏幕共享 | P1 | getDisplayMedia（Web）/ MediaProjection（Android） |
| | 通话转接 | P2 | 信令控制 + 新房间 |
| | 通话等待 | P2 | 保持当前通话，提示新来电 |
| **网络适配** | 弱网自适应 | P0 | Janus 内置码率自适应 |
| | 网络质量提示 | P1 | RTCPeerConnection stats 监控 |
| | 断线重连 | P0 | Janus keep_alive + 自动重连 |
| **通话记录** | 通话记录查询 | P1 | 数据库存储 + API 查询 |
| | 通话记录消息气泡 | P1 | 聊天窗口插入系统消息 |

### 3.2 复杂业务场景

#### 场景 1：多设备来电处理

**场景描述**：用户在手机、平板、电脑同时登录，来电时所有设备同时响铃。

**处理流程**：
```
1. 主叫方发起通话 → WebSocket 发送 CALL_INITIATE
2. 后端查询被叫方所有在线设备
3. 后端向所有设备广播 CALL_INITIATE 信令
4. 各设备收到信令后：
   - 显示来电界面
   - 播放铃声 + 震动
   - 启动 30 秒无应答计时器
5. 任一设备接听 → 发送 CALL_ACCEPTED
6. 后端向所有设备广播 CALL_ACCEPTED
7. 其他设备收到后：
   - 关闭来电界面
   - 停止铃声
   - 更新通话状态为"已在其他设备接听"
```

**源码映射**：
```dart
// call_controller.dart
Future<void> _onSocketEvent(CallSocketEvent event) async {
  switch (event.type) {
    case CallSocketEventType.invite:
      onInviteReceived(event);  // 显示来电界面
      break;
    case CallSocketEventType.accepted:
      await onAccepted();  // 进入通话
      break;
    case CallSocketEventType.deviceTerminated:
      await onDeviceTerminated();  // 被其他设备接听
      break;
  }
}
```

#### 场景 2：通话中网络切换

**场景描述**：用户从 WiFi 切换到 4G，通话不中断。

**处理流程**：
```
1. 网络变化触发 ICE 重新协商
2. flutter_webrtc 自动收集新 ICE candidates
3. 通过 Janus 信令交换 candidates
4. 建立新的媒体通道
5. 通话继续（用户无感知）
```

**源码映射**：
```dart
// call_controller.dart
void markReconnecting() {
  state = state.copyWith(
    pageStatus: CallPageStatus.reconnecting,
    mediaState: _callMediaController.markReconnecting(state.mediaState),
  );
}

void restoreConnected() {
  state = state.copyWith(
    pageStatus: CallPageStatus.connected,
    mediaState: _callMediaController.markConnected(state.mediaState),
  );
}
```

#### 场景 3：通话记录消息气泡

**场景描述**：通话结束后，在聊天窗口插入一条通话记录消息（类似微信）。

**处理流程**：
```
1. 通话结束 → 后端保存通话记录到 im_call_record 表
2. 后端生成 CALL_RECORD 消息（MessageType = 209；207/208 已被 WORKFLOW_NOTIFY/TODO_REMINDER 占用）
3. 后端向双方推送 CALL_RECORD 消息
4. 客户端收到后：
   - 插入到聊天记录流
   - 渲染为通话记录气泡
   - 展示通话类型、时长、状态
```

**消息展示规则**：
- 已接通：`📞 通话时长 03:25`（绿色）
- 未接听：`📞 未接听`（灰色）
- 已拒绝：`📞 已拒绝`（灰色）
- 忙线：`📞 对方忙线中`（灰色）

---

## 4. 系统架构设计

### 4.1 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    客户端层 (Flutter)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ CallController│  │ Janus Client │  │ flutter_     │   │
│  │ (状态管理)    │  │ (信令交互)   │  │ webrtc       │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          │ WebSocket 信令   │ WebRTC 媒体流    │ HTTP API
          │ (SYSTEM_NOTIFY  │ (Janus)         │ (Token/记录)
          │  + call.前缀)   │                 │
          │                 │                 │
┌─────────┴─────────────────┴─────────────────┴───────────┐
│                    服务端层                                │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Janus Gateway 集群                     │ │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐   │ │
│  │  │ videoroom  │  │ textroom   │  │ streaming  │   │ │
│  │  │ (通话)     │  │ (字幕)     │  │ (录制)     │   │ │
│  │  └────────────┘  └────────────┘  └────────────┘   │ │
│  └────────────────────────────────────────────────────┘ │
│                          ▲                               │
│                          │ Janus API (HTTP/WS)           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              圣钰业务服务层                           │ │
│  │  ┌──────────────┐  ┌──────────────┐                │ │
│  │  │ CallService  │  │ TokenService │                │ │
│  │  │ (通话业务)   │  │ (JWT 生成)   │                │ │
│  │  └──────────────┘  └──────────────┘                │ │
│  │  ┌──────────────┐  ┌──────────────┐                │ │
│  │  │ CallRecord   │  │ PushService  │                │ │
│  │  │ Service      │  │ (离线推送)   │                │ │
│  │  └──────────────┘  └──────────────┘                │ │
│  └────────────────────────────────────────────────────┘ │
│                          ▲                               │
│                          │                               │
│  ┌────────────────────────────────────────────────────┐ │
│  │              WebSocket 中间件 (Netty)                │ │
│  │  ┌──────────────────────────────────────────────┐  │ │
│  │  │ SystemNotifyProcessor (SYSTEM_NOTIFY = 200)  │  │ │
│  │  │  → 通过 action=call.* 前缀分发通话信令        │  │ │
│  │  │ - 呼叫发起 / 接听 / 拒绝 / 挂断              │  │ │
│  │  │ - 多设备广播                                 │  │ │
│  │  │ - 媒体控制（静音/摄像头切换）                 │  │ │
│  │  └──────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 4.2 核心组件职责

| 组件 | 职责 | 技术选型 | 源码位置 |
|-----|------|---------|---------|
| **Janus Gateway** | 媒体流转发、房间管理、录制 | C, 独立部署 | - |
| **CallController** | 通话状态管理、信令处理 | Flutter/Riverpod | `call_controller.dart` |
| **CallRepository** | 通话数据访问、信令发送 | Flutter | `call_repository.dart` |
| **CallMediaController** | 媒体流控制（静音/摄像头/扬声器） | Flutter | `call_media_controller.dart` |
| **CallSignalProcessor** | 通话信令处理 | Java/Netty | `CallSignalProcessor.java` |
| **CallService** | 通话业务逻辑、状态管理 | Spring Boot | `CallService.java` |
| **TokenService** | 生成 Janus Token | Spring Boot | `TokenService.java` |
| **CallRecordService** | 通话记录存储与查询 | Spring Boot | `CallRecordService.java` |

### 4.3 通话流程时序图

#### 4.3.1 1v1 语音通话

```
主叫方(A)              WebSocket              被叫方(B)              Janus
   │                      │                      │                      │
   │ CALL_INITIATE        │                      │                      │
   │ (callType=1)         │                      │                      │
   │─────────────────────>│                      │                      │
   │                      │                      │                      │
   │                      │ CALL_INITIATE        │                      │
   │                      │ (广播给 B 的所有设备) │                      │
   │                      │─────────────────────>│                      │
   │                      │                      │                      │
   │                      │ CALL_RINGING         │                      │
   │                      │<─────────────────────│                      │
   │ CALL_RINGING         │                      │                      │
   │<─────────────────────│                      │                      │
   │                      │                      │                      │
   │                      │ CALL_ACCEPTED        │                      │
   │                      │<─────────────────────│                      │
   │ CALL_ACCEPTED        │                      │                      │
   │<─────────────────────│                      │                      │
   │                      │                      │                      │
   │ [HTTP] 获取 Janus Token                      │                      │
   │───────────────────────────────────────────────────────────────────>│
   │                      │                      │                      │
   │ [Janus] Join Room    │                      │                      │
   │───────────────────────────────────────────────────────────────────>│
   │                      │                      │ [HTTP] 获取 Token    │
   │                      │                      │─────────────────────>│
   │                      │                      │ [Janus] Join Room    │
   │                      │                      │─────────────────────>│
   │                      │                      │                      │
   │ <═══════════════ WebRTC 媒体流建立 ═══════════════════════════════> │
   │                      │                      │                      │
   │ CALL_HANGUP          │                      │                      │
   │─────────────────────>│                      │                      │
   │                      │ CALL_HANGUP          │                      │
   │                      │─────────────────────>│                      │
   │                      │                      │                      │
   │                      │ CALL_RECORD (209)    │                      │
   │                      │─────────────────────>│                      │
   │ CALL_RECORD (209)    │                      │                      │
   │<─────────────────────│                      │                      │
```

#### 4.3.2 群组视频会议

```
发起人(A)           WebSocket            参与者(B,C,D)        Janus
   │                   │                      │                  │
   │ CALL_INITIATE     │                      │                  │
   │ (callType=2)      │                      │                  │
   │ inviteeIds=[B,C,D]│                      │                  │
   │──────────────────>│                      │                  │
   │                   │                      │                  │
   │                   │ CALL_INITIATE        │                  │
   │                   │─────────────────────>│                  │
   │                   │                      │                  │
   │ CALL_ACCEPTED     │                      │                  │
   │──────────────────>│                      │                  │
   │                   │                      │                  │
   │ [HTTP] Token      │                      │                  │
   │─────────────────────────────────────────────────────────────>│
   │                   │                      │                  │
   │ Join Room         │                      │                  │
   │─────────────────────────────────────────────────────────────>│
   │                   │                      │                  │
   │                   │ CALL_JOIN            │                  │
   │                   │<─────────────────────│                  │
   │ CALL_JOIN         │                      │                  │
   │<──────────────────│                      │                  │
   │                   │                      │                  │
   │                   │                      │ Join Room        │
   │                   │                      │─────────────────>│
   │                   │                      │                  │
   │ <═══════════════ 多方媒体流 ═══════════════════════════════> │
```

---

## 5. 协议设计

### 5.1 扩展 CallSignalMessage Proto

**现有 Proto 定义**（基于源码验证）：
```protobuf
// shengyu-spring-boot-starter-websocket/src/main/proto/im_message.proto
message CallSignalMessage {
  string callId = 1;
  int32 callType = 2;      // 1-语音 2-视频
  int32 signalType = 3;    // 1-呼叫 2-接听 3-拒绝 4-挂断 5-忙线 6-切换摄像头
  int64 callerId = 4;
  int64 calleeId = 5;
  string rejectReason = 6;
  string extraData = 7;    // JSON 扩展字段
}
```

**扩展设计**（保持向后兼容）：
```protobuf
// 扩展版 CallSignalMessage（新增字段从 8 开始）
message CallSignalMessage {
  string callId = 1;
  int32 callType = 2;
  int32 signalType = 3;
  int64 callerId = 4;
  int64 calleeId = 5;
  string rejectReason = 6;
  string extraData = 7;
  
  // ===== 新增字段 =====
  
  // 群组 ID（群通话时使用）
  int64 groupId = 8;
  
  // 被邀请人列表（群通话时使用）
  repeated int64 inviteeIds = 9;
  
  // Janus Room ID（通话建立后生成）
  string roomId = 10;
  
  // Janus Token（客户端加入房间用）
  string janusToken = 11;
  
  // 通话发起时间戳（毫秒）
  int64 initiateTime = 12;
  
  // 设备 ID（用于多设备区分）
  string deviceId = 13;
  
  // 设备名称（用于多设备显示）
  string deviceName = 14;
}

// 信令类型枚举（扩展）
enum CallSignalType {
  SIGNAL_UNKNOWN = 0;
  
  // 呼叫阶段
  SIGNAL_CALL_INITIATE = 1;    // 发起呼叫
  SIGNAL_CALL_RINGING = 2;     // 正在响铃
  SIGNAL_CALL_ACCEPTED = 3;    // 接听
  SIGNAL_CALL_REJECTED = 4;    // 拒绝
  SIGNAL_CALL_BUSY = 5;        // 忙线
  SIGNAL_CALL_NO_ANSWER = 6;   // 无应答
  SIGNAL_CALL_CANCEL = 7;      // 取消呼叫
  
  // 通话中控制
  SIGNAL_CALL_HANGUP = 10;     // 挂断
  SIGNAL_CALL_MUTE = 11;       // 静音
  SIGNAL_CALL_UNMUTE = 12;     // 取消静音
  SIGNAL_CALL_VIDEO_ON = 13;   // 开启视频
  SIGNAL_CALL_VIDEO_OFF = 14;  // 关闭视频
  SIGNAL_CALL_SWITCH_CAMERA = 15; // 切换摄像头
  
  // 群组通话特有
  SIGNAL_CALL_JOIN = 20;       // 加入通话
  SIGNAL_CALL_LEAVE = 21;      // 离开通话
  SIGNAL_CALL_INVITE = 22;     // 邀请他人
  SIGNAL_CALL_KICK = 23;       // 踢出通话
  
  // 通话状态同步
  SIGNAL_CALL_STATE_SYNC = 30; // 状态同步（多设备）
  SIGNAL_CALL_DEVICE_TERMINATED = 31; // 设备被踢出
}
```

### 5.2 新增通话记录消息类型

**修正说明**：根据 `im_message.proto` 实际定义，207 已被 `WORKFLOW_NOTIFY` 占用，208 已被 `TODO_REMINDER` 占用，因此通话记录使用 **209**。

```protobuf
// MessageType 枚举扩展（基于实际源码验证）
enum MessageType {
  // ... 现有类型
  CALL_SIGNAL = 206;       // 通话信令
  WORKFLOW_NOTIFY = 207;   // 流程通知（已占用）
  TODO_REMINDER = 208;     // 待办提醒（已占用）
  CALL_RECORD = 209;       // ← 新增：通话记录消息
}

// 通话记录消息体
message CallRecordMessage {
  // 通话 ID
  string callId = 1;
  
  // 通话类型（1-语音 2-视频）
  int32 callType = 2;
  
  // 通话状态（1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消）
  int32 status = 3;
  
  // 通话时长（秒）
  int32 duration = 4;
  
  // 主叫方 ID
  int64 callerId = 5;
  
  // 被叫方 ID
  int64 calleeId = 6;
  
  // 主叫方昵称
  string callerName = 7;
  
  // 主叫方头像
  string callerAvatar = 8;
  
  // 被叫方昵称
  string calleeName = 9;
  
  // 被叫方头像
  string calleeAvatar = 10;
  
  // 通话发起时间戳
  int64 initiateTime = 11;
  
  // 群组 ID（群通话时使用）
  int64 groupId = 12;
}
```

### 5.3 Flutter 端事件类型扩展

```dart
// socket_event_types.dart（扩展）
abstract final class SocketEventTypes {
  // ... 现有类型
  
  /// 通话信令接收事件
  static const callSignalReceived = 'callSignalReceived';
  
  /// 通话记录接收事件
  static const callRecordReceived = 'callRecordReceived';
}

// socket_message_type.dart（扩展）
abstract final class SocketMessageType {
  // ... 现有类型
  static const callSignal = 206;
  // 注：通话记录通过 SYSTEM_NOTIFY (200) + action=call.record 传输
  // 无需新增独立 MessageType，与通话信令复用同一通道
}
```

---

## 6. 后端实现方案

### 6.1 Janus Gateway 部署

#### 6.1.1 Docker Compose 部署

```yaml
# docker-compose.janus.yml
version: '3.8'

services:
  janus:
    image: canyan/janus-gateway:latest
    container_name: janus-server
    ports:
      - "8088:8088"   # HTTP API
      - "8188:8188"   # WebSocket API
      - "10000-10200:10000-10200/udp"  # RTP 端口范围
    environment:
      - JANUS_API_SECRET=${JANUS_API_SECRET}
      - JANUS_ADMIN_SECRET=${JANUS_ADMIN_SECRET}
    volumes:
      - ./janus.jcfg:/usr/local/etc/janus/janus.jcfg
      - ./janus.plugin.videoroom.jcfg:/usr/local/etc/janus/janus.plugin.videoroom.jcfg
    restart: unless-stopped

  # coturn (TURN 服务器)
  coturn:
    image: coturn/coturn:latest
    container_name: coturn-server
    ports:
      - "3478:3478/udp"
      - "3478:3478/tcp"
    environment:
      - TURN_SECRET=${TURN_SECRET}
    volumes:
      - ./turnserver.conf:/etc/turnserver.conf
    command: -c /etc/turnserver.conf
    restart: unless-stopped
```

#### 6.1.2 Janus 配置文件

```ini
# janus.jcfg
general:
  configs_folder = "/usr/local/etc/janus"
  plugins_folder = "/usr/local/lib/janus/plugins"
  log_to_stdout = true
  debug_level = 3

media:
  rtp_port_range = "10000-10200"

nat:
  stun_server = "stun.l.google.com"
  stun_port = 19302
  nice_debug = false
  ice_tcp = false
  turn_server = "127.0.0.1"
  turn_port = 3478
  turn_type = "udp"
  turn_user = "turnuser"
  turn_pwd = "${TURN_SECRET}"

plugins:
  enabled = "libjanus_videoroom.so,libjanus_streaming.so"

transports:
  enabled = "libjanus_http.so,libjanus_websockets.so"
```

### 6.2 Spring Boot 集成

#### 6.2.1 添加依赖

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.java-websocket</groupId>
    <artifactId>Java-WebSocket</artifactId>
    <version>1.5.3</version>
</dependency>
```

#### 6.2.2 TokenService 实现

```java
// TokenService.java
@Service
@Slf4j
public class TokenService {
    
    @Value("${janus.api-secret}")
    private String apiSecret;
    
    @Value("${janus.ws-url}")
    private String janusWsUrl;
    
    /**
     * 生成 Janus Token（基于 API Secret）
     * 
     * @param userId 用户 ID
     * @param roomId 房间 ID
     * @return Token 字符串
     */
    public String generateToken(Long userId, String roomId) {
        // Janus 使用 API Secret 进行身份验证
        // Token 格式：{api_secret}_{userId}_{roomId}_{timestamp}
        long timestamp = System.currentTimeMillis();
        return String.format("%s_%d_%s_%d", apiSecret, userId, roomId, timestamp);
    }
    
    /**
     * 生成房间 ID（全局唯一）
     */
    public String generateRoomId() {
        // 格式：room_{timestamp}_{random}
        return String.format("room_%d_%s", 
            System.currentTimeMillis(),
            UUID.randomUUID().toString().substring(0, 8));
    }
}
```

#### 6.2.3 CallSignalProcessor 实现

**实际实现说明**：通话信令通过 `SYSTEM_NOTIFY` (200) 消息类型传输，使用 `action=call.*` 前缀区分不同信令。后端通过 `NettyMessageSender.sendToUser()` 方法向指定用户的所有设备广播信令。

**消息处理链路**（基于源码验证）：
```
WebSocket 收到消息
  → JsonWebSocketMessageHandler.handleTextMessage()
    → 解析 JsonWebSocketMessage（type + content）
    → 根据 type 查找对应的 WebSocketMessageListener
    → 调用 listener.onMessage(session, messageObj)
      → SystemNotifyProcessor（处理 SYSTEM_NOTIFY 类型）
        → 根据 action 字段分发（action=call.* → CallService）
```

```java
// CallSignalProcessor.java（实际实现）
@Component
@Slf4j
public class CallSignalProcessor implements WebSocketMessageListener<CallSignalMessage> {
    
    @Autowired
    private CallService callService;
    
    @Autowired
    private NettyMessageSender messageSender;
    
    @Override
    public void onMessage(NettySession session, CallSignalMessage signal) {
        try {
            Long userId = session.getUserId();
            Long tenantId = session.getTenantId();
            
            // 根据信令类型分发处理
            switch (signal.getSignalType()) {
                case 1:  // 发起呼叫
                    handleCallInitiate(userId, tenantId, signal);
                    break;
                case 2:  // 接听
                    handleCallAccept(userId, signal);
                    break;
                case 3:  // 拒绝
                    handleCallReject(userId, signal);
                    break;
                case 4:  // 挂断
                    handleCallHangup(userId, signal);
                    break;
                case 5:  // 忙线
                    handleCallBusy(userId, signal);
                    break;
                case 6:  // 切换摄像头
                    handleMediaControl(userId, signal);
                    break;
                default:
                    log.warn("[CallProcessor] 未知信令类型：{}", signal.getSignalType());
            }
        } catch (Exception e) {
            log.error("[CallProcessor] 处理通话信令失败", e);
        }
    }
    
    @Override
    public String getType() {
        return "call_signal";  // 对应 JsonWebSocketMessage.type
    }
    
    /**
     * 处理发起呼叫
     */
    private void handleCallInitiate(Long userId, CallSignalMessage signal) {
        // 1. 创建通话会话
        // 2. 生成 Janus Room ID
        // 3. 构建 SYSTEM_NOTIFY 消息（action=call.invite）
        // 4. 向被叫方所有设备广播
        callService.initiateCall(userId, signal);
    }
    
    /**
     * 处理接听
     */
    private void handleCallAccept(Long userId, CallSignalMessage signal) {
        // 1. 生成 Janus Token
        // 2. 构建 SYSTEM_NOTIFY 消息（action=call.accepted，携带 token）
        // 3. 向主叫方广播
        callService.acceptCall(userId, signal.getCallId());
    }
    
    /**
     * 处理挂断
     */
    private void handleCallHangup(Long userId, CallSignalMessage signal) {
        // 1. 计算通话时长
        // 2. 更新通话记录
        // 3. 构建 SYSTEM_NOTIFY 消息（action=call.ended）
        // 4. 向对方广播
        // 5. 生成通话记录消息（action=call.record）
        callService.hangupCall(userId, signal.getCallId());
    }
    
    /**
     * 处理媒体控制（静音、摄像头切换等）
     */
    private void handleMediaControl(Long userId, CallSignalMessage signal) {
        // 媒体控制信令直接广播给其他参与者
        callService.broadcastMediaControl(userId, signal);
    }
    
    @Override
    public MessageType getType() {
        return MessageType.SYSTEM_NOTIFY;
    }
}
```

#### 6.2.4 CallService 实现

**实际实现说明**：通话信令通过 `SYSTEM_NOTIFY` 消息类型传输，使用 `action=call.*` 前缀区分不同信令。后端通过 `WebSocketMessageSender.sendToUser()` 方法向指定用户的所有设备广播信令。

```java
// CallService.java
@Service
@Slf4j
public class CallService {
    
    @Autowired
    private TokenService tokenService;
    
    @Autowired
    private WebSocketMessageSender messageSender;
    
    @Autowired
    private CallRecordService callRecordService;
    
    // 通话状态缓存 (callId -> CallSession)
    private final Map<String, CallSession> callSessions = new ConcurrentHashMap<>();
    
    /**
     * 发起通话
     */
    public void initiateCall(Long callerId, CallSignalMessage signal) {
        String callId = signal.getCallId();
        String roomId = tokenService.generateRoomId();
        
        // 创建通话会话
        CallSession session = CallSession.builder()
            .callId(callId)
            .roomId(roomId)
            .callType(signal.getCallType())
            .callerId(callerId)
            .calleeId(signal.getCalleeId())
            .groupId(signal.getGroupId())
            .inviteeIds(signal.getInviteeIdsList())
            .status(CallStatus.RINGING)
            .initiateTime(System.currentTimeMillis())
            .build();
        
        callSessions.put(callId, session);
        
        // 构建 SYSTEM_NOTIFY 消息（action=call.invite）
        Map<String, Object> payload = new HashMap<>();
        payload.put("action", "call.invite");
        payload.put("callId", callId);
        payload.put("callType", signal.getCallType());
        payload.put("callerId", callerId);
        payload.put("calleeId", signal.getCalleeId());
        payload.put("groupId", signal.getGroupId());
        payload.put("roomId", roomId);
        payload.put("initiateTime", session.getInitiateTime());
        payload.put("inviteeIds", signal.getInviteeIdsList());
        
        // 发送给被叫方（所有在线设备）
        if (signal.getCallType() == 2) {  // 群通话
            for (Long inviteeId : signal.getInviteeIdsList()) {
                sendSystemNotify(inviteeId, payload);
            }
        } else {
            sendSystemNotify(signal.getCalleeId(), payload);
        }
        
        log.info("[CallService] 发起通话：callId={}, caller={}, callee={}", 
            callId, callerId, signal.getCalleeId());
    }
    
    /**
     * 接听通话
     */
    public void acceptCall(Long userId, String callId) {
        CallSession session = callSessions.get(callId);
        if (session == null) {
            throw new BusinessException("通话不存在");
        }
        
        // 生成 Janus Token
        String token = tokenService.generateToken(userId, session.getRoomId());
        
        // 更新会话状态
        session.setStatus(CallStatus.CONNECTED);
        session.setConnectTime(System.currentTimeMillis());
        
        // 构建 SYSTEM_NOTIFY 消息（action=call.accepted）
        Map<String, Object> payload = new HashMap<>();
        payload.put("action", "call.accepted");
        payload.put("callId", callId);
        payload.put("calleeId", userId);
        payload.put("janusToken", token);
        payload.put("roomId", session.getRoomId());
        
        // 通知所有参与者
        broadcastToParticipants(session, payload);
        
        log.info("[CallService] 接听通话：callId={}, userId={}", callId, userId);
    }
    
    /**
     * 挂断通话
     */
    public void hangupCall(Long userId, String callId) {
        CallSession session = callSessions.get(callId);
        if (session == null) return;
        
        // 构建 SYSTEM_NOTIFY 消息（action=call.ended）
        Map<String, Object> payload = new HashMap<>();
        payload.put("action", "call.ended");
        payload.put("callId", callId);
        payload.put("endedBy", userId);
        
        broadcastToParticipants(session, payload);
        
        // 记录通话时长
        long duration = System.currentTimeMillis() - session.getConnectTime();
        callRecordService.saveCallRecord(session, duration);
        
        // 生成通话记录消息（action=call.record）
        generateCallRecordMessage(session, duration);
        
        // 清理会话
        callSessions.remove(callId);
        
        log.info("[CallService] 挂断通话：callId={}, userId={}, duration={}ms", 
            callId, userId, duration);
    }
    
    /**
     * 生成通话记录消息
     */
    private void generateCallRecordMessage(CallSession session, long duration) {
        // 构建 SYSTEM_NOTIFY 消息（action=call.record）
        Map<String, Object> payload = new HashMap<>();
        payload.put("action", "call.record");
        payload.put("callId", session.getCallId());
        payload.put("callType", session.getCallType());
        payload.put("status", session.getStatus().getCode());
        payload.put("duration", (int) (duration / 1000));
        payload.put("callerId", session.getCallerId());
        payload.put("calleeId", session.getCalleeId());
        payload.put("groupId", session.getGroupId());
        payload.put("initiateTime", session.getInitiateTime());
        
        // 推送给双方
        sendSystemNotify(session.getCallerId(), payload);
        if (session.getCalleeId() != null) {
            sendSystemNotify(session.getCalleeId(), payload);
        }
    }
    
    /**
     * 发送 SYSTEM_NOTIFY 消息给指定用户（所有设备）
     * 
     * 实际实现说明：
     * 1. 使用 NettyMessageSender.sendToUser() 方法
     * 2. 需要传入 MessageType、MessageLite（Proto 消息）、senderId、tenantId 等参数
     * 3. 实际调用时需要构建 CallSignalMessage 或其他 Proto 消息体
     */
    private void sendSystemNotify(Long userId, Long tenantId, Map<String, Object> payload) {
        // 构建 CallSignalMessage（或其他 Proto 消息）
        CallSignalMessage signal = CallSignalMessage.newBuilder()
            .setCallId(payload.get("callId").toString())
            .setCallType((Integer) payload.get("callType"))
            .setSignalType(getSignalTypeFromAction(payload.get("action").toString()))
            .setCallerId((Long) payload.get("callerId"))
            .setCalleeId((Long) payload.get("calleeId"))
            .setExtraData(JSON.toJSONString(payload))
            .build();
        
        // 使用 NettyMessageSender 发送
        messageSender.sendToUser(
            userId,
            MessageType.SYSTEM_NOTIFY,
            signal,
            null,  // senderId
            userId,  // receiverId
            null,  // groupId
            tenantId,
            null   // messageId
        );
    }
    
    /**
     * 从 action 字段提取信令类型
     */
    private int getSignalTypeFromAction(String action) {
        switch (action) {
            case "call.invite": return 1;
            case "call.accepted": return 2;
            case "call.rejected": return 3;
            case "call.ended": return 4;
            case "call.busy": return 5;
            default: return 0;
        }
    }
    
    /**
     * 广播给所有参与者
     */
    private void broadcastToParticipants(CallSession session, Map<String, Object> payload) {
        Set<Long> participants = new HashSet<>();
        participants.add(session.getCallerId());
        if (session.getCalleeId() != null) {
            participants.add(session.getCalleeId());
        }
        participants.addAll(session.getInviteeIds());
        
        for (Long userId : participants) {
            sendSystemNotify(userId, payload);
        }
    }
}
```

---

## 7. Flutter 客户端实现

### 7.1 添加依赖

```yaml
# pubspec.yaml
dependencies:
  # WebRTC 核心（已存在）
  flutter_webrtc: ^1.4.0
  
  # 权限管理（已存在）
  permission_handler: ^11.3.1
  
  # 音频会话（iOS 后台播放）
  audio_session: ^0.1.18
  
  # 震动反馈
  vibration: ^2.0.0
  
  # Janus Client（需自行实现或引入第三方库）
  # 注：项目可能已实现 Janus 客户端，需检查源码
```

### 7.2 CallController 增强

**现有实现**（基于源码验证）：
```dart
// call_controller.dart（已实现）
class CallController extends StateNotifier<CallState> {
  // 已实现的方法：
  Future<void> initialize(CallLaunchArgs args) async { ... }
  Future<void> startOutgoing() async { ... }
  Future<void> accept() async { ... }
  Future<void> reject() async { ... }
  Future<void> cancel() async { ... }
  Future<void> hangup() async { ... }
  void toggleMute() { ... }
  void toggleSpeaker() { ... }
  void toggleCamera() { ... }
  void switchCamera() { ... }
  
  // Socket 事件处理（已实现）
  Future<void> _onSocketEvent(CallSocketEvent event) async {
    switch (event.type) {
      case CallSocketEventType.invite:
        onInviteReceived(event);
        break;
      case CallSocketEventType.accepted:
        await onAccepted();
        break;
      case CallSocketEventType.rejected:
        await onRejected();
        break;
      case CallSocketEventType.busy:
        await onBusy();
        break;
      case CallSocketEventType.cancelled:
        await onCancelled();
        break;
      case CallSocketEventType.ended:
        await onEnded();
        break;
      case CallSocketEventType.timeout:
        await onTimeout();
        break;
      case CallSocketEventType.deviceTerminated:
        await onDeviceTerminated();
        break;
      case CallSocketEventType.mediaTokenIssued:
        await onMediaTokenIssued(event);
        break;
    }
  }
}
```

**需要增强的功能**：
```dart
// call_controller.dart（增强）
class CallController extends StateNotifier<CallState> {
  
  /// 处理通话记录消息
  void onCallRecordReceived(CallRecordMessage record) {
    // 1. 保存到本地数据库
    // 2. 插入到聊天记录流
    // 3. 触发 UI 更新
  }
  
  /// 网络质量监控
  void _monitorNetworkQuality() {
    // 定期获取 RTCPeerConnection stats
    // 计算丢包率、延迟、抖动
    // 根据网络质量调整视频码率
  }
  
  /// 屏幕共享（Web 端）
  Future<void> startScreenShare() async {
    // Web: getDisplayMedia()
    // Android: MediaProjection API
    // iOS: ReplayKit（需系统版本支持）
  }
}
```

### 7.3 SocketInboundMapper 扩展

**实际实现说明**：通话信令和通话记录均通过 `SYSTEM_NOTIFY` (200) 消息类型传输。现有 `_mapSystemNotify()` 方法已将所有 `SYSTEM_NOTIFY` 消息统一映射为 `SocketEventTypes.systemNotify` 事件，再由 `CallSocketDataSource` 根据 `action` 字段的 `call.` 前缀进行二次分发。

因此 **SocketInboundMapper 无需新增 case 分支**，通话信令和通话记录的分发完全在 `CallSocketDataSource` 层完成。

**CallSocketDataSource 扩展**（增加对 `call.record` 的支持）：

**现有实现**（基于源码验证 `call_socket_data_source.dart`）：
```dart
// call_socket_data_source.dart（当前实现）
CallSignalEventDto? _toCallSignalEvent(Map<String, Object?> payload) {
  final eventType =
      payload['type']?.toString() ??
      payload['eventType']?.toString() ??
      payload['event']?.toString() ??
      '';
  if (!eventType.startsWith('call.')) {
    return null;
  }

  final callSessionId =
      payload['callSessionId']?.toString() ??
      payload['sessionId']?.toString() ??
      '';
  if (callSessionId.isEmpty) {
    return null;
  }

  final nestedPayload = payload['payload'];
  final mergedPayload = <String, Object?>{
    ...payload,
    if (nestedPayload is Map<String, dynamic>) ...nestedPayload,
    if (nestedPayload is Map<Object?, Object?>)
      ...nestedPayload.cast<String, Object?>(),
  };

  return CallSignalEventDto(
    type: eventType,
    callSessionId: callSessionId,
    payload: mergedPayload,
  );
}
```

**需要扩展**（增加对后端 `action` 和 `callId` 字段的兼容）：
```dart
// call_socket_data_source.dart（扩展后）
CallSignalEventDto? _toCallSignalEvent(Map<String, Object?> payload) {
  final eventType =
      payload['type']?.toString() ??
      payload['action']?.toString() ??     // ← 新增：兼容后端 action 字段
      payload['eventType']?.toString() ??
      payload['event']?.toString() ??
      '';
  if (!eventType.startsWith('call.')) {
    return null;
  }

  final callSessionId =
      payload['callSessionId']?.toString() ??
      payload['callId']?.toString() ??      // ← 新增：兼容后端 callId 字段
      payload['sessionId']?.toString() ??
      '';
  if (callSessionId.isEmpty) {
    return null;
  }

  final nestedPayload = payload['payload'];
  final mergedPayload = <String, Object?>{
    ...payload,
    if (nestedPayload is Map<String, dynamic>) ...nestedPayload,
    if (nestedPayload is Map<Object?, Object?>)
      ...nestedPayload.cast<String, Object?>(),
  };

  return CallSignalEventDto(
    type: eventType,
    callSessionId: callSessionId,
    payload: mergedPayload,
  );
}
```

**信令分发链路**：

```
WebSocket 收到消息
  → SocketInboundMapper.map()
    → messageType == 200 (SYSTEM_NOTIFY)
      → _mapSystemNotify() → ImSocketEvent(type: systemNotify, payload: {...})
        → CallSocketDataSource._onSocketEvent()
          → _toCallSignalEvent() 检查 action/call.* 前缀
            → CallSignalEventDto → CallController 处理
```

### 7.4 通话 UI 页面

#### 7.4.1 来电页面（已有，需增强）

**现有实现**（基于源码验证）：
```dart
// incoming_call_page.dart（已实现）
class IncomingCallPage extends ConsumerStatefulWidget {
  final CallLaunchArgs args;
  
  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  @override
  void initState() {
    super.initState();
    // 播放铃声
    _playRingtone();
    // 震动
    _vibrate();
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeCallStateProvider);
    final title = state.title ?? widget.args.title ?? '语音通话';
    
    return Scaffold(
      backgroundColor: const Color(0xFF101521),
      body: SafeArea(
        child: Column(
          children: [
            // 头像 + 昵称
            AppAvatar(
              name: title,
              avatarUrl: state.callerProfile?.avatarUrl,
              size: 96,
              borderRadius: 32,
            ),
            Text(title, style: TextStyle(color: Colors.white)),
            
            // 操作按钮
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(callControllerProvider.notifier).reject();
                    context.pop();
                  },
                  child: Text('拒绝'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref.read(callControllerProvider.notifier).accept();
                  },
                  child: Text('接听'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**需要增强的功能**：
```dart
// incoming_call_page.dart（增强）
class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  
  /// 显示多设备信息
  Widget _buildDeviceIndicator() {
    return Text(
      '正在呼叫您的所有设备',
      style: TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
  
  /// 显示网络质量指示器
  Widget _buildNetworkQualityIndicator() {
    // 根据网络质量显示不同图标
    return Icon(Icons.signal_cellular_4_bar, color: Colors.green);
  }
}
```

#### 7.4.2 通话中页面

**现有实现**（基于源码验证）：
```dart
// call_session_page.dart（已实现）
class CallSessionPage extends ConsumerStatefulWidget {
  final CallLaunchArgs args;
  
  @override
  ConsumerState<CallSessionPage> createState() => _CallSessionPageState();
}

class _CallSessionPageState extends ConsumerState<CallSessionPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callControllerProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFF101521),
      body: Stack(
        children: [
          // 远端视频（视频通话时显示）
          if (state.callType == CallType.video && state.mediaState.remoteVideoTrack != null)
            Positioned.fill(
              child: RTCVideoView(state.mediaState.remoteVideoTrack!),
            ),
          
          // 本地视频预览（小窗）
          if (state.callType == CallType.video && state.mediaState.localVideoTrack != null)
            Positioned(
              right: 16,
              top: 16,
              width: 120,
              height: 160,
              child: RTCVideoView(state.mediaState.localVideoTrack!),
            ),
          
          // 控制层
          SafeArea(
            child: Column(
              children: [
                // 顶部信息栏（通话时长）
                Text(_formatDuration(Duration(seconds: state.elapsedSeconds))),
                
                // 底部控制栏
                Row(
                  children: [
                    // 静音
                    IconButton(
                      icon: Icon(state.mediaState.isMuted ? Icons.mic_off : Icons.mic),
                      onPressed: () => ref.read(callControllerProvider.notifier).toggleMute(),
                    ),
                    
                    // 切换摄像头（仅视频通话）
                    if (state.callType == CallType.video)
                      IconButton(
                        icon: Icon(Icons.cameraswitch),
                        onPressed: () => ref.read(callControllerProvider.notifier).switchCamera(),
                      ),
                    
                    // 挂断
                    IconButton(
                      icon: Icon(Icons.call_end, color: Colors.red),
                      onPressed: () => ref.read(callControllerProvider.notifier).hangup(),
                    ),
                    
                    // 扬声器
                    IconButton(
                      icon: Icon(state.mediaState.isSpeakerOn ? Icons.volume_up : Icons.volume_down),
                      onPressed: () => ref.read(callControllerProvider.notifier).toggleSpeaker(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**需要增强的功能**：
```dart
// call_session_page.dart（增强）
class _CallSessionPageState extends ConsumerState<CallSessionPage> {
  
  /// 显示网络质量指示器
  Widget _buildNetworkQualityIndicator() {
    // 根据 RTCPeerConnection stats 显示网络质量
    return Icon(Icons.signal_cellular_4_bar, color: Colors.green);
  }
  
  /// 显示加密标识
  Widget _buildEncryptionIndicator() {
    return Row(
      children: [
        Icon(Icons.lock, size: 16, color: Colors.white54),
        SizedBox(width: 4),
        Text('端到端加密', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
  
  /// 屏幕共享按钮（Web 端）
  Widget _buildScreenShareButton() {
    if (!kIsWeb) return SizedBox.shrink();
    
    return IconButton(
      icon: Icon(Icons.screen_share),
      onPressed: () => ref.read(callControllerProvider.notifier).startScreenShare(),
    );
  }
}
```

---

## 8. 通话记录与消息气泡

### 8.1 通话记录消息气泡设计

#### 8.1.1 设计说明

参考微信通话记录展示方式，在聊天窗口以系统消息形式展示通话记录：

- **展示位置**：聊天窗口中，按时间顺序插入
- **展示样式**：居中显示，带通话图标和状态文本
- **展示内容**：
  - 已接通：`📞 通话时长 03:25`（绿色）
  - 未接听：`📞 未接听`（灰色）
  - 已拒绝：`📞 已拒绝`（灰色）
  - 忙线：`📞 对方忙线中`（灰色）
  - 已取消：`📞 已取消`（灰色）

#### 8.1.2 设计要点

- 通话记录消息**不可点击、不可复制**，纯记录展示
- 通话记录消息**不参与消息搜索**（搜索时单独过滤）
- 通话记录消息**跟随聊天记录存储**，删除聊天窗口时一并删除
- 通话记录消息**不推送、不同步**到对端（各端独立记录）

#### 8.1.3 Flutter 端消息气泡实现

新增 `CallRecordMessageBubble` 组件，放置在 `features/im/chat/presentation/widgets/` 目录：

```dart
// call_record_message_bubble.dart
class CallRecordMessageBubble extends StatelessWidget {
  final CallRecordMessage message;

  const CallRecordMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_callIcon, size: 14, color: _iconColor),
            const SizedBox(width: 4),
            Text(
              _buildDisplayText(),
              style: TextStyle(
                fontSize: 12,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展示文本
  String _buildDisplayText() {
    final isOutgoing = message.callerId == currentUserId;
    
    switch (message.status) {
      case CallStatus.completed:
        // 已接通：显示通话时长
        final duration = _formatDuration(message.duration);
        return isOutgoing ? '通话时长 $duration' : '通话时长 $duration';
      case CallStatus.missed:
        // 未接听
        return isOutgoing ? '未接听' : '未接听';
      case CallStatus.rejected:
        // 已拒绝
        return isOutgoing ? '已取消' : '对方已拒绝';
      case CallStatus.busy:
        // 忙线
        return '对方忙线中';
      case CallStatus.cancelled:
        // 已取消
        return '已取消';
      default:
        return '通话结束';
    }
  }

  /// 通话图标
  IconData get _callIcon {
    return message.callType == CallType.video
        ? Icons.videocam_outlined
        : Icons.call_outlined;
  }

  /// 背景色（已接通绿色系，未接通灰色系）
  Color get _backgroundColor {
    if (message.status == CallStatus.completed) {
      return const Color(0xFFE8F5E9); // 浅绿
    }
    return const Color(0xFFF5F5F5); // 浅灰
  }

  /// 图标颜色
  Color get _iconColor {
    if (message.status == CallStatus.completed) {
      return const Color(0xFF4CAF50); // 绿色
    }
    return const Color(0xFF9E9E9E); // 灰色
  }

  /// 文本颜色
  Color get _textColor {
    if (message.status == CallStatus.completed) {
      return const Color(0xFF2E7D32);
    }
    return const Color(0xFF757575);
  }

  /// 格式化通话时长
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}小时${minutes}分${secs}秒';
    } else if (minutes > 0) {
      return '${minutes}分${secs}秒';
    } else {
      return '${secs}秒';
    }
  }
}
```

#### 8.1.4 MessageBubbleFactory 扩展

在 `MessageBubbleFactory.build()` 方法中增加 `callRecord` 类型处理：

```dart
// message_bubble_factory.dart
case MessageType.callRecord:
  return CallRecordMessageBubble(
    message: message as CallRecordMessage,
  );
```

### 8.2 通话记录汇总页面（独立入口）

#### 8.2.1 设计说明

参考微信「通讯录 → 通话」入口，提供独立的通话记录汇总页面：

- **入口位置**：IM 首页右上角菜单 → 「通话记录」
- **展示内容**：按时间倒序展示所有通话记录（不区分聊天对象）
- **点击行为**：点击某条记录 → 跳转到对应聊天窗口
- **筛选功能**：支持按通话类型（语音/视频）、时间范围筛选

#### 8.2.2 Flutter 端页面实现

新增 `CallHistoryPage` 页面，放置在 `features/im/call/presentation/pages/` 目录：

```dart
// call_history_page.dart
class CallHistoryPage extends ConsumerStatefulWidget {
  const CallHistoryPage({super.key});

  @override
  ConsumerState<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends ConsumerState<CallHistoryPage> {
  CallType? _filterType; // null=全部，1=语音，2=视频
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final callRecords = ref.watch(callHistoryProvider(
      filterType: _filterType,
      dateRange: _dateRange,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('通话记录'),
        actions: [
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: callRecords.when(
        data: (records) => records.isEmpty
            ? const Center(child: Text('暂无通话记录'))
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return CallHistoryItem(record: record);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选条件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 通话类型筛选
            DropdownButton<CallType?>(
              value: _filterType,
              hint: const Text('通话类型'),
              items: [
                const DropdownMenuItem(value: null, child: Text('全部')),
                const DropdownMenuItem(
                    value: CallType.voice, child: Text('语音通话')),
                const DropdownMenuItem(
                    value: CallType.video, child: Text('视频通话')),
              ],
              onChanged: (value) {
                setState(() => _filterType = value);
              },
            ),
            // 时间范围筛选
            ListTile(
              title: const Text('时间范围'),
              subtitle: Text(_dateRange != null
                  ? '${_dateRange!.start} - ${_dateRange!.end}'
                  : '全部'),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null) {
                  setState(() => _dateRange = range);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 通话记录列表项
class CallHistoryItem extends StatelessWidget {
  final CallRecordItem record;

  const CallHistoryItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(
        name: record.peerName,
        avatarUrl: record.peerAvatar,
        size: 48,
      ),
      title: Text(record.peerName),
      subtitle: Row(
        children: [
          Icon(
            record.callType == CallType.video
                ? Icons.videocam_outlined
                : Icons.call_outlined,
            size: 14,
            color: _statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            _buildSubtitle(),
            style: TextStyle(color: _statusColor, fontSize: 12),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(record.initiateTime),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (record.status == CallStatus.completed)
            Text(
              _formatDuration(record.duration),
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
        ],
      ),
      onTap: () {
        // 跳转到对应聊天窗口
        context.push('/im/chat/${record.chatId}');
      },
    );
  }

  Color get _statusColor {
    return record.status == CallStatus.completed
        ? Colors.green
        : Colors.grey;
  }

  String _buildSubtitle() {
    final isOutgoing = record.callerId == currentUserId;
    switch (record.status) {
      case CallStatus.completed:
        return isOutgoing ? '已拨出' : '已接听';
      case CallStatus.missed:
        return isOutgoing ? '未接听' : '未接听';
      case CallStatus.rejected:
        return isOutgoing ? '已取消' : '已拒绝';
      case CallStatus.busy:
        return '对方忙线中';
      default:
        return '通话结束';
    }
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays < 1) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays < 2) {
      return '昨天';
    } else {
      return '${time.month}-${time.day}';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}分${secs}秒';
  }
}
```

### 8.3 通话记录搜索功能

#### 8.3.1 设计说明

参考微信「查找聊天记录 → 语音通话/视频通话」功能：

- **入口**：聊天窗口右上角「···」→「查找聊天记录」→ 选择「通话」
- **搜索范围**：当前聊天窗口的所有通话记录
- **展示方式**：按时间倒序展示匹配的通话记录

#### 8.3.2 Flutter 端实现

在聊天窗口搜索功能中增加「通话」类型筛选：

```dart
// chat_search_page.dart
class ChatSearchPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatSearchPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends ConsumerState<ChatSearchPage> {
  String _keyword = '';
  MessageType? _typeFilter; // null=全部，callRecord=仅通话

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    
    // 过滤通话记录
    final callRecords = messages.where((m) {
      if (_typeFilter != null && m.type != MessageType.callRecord) {
        return false;
      }
      if (_keyword.isNotEmpty) {
        // 搜索通话类型、状态等
        final text = _buildSearchText(m);
        return text.contains(_keyword);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // 搜索框
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索通话记录',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _keyword = v),
        ),
        // 类型筛选
        SegmentedButton<MessageType?>(
          segments: const [
            ButtonSegment(value: null, label: Text('全部')),
            ButtonSegment(
                value: MessageType.callRecord, label: Text('通话')),
          ],
          selected: {_typeFilter},
          onSelectionChanged: (v) => setState(() => _typeFilter = v.first),
        ),
        // 结果列表
        Expanded(
          child: ListView.builder(
            itemCount: callRecords.length,
            itemBuilder: (context, index) {
              final record = callRecords[index] as CallRecordMessage;
              return CallRecordSearchItem(record: record);
            },
          ),
        ),
      ],
    );
  }

  String _buildSearchText(Message m) {
    if (m is CallRecordMessage) {
      return '${m.callType} ${m.status} ${m.callerName} ${m.calleeName}';
    }
    return '';
  }
}
```

### 8.4 未接来电提醒设计

#### 8.4.1 设计说明

参考微信「服务通知」未接来电提醒：

- **触发条件**：用户离线时收到来电，且对方未再次拨打
- **提醒方式**：通过系统通知（APNs/FCM）推送「未接来电」
- **点击行为**：点击通知 → 跳转到对应聊天窗口

#### 8.4.2 后端推送实现

```java
// CallPushService.java
@Service
public class CallPushService {
    
    @Autowired
    private PushService pushService;
    
    /**
     * 推送未接来电通知
     */
    public void pushMissedCallNotification(Long calleeId, CallSession session) {
        // 查询主叫方信息
        UserDO caller = userService.getUser(session.getCallerId());
        
        // 构建推送内容
        PushNotification notification = PushNotification.builder()
            .title("未接来电")
            .body(String.format("%s 呼叫过你", caller.getNickname()))
            .type("missed_call")
            .extra(Map.of(
                "chatId", session.getChatId(),
                "callId", session.getCallId(),
                "callType", session.getCallType()
            ))
            .build();
        
        // 推送给被叫方
        pushService.pushToUser(calleeId, notification);
    }
}
```

#### 8.4.3 Flutter 端通知处理

```dart
// call_notification_handler.dart
class CallNotificationHandler {
  
  /// 处理未接来电通知点击
  void onMissedCallNotificationTapped(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String;
    final callId = data['callId'] as String;
    
    // 跳转到聊天窗口
    GoRouter.of(navigatorKey.currentContext!).go('/im/chat/$chatId');
  }
}
```

---

## 9. 数据库设计

### 9.1 与现有 ImCallRecordDO 对齐

**现有 DO 定义**（基于源码验证 `ImCallRecordDO.java`）：
```java
// ImCallRecordDO.java（现有字段）
public class ImCallRecordDO extends BaseDO {
    @TableId
    private Long id;
    private String callId;           // 通话ID(唯一标识)
    private Integer callType;        // 通话类型 1-语音通话 2-视频通话
    private Long callerId;           // 呼叫者ID
    private Long calleeId;           // 被叫者ID
    private LocalDateTime startTime; // 通话开始时间
    private LocalDateTime endTime;   // 通话结束时间
    private Integer duration;        // 通话时长(秒)
    private Integer status;          // 1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消
}
```

### 9.2 补充字段设计

为支持通话记录消息气泡展示和群通话，需补充以下字段：

```java
// ImCallRecordDO.java（新增字段）
public class ImCallRecordDO extends BaseDO {
    // ... 现有字段保持不变 ...

    /** 聊天窗口 ID（单聊/群聊） */
    private String chatId;

    /** 群组 ID（群通话时使用） */
    private Long groupId;

    /** 主叫方昵称（冗余存储，避免查询时联表） */
    private String callerName;

    /** 主叫方头像 URL */
    private String callerAvatar;

    /** 被叫方昵称 */
    private String calleeName;

    /** 被叫方头像 URL */
    private String calleeAvatar;

    /** Janus 房间 ID */
    private String roomId;
}
```

```sql
-- 补充字段 ALTER
ALTER TABLE `im_call_record`
ADD COLUMN `chat_id` varchar(64) DEFAULT NULL COMMENT '聊天窗口 ID（单聊/群聊）' AFTER `callee_id`,
ADD COLUMN `group_id` bigint DEFAULT NULL COMMENT '群组 ID（群通话时使用）' AFTER `chat_id`,
ADD COLUMN `caller_name` varchar(64) DEFAULT NULL COMMENT '主叫方昵称' AFTER `caller_id`,
ADD COLUMN `caller_avatar` varchar(512) DEFAULT NULL COMMENT '主叫方头像 URL' AFTER `caller_name`,
ADD COLUMN `callee_name` varchar(64) DEFAULT NULL COMMENT '被叫方昵称' AFTER `callee_id`,
ADD COLUMN `callee_avatar` varchar(512) DEFAULT NULL COMMENT '被叫方头像 URL' AFTER `callee_name`,
ADD COLUMN `room_id` varchar(128) DEFAULT NULL COMMENT 'Janus 房间 ID' AFTER `callee_avatar`;

-- 索引
ALTER TABLE `im_call_record`
ADD INDEX `idx_chat_id` (`chat_id`),
ADD INDEX `idx_group_id` (`group_id`),
ADD INDEX `idx_room_id` (`room_id`);
```

### 9.3 完整建表语句

```sql
-- 通话记录表（完整版，与 9.2 补充字段对齐）
CREATE TABLE `im_call_record` (
  `id` bigint NOT NULL COMMENT '主键 ID',
  `call_id` varchar(64) NOT NULL COMMENT '通话 ID（全局唯一）',
  `call_type` tinyint NOT NULL COMMENT '通话类型：1-语音 2-视频',
  `caller_id` bigint NOT NULL COMMENT '主叫方用户 ID',
  `caller_name` varchar(64) DEFAULT NULL COMMENT '主叫方昵称',
  `caller_avatar` varchar(512) DEFAULT NULL COMMENT '主叫方头像 URL',
  `callee_id` bigint DEFAULT NULL COMMENT '被叫方用户 ID（1v1 通话）',
  `callee_name` varchar(64) DEFAULT NULL COMMENT '被叫方昵称',
  `callee_avatar` varchar(512) DEFAULT NULL COMMENT '被叫方头像 URL',
  `chat_id` varchar(64) DEFAULT NULL COMMENT '聊天窗口 ID',
  `group_id` bigint DEFAULT NULL COMMENT '群组 ID（群通话）',
  `room_id` varchar(128) DEFAULT NULL COMMENT 'Janus 房间 ID',
  `status` tinyint NOT NULL COMMENT '通话状态：1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消',
  `duration` int DEFAULT 0 COMMENT '通话时长（秒）',
  `start_time` datetime DEFAULT NULL COMMENT '通话开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '通话结束时间',
  `tenant_id` bigint NOT NULL COMMENT '租户 ID',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_call_id` (`call_id`),
  KEY `idx_caller_id` (`caller_id`),
  KEY `idx_callee_id` (`callee_id`),
  KEY `idx_chat_id` (`chat_id`),
  KEY `idx_group_id` (`group_id`),
  KEY `idx_room_id` (`room_id`),
  KEY `idx_start_time` (`start_time`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM 通话记录表';

-- 通话参与者表（多人通话）
CREATE TABLE `im_call_participant` (
  `id` bigint NOT NULL COMMENT '主键 ID',
  `call_id` varchar(64) NOT NULL COMMENT '通话 ID',
  `user_id` bigint NOT NULL COMMENT '参与者用户 ID',
  `role` tinyint NOT NULL COMMENT '角色：1-发起人 2-参与者',
  `join_time` datetime DEFAULT NULL COMMENT '加入时间',
  `leave_time` datetime DEFAULT NULL COMMENT '离开时间',
  `duration` int DEFAULT 0 COMMENT '参与时长（秒）',
  `status` tinyint NOT NULL COMMENT '状态：1-已邀请 2-已接听 3-已拒绝 4-未应答',
  `tenant_id` bigint NOT NULL COMMENT '租户 ID',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_call_id` (`call_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM 通话参与者表';
```

### 9.4 Flutter 本地数据库表

```dart
// call_record_table.dart (Drift)
class CallRecordTable extends Table {
  IntColumn get id => integer()();
  TextColumn get callId => text()();
  IntColumn get callType => integer()();
  IntColumn get callerId => integer()();
  TextColumn get callerName => text().nullable()();
  TextColumn get callerAvatar => text().nullable()();
  IntColumn get calleeId => integer().nullable()();
  TextColumn get calleeName => text().nullable()();
  TextColumn get calleeAvatar => text().nullable()();
  TextColumn get chatId => text().nullable()();
  IntColumn get groupId => integer().nullable()();
  TextColumn get messageId => text().nullable()();
  TextColumn get roomId => text().nullable()();
  IntColumn get status => integer()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  IntColumn get tenantId => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 10. API 接口设计

### 10.1 查询通话记录列表

```
GET /system/im/call/records

请求参数:
- page: 页码（默认 1）
- pageSize: 每页数量（默认 20）
- callType: 通话类型（可选，1-语音 2-视频）
- startTime: 开始时间（可选，格式 yyyy-MM-dd HH:mm:ss）
- endTime: 结束时间（可选）

响应:
{
  "code": 0,
  "data": {
    "list": [
      {
        "callId": "call_123456",
        "callType": 1,
        "callerId": 1001,
        "callerName": "张三",
        "callerAvatar": "https://...",
        "calleeId": 1002,
        "calleeName": "李四",
        "calleeAvatar": "https://...",
        "chatId": "chat_1001_1002",
        "status": 2,
        "duration": 120,
        "startTime": "2026-07-19 10:00:00",
        "endTime": "2026-07-19 10:02:00"
      }
    ],
    "total": 100
  }
}
```

### 10.2 查询聊天窗口通话记录

```
GET /system/im/call/records/by-chat

请求参数:
- chatId: 聊天窗口 ID
- page: 页码
- pageSize: 每页数量

响应:
{
  "code": 0,
  "data": {
    "list": [
      {
        "callId": "call_123456",
        "callType": 1,
        "status": 2,
        "duration": 120,
        "initiateTime": "2026-07-19 10:00:00",
        "callerName": "张三",
        "calleeName": "李四"
      }
    ],
    "total": 10
  }
}
```

### 10.3 获取 Janus Token

```
POST /system/im/call/token

请求体:
{
  "callId": "call_123456",
  "roomId": "room_xxx"
}

响应:
{
  "code": 0,
  "data": {
    "token": "xxx_xxx_xxx_xxx",
    "roomId": "room_xxx",
    "janusWsUrl": "wss://janus.example.com/ws"
  }
}
```

### 10.4 后端 Controller 实现

```java
// AppCallController.java
@RestController
@RequestMapping("/system/im/call")
@Tag(name = "用户 APP - 通话记录")
public class AppCallController {

    @Autowired
    private CallRecordService callRecordService;

    @GetMapping("/records")
    @Operation(summary = "查询通话记录列表")
    public CommonResult<PageResult<CallRecordVO>> getCallRecords(
            @Valid CallRecordPageReqVO pageVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(callRecordService.queryCallRecords(userId, pageVO));
    }

    @GetMapping("/records/by-chat")
    @Operation(summary = "查询聊天窗口通话记录")
    public CommonResult<PageResult<CallRecordVO>> getCallRecordsByChat(
            @RequestParam String chatId,
            @Valid CallRecordPageReqVO pageVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(callRecordService.queryCallRecordsByChat(userId, chatId, pageVO));
    }
    
    @PostMapping("/token")
    @Operation(summary = "获取 Janus Token")
    public CommonResult<CallTokenVO> getJanusToken(
            @RequestBody @Valid CallTokenReqVO reqVO) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        return success(callRecordService.generateJanusToken(userId, reqVO));
    }
}
```

---

## 11. 配置管理与国际化

### 11.1 AppConfig 扩展

**现有配置**（基于源码验证）：
```dart
// app_config.dart（已存在）
abstract final class AppConfig {
  static const String companyName = '圣钰科技';
  static const String appName = '圣钰科技 IM';
  static const String apiBaseUrl = 'http://MacBook-Pro-3.local:48080/app-api';
  static const String socketUrl = 'ws://MacBook-Pro-3.local:9000/ws';
  
  // WebSocket 心跳配置
  static const Duration socketHeartbeatInterval = Duration(seconds: 30);
  static const Duration socketHeartbeatTimeout = Duration(seconds: 90);
  
  // 文件上传配置
  static const int maxImageUploadSize = 20 * 1024 * 1024;
  static const int maxVideoUploadSize = 100 * 1024 * 1024;
  static const int maxFileUploadSize = 100 * 1024 * 1024;
}
```

**新增通话相关配置**（基于源码验证 `app_config.dart` 现有结构）：
```dart
// app_config.dart（扩展）
abstract final class AppConfig {
  // ... 现有配置保持不变 ...
  
  // ===== 通话相关配置 =====
  
  /// Janus WebSocket 地址
  /// TODO: 生产环境替换为 wss://janus.yourdomain.com/ws
  static const String janusWsUrl = 'ws://MacBook-Pro-3.local:8188/ws';
  
  /// Janus HTTP API 地址
  /// TODO: 生产环境替换为 https://janus.yourdomain.com
  static const String janusHttpUrl = 'http://MacBook-Pro-3.local:8088';
  
  /// Janus API Secret（用于生成 Token）
  /// TODO: 生产环境从环境变量或配置文件读取
  static const String janusApiSecret = 'your-janus-api-secret';
  
  /// 通话超时时间（秒）
  static const int callTimeoutSeconds = 30;
  
  /// 通话最长时长（小时）
  static const int callMaxDurationHours = 24;
  
  /// 通话铃声资源路径
  static const String callRingtoneAsset = 'assets/sounds/call_ringtone.mp3';
  
  /// 通话结束铃声资源路径
  static const String callEndSoundAsset = 'assets/sounds/call_end.mp3';
  
  /// 是否启用通话录制
  static const bool callRecordingEnabled = false;
  
  /// 通话录制质量（1-5，5 为最高）
  static const int callRecordingQuality = 3;
  
  /// 通话视频码率配置（bps）
  static const int callVideoMinBitrate = 300 * 1000;   // 300 kbps
  static const int callVideoStartBitrate = 1000 * 1000; // 1 Mbps
  static const int callVideoMaxBitrate = 2000 * 1000;  // 2 Mbps
  
  /// 通话房间人数限制
  static const int callMaxParticipantsOneOnOne = 2;
  static const int callMaxParticipantsGroupCall = 9;
  static const int callMaxParticipantsVideoMeeting = 20;
}
```

### 11.2 国际化设计

#### 11.2.1 现有国际化方案

**基于源码验证**，项目使用 **ARB 格式** 进行国际化，文件位于 `lib/l10n/arb/` 目录：

- `app_zh.arb` — 中文
- `app_en.arb` — 英文
- `app_ja.arb` — 日文
- `app_ko.arb` — 韩文

ARB 文件为 JSON 格式，通过 Flutter 官方 `flutter_localizations` + `intl_utils` 生成类型安全的访问代码。

#### 11.2.2 新增通话相关国际化文本

**中文**（`lib/l10n/arb/app_zh.arb`）：
```json
{
  "@@@CALL": "Section: Call",
  "callIncoming": "来电",
  "callOutgoing": "去电",
  "callVoice": "语音通话",
  "callVideo": "视频通话",
  "callAccept": "接听",
  "callReject": "拒绝",
  "callHangup": "挂断",
  "callCancel": "取消",
  "callBusy": "对方忙线中",
  "callNoAnswer": "未接听",
  "callRejected": "已拒绝",
  "callCancelled": "已取消",
  "callDuration": "通话时长 {duration}",
  "@callDuration": {
    "placeholders": {
      "duration": { "type": "String" }
    }
  },
  "callMissed": "未接来电",
  "callEnded": "通话结束",
  "callConnecting": "连接中...",
  "callReconnecting": "重新连接中...",
  "callNetworkPoor": "网络质量差",
  "callEncryptionEnabled": "端到端加密",
  "callScreenShare": "屏幕共享",
  "callSwitchCamera": "切换摄像头",
  "callMute": "静音",
  "callUnmute": "取消静音",
  "callSpeaker": "扬声器",
  "callEarpiece": "听筒",
  "callCameraOn": "开启视频",
  "callCameraOff": "关闭视频",
  "callHistoryTitle": "通话记录",
  "callHistoryEmpty": "暂无通话记录",
  "callHistoryFilterAll": "全部",
  "callHistoryFilterVoice": "语音通话",
  "callHistoryFilterVideo": "视频通话",
  "callRecordCompleted": "通话时长 {duration}",
  "@callRecordCompleted": {
    "placeholders": {
      "duration": { "type": "String" }
    }
  },
  "callRecordMissed": "未接听",
  "callRecordRejected": "已拒绝",
  "callRecordBusy": "对方忙线中",
  "callRecordCancelled": "已取消",
  "callRecordOutgoing": "已拨出",
  "callRecordIncoming": "已接听"
}
```

**英文**（`lib/l10n/arb/app_en.arb`）：
```json
{
  "@@@CALL": "Section: Call",
  "callIncoming": "Incoming Call",
  "callOutgoing": "Outgoing Call",
  "callVoice": "Voice Call",
  "callVideo": "Video Call",
  "callAccept": "Accept",
  "callReject": "Reject",
  "callHangup": "Hang Up",
  "callCancel": "Cancel",
  "callBusy": "Line Busy",
  "callNoAnswer": "No Answer",
  "callRejected": "Rejected",
  "callCancelled": "Cancelled",
  "callDuration": "Duration {duration}",
  "@callDuration": {
    "placeholders": {
      "duration": { "type": "String" }
    }
  },
  "callMissed": "Missed Call",
  "callEnded": "Call Ended",
  "callConnecting": "Connecting...",
  "callReconnecting": "Reconnecting...",
  "callNetworkPoor": "Poor Network Quality",
  "callEncryptionEnabled": "End-to-End Encrypted",
  "callScreenShare": "Screen Share",
  "callSwitchCamera": "Switch Camera",
  "callMute": "Mute",
  "callUnmute": "Unmute",
  "callSpeaker": "Speaker",
  "callEarpiece": "Earpiece",
  "callCameraOn": "Camera On",
  "callCameraOff": "Camera Off",
  "callHistoryTitle": "Call History",
  "callHistoryEmpty": "No call history",
  "callHistoryFilterAll": "All",
  "callHistoryFilterVoice": "Voice Call",
  "callHistoryFilterVideo": "Video Call",
  "callRecordCompleted": "Duration {duration}",
  "@callRecordCompleted": {
    "placeholders": {
      "duration": { "type": "String" }
    }
  },
  "callRecordMissed": "No Answer",
  "callRecordRejected": "Rejected",
  "callRecordBusy": "Line Busy",
  "callRecordCancelled": "Cancelled",
  "callRecordOutgoing": "Outgoing",
  "callRecordIncoming": "Answered"
}
```

#### 11.2.3 使用方式

```dart
// 在代码中使用（基于 ARB 生成的类型安全访问）
Text(AppLocalizations.of(context)!.callIncoming);
Text(AppLocalizations.of(context)!.callDuration(formattedDuration));
```

---

## 12. 安全与性能优化

### 12.1 安全设计

#### 12.1.1 端到端加密

- Janus 默认启用 DTLS-SRTP 加密
- 媒体流在客户端之间端到端加密
- 服务器无法解密媒体内容

#### 12.1.2 Token 安全

- Janus Token 使用 API Secret 签名
- Token 有效期可配置（建议 24 小时）
- 支持 Token 刷新机制

#### 12.1.3 权限控制

```dart
// 通话权限检查
Future<bool> checkCallPermissions() async {
  // 检查麦克风权限
  final micStatus = await Permission.microphone.request();
  if (micStatus.isDenied) return false;
  
  // 视频通话还需检查摄像头权限
  if (callType == CallType.video) {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) return false;
  }
  
  return true;
}
```

### 12.2 性能优化

#### 12.2.1 网络优化

| 优化项 | 方案 |
|-------|------|
| **NAT 穿透** | Janus 内置 TURN 服务器支持 |
| **弱网适配** | Janus 自适应码率，根据网络状况动态调整 |
| **丢包恢复** | NACK + FEC 前向纠错 |
| **抖动缓冲** | Jitter Buffer 平滑网络抖动 |

#### 12.2.2 客户端优化

| 优化项 | 方案 |
|-------|------|
| **硬件编解码** | 优先使用硬件编解码器 |
| **后台模式** | iOS 后台音频模式 |
| **内存管理** | 及时释放未使用的媒体流 |
| **电量优化** | 屏幕关闭时降低视频帧率 |

#### 12.2.3 服务端优化

| 优化项 | 方案 |
|-------|------|
| **集群部署** | Janus 支持多节点部署 |
| **负载均衡** | 基于房间数/带宽的负载均衡 |
| **录制优化** | 异步录制，不影响通话质量 |
| **监控告警** | Prometheus + Grafana 监控 |

---

## 13. 实施路线图

### Phase 1: 基础通话（4 周）

- [ ] Janus Gateway 部署与配置
- [ ] 后端 CallSignalProcessor 实现
- [ ] 后端 CallService 实现
- [ ] Flutter 客户端基础通话功能
- [ ] 1v1 语音/视频通话

### Phase 2: 群组通话（3 周）

- [ ] 群组语音/视频会议
- [ ] 多设备来电处理
- [ ] 通话记录存储与查询
- [ ] 离线推送集成

### Phase 3: 通话记录与消息气泡（2 周）

- [ ] 通话记录消息气泡 UI
- [ ] 通话记录汇总页面
- [ ] 通话记录搜索功能
- [ ] 未接来电提醒

### Phase 4: 高级功能（4 周）

- [ ] 屏幕共享
- [ ] 通话录制
- [ ] 通话转接
- [ ] 网络质量监控

### Phase 5: 优化与测试（3 周）

- [ ] 弱网测试与优化
- [ ] 性能压测
- [ ] 安全审计
- [ ] 多端兼容性测试

---

## 14. 边界场景处理

> 参考微信/企业微信/腾讯云 IM/ZIM SDK 等多大厂处理经验，系统性覆盖通话过程中的非常规场景。

### 14.1 通话过程中登录/登出

#### 14.1.1 场景分析

| 场景 | 触发条件 | 影响范围 |
|-----|---------|---------|
| 通话中主动登出 | 用户点击"退出登录" | 当前通话中断，通话记录需保存 |
| 通话中被踢下线 | 其他设备登录触发 `KICKED_OUT` 事件 | 当前设备通话中断，其他设备可能继续 |
| 通话中 Token 过期 | JWT Token 失效需刷新 | 需无感刷新，避免通话中断 |
| 通话中切换账号 | 用户切换不同账号 | 当前通话终止，新账号无关联 |

#### 14.1.2 微信处理经验

- **主动登出**：微信在用户主动登出时，自动挂断所有进行中的通话，并生成通话记录
- **被踢下线**：触发 `KICKED_OUT` 事件后，客户端自动执行登出流程，通话随之终止
- **多设备协同**：微信支持手机+平板+电脑三端同时在线，通话在接听设备上进行，其他设备自动关闭来电界面

#### 14.1.3 设计方案

**Flutter 端实现**：

```dart
// active_call_registry.dart
class ActiveCallRegistry {
  // 通话状态缓存 (callId -> CallSession)
  final Map<String, CallSession> _activeCalls = {};
  
  /// 处理登录状态变化
  void handleAuthStateChanged(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.unauthenticated:
        // 登出时终止所有通话
        _terminateAllCalls(reason: CallEndReason.userLogout);
        _activeCalls.clear();
        break;
        
      case AuthStatus.authenticated:
        // 登录时检查是否有未完成的通话
        _checkPendingCalls();
        break;
        
      case AuthStatus.tokenExpired:
        // Token 过期时尝试无感刷新
        _refreshTokenWithoutInterruptingCalls();
        break;
    }
  }
  
  /// 处理被踢下线事件
  void handleKickedOut(KickedOutEvent event) {
    // 1. 记录被踢原因
    log.info('[ActiveCallRegistry] 被踢下线: reason=${event.reason}');
    
    // 2. 终止当前设备所有通话
    _terminateAllCalls(reason: CallEndReason.deviceKicked);
    
    // 3. 清理本地状态
    _activeCalls.clear();
    
    // 4. 跳转到登录页
    _navigateToLoginPage();
  }
  
  /// 终止所有通话
  void _terminateAllCalls({required CallEndReason reason}) {
    for (final session in _activeCalls.values) {
      // 发送挂断信令
      _callRepository.sendHangupSignal(
        callId: session.callId,
        reason: reason.name,
      );
      
      // 保存通话记录
      _callRecordService.saveCallRecord(
        session: session,
        endReason: reason,
      );
      
      // 释放媒体资源
      _mediaController.releaseResources(session.callId);
    }
  }
}
```

**后端实现**：

```java
// CallService.java
@Service
public class CallService {
    
    /**
     * 处理用户登出时的通话清理
     */
    public void handleUserLogout(Long userId, String deviceId) {
        // 1. 查询用户所有进行中的通话
        List<CallSession> activeSessions = callSessions.values().stream()
            .filter(s -> s.isParticipant(userId))
            .collect(Collectors.toList());
        
        // 2. 逐个处理通话
        for (CallSession session : activeSessions) {
            if (session.isOneOnOneCall()) {
                // 1v1 通话：直接挂断
                hangupCall(userId, session.getCallId());
            } else {
                // 群组通话：仅移除当前用户
                removeParticipant(session, userId, deviceId);
            }
        }
        
        // 3. 清理用户通话状态缓存
        userCallStatusCache.remove(userId);
    }
    
    /**
     * 处理设备被踢下线
     */
    public void handleDeviceKicked(Long userId, String deviceId, String reason) {
        // 1. 获取该设备上的通话
        List<String> deviceCalls = userDeviceCallMap.get(userId + ":" + deviceId);
        if (deviceCalls == null) return;
        
        // 2. 终止该设备上的所有通话
        for (String callId : deviceCalls) {
            CallSession session = callSessions.get(callId);
            if (session != null) {
                // 发送设备终止信令
                broadcastToDevice(session, deviceId, CallSignalType.DEVICE_TERMINATED, reason);
                
                // 如果是唯一设备，则挂断通话
                if (isLastDevice(userId, session)) {
                    hangupCall(userId, callId);
                }
            }
        }
        
        // 3. 清理设备通话映射
        userDeviceCallMap.remove(userId + ":" + deviceId);
    }
}
```

### 14.2 多通话冲突处理

#### 14.2.1 场景分析

| 场景 | 触发条件 | 处理策略 |
|-----|---------|---------|
| 通话中收到新来电 | 第三方用户发起呼叫 | 新通话优先，当前通话保持或挂断 |
| 多设备同时来电 | 多个用户同时发起呼叫 | 按时间戳排序，优先处理最早的 |
| 群组通话中收到新来电 | 群聊进行中收到私聊来电 | 提示用户，由用户决定是否接听 |
| 通话中发起新通话 | 用户主动发起新呼叫 | 先挂断当前通话，再发起新通话 |

#### 14.2.2 微信处理经验

- **通话等待**：微信在通话中收到新来电时，显示"通话等待"界面，用户可选择：
  - 挂断当前通话，接听新来电
  - 拒绝新来电，保持当前通话
  - 将当前通话保持，接听新来电（双通话模式）
- **忙线提示**：当用户正在通话中，其他用户发起呼叫时，主叫方收到"对方忙线中"提示

#### 14.2.3 设计方案

**通话冲突管理器**：

```dart
// call_conflict_manager.dart
class CallConflictManager {
  final ActiveCallRegistry _registry;
  final CallController _controller;
  
  /// 处理新来电冲突
  Future<CallConflictResult> handleIncomingCall(CallInvite invite) async {
    final currentCall = _registry.getActiveCall();
    
    // 1. 无当前通话：直接接受
    if (currentCall == null) {
      return CallConflictResult(
        action: CallConflictAction.accept,
        callId: invite.callId,
      );
    }
    
    // 2. 同一通话（多设备通知）：忽略
    if (currentCall.callId == invite.callId) {
      return CallConflictResult(
        action: CallConflictAction.ignore,
        reason: 'DUPLICATE_CALL',
      );
    }
    
    // 3. 新通话优先级判断
    return await _resolveConflict(currentCall, invite);
  }
  
  /// 解决通话冲突
  Future<CallConflictResult> _resolveConflict(
    CallSession currentCall,
    CallInvite newInvite,
  ) async {
    // 策略 1：新通话优先（微信策略）
    if (_isNewCallPriorityEnabled()) {
      // 挂断当前通话
      await _controller.hangup(reason: CallEndReason.newCallPreempt);
      
      // 接受新通话
      return CallConflictResult(
        action: CallConflictAction.accept,
        callId: newInvite.callId,
        preemptedCallId: currentCall.callId,
      );
    }
    
    // 策略 2：当前通话优先
    if (_isCurrentCallPriorityEnabled()) {
      // 拒绝新通话
      await _controller.rejectCall(
        callId: newInvite.callId,
        reason: CallRejectReason.onAnotherCall,
      );
      
      return CallConflictResult(
        action: CallConflictAction.reject,
        callId: newInvite.callId,
        reason: 'CURRENT_CALL_PRIORITY',
      );
    }
    
    // 策略 3：用户选择（通话等待模式）
    return CallConflictResult(
      action: CallConflictAction.showWaitingUI,
      callId: newInvite.callId,
      currentCallId: currentCall.callId,
    );
  }
}

/// 通话冲突结果
class CallConflictResult {
  final CallConflictAction action;
  final String callId;
  final String? preemptedCallId;
  final String? currentCallId;
  final String? reason;
  
  CallConflictResult({
    required this.action,
    required this.callId,
    this.preemptedCallId,
    this.currentCallId,
    this.reason,
  });
}

enum CallConflictAction {
  accept,        // 接受新通话
  reject,        // 拒绝新通话
  ignore,        // 忽略（重复通知）
  showWaitingUI, // 显示通话等待界面
}
```

**通话等待 UI**：

```dart
// call_waiting_dialog.dart
class CallWaitingDialog extends StatelessWidget {
  final CallSession currentCall;
  final CallInvite newInvite;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('通话等待'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前通话信息
          ListTile(
            leading: Icon(Icons.phone_in_talk),
            title: Text('当前通话'),
            subtitle: Text(currentCall.peerName),
            trailing: Text(_formatDuration(currentCall.elapsed)),
          ),
          
          Divider(),
          
          // 新来电信息
          ListTile(
            leading: Icon(Icons.call),
            title: Text('新来电'),
            subtitle: Text(newInvite.callerName),
          ),
        ],
      ),
      actions: [
        // 拒绝新来电
        TextButton(
          onPressed: () => Navigator.pop(context, CallWaitingAction.rejectNew),
          child: Text('拒绝新来电'),
        ),
        
        // 挂断当前，接听新来电
        TextButton(
          onPressed: () => Navigator.pop(context, CallWaitingAction.swapCalls),
          child: Text('挂断当前并接听'),
        ),
        
        // 保持当前，接听新来电
        FilledButton(
          onPressed: () => Navigator.pop(context, CallWaitingAction.holdCurrent),
          child: Text('保持当前并接听'),
        ),
      ],
    );
  }
}
```

### 14.3 企业切换（多租户隔离）

#### 14.3.1 场景分析

| 场景 | 触发条件 | 影响范围 |
|-----|---------|---------|
| 通话中切换企业 | 用户在设置中切换租户 | 当前通话需终止，数据需隔离 |
| 跨企业通话 | 尝试呼叫其他企业用户 | 需校验企业隔离策略 |
| Janus 房间隔离 | 不同企业的通话房间 | 房间 ID 需包含租户标识 |
| 媒体流隔离 | 不同企业的媒体流 | 需确保媒体流不跨租户泄露 |

#### 14.3.2 多租户隔离策略

**数据层隔离**：

```java
// JanusRoomManager.java
@Service
public class JanusRoomManager {
    
    @Value("${janus.tenant-isolation:true}")
    private boolean tenantIsolation;
    
    /**
     * 生成带租户隔离的房间ID
     */
    public String generateRoomId(Long tenantId) {
        if (tenantIsolation) {
            // 格式：tenant_{tenantId}_room_{timestamp}_{random}
            return String.format("tenant_%d_room_%d_%s",
                tenantId,
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8));
        } else {
            return String.format("room_%d_%s",
                System.currentTimeMillis(),
                UUID.randomUUID().toString().substring(0, 8));
        }
    }
    
    /**
     * 验证房间访问权限（租户隔离）
     */
    public boolean validateRoomAccess(String roomId, Long tenantId) {
        if (!tenantIsolation) return true;
        
        // 解析房间ID中的租户信息
        if (roomId.startsWith("tenant_")) {
            String[] parts = roomId.split("_");
            if (parts.length >= 2) {
                try {
                    Long roomTenantId = Long.parseLong(parts[1]);
                    return roomTenantId.equals(tenantId);
                } catch (NumberFormatException e) {
                    return false;
                }
            }
        }
        return false;
    }
}
```

**企业切换处理**：

```dart
// tenant_switch_handler.dart
class TenantSwitchHandler {
  final ActiveCallRegistry _callRegistry;
  final CallRepository _callRepository;
  
  /// 处理企业切换
  Future<void> handleTenantSwitch(Long oldTenantId, Long newTenantId) async {
    // 1. 获取当前租户下的所有通话
    final tenantCalls = _callRegistry.getCallsByTenant(oldTenantId);
    
    if (tenantCalls.isEmpty) {
      // 无进行中的通话，直接切换
      await _performTenantSwitch(newTenantId);
      return;
    }
    
    // 2. 提示用户即将终止通话
    final shouldProceed = await _showTenantSwitchDialog(tenantCalls.length);
    if (!shouldProceed) {
      // 用户取消切换
      return;
    }
    
    // 3. 终止所有通话
    for (final session in tenantCalls) {
      await _callRepository.sendHangupSignal(
        callId: session.callId,
        reason: 'TENANT_SWITCH',
      );
      
      // 保存通话记录
      await _callRecordService.saveCallRecord(
        session: session,
        endReason: CallEndReason.tenantSwitch,
      );
    }
    
    // 4. 清理通话状态
    _callRegistry.clearTenantCalls(oldTenantId);
    
    // 5. 执行企业切换
    await _performTenantSwitch(newTenantId);
  }
  
  /// 显示企业切换确认对话框
  Future<bool> _showTenantSwitchDialog(int activeCallCount) async {
    return await showDialog<bool>(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('切换企业'),
        content: Text(
          '当前有 $activeCallCount 个通话正在进行中，切换企业后将终止所有通话。是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确认切换'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

**后端跨企业通话校验**：

```java
// CallService.java
@Service
public class CallService {
    
    /**
     * 发起通话（含企业隔离校验）
     */
    public void initiateCall(Long callerId, CallSignalMessage signal) {
        // 1. 获取主叫方当前租户
        Long callerTenantId = tenantContext.getCurrentTenantId(callerId);
        
        // 2. 校验被叫方是否在同一租户
        if (signal.getCalleeId() != null) {
            Long calleeTenantId = tenantContext.getCurrentTenantId(signal.getCalleeId());
            if (!callerTenantId.equals(calleeTenantId)) {
                throw new BusinessException("跨企业通话不允许");
            }
        }
        
        // 3. 群组通话校验所有参与者
        if (signal.getInviteeIdsCount() > 0) {
            for (Long inviteeId : signal.getInviteeIdsList()) {
                Long inviteeTenantId = tenantContext.getCurrentTenantId(inviteeId);
                if (!callerTenantId.equals(inviteeTenantId)) {
                    throw new BusinessException("群组通话参与者必须在同一企业");
                }
            }
        }
        
        // 4. 生成带租户隔离的房间ID
        String roomId = janusRoomManager.generateRoomId(callerTenantId);
        
        // 5. 继续通话流程...
    }
}
```

### 14.4 用户/设备删除场景

#### 14.4.1 场景分析

| 场景 | 触发条件 | 影响范围 |
|-----|---------|---------|
| 通话中用户被删除 | 管理员从企业移除用户 | 用户无法继续通话，需终止 |
| 通话中设备被删除 | 用户从设备管理移除设备 | 该设备需终止通话 |
| 通话中被拉黑 | 对方将用户加入黑名单 | 需根据策略决定是否终止 |
| 好友关系解除 | 双方删除好友关系 | 通话可继续，但结束后无法再次呼叫 |

#### 14.4.2 设计方案

**成员变更监听**：

```dart
// member_change_listener.dart
class MemberChangeListener {
  final ActiveCallRegistry _callRegistry;
  final CallController _controller;
  
  /// 监听用户成员变化
  void onMemberChanged(MemberChangeEvent event) {
    switch (event.changeType) {
      case MemberChangeType.removed:
        _handleUserRemoved(event.userId);
        break;
      case MemberChangeType.deviceRemoved:
        _handleDeviceRemoved(event.userId, event.deviceId);
        break;
      case MemberChangeType.blocked:
        _handleUserBlocked(event.userId, event.blockedBy);
        break;
    }
  }
  
  /// 处理用户被移除
  void _handleUserRemoved(Long userId) {
    // 1. 检查用户是否在通话中
    final userCalls = _callRegistry.getCallsByUser(userId);
    if (userCalls.isEmpty) return;
    
    // 2. 终止用户的所有通话
    for (final session in userCalls) {
      if (session.isCurrentUser) {
        // 当前用户被移除：终止通话
        _controller.hangup(reason: CallEndReason.userRemoved);
      } else {
        // 其他参与者被移除：通知通话
        _controller.notifyParticipantLeft(userId, reason: 'USER_REMOVED');
      }
    }
  }
  
  /// 处理设备被移除
  void _handleDeviceRemoved(Long userId, String deviceId) {
    // 1. 检查该设备是否在通话中
    final deviceCalls = _callRegistry.getCallsByDevice(userId, deviceId);
    if (deviceCalls.isEmpty) return;
    
    // 2. 终止该设备上的通话
    for (final session in deviceCalls) {
      if (session.isCurrentDevice) {
        // 当前设备被移除：终止通话
        _controller.hangup(reason: CallEndReason.deviceRemoved);
      }
    }
  }
  
  /// 处理用户被拉黑
  void _handleUserBlocked(Long userId, Long blockedBy) {
    // 1. 检查是否在与拉黑者的通话中
    final callWithBlocker = _callRegistry.getCallWithUser(userId, blockedBy);
    if (callWithBlocker == null) return;
    
    // 2. 根据策略处理
    if (_shouldTerminateCallOnBlock()) {
      // 策略 1：立即终止通话
      _controller.hangup(reason: CallEndReason.userBlocked);
    } else {
      // 策略 2：允许通话继续，但结束后无法再次呼叫
      _controller.notifyUserBlocked(blockedBy);
    }
  }
}
```

**后端成员变更通知**：

```java
// MemberChangeService.java
@Service
public class MemberChangeService {
    
    @Autowired
    private WebSocketMessageSender messageSender;
    
    /**
     * 用户被移除出企业
     */
    public void removeUserFromTenant(Long userId, Long tenantId) {
        // 1. 查询用户进行中的通话
        List<CallSession> activeCalls = callService.getUserActiveCalls(userId);
        
        // 2. 终止所有通话
        for (CallSession session : activeCalls) {
            callService.hangupCall(userId, session.getCallId());
            
            // 通知其他参与者
            Map<String, Object> payload = new HashMap<>();
            payload.put("action", "call.participantLeft");
            payload.put("callId", session.getCallId());
            payload.put("userId", userId);
            payload.put("reason", "USER_REMOVED");
            
            callService.broadcastToParticipants(session, payload);
        }
        
        // 3. 发送系统通知给客户端
        Map<String, Object> notify = new HashMap<>();
        notify.put("action", "member.removed");
        notify.put("userId", userId);
        notify.put("tenantId", tenantId);
        
        messageSender.sendToUser(userId, buildSystemNotify(notify));
    }
    
    /**
     * 设备被移除
     */
    public void removeDevice(Long userId, String deviceId) {
        // 1. 查询该设备上的通话
        List<CallSession> deviceCalls = callService.getDeviceActiveCalls(userId, deviceId);
        
        // 2. 终止设备上的通话
        for (CallSession session : deviceCalls) {
            // 发送设备终止信令
            Map<String, Object> payload = new HashMap<>();
            payload.put("action", "call.deviceTerminated");
            payload.put("callId", session.getCallId());
            payload.put("deviceId", deviceId);
            payload.put("reason", "DEVICE_REMOVED");
            
            messageSender.sendToDevice(userId, deviceId, buildSystemNotify(payload));
        }
    }
}
```

### 14.5 应用生命周期处理

#### 14.5.1 场景分析

| 场景 | 触发条件 | 处理策略 |
|-----|---------|---------|
| 应用进入后台 | 用户按 Home 键或切换应用 | 保持通话，但关闭摄像头 |
| 应用被系统杀死 | 内存不足或用户强制关闭 | 终止通话，保存记录 |
| 应用恢复前台 | 用户切回应用 | 恢复视频流，同步状态 |
| 屏幕锁定 | 用户锁定屏幕 | 保持音频，关闭视频 |

#### 14.5.2 设计方案

```dart
// app_lifecycle_handler.dart
class AppLifecycleHandler {
  final CallController _controller;
  final ActiveCallRegistry _registry;
  
  /// 监听应用生命周期
  void onAppStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 应用进入后台
        _handleAppBackgrounded();
        break;
        
      case AppLifecycleState.resumed:
        // 应用恢复前台
        _handleAppForegrounded();
        break;
        
      case AppLifecycleState.detached:
        // 应用即将被杀死
        _handleAppTerminated();
        break;
    }
  }
  
  /// 应用进入后台
  void _handleAppBackgrounded() {
    final activeCall = _registry.getActiveCall();
    if (activeCall == null) return;
    
    // 1. 关闭摄像头（节省资源）
    _controller.disableVideo();
    
    // 2. 保持音频连接
    _controller.enableAudioOnly();
    
    // 3. 显示后台通话通知（iOS/Android）
    _showBackgroundCallNotification(activeCall);
    
    // 4. 启用后台模式
    _enableBackgroundMode();
  }
  
  /// 应用恢复前台
  void _handleAppForegrounded() {
    final activeCall = _registry.getActiveCall();
    if (activeCall == null) return;
    
    // 1. 移除后台通知
    _removeBackgroundNotification();
    
    // 2. 恢复视频流（如果是视频通话）
    if (activeCall.callType == CallType.video) {
      _controller.restoreVideo();
    }
    
    // 3. 同步通话状态
    _syncCallState();
  }
  
  /// 应用被杀死
  void _handleAppTerminated() {
    final activeCall = _registry.getActiveCall();
    if (activeCall == null) return;
    
    // 1. 发送挂断信令（尽力而为）
    try {
      _controller.sendHangupSignal(reason: CallEndReason.appTerminated);
    } catch (e) {
      // 忽略错误
    }
    
    // 2. 保存通话记录到本地
    _saveCallRecordLocally(activeCall);
    
    // 3. 释放媒体资源
    _controller.releaseResources();
  }
  
  /// 显示后台通话通知
  void _showBackgroundCallNotification(CallSession session) {
    flutterLocalNotificationsPlugin.show(
      0,
      '通话中',
      '${session.peerName} - ${_formatDuration(session.elapsed)}',
      NotificationDetails(
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
      ),
    );
  }
  
  /// 启用后台模式
  void _enableBackgroundMode() {
    // iOS: 启用后台音频模式
    if (Platform.isIOS) {
      AudioSession.instance.then((session) {
        session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
        ));
      });
    }
    
    // Android: 启用前台服务
    if (Platform.isAndroid) {
      _startForegroundService();
    }
  }
}
```

### 14.6 系统级中断处理

#### 14.6.1 场景分析

| 场景 | 触发条件 | 处理策略 |
|-----|---------|---------|
| 系统来电中断 | 手机来电（VoLTE 未开启） | 暂停通话，等待用户选择 |
| 闹钟响起 | 闹钟应用触发 | 降低通话音量，继续通话 |
| 低电量模式 | 系统电量低于阈值 | 降低视频质量，关闭不必要的功能 |
| 网络切换 | WiFi 切换到移动网络 | ICE 重新协商，保持通话 |

#### 14.6.2 设计方案

```dart
// system_interruption_handler.dart
class SystemInterruptionHandler {
  final CallController _controller;
  final AudioFocusManager _audioFocusManager;
  
  /// 监听音频焦点变化（系统来电、闹钟等）
  void onAudioFocusChanged(AudioFocusState state) {
    switch (state) {
      case AudioFocusState.gained:
        // 重新获得焦点
        _controller.restoreAudio();
        break;
        
      case AudioFocusState.lost:
        // 失去焦点（系统来电、闹钟等）
        _controller.pauseAudio();
        break;
        
      case AudioFocusState.ducked:
        // 降低音量（导航提示等）
        _controller.duckAudio();
        break;
    }
  }
  
  /// 监听电池状态
  void onBatteryStateChanged(BatteryState state) {
    switch (state) {
      case BatteryState.low:
        // 低电量：降低视频质量
        _controller.reduceVideoQuality();
        _controller.disableScreenShare();
        break;
        
      case BatteryState.critical:
        // 极低电量：关闭视频
        _controller.disableVideo();
        _showLowBatteryWarning();
        break;
        
      default:
        // 恢复正常
        _controller.restoreVideoQuality();
        break;
    }
  }
  
  /// 处理系统来电
  Future<void> handlePhoneCallIncoming() async {
    // 1. 暂停通话音频
    await _controller.pauseAudio();
    
    // 2. 显示系统来电界面
    _showPhoneCallOverlay();
    
    // 3. 等待用户选择
    final action = await _showPhoneCallDialog();
    
    switch (action) {
      case PhoneCallAction.endCall:
        // 结束 IM 通话，接听系统来电
        await _controller.hangup(reason: CallEndReason.phoneCallInterrupt);
        break;
        
      case PhoneCallAction.ignoreCall:
        // 忽略系统来电，继续 IM 通话
        await _controller.restoreAudio();
        break;
    }
  }
}
```

### 14.7 性能控制

#### 14.7.1 动态码率调整

```dart
// bandwidth_estimator.dart
class BandwidthEstimator {
  final RTCPeerConnection _peerConnection;
  
  // 码率配置
  static const int minBitrate = 300 * 1000;   // 300 kbps
  static const int startBitrate = 1000 * 1000; // 1 Mbps
  static const int maxBitrate = 2000 * 1000;  // 2 Mbps
  
  /// 根据网络状况动态调整码率
  void adjustBitrate() {
    _peerConnection.getStats().then((stats) {
      // 1. 获取网络指标
      final availableOutgoingBitrate = stats.availableOutgoingBitrate;
      final packetLossRate = stats.packetLossRate;
      final roundTripTime = stats.roundTripTime;
      
      // 2. 计算目标码率
      int targetBitrate = _calculateTargetBitrate(
        availableBitrate: availableOutgoingBitrate,
        packetLoss: packetLossRate,
        rtt: roundTripTime,
      );
      
      // 3. 应用码率限制
      _peerConnection.setBitrate(targetBitrate);
      
      // 4. 根据码率调整视频质量
      _adjustVideoQuality(targetBitrate);
    });
  }
  
  /// 计算目标码率
  int _calculateTargetBitrate({
    required int availableBitrate,
    required double packetLoss,
    required int rtt,
  }) {
    // 网络质量好：使用较高码率
    if (packetLoss < 0.01 && rtt < 100) {
      return min(availableBitrate * 0.8, maxBitrate);
    }
    
    // 网络质量中等：使用中等码率
    if (packetLoss < 0.05 && rtt < 300) {
      return min(availableBitrate * 0.5, startBitrate);
    }
    
    // 网络质量差：使用最低码率
    return minBitrate;
  }
  
  /// 根据码率调整视频质量
  void _adjustVideoQuality(int bitrate) {
    if (bitrate < 500 * 1000) {
      // 低码率：降低分辨率和帧率
      _controller.setVideoResolution(320, 240);
      _controller.setVideoFrameRate(15);
    } else if (bitrate < 1000 * 1000) {
      // 中等码率：中等质量
      _controller.setVideoResolution(640, 480);
      _controller.setVideoFrameRate(24);
    } else {
      // 高码率：高质量
      _controller.setVideoResolution(1280, 720);
      _controller.setVideoFrameRate(30);
    }
  }
}
```

#### 14.7.2 房间人数限制

```dart
// room_capacity_manager.dart
class RoomCapacityManager {
  // 房间人数限制配置
  static const int maxParticipantsOneOnOne = 2;
  static const int maxParticipantsGroupCall = 9;  // 微信限制
  static const int maxParticipantsVideoMeeting = 20;
  
  /// 检查是否可以加入房间
  bool canJoinRoom(String roomId, int currentParticipants) {
    final roomType = _getRoomType(roomId);
    
    switch (roomType) {
      case RoomType.oneOnOne:
        return currentParticipants < maxParticipantsOneOnOne;
        
      case RoomType.groupCall:
        return currentParticipants < maxParticipantsGroupCall;
        
      case RoomType.videoMeeting:
        return currentParticipants < maxParticipantsVideoMeeting;
        
      default:
        return false;
    }
  }
  
  /// 房间满员时的处理
  void handleRoomFull(String roomId) {
    // 1. 提示用户房间已满
    _showRoomFullDialog();
    
    // 2. 发送忙线信令
    _sendBusySignal(roomId);
  }
}
```

#### 14.7.3 资源占用优化

```dart
// resource_optimizer.dart
class ResourceOptimizer {
  
  /// 优化 CPU 占用
  void optimizeCpuUsage() {
    // 1. 降低视频编码复杂度
    if (_isCpuUsageHigh()) {
      _setVideoCodec(VideoCodec.vp8); // VP8 比 H.264 CPU 占用低
      _reduceVideoFrameRate(15);
    }
  }
  
  /// 优化内存占用
  void optimizeMemoryUsage() {
    // 1. 释放未使用的视频流
    _releaseUnusedVideoStreams();
    
    // 2. 降低视频缓冲区大小
    _reduceJitterBufferSize();
  }
  
  /// 优化网络占用
  void optimizeNetworkUsage() {
    // 1. 启用 Simulcast（多流发送）
    _enableSimulcast();
    
    // 2. 启用 SVC（可伸缩视频编码）
    _enableSVC();
    
    // 3. 启用 NACK + FEC（丢包恢复）
    _enablePacketLossRecovery();
  }
}
```

### 14.8 异常恢复

#### 14.8.1 网络中断恢复

```dart
// network_recovery_manager.dart
class NetworkRecoveryManager {
  final CallController _controller;
  final ActiveCallRegistry _registry;
  
  /// 网络状态变化监听
  void onNetworkChanged(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.disconnected:
        // 网络断开
        _handleNetworkDisconnected();
        break;
        
      case NetworkStatus.connected:
        // 网络恢复
        _handleNetworkConnected();
        break;
        
      case NetworkStatus.degraded:
        // 网络质量下降
        _handleNetworkDegraded();
        break;
    }
  }
  
  /// 网络断开处理
  void _handleNetworkDisconnected() {
    final activeCall = _registry.getActiveCall();
    if (activeCall == null) return;
    
    // 1. 显示重连中界面
    _controller.markReconnecting();
    
    // 2. 启动重连计时器
    _startReconnectTimeout();
    
    // 3. 尝试重连
    _attemptReconnect();
  }
  
  /// 尝试重连
  Future<void> _attemptReconnect() async {
    final activeCall = _registry.getActiveCall();
    if (activeCall == null) return;
    
    try {
      // 1. 重新建立 WebSocket 连接
      await _socketService.reconnect();
      
      // 2. 查询通话状态
      final callState = await _callRepository.getCallState(activeCall.callId);
      
      if (callState == null || callState.status == CallStatus.ended) {
        // 通话已结束
        _controller.endCall(reason: CallEndReason.callEnded);
        return;
      }
      
      // 3. 重新加入 Janus 房间
      await _janusClient.rejoinRoom(
        roomId: callState.roomId,
        token: callState.janusToken,
      );
      
      // 4. 恢复媒体流
      await _controller.restoreMediaStreams();
      
      // 5. 恢复连接状态
      _controller.restoreConnected();
      
    } catch (e) {
      // 重连失败，继续重试
      _scheduleReconnectRetry();
    }
  }
  
  /// 重连超时处理
  void _startReconnectTimeout() {
    Timer(Duration(seconds: 30), () {
      final activeCall = _registry.getActiveCall();
      if (activeCall == null) return;
      
      // 30 秒内未重连成功，终止通话
      _controller.endCall(reason: CallEndReason.networkTimeout);
    });
  }
}
```

#### 14.8.2 通话状态重建

```dart
// call_state_rebuilder.dart
class CallStateRebuilder {
  
  /// 从服务端重建通话状态
  Future<CallSession?> rebuildCallState(String callId) async {
    try {
      // 1. 查询通话详情
      final callDetail = await _callApi.getCallDetail(callId);
      if (callDetail == null) return null;
      
      // 2. 重建本地状态
      final session = CallSession.fromDto(callDetail);
      
      // 3. 重建参与者列表
      for (final participant in callDetail.participants) {
        session.addParticipant(CallParticipant.fromDto(participant));
      }
      
      // 4. 重建媒体状态
      await _rebuildMediaState(session);
      
      return session;
      
    } catch (e) {
      log.error('[CallStateRebuilder] 重建通话状态失败: $e');
      return null;
    }
  }
  
  /// 重建媒体状态
  Future<void> _rebuildMediaState(CallSession session) async {
    // 1. 重新获取 Janus Token
    final token = await _callApi.getJanusToken(session.callId, session.roomId);
    
    // 2. 重新加入房间
    await _janusClient.joinRoom(
      roomId: session.roomId,
      token: token,
      displayName: _currentUser.displayName,
    );
    
    // 3. 恢复本地媒体流
    await _mediaController.restoreLocalStreams();
    
    // 4. 订阅远端媒体流
    await _mediaController.subscribeRemoteStreams();
  }
}
```

### 14.9 并发冲突处理

#### 14.9.1 信令冲突解决

```dart
// signal_conflict_resolver.dart
class SignalConflictResolver {
  
  /// 处理信令冲突
  CallSignal resolveSignalConflict(
    CallSignal existingSignal,
    CallSignal newSignal,
  ) {
    // 1. 基于时间戳判断
    if (newSignal.timestamp > existingSignal.timestamp) {
      return newSignal; // 新信令优先
    }
    
    // 2. 基于信令类型优先级
    final priority = _getSignalPriority(newSignal.type);
    final existingPriority = _getSignalPriority(existingSignal.type);
    
    if (priority > existingPriority) {
      return newSignal;
    }
    
    return existingSignal;
  }
  
  /// 信令优先级
  int _getSignalPriority(CallSignalType type) {
    switch (type) {
      case CallSignalType.hangup:
        return 100; // 挂断最高优先级
      case CallSignalType.rejected:
        return 90;
      case CallSignalType.accepted:
        return 80;
      case CallSignalType.invite:
        return 70;
      default:
        return 50;
    }
  }
}
```

#### 14.9.2 多设备状态同步

```dart
// multi_device_sync_manager.dart
class MultiDeviceSyncManager {
  
  /// 同步通话状态到所有设备
  Future<void> syncCallStateToAllDevices(CallSession session) async {
    // 1. 构建状态同步消息
    final syncMessage = CallStateSyncMessage(
      callId: session.callId,
      status: session.status,
      participants: session.participants.map((p) => p.toDto()).toList(),
      mediaState: session.mediaState.toDto(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    // 2. 广播给所有设备
    await _callRepository.broadcastStateSync(syncMessage);
  }
  
  /// 处理来自其他设备的状态同步
  void handleStateSyncFromOtherDevice(CallStateSyncMessage sync) {
    final localSession = _registry.getActiveCall();
    if (localSession == null) return;
    
    // 1. 比较时间戳
    if (sync.timestamp < localSession.lastUpdateTime) {
      return; // 忽略旧状态
    }
    
    // 2. 更新本地状态
    localSession.updateFromSync(sync);
    
    // 3. 刷新 UI
    _controller.notifyStateChanged();
  }
}
```

### 14.10 其他边界场景

#### 14.10.1 设备电量低

```dart
// low_battery_handler.dart
class LowBatteryHandler {
  
  /// 电量低于 10% 时
  void onBatteryLow() {
    // 1. 提示用户
    _showLowBatteryWarning();
    
    // 2. 降低视频质量
    _controller.reduceVideoQuality();
    
    // 3. 关闭屏幕共享
    _controller.disableScreenShare();
    
    // 4. 如果电量低于 5%，建议用户结束通话
    if (_batteryLevel < 5) {
      _suggestEndCall();
    }
  }
}
```

#### 14.10.2 通话时长限制

```dart
// call_duration_limiter.dart
class CallDurationLimiter {
  static const int maxCallDurationHours = 24; // 最长 24 小时
  
  /// 检查通话时长
  void checkCallDuration(CallSession session) {
    if (session.elapsedHours >= maxCallDurationHours) {
      // 1. 提示用户
      _showMaxDurationWarning();
      
      // 2. 30 秒后自动挂断
      Timer(Duration(seconds: 30), () {
        _controller.hangup(reason: CallEndReason.maxDurationReached);
      });
    }
  }
}
```

#### 14.10.3 时区变化

```dart
// timezone_change_handler.dart
class TimezoneChangeHandler {
  
  /// 时区变化时更新通话记录时间
  void onTimezoneChanged(TimeZone newTimezone) {
    // 1. 更新本地通话记录时间显示
    _callRecordService.updateDisplayTime(newTimezone);
    
    // 2. 同步到服务端
    _callRecordService.syncTimezoneToServer(newTimezone);
  }
}
```

---

## 附录

### A. 参考资料

1. [Janus Gateway 官方文档](https://janus.conf.meetecho.com/docs/)
2. [flutter_webrtc 插件](https://pub.dev/packages/flutter_webrtc)
3. [WebRTC 协议详解](https://webrtc.org/getting-started/overview)
4. [企业微信通话设计参考](https://work.weixin.qq.com/)

### B. 术语表

| 术语 | 说明 |
|-----|------|
| **SFU** | Selective Forwarding Unit，选择性转发单元 |
| **Janus** | 开源 WebRTC 网关，支持多种插件 |
| **videoroom** | Janus 视频房间插件，用于多人视频会议 |
| **DTLS** | Datagram Transport Layer Security |
| **SRTP** | Secure Real-time Transport Protocol |
| **TURN** | Traversal Using Relays around NAT |
| **ICE** | Interactive Connectivity Establishment |
| **Simulcast** | 同时发送多路不同质量的视频流 |

### C. 源码验证清单

| 验证项 | 状态 | 说明 |
|-------|------|------|
| WebSocket 中间件 | ✅ 已验证 | MessageProcessor 模式已实现 |
| Proto 协议 | ✅ 已验证 | CALL_SIGNAL = 206 已定义 |
| Flutter 通话模块 | ✅ 已验证 | call_controller 等基础架构已搭建 |
| 后端 DO 实体 | ✅ 已验证 | ImCallRecordDO 已存在 |
| 多设备管理 | ✅ 已验证 | 已有 sendToUser 方法 |
| 消息推送 | ✅ 已验证 | OfflinePushService 已实现 |

---

**文档版本**: v2.0  
**最后更新**: 2026-07-19  
**维护者**: 圣钰科技 IM 团队
