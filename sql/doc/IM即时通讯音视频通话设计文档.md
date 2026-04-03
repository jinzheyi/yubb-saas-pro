---
description: IM 音视频通话（WebRTC 自研）设计文档
owner: IM
status: draft
version: v1.4
updated: 2026-04-03
---

# IM 即时通讯音视频通话设计文档（纯自研 WebRTC 路线）

## 变更记录

| 版本 | 日期 | 变更摘要 |
|------|------|---------|
| v1.0 | 2026-03-28 | 初稿 |
| v1.1 | 2026-04-01 | 完善信令协议、状态机、UI 规范 |
| v1.2 | 2026-04-02 | 新增 CALL_RECORD=209 决策、SPI 分层约束 |
| v1.3 | 2026-04-03 | 修复8处架构漏洞：离线推送缺口、超时任务分布式锁、REJECT/BUSY 语义、STATE_SYNC 触发时机、STUN/TURN 国内替代、ImCallRecordMapper 缺失方法、附录A补全 CALL_RECORD 待实现、callId 精度约定 |
| v1.4 | 2026-04-03 | 离线推送方案落地：明确采用 UniPush 2.0（客户端）+ 个推 REST API V2（服务端），详细人工准备清单/数据库设计/Java 代码/免费额度管理/兜底降级策略 |

---

## 0. 背景与目标

### 0.1 背景

当前 IM 已具备：
- WebSocket 双栈（JSON/PB）协议与鉴权（Milestone B 已完成）
- 会话增量同步（cursorVersion/conversationVersion）（Milestone C3 已完成）
- 消息存储与断线补偿（sequence）（Milestone C1/C2 已完成）
- 消息处理器工厂模式（TEXT/IMAGE/VOICE/VIDEO/FILE/LOCATION/QUOTE_REPLY 均已注册）
- 多端互踢与 CLOSE 语义闭环（Milestone A 已完成）
- 消息体 Schema 冻结（Milestone S1 已完成）

希望新增音视频通话能力，并且：
- 尽可能纯自研（优先 WebRTC）
- 保持企业级规模、可观测、可灰度、可长期维护

### 0.2 目标（必须满足）

- 通话信令：在现有 IM WS 上闭环（JSON/PB 双栈）
- 媒体传输：基于 WebRTC（端侧）
- 服务端：维护权威状态机，处理多端/乱序/重试/超时
- 可观测：可按 tenantId/userId/callId 串起链路，具备基础指标与日志
- 灰度开关：按 tenant/user/deviceType 可控启用

### 0.3 非目标（本期不做/可后续迭代）

- 群通话（多人会议）
- 录制/转写/同声传译
- 运营侧复杂策略（如强制主端接听、并发策略可配置）

### 0.4 Milestone 定位

对应 `Milestone R`（P2），当前状态为**不做（本期不排期）**。本文档为预研设计，待排期后按 Phase 0 -> Phase 1 -> Phase 2 分阶段落地。

---

## 1. 总体架构

### 1.1 模块拆分

- **IM 信令层（自研）**
  - 复用现有 WS 连接与认证（PROBE -> AUTH_REQ 握手不变）
  - 复用 `MessageType.CALL_SIGNAL(206)` 统一消息类型，通过 `signalType` 子类型分发
  - 负责状态同步、重试、幂等、离线补偿

- **RTC 媒体层（WebRTC）**
  - iOS/Android 端集成 WebRTC 栈（uni-app x 需 Native Plugin）
  - Web 端直接使用浏览器 WebRTC API
  - 负责采集/编解码/回声消除/弱网自适应（由 WebRTC 提供基础能力）

- **服务端 Call State 服务（自研）**
  - callId 维度权威状态机（Server-Driven，参考微信/企业微信设计）
  - 负责：多端一致、超时、并发控制、幂等
  - 保存通话最终态，产生通话记录消息

- **离线推送（Phase 1）**
  - 当被叫方全部设备离线时，通过 `ImCallPushService` 触发离线推送（个推 Getui REST API）
  - 推送 Payload 携带 `callId`/`callerId`/`callType`，端侧收到后通过 REST 拉取通话状态

### 1.2 数据流

```
1) A 发起通话：CALL_SIGNAL(signalType=1/CALL) -> WS -> 服务端
2) 服务端忙线检测 + 落库(im_call_record) + 推进状态：INIT -> RINGING
3a) B 在线：服务端 sendToUser(calleeId, CALL_SIGNAL(signalType=1)) fanout 全部在线设备
3b) B 离线：服务端检测到 B 无 session，触发 ImCallPushService 推送唤醒通知（Phase 1）
    → B 设备收到推送，打开 App，WS 重连后服务端下发 STATE_SYNC
4) B 任一端接受：CALL_SIGNAL(signalType=2/ANSWER) -> WS -> 服务端
5) 服务端 CAS 并发裁决（WHERE state='RINGING' AND accepted_device_id IS NULL）
   → 成功：state=RINGING -> CONNECTING，记录 accepted_device_id
   → 向主叫 fanout ANSWER
6) 向 B 未接听的其他设备（排除 acceptedDeviceId）逐一 sendToDevice HANGUP(signalType=4)
7) 双方通过 CALL_SIGNAL(signalType=7/8/9) 交换 SDP/ICE（服务端纯透传，指定 accepted device）
   → ICE 连接成功后服务端推进状态至 CONNECTED
8) 结束：任一方 CALL_SIGNAL(signalType=4/HANGUP)
   → 服务端落最终态 + 生成 CALL_RECORD(209) 消息 + 广播 HANGUP 给对端所有设备
```

---

## 2. 关键约束与原则（企业级）

### 2.1 幂等性

- 所有 `CALL_SIGNAL` 事件必须带 `callId` + `header.messageId`
- 服务端必须按 `messageId` 幂等处理，重复事件不导致状态倒退
- 端侧 `messageId` 生成规则复用 `utils/message-utils.uts#generateMessageId`（snowflake-like 纯数字字符串）

### 2.2 状态机权威性（Server-Driven）

- 服务端是权威：端侧仅是 UI + 媒体控制，不做任何状态裁决
- 状态只允许单向推进，不允许回滚（任何状态变更必须经过 `ImCallService` 并落库）
- 端侧不自行决定"我被接听了"，必须等服务端下发 ANSWER/BUSY 确认

### 2.3 多端一致

- 同账号多端可同时响铃（通过 `NettyMessageSender.sendToUser` fanout 到所有在线设备）
- 只能一个端 ANSWER 成功（MySQL CAS 保证），其余端必须收到 `HANGUP(signalType=4)`
- 利用 `NettySession.deviceId` 标识接听设备，指定设备转发 SDP/ICE

### 2.4 超时治理

- RINGING 超时：30s，自动推进为 ENDED，status=MISSED
- CONNECTING（SDP/ICE 协商）超时：60s，自动推进为 ENDED，status=CANCELLED
- 超时任务实现方式：`@Scheduled` + `redissonClient.getLock().tryLock()`（见 §4.8）
  - 参考项目已有实现：`RedisPendingMessageResendJob`（framework 层同模式）

### 2.5 可灰度/可降级

- FeatureFlag：关闭时不展示入口、Processor 直接 ack 忽略（不处理媒体）
- 允许"仅信令联调"模式（`shengyu.im.rtc.signal-only-mode=true`）用于灰度排障

### 2.6 与现有 IM 规范对齐（强制）

- **Long 精度**：`callId` 在 proto 中为 `string`（已实现），前端统一用 `string`，后端 VO 中 `callerId/calleeId` 为 `Long` 型需 `@JsonSerialize(using = ToStringSerializer.class)` 输出
- **先存储后投递**：通话结束时生成的 `CALL_RECORD` 消息走「先落库后 fanout」门禁（与 TEXT/IMAGE 等七类消息一致）
- **会话预览**：`CALL_SIGNAL` 在 `buildConversationPreview()` 中已映射为 `"[通话]"`（`SystemMessageStorageServiceImpl:909`）；`CALL_RECORD(209)` 需新增分支（见 §5.4）

---

## 3. 信令协议设计（对齐已有实现）

### 3.1 消息类型

**已有**：`MessageType.CALL_SIGNAL = 206`（proto 与 Java 枚举均已定义）

**不新增 MessageType**，通过 `CallSignalMessage.signalType` 子类型区分：

| signalType | 枚举名 | 说明 | 方向 |
|-----------|--------|------|------|
| 1 | CALL | 发起呼叫 / 推送来电 | A -> Server -> B(多端) |
| 2 | ANSWER | 接听 | B -> Server -> A |
| 3 | REJECT | 拒绝 | B -> Server -> A |
| 4 | HANGUP | 挂断 / 取消 / 通知其他设备停止响铃 | 任一方 -> Server -> 对方(多端) |
| 5 | BUSY | 忙线（服务端生成，仅发给 B 未接听的设备） | Server -> B(未接听端) |
| 6 | SWITCH_CAMERA | 切换摄像头通知 | A <-> B（纯透传） |
| 7 | SDP_OFFER | WebRTC SDP offer | A -> Server -> B(accepted device) |
| 8 | SDP_ANSWER | WebRTC SDP answer | B(accepted device) -> Server -> A |
| 9 | ICE_CANDIDATE | WebRTC ICE candidate | 双向透传（accepted device 之间） |
| 10 | STATE_SYNC | 断线重连状态同步 | Server -> 端侧 |
| 11 | TIMEOUT | 超时（服务端生成） | Server -> A+B(多端) |

> **重要说明**：signalType=5 BUSY 仅用于多端裁决场景（B 的其他未接听设备）。当 B 整体拒绝/超时时，向 A 发 REJECT(3)/TIMEOUT(11)，向 B 其他设备发 **HANGUP(4)**（不是 TIMEOUT，TIMEOUT 是服务端超时机制的术语，不是对端通知的语义）。

### 3.2 Protobuf 定义（已落地）

```protobuf
// 文件: shengyu-framework/.../proto/im_message.proto
message CallSignalMessage {
  string callId = 1;       // 通话ID（UUID/simpleUUID）
  int32 callType = 2;      // 通话类型（1-语音 2-视频）
  int32 signalType = 3;    // 信令类型（见上表）
  int64 callerId = 4;      // 呼叫方ID
  int64 calleeId = 5;      // 被叫方ID
  string rejectReason = 6;  // 拒绝原因（signalType=3 时使用）
  string extraData = 7;    // JSON 扩展（用于 SDP/ICE 等 WebRTC 信令）
}
```

### 3.3 Header 约定

复用现有 IM `MessageHeader`：
- `messageId`：snowflake-like 纯数字字符串，用于幂等
- `messageType`：固定 `CALL_SIGNAL(206)`
- `senderId`：服务端从 session 覆盖（防伪造）
- `receiverId`：单聊对端 userId
- `tenantId`：服务端从 session 覆盖
- `timestamp`：服务端覆盖
- `sequence`：**通话信令不分配 sequence**；仅通话结束时的通话记录消息才分配
- `chatId`：仅通话结束时关联会话

**关键区别**：通话信令（signalType 1-11）为**瞬态事件**，不分配 sequence、不进入消息列表。仅通话结束时产生的**通话记录消息（CALL_RECORD=209）**才走标准消息存储链路。

### 3.4 extraData JSON 格式约定

#### SDP 信令（signalType=7/8）

```json
{
  "sdp": "v=0\r\no=- 46117...",
  "type": "offer"
}
```

#### ICE Candidate（signalType=9）

```json
{
  "candidate": "candidate:842163049 1 udp ...",
  "sdpMid": "0",
  "sdpMLineIndex": 0
}
```

#### STATE_SYNC（signalType=10，服务端下发）

```json
{
  "state": "RINGING",
  "callType": 1,
  "callerId": "123456",
  "calleeId": "789012",
  "startTime": 1711929600000,
  "acceptedDeviceId": null
}
```

#### 离线推送唤醒后 REST 拉取（Phase 1）

端侧收到离线推送后，通过 `GET /system/im/call/detail?callId={callId}` 查询当前通话状态，再据此决定是否展示来电 UI。

### 3.5 事件幂等与状态机

服务端状态机（仅允许单向推进）：

```
INIT -> RINGING -> CONNECTING -> CONNECTED -> ENDED
                      |
          RINGING -> ENDED（reject/timeout/busy/cancel/callee_offline）
```

- `INIT`：`initiateCall()` 落库时置
- `RINGING`：落库后 fanout 到被叫方在线设备完成后置
- `CONNECTING`：被叫某端 ANSWER 且通过 CAS 裁决后置
- `CONNECTED`：端侧 ICE 连通后服务端收到确认信号后置（端侧在 `onIceConnectionStateChange(connected)` 时发 `extraData={"connected":true}` 的 ANSWER 信令）
- `ENDED`：挂断/拒绝/超时/忙线/被叫离线，由 `end_reason` 区分

---

## 4. 服务端数据模型与实现

### 4.1 已有数据库表

**`im_call_record`**（已落地，DDL 见 `sql/mysql/1.0/im/ddl_im_tables.sql:442`）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint PK | 自增主键 |
| call_id | varchar(64) UK | 通话唯一标识（simpleUUID，32位无横线） |
| call_type | tinyint | 1-语音 2-视频 |
| caller_id | bigint | 呼叫方 |
| callee_id | bigint | 被叫方 |
| start_time | datetime | 呼叫发起时间（INIT）；接通后更新为实际接通时间 |
| end_time | datetime | 通话结束时间 |
| duration | int | 通话时长（秒），仅 status=ANSWERED 时有值 |
| status | tinyint | 1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消 |
| tenant_id | bigint | 租户 |

索引：`idx_tenant_call_id`（UK）、`idx_caller`、`idx_callee`、`idx_tenant`

### 4.2 待新增字段（Phase 0 必须，开工即执行）

```sql
ALTER TABLE `im_call_record`
  ADD COLUMN `state` varchar(20) NOT NULL DEFAULT 'INIT'
    COMMENT '状态机状态(INIT/RINGING/CONNECTING/CONNECTED/ENDED)' AFTER `status`,
  ADD COLUMN `end_reason` varchar(20) NULL DEFAULT NULL
    COMMENT '结束原因(HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/CALLEE_OFFLINE/ERROR)' AFTER `state`,
  ADD COLUMN `accepted_device_id` varchar(64) NULL DEFAULT NULL
    COMMENT '接听设备ID（CAS 裁决写入，用于 SDP/ICE 定向转发）' AFTER `end_reason`,
  ADD COLUMN `chat_id` bigint NULL DEFAULT NULL
    COMMENT '关联会话ID（通话结束时填入）' AFTER `accepted_device_id`,
  ADD COLUMN `record_message_id` bigint NULL DEFAULT NULL
    COMMENT '通话记录消息ID（CALL_RECORD=209 生成后回填）' AFTER `chat_id`;
```

### 4.3 待新增事件表（Phase 2 必须）

```sql
CREATE TABLE `im_call_event` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `call_id` varchar(64) NOT NULL COMMENT '通话ID',
  `event_id` varchar(64) NOT NULL COMMENT '事件ID（messageId，用于幂等）',
  `signal_type` tinyint NOT NULL COMMENT '信令类型',
  `sender_id` bigint NOT NULL COMMENT '发送者',
  `device_id` varchar(64) NULL COMMENT '设备ID',
  `payload_json` text NULL COMMENT '事件载荷（extraData）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tenant_id` bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uk_call_event`(`call_id`, `event_id`),
  INDEX `idx_call_id`(`call_id`, `create_time`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM通话事件流水表';
```

### 4.4 已有枚举

| 枚举类 | 文件位置 | 值 |
|--------|---------|-----|
| `ImCallTypeEnum` | `system-api/.../enums/im/ImCallTypeEnum.java` | VOICE(1), VIDEO(2) |
| `ImCallStatusEnum` | `system-api/.../enums/im/ImCallStatusEnum.java` | MISSED(1), ANSWERED(2), REJECTED(3), BUSY(4), CANCELLED(5) |

### 4.5 待新增枚举（Phase 0 必须）

```java
// system-api/.../enums/im/ImCallStateEnum.java
public enum ImCallStateEnum {
    INIT("INIT", "初始化"),
    RINGING("RINGING", "响铃中"),
    CONNECTING("CONNECTING", "连接中"),
    CONNECTED("CONNECTED", "通话中"),
    ENDED("ENDED", "已结束");
    // 含 code/name 字段 + 标准 getByCode 方法，对齐其他枚举风格
}

// system-api/.../enums/im/ImCallEndReasonEnum.java
public enum ImCallEndReasonEnum {
    HANGUP("HANGUP", "正常挂断"),
    REJECT("REJECT", "被拒绝"),
    TIMEOUT("TIMEOUT", "超时未接"),
    BUSY("BUSY", "忙线"),
    CANCEL("CANCEL", "主叫取消"),
    CALLEE_OFFLINE("CALLEE_OFFLINE", "被叫离线"),  // Phase 1 新增
    ERROR("ERROR", "异常结束");
}

// system-api/.../enums/im/ImCallSignalTypeEnum.java
public enum ImCallSignalTypeEnum {
    CALL(1, "呼叫"),
    ANSWER(2, "接听"),
    REJECT(3, "拒绝"),
    HANGUP(4, "挂断"),
    BUSY(5, "忙线"),
    SWITCH_CAMERA(6, "切换摄像头"),
    SDP_OFFER(7, "SDP Offer"),
    SDP_ANSWER(8, "SDP Answer"),
    ICE_CANDIDATE(9, "ICE Candidate"),
    STATE_SYNC(10, "状态同步"),
    TIMEOUT(11, "超时");
}
```

### 4.6 已有 Service 层

| 类 | 文件位置 | 说明 |
|-----|---------|------|
| `ImCallService` | `system-biz/.../service/im/ImCallService.java` | 接口 |
| `ImCallServiceImpl` | `system-biz/.../service/im/ImCallServiceImpl.java` | 实现，需重构 |
| `ImCallRecordDO` | `system-biz/.../dal/dataobject/im/ImCallRecordDO.java` | 数据对象 |
| `ImCallRecordMapper` | `system-biz/.../dal/mysql/im/ImCallRecordMapper.java` | DAO |

### 4.6.1 `ImCallServiceImpl` 现有问题（必须在 R0.3 修复）

| 问题 | 代码位置 | 修复方案 |
|------|---------|---------|
| `acceptCall` 直接 `updateById`，多端并发无保护 | `:71-73` | 改为 CAS UPDATE（`WHERE state='RINGING' AND accepted_device_id IS NULL`）+ 校验受影响行数 |
| `initiateCall` 未检测被叫是否在通话中 | `:33-53` | 调用前查 `WHERE (caller_id=? OR callee_id=?) AND state IN ('RINGING','CONNECTING','CONNECTED')` |
| 所有方法无状态机 guard | 各方法 | 每个方法前加 `assertState(allowedStates)` 防止非法状态操作 |
| `initiateCall` 落库后 state 无初始值 | `:38` | 新增字段后，insert 时 state=INIT，fanout 后再更新 state=RINGING |
| `forwardCallSignal` 仅打日志无实际逻辑 | `:134-148` | **废弃**：从 `ImCallService` 接口和实现中均删除此方法，转发逻辑统一在 Processor 完成 |

**重构后 `ImCallService` 接口新增的方法签名**（在原有 initiate/accept/reject/hangup/query 基础上新增）：

```java
/**
 * 忙线检测：被叫是否可以接受新来电（Phase 0 必须）
 * 查询条件：caller_id=calleeId OR callee_id=calleeId，state IN ('RINGING','CONNECTING','CONNECTED')
 */
boolean isCalleeAvailable(Long calleeId, Long tenantId);

/**
 * CAS 并发裁决接听（Phase 0 必须）
 * 执行：UPDATE im_call_record SET state='CONNECTING', accepted_device_id=#{deviceId}
 *       WHERE call_id=#{callId} AND state='RINGING' AND accepted_device_id IS NULL
 * @return ACCEPTED / BUSY / NOT_FOUND
 */
CallAnswerResult answerWithCas(String callId, Long userId, String deviceId);

/**
 * 统一结束入口（Phase 0 必须）
 * 兜底：若已经是 ENDED 则幂等返回，不重复操作
 * 执行：UPDATE state=ENDED, end_reason=?, end_time=now(), status=?, duration=? WHERE call_id=? AND state != 'ENDED'
 * @return 结束前的通话记录（用于生成 CALL_RECORD 消息）
 */
ImCallEndResult endCall(String callId, Long operatorUserId, ImCallEndReasonEnum endReason, ImCallStatusEnum finalStatus);

/**
 * 推进状态（仅允许单向推进，已在目标状态时幂等返回）
 */
boolean advanceState(String callId, ImCallStateEnum fromState, ImCallStateEnum toState);
```

**裁决结果枚举**（放在 `system-api` 或 `system-biz` dto 包）：

```java
public enum CallAnswerResult { ACCEPTED, BUSY, NOT_FOUND }
```

**CAS UPDATE 的 Mapper 方法**（`ImCallRecordMapper` 新增）：

```java
// XML: UPDATE im_call_record SET state='CONNECTING', accepted_device_id=#{deviceId}
//      WHERE call_id=#{callId} AND state='RINGING' AND accepted_device_id IS NULL AND deleted=0
int answerWithCas(@Param("callId") String callId, @Param("deviceId") String deviceId);

// XML: UPDATE im_call_record SET state=#{toState} WHERE call_id=#{callId} AND state=#{fromState} AND deleted=0
int advanceState(@Param("callId") String callId,
                 @Param("fromState") String fromState,
                 @Param("toState") String toState);

// XML: SELECT * FROM im_call_record
//      WHERE state IN <foreach collection="states" .../>
//      AND start_time < #{deadline} AND deleted=0
List<ImCallRecordDO> selectByStates(@Param("states") List<String> states,
                                    @Param("deadline") LocalDateTime deadline);

// 忙线检测（查询被叫是否已在活跃通话中）
// XML: SELECT COUNT(1) FROM im_call_record
//      WHERE (caller_id=#{userId} OR callee_id=#{userId})
//      AND state IN ('RINGING','CONNECTING','CONNECTED') AND deleted=0
int countActiveCallsByUser(@Param("userId") Long userId, @Param("tenantId") Long tenantId);
```

### 4.7 并发裁决（多端 accept）

`CALL_SIGNAL(signalType=2/ANSWER)` 到达服务端时：

1. 调用 `callSignalService.handleAnswer(callId, userId, session.deviceId)`
2. 内部执行 CAS：`callRecordMapper.answerWithCas(callId, deviceId)`
   - **受影响行数 = 1（成功）**：
     - 调用 `advanceState(callId, RINGING, CONNECTING)` 已在 CAS 中一并完成
     - 向主叫 `sendToUser(callerId, CALL_SIGNAL(signalType=2/ANSWER, callId))`
     - 遍历 `sessionManager.getSessionsByUserId(calleeId)` 中 `deviceId != acceptedDeviceId` 的设备，逐一 `sendToDevice(otherDeviceId, CALL_SIGNAL(signalType=4/HANGUP, callId))`（**不是 BUSY，BUSY 仅用于另一个 CAS 失败者**）
   - **受影响行数 = 0（失败，已被其他设备抢先）**：
     - 向当前设备 `sendToDevice(session.deviceId, CALL_SIGNAL(signalType=5/BUSY, callId))`

> **关键语义区分**：
> - `BUSY(5)` = "你的 ANSWER 被 CAS 拒绝了，有另一个设备抢先接了"，仅发给 CAS 失败的那一个设备
> - `HANGUP(4)` = "通话已被你的另一设备接听，请停止响铃"，发给其他所有未参与 CAS 的设备

### 4.8 超时任务

**架构决策**：放在 `module-system` 层，使用 `@Scheduled` + Redisson `tryLock()` 防多实例重复执行。

> **参考项目已有实现**：`RedisPendingMessageResendJob`（`shengyu-framework/shengyu-spring-boot-starter-mq/.../RedisPendingMessageResendJob.java`）——完全相同的 `@Scheduled` + `redissonClient.getLock(LOCK_KEY).tryLock()` 模式。

**位置**：`system-biz/.../service/im/job/ImCallTimeoutJob.java`（对齐已有的 `ImVoicePlayCleanupJob` 位置）

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class ImCallTimeoutJob {

    private static final String LOCK_KEY = "im:call:timeout:lock";

    private final ImCallRecordMapper callRecordMapper;
    private final NettyMessageSender messageSender;
    // 通过 SPI 接口注入，避免直接依赖 ImCallServiceImpl
    private final CallSignalService callSignalService;
    private final RedissonClient redissonClient;

    @Value("${shengyu.im.rtc.ringing-timeout-seconds:30}")
    private int ringTimeoutSec;

    @Value("${shengyu.im.rtc.connecting-timeout-seconds:60}")
    private int connectTimeoutSec;

    /**
     * 每 5 秒扫描一次超时通话（Redisson tryLock 防多实例重复执行）
     */
    @Scheduled(fixedDelay = 5000)
    public void scanTimeout() {
        RLock lock = redissonClient.getLock(LOCK_KEY);
        if (!lock.tryLock()) {
            return;  // 另一实例正在执行，直接跳过
        }
        try {
            scanRinging();
            scanConnecting();
        } catch (Exception e) {
            log.error("[ImCallTimeout] 扫描超时通话异常", e);
        } finally {
            lock.unlock();
        }
    }

    private void scanRinging() {
        LocalDateTime deadline = LocalDateTime.now().minusSeconds(ringTimeoutSec);
        List<ImCallRecordDO> list = callRecordMapper.selectByStates(
            List.of(ImCallStateEnum.RINGING.getCode()), deadline);
        for (ImCallRecordDO record : list) {
            TenantUtils.execute(record.getTenantId(), () -> {
                ImCallEndResult result = callSignalService.handleTimeout(record.getCallId());
                if (result != null) {  // null 表示已被其他操作抢先结束
                    broadcastTimeout(record);
                    log.info("[ImCallTimeout] RINGING 超时, callId={}", record.getCallId());
                }
            });
        }
    }

    private void scanConnecting() {
        LocalDateTime deadline = LocalDateTime.now().minusSeconds(connectTimeoutSec);
        List<ImCallRecordDO> list = callRecordMapper.selectByStates(
            List.of(ImCallStateEnum.CONNECTING.getCode()), deadline);
        for (ImCallRecordDO record : list) {
            TenantUtils.execute(record.getTenantId(), () -> {
                ImCallEndResult result = callSignalService.handleTimeout(record.getCallId());
                if (result != null) {
                    broadcastTimeout(record);
                    log.info("[ImCallTimeout] CONNECTING 超时, callId={}", record.getCallId());
                }
            });
        }
    }

    private void broadcastTimeout(ImCallRecordDO record) {
        // 向主叫和被叫所有设备广播 TIMEOUT
        sendCallSignalToUser(record.getCallerId(), record, ImCallSignalTypeEnum.TIMEOUT.getCode(), record.getTenantId());
        sendCallSignalToUser(record.getCalleeId(), record, ImCallSignalTypeEnum.TIMEOUT.getCode(), record.getTenantId());
    }

    private void sendCallSignalToUser(Long userId, ImCallRecordDO record, int signalType, Long tenantId) {
        CallSignalMessage body = CallSignalMessage.newBuilder()
            .setCallId(record.getCallId())
            .setCallType(record.getCallType())
            .setSignalType(signalType)
            .setCallerId(record.getCallerId())
            .setCalleeId(record.getCalleeId())
            .build();
        messageSender.sendToUser(userId, MessageType.CALL_SIGNAL, body,
            record.getCallerId(), record.getCalleeId(), null, tenantId, null);
    }
}
```

---

## 5. 服务端待实现清单（按文件级）

### 5.0 架构分层约束（必读，开工前冻结）

**关键约束**：`shengyu-framework` 不允许依赖 `shengyu-module-system`。`CallSignalMessageProcessor` 在 framework 层，`ImCallService` 在 module-system 层，两者不能直接调用。

**解决方案：复用已有 SPI 模式**，类似 `MessageStorageService`（framework 层定义接口，module-system 层注入实现）：

```
framework 层定义：
  CallSignalService（接口）
  位置：shengyu-framework/.../websocket/spi/CallSignalService.java

module-system 层实现：
  SystemCallSignalServiceImpl
  位置：system-biz/.../service/im/spi/SystemCallSignalServiceImpl.java
  → 注入 ImCallService、ImCallRecordMapper、NettyMessageSender、NettySessionManager
```

`CallSignalService` 接口定义（framework 层）：

```java
// 位置：shengyu-framework/.../websocket/spi/CallSignalService.java
public interface CallSignalService {

    /** 处理主叫发起呼叫，返回生成的 callId */
    String handleCall(Long callerId, Long calleeId, Integer callType, Long tenantId);

    /** 处理被叫接听，返回裁决结果 */
    CallAnswerResult handleAnswer(String callId, Long userId, String deviceId);

    /** 处理拒绝（被叫主动拒绝） */
    void handleReject(String callId, Long userId, String reason);

    /** 处理挂断（主叫取消 / 正常挂断）*/
    ImCallEndResult handleHangup(String callId, Long userId);

    /** 服务端超时处理（ImCallTimeoutJob 调用） */
    ImCallEndResult handleTimeout(String callId);

    /** 查询当前通话状态（断线重连 STATE_SYNC 用） */
    CallStateSnapshot queryState(String callId, Long userId);

    /** 校验是否允许发起通话（忙线检测） */
    boolean isCalleeAvailable(Long calleeId, Long tenantId);

    /** 推进通话状态至 CONNECTED（端侧 ICE 连通后上报） */
    void markConnected(String callId, Long userId);
}
```

### 5.1 消息处理器（关键缺失）

**`CallSignalMessageProcessor.java`**（待新建）

位置：`shengyu-framework/.../websocket/core/processor/impl/CallSignalMessageProcessor.java`

注入：`NettySessionManager`、`NettyMessageSender`、`CallSignalService`（SPI，不是 ImCallService）

注册方式（在 `NettyAutoConfiguration.java` 中）：

```java
@Bean
public CallSignalMessageProcessor callSignalMessageProcessor(
        NettySessionManager sessionManager,
        NettyMessageSender messageSender,
        CallSignalService callSignalService,
        MessageProcessorFactory processorFactory) {
    CallSignalMessageProcessor processor = new CallSignalMessageProcessor(
        sessionManager, messageSender, callSignalService);
    processorFactory.registerProcessor(MessageType.CALL_SIGNAL, processor);
    log.info("[Netty] 注册通话信令处理器 CALL_SIGNAL(206)");
    return processor;
}
```

**注意**：`CallSignalMessageProcessor` **不注入** `MessageStorageService`——通话信令为瞬态事件，不走「先存储后投递」门禁。

**各 signalType 处理逻辑（权威伪代码）**：

```
公共前置（所有 signalType 均执行）：
  0. 若 shengyu.im.rtc.enabled=false → 回复 ACK(feature_disabled) 并 return
  1. 从 session 取 userId、deviceId、tenantId（服务端覆盖，防伪造）
  2. 解析 CallSignalMessage body

signalType=1 CALL（主叫发起）：
  1. 若 !callSignalService.isCalleeAvailable(calleeId, tenantId)
     → sendCallSignal(callerId, BUSY, callId, tenantId, session.deviceId) 并 return
  2. callId = callSignalService.handleCall(callerId, calleeId, callType, tenantId)
  3. fanout 到被叫所有在线 session：
     sessions = sessionManager.getSessionsByUserId(calleeId)
     if sessions.isEmpty():
       // Phase 0：被叫全部离线 → 立即结束通话，状态 ENDED/CALLEE_OFFLINE
       callSignalService.handleHangup(callId, callerId)  // 用 CANCEL 语义
       // Phase 1：触发离线推送（见 §11）
       return
     else:
       for each session: sendToDevice(session.deviceId, CALL_SIGNAL(1, callId))
  4. 回显给主叫确认（携带 callId）：sendCallSignal(callerId, CALL, callId, tenantId, session.deviceId)
     // 主叫需要这个 callId 来后续发 SDP/ANSWER 等

signalType=2 ANSWER（被叫接听）：
  1. result = callSignalService.handleAnswer(callId, userId, session.deviceId)
  2. if result == ACCEPTED:
     a. 向主叫：sendToUser(callerId, CALL_SIGNAL(signalType=2/ANSWER, callId))
     b. 向被叫其他设备（排除 acceptedDeviceId）逐一 sendToDevice:
        sessions = sessionManager.getSessionsByUserId(calleeId)
        for s in sessions where s.deviceId != session.deviceId:
          sendToDevice(s.deviceId, CALL_SIGNAL(signalType=4/HANGUP, callId))
  3. if result == BUSY:
     sendToDevice(session.deviceId, CALL_SIGNAL(signalType=5/BUSY, callId))
  4. if result == NOT_FOUND:
     sendToDevice(session.deviceId, CALL_SIGNAL(signalType=11/TIMEOUT, callId))  // 通话已结束

signalType=3 REJECT（被叫拒绝）：
  1. callSignalService.handleReject(callId, userId, rejectReason)
  2. 向主叫：sendToUser(callerId, CALL_SIGNAL(signalType=3/REJECT, rejectReason))
  3. 向被叫其他在线设备（排除当前 session）：sendToDevice(s.deviceId, CALL_SIGNAL(signalType=4/HANGUP, callId))
     // 明确使用 HANGUP(4)，不是 TIMEOUT(11)；语义：你的另一设备已拒绝，停止响铃

signalType=4 HANGUP（挂断 / 主叫取消）：
  1. result = callSignalService.handleHangup(callId, userId)
  2. 判断对端 userId（若 userId==callerId 则 otherUserId=calleeId，反之亦然）
  3. 向对端所有设备：sendToUser(otherUserId, CALL_SIGNAL(signalType=4/HANGUP, callId, endReason))
  4. 向己方其他设备：遍历 sessionManager.getSessionsByUserId(userId) 中 deviceId != session.deviceId 的设备发 HANGUP
  5. 通话记录消息生成（见 §5.4）

signalType=7 SDP_OFFER / signalType=8 SDP_ANSWER（WebRTC 协商，定向透传）：
  1. state = callSignalService.queryState(callId, userId)
  2. 若 state != CONNECTING/CONNECTED → 忽略（乱序保护）
  3. 向对端 acceptedDevice 定向转发：
     record = callRecordMapper.selectByCallId(callId)
     if userId == callerId:
       targetDeviceId = record.getAcceptedDeviceId()  // A→B
     else:
       // B→A：A 的主动设备（可从 session 中查 callerId 的最新活跃 session）
       targetSession = sessionManager.getLatestSessionByUserId(record.getCallerId())
       targetDeviceId = targetSession.deviceId
     sendToDevice(targetDeviceId, 原消息体（保留 extraData）)
  4. 不落库，不修改状态

signalType=9 ICE_CANDIDATE（纯透传，同 SDP 定向逻辑）：
  按上述 SDP 定向转发逻辑执行，无需校验通话状态（ICE 候选可在任意时刻交换）

signalType=10 STATE_SYNC（服务端主动下发，Processor 收到客户端发来的忽略）：
  收到则 ack 忽略

signalType=6 SWITCH_CAMERA（纯透传）：
  直接向对端 sendToUser（或 accepted device），不做状态校验
```

**发送 CALL_SIGNAL 的统一工具方法**（Processor 内部私有方法）：

```java
/**
 * 发送 CALL_SIGNAL 给指定用户（fanout 到该 userId 所有在线 session）
 * 参数映射：senderId=callerId, receiverId=calleeId
 */
private void sendCallSignalToUser(Long toUserId, String callId, Integer callType,
                                   Integer signalType, Long callerId, Long calleeId,
                                   String rejectReason, String extraData, Long tenantId) {
    CallSignalMessage body = CallSignalMessage.newBuilder()
        .setCallId(callId)
        .setCallType(callType != null ? callType : 0)
        .setSignalType(signalType)
        .setCallerId(callerId)
        .setCalleeId(calleeId)
        .setRejectReason(rejectReason != null ? rejectReason : "")
        .setExtraData(extraData != null ? extraData : "")
        .build();
    // sendToUser 参数说明：
    // userId=toUserId, messageType=CALL_SIGNAL, body=body,
    // senderId=callerId, receiverId=calleeId, groupId=null, tenantId=tenantId, messageId=null（自动生成）
    messageSender.sendToUser(toUserId, MessageType.CALL_SIGNAL, body,
        callerId, calleeId, null, tenantId, null);
}

/**
 * 发送 CALL_SIGNAL 给指定设备（用于 CAS 裁决后的设备级精准推送）
 */
private void sendCallSignalToDevice(String deviceId, Long deviceUserId, String callId, Integer callType,
                                     Integer signalType, Long callerId, Long calleeId,
                                     String extraData, Long tenantId) {
    CallSignalMessage body = CallSignalMessage.newBuilder()
        .setCallId(callId)
        .setCallType(callType != null ? callType : 0)
        .setSignalType(signalType)
        .setCallerId(callerId)
        .setCalleeId(calleeId)
        .setExtraData(extraData != null ? extraData : "")
        .build();
    messageSender.sendToDevice(deviceUserId, deviceId, MessageType.CALL_SIGNAL, body);
}
```

### 5.2 STATE_SYNC 触发时机（断线重连后）

**问题**：用户断线重连后执行 AUTH_REQ，若此时他参与的通话仍处于 RINGING/CONNECTING/CONNECTED，端侧无法感知，UI 陷入空白。

**解决方案**：在 `WebSocketAuthHandler`（或处理 AUTH_REQ 的 Processor）认证成功回调中，增加以下逻辑：

```java
// 认证成功后（AUTH_REQ 处理完毕，session 已建立）
// 查询该用户是否有活跃通话
CallStateSnapshot snapshot = callSignalService.queryState(null, userId);  // callId=null 表示查用户维度
if (snapshot != null && !snapshot.isEnded()) {
    // 下发 STATE_SYNC，让端侧恢复通话 UI
    sendCallSignalToUser(userId, snapshot.getCallId(), snapshot.getCallType(),
        ImCallSignalTypeEnum.STATE_SYNC.getCode(), snapshot.getCallerId(), snapshot.getCalleeId(),
        null, snapshot.toExtraDataJson(), session.getTenantId());
}
```

> `CallSignalService.queryState(null, userId)` 需在接口和实现中支持按 userId 维度查最近一条活跃通话。

### 5.3 REST API（待新建）

位置：`shengyu-module-system/.../controller/app/im/AppImCallController.java`

| 能力 | HTTP URL | 方法 | 说明 |
|------|----------|------|------|
| 通话记录列表 | GET /system/im/call/records | getCallRecords | 按 userId 分页查询 |
| 两人通话记录 | GET /system/im/call/records-between | getCallRecordsBetween | 按 userId1+userId2 查询 |
| 通话详情 | GET /system/im/call/detail?callId= | getCallDetail | 按 callId 查询（离线唤醒后端侧用此接口恢复状态） |
| TURN 配置 | GET /system/im/call/turn-config | getTurnConfig | 返回 STUN/TURN 服务器配置 |

**说明**：通话的发起/接听/拒绝/挂断全部走 WS 信令，不走 REST。REST 仅用于查询通话记录和获取 TURN 配置。

### 5.4 通话记录消息生成

**决策（冻结）**：**新增 `CALL_RECORD = 209`**，不复用 CALL_SIGNAL(206)。理由：信令消息为瞬态，记录消息需要 sequence、进消息列表、展示 UI，语义完全不同。

**proto 需补充**（`im_message.proto`，Phase 1 开工时添加）：

```protobuf
// MessageType 枚举中新增（紧跟 CALL_SIGNAL = 206 附近）:
CALL_RECORD = 209;  // 通话记录消息（通话结束后生成，进消息列表）

// message 定义：
message CallRecordMessage {
  string callId = 1;
  int32 callType = 2;   // 1-语音 2-视频
  int32 duration = 3;   // 通话时长（秒），仅 status=ANSWERED 有值
  int32 status = 4;     // 对应 ImCallStatusEnum 的 code
  string endReason = 5; // 对应 ImCallEndReasonEnum 的 code
  int64 callerId = 6;
  int64 calleeId = 7;
}
```

**触发时机**：`SystemCallSignalServiceImpl.endCall()` 最后调用 `MessageStorageService.saveMessageWithResult()`，由服务端构造消息（非端侧发送）。

**会话预览**（`SystemMessageStorageServiceImpl.buildConversationPreview()`）需补充：

```java
case CALL_RECORD:
    CallRecordMessage record = CallRecordMessage.parseFrom(body.getBody());
    if (record.getStatus() == ImCallStatusEnum.ANSWERED.getStatus()) {
        return record.getCallType() == 1 ? "[语音通话]" : "[视频通话]";
    } else if (record.getStatus() == ImCallStatusEnum.MISSED.getStatus()) {
        return "[未接来电]";
    } else {
        return "[通话]";
    }
```

**聊天消息列表气泡文案（主叫/被叫视角区分，参考微信规范）**：

端侧渲染 `CALL_RECORD` 时，根据 `callerId == currentUserId` 判断视角：

| `status` | 主叫（己方发起）视角 | 被叫（己方接收）视角 |
|---------|----------------|----------------|
| ANSWERED(2) | `已拨出语音/视频通话 MM:SS` | `语音/视频通话 MM:SS` |
| MISSED(1) | `对方未接听` | `未接来电`（红色文字） |
| REJECTED(3) | `对方已拒绝` | `已拒绝` |
| CANCELLED(5) | `已取消` | `对方已取消` |
| BUSY(4) | `对方忙线` | `忙线` |

### 5.5 TURN 配置（待实现）

**国内 STUN/TURN 服务器说明**：

> ⚠️ `stun.l.google.com:19302` 在中国大陆网络环境大概率不可达（GFW），**生产环境严禁使用**。

**推荐方案**（按成本从低到高）：
1. **Phase 0/测试阶段**：使用国内可用的公共 STUN 服务器备用列表（见下）
2. **Phase 1/生产**：在阿里云/腾讯云部署 `coturn`（开源 STUN/TURN 实现），具体见 §12

```yaml
# application.yaml 新增
shengyu:
  im:
    rtc:
      enabled: false  # 灰度开关，默认关闭
      signal-only-mode: false  # Phase 0 联调时置为 true
      stun-servers:
        # 国内可用的公共 STUN（仅用于测试，生产请换自建 coturn）
        - "stun:stun.miwifi.com:3478"
        - "stun:stun.stunprotocol.org:3478"
        - "stun:stun.voipbuster.com:3478"
      turn-servers:
        # Phase 1 生产替换为自建 coturn 地址
        - url: "turn:your-coturn-server.example.com:3478"
          username: "${TURN_USERNAME}"
          credential: "${TURN_CREDENTIAL}"
      ringing-timeout-seconds: 30
      connecting-timeout-seconds: 60
```

### 5.6 已有 ErrorCode

```java
// ErrorCodeConstants.java（已有）
CALL_RECORD_NOT_EXISTS = new ErrorCode(1_002_030_500, "通话记录不存在");
CALL_PERMISSION_DENIED = new ErrorCode(1_002_030_501, "无权操作该通话");
```

待新增（Phase 0）：
```java
CALL_ALREADY_IN_PROGRESS = new ErrorCode(1_002_030_502, "对方正在通话中");
CALL_STATE_INVALID       = new ErrorCode(1_002_030_503, "通话状态不允许此操作");
CALL_FEATURE_DISABLED    = new ErrorCode(1_002_030_504, "音视频通话功能未启用");
CALL_CALLEE_OFFLINE      = new ErrorCode(1_002_030_505, "被叫方不在线");
```

---

## 6. 端侧实现清单

### 6.1 已有基础

| 已有项 | 位置 | 说明 |
|--------|------|------|
| `CALL_SIGNAL = 206` | `utils/websocket.uts:75` | MessageType 枚举已定义 |
| WS 消息收发 | `utils/websocket.uts` | JSON/PB 双栈发送能力 |
| messageId 生成 | `utils/message-utils.uts` | snowflake-like 纯数字 |

### 6.2 待新建文件

| 文件 | 位置 | 职责 | Phase |
|------|------|------|-------|
| `call-service.uts` | `services/call-service.uts` | 通话状态管理、信令收发、超时计时 | 0 |
| `call-timer.uts` | `utils/call-timer.uts` | 通话计时器（计秒 + 格式化 `MM:SS`） | 0 |
| `call-permission.uts` | `utils/call-permission.uts` | 麦克风/摄像头权限检查与请求封装 | 0 |
| `call.uts` | `api/call.uts` | REST API 封装（通话记录查询、TURN 配置获取） | 0 |
| `call.uvue` | `pages/message/call.uvue` | 通话 UI 主页面 | 0 |
| `call-float-window.uts` | `utils/call-float-window.uts` | 悬浮窗（Native Plugin 调用封装） | 1 |
| `webrtc-manager.uts` | `utils/webrtc-manager.uts` | PeerConnection 生命周期、SDP/ICE 管理 | 1 |

### 6.3 端侧通话状态机

```
IDLE -> OUTGOING_RINGING -> CONNECTING -> CONNECTED -> ENDED
IDLE -> INCOMING_RINGING -> CONNECTING -> CONNECTED -> ENDED
              ↓
           ENDED（超时/拒绝/取消/忙线）
```

### 6.4 WS 信令接收分发（`call-service.uts` 核心逻辑）

```typescript
// call-service.uts 中的 WS 消息分发
function handleCallSignal(msg: CallSignalMessage) {
  const { signalType, callId, callType, callerId, calleeId, extraData } = msg

  switch (signalType) {
    case 1: // CALL - 来电
      if (currentUserId === calleeId) {
        callState.callId = callId
        callState.callType = callType
        callState.callerId = callerId
        callState.status = 'INCOMING_RINGING'
        // 跳转来电页面（若不在 call.uvue）
        if (!isOnCallPage()) {
          uni.navigateTo({ url: `/pages/message/call?callId=${callId}&type=incoming` })
        }
      }
      break

    case 2: // ANSWER - 己方拨出后对方接听
      if (currentUserId === callerId) {
        callState.status = 'CONNECTING'
        // Phase 1: 初始化 PeerConnection，发送 SDP Offer
      }
      break

    case 3: // REJECT
      endCallUI('REJECT')
      break

    case 4: // HANGUP（含：对方挂断 / 其他设备已接听通知本设备停止响铃）
      endCallUI('HANGUP')
      break

    case 5: // BUSY（己方 ANSWER 被 CAS 拒绝，说明另一设备已抢先接听）
      endCallUI('BUSY')
      break

    case 7: // SDP_OFFER (Phase 1)
    case 8: // SDP_ANSWER (Phase 1)
    case 9: // ICE_CANDIDATE (Phase 1)
      webRTCManager.handleSignal(signalType, JSON.parse(extraData))
      break

    case 10: // STATE_SYNC（断线重连恢复）
      const snapshot = JSON.parse(extraData)
      restoreCallStateFromSnapshot(snapshot)
      break

    case 11: // TIMEOUT
      endCallUI('TIMEOUT')
      break
  }
}
```

### 6.5 离线推送处理（Phase 1）

当端侧从后台被推送唤醒时：

```typescript
// App.uvue 或推送插件回调
function onNotificationReceived(payload: object) {
  const { type, callId, callerId, callType } = payload
  if (type === 'CALL_INVITE' && callId) {
    // 通过 REST 拉取当前通话状态（避免推送到达时通话已超时/取消）
    getCallDetail(callId).then(detail => {
      if (detail && detail.state === 'RINGING') {
        // 通话仍然有效，展示来电 UI
        uni.navigateTo({ url: `/pages/message/call?callId=${callId}&type=incoming` })
      }
      // 若 state 已是 ENDED，静默忽略
    })
  }
}
```

### 6.6 WebRTC 集成要点（Phase 1）

- **Android/iOS**：uni-app x 需要 Native Plugin 封装 WebRTC
  - **Phase 1 开工前必须做 Spike（1-2天）**验证 Native Plugin 接入可行性
  - Android: `org.webrtc:google-webrtc` 或 libwebrtc；iOS: WebRTC.framework
- **Web**：直接使用 `RTCPeerConnection` API
  - 条件编译：`// #ifdef WEB` / `// #ifdef APP-ANDROID` / `// #ifdef APP-IOS`
- **STUN/TURN 配置**：通话前 `GET /system/im/call/turn-config` 获取，存入 `iceServers` 参数

### 6.7 音频/视频采集约束

```typescript
// 语音通话
const audioConstraints = { audio: true, video: false }

// 视频通话
const videoConstraints = {
  audio: true,
  video: { width: { ideal: 720 }, height: { ideal: 1280 }, frameRate: { ideal: 30 } }
}
```

---

## 7. 可观测性与排障

### 7.1 日志

- 服务端每条事件日志必须带：`tenantId/userId/callId/signalType/state`
- `CallSignalMessageProcessor` 入口统一 `log.info("[CallSignal] callId={}, signalType={}, from={}, state={}", callId, signalType, userId, currentState)`
- 状态变更时 `log.info("[CallState] callId={}, {} -> {}, reason={}", callId, oldState, newState, endReason)`
- CAS 裁决结果：`log.info("[CallCAS] callId={}, deviceId={}, result={}", callId, deviceId, result)`

### 7.2 指标（建议，Phase 2）

| 指标名 | 说明 |
|--------|------|
| `im_call_invite_total` | 发起通话总数 |
| `im_call_answer_total` | 接听总数 |
| `im_call_connect_success_total` | SDP/ICE 连接成功数 |
| `im_call_end_total{reason}` | 通话结束总数（按 endReason 标签） |
| `im_call_timeout_total` | 超时总数 |
| `im_call_duration_seconds` | 通话时长直方图 |
| `im_call_callee_offline_total` | 被叫离线丢失通话数 |

### 7.3 Trace

- 按 `callId` 聚合事件流（查 `im_call_event` 表，Phase 2）
- 端侧 WebRTC `getStats()` 数据可选上报（Phase 2）

---

## 8. 灰度与开关

- **全局开关**：`shengyu.im.rtc.enabled`（默认 false），Processor 收到 CALL_SIGNAL 时检查，关闭则返回 CALL_FEATURE_DISABLED
- **端侧入口控制**：端侧读取配置后决定是否展示通话按钮
- **仅信令模式**：`shengyu.im.rtc.signal-only-mode=true`（Phase 0 联调用，媒体层不启用）
- 后续可扩展：user 白名单、deviceType 策略（如仅 App 支持通话，Web 端不展示）

---

## 9. 验收用例

### Phase 0（仅信令）

| 用例 | 验收标准 |
|------|---------|
| A 呼叫 B（B 在线） | B 所有在线设备收到 CALL_SIGNAL(1)，`im_call_record` 落库，state=RINGING |
| A 呼叫 B（B 全部离线） | 服务端感知无 session，立即结束通话 ENDED/CALLEE_OFFLINE，A 收到错误提示 |
| B 接听 | A 收到 ANSWER(2)，state 推进 RINGING -> CONNECTING |
| B 拒绝 | A 收到 REJECT(3)，B 其他设备收到 HANGUP(4)，state ENDED/REJECT |
| 超时 | B 不操作 30s，A+B 所有设备收到 TIMEOUT(11)，state ENDED/TIMEOUT |
| 多端裁决 | B 两台设备同时 ANSWER，仅一台收到服务端确认，另一台收到 BUSY(5)，主叫收到 ANSWER(2) |
| B 另一台已有设备停铃 | B 接听后，其他 B 设备收到 HANGUP(4)（不是 BUSY） |
| 主叫取消 | A 在 B 接听前 HANGUP(4)，B 所有设备收到 HANGUP(4)，state ENDED/CANCEL |
| 幂等 | 相同 messageId 重复发送，state 不倒退，不重复落库 |
| 断线重连 STATE_SYNC | B 断线重连后，若通话仍处于 RINGING，服务端自动下发 STATE_SYNC(10) |

### Phase 1（音频通话）

| 用例 | 验收标准 |
|------|---------|
| 1v1 音频 | 双方建立 WebRTC 连接，音频正常传输 |
| 挂断 | 任一方挂断，双方 UI 结束，`im_call_record` 记录时长，聊天记录出现 CALL_RECORD 气泡 |
| 通话中断线恢复 | B 断网 10s 恢复，通过 ICE Restart 恢复媒体流 |
| 通话记录 | 通话结束后聊天记录中出现通话记录气泡，文案符合主叫/被叫视角 |
| 离线推送唤醒 | B 完全离线，A 发起通话，B 收到推送，点击打开 App，能展示来电 UI |
| TURN 配置 | 端侧获取 TURN 配置成功，ICE 通过 TURN 中继建立连接 |

### Phase 2（视频 + 增强）

| 用例 | 验收标准 |
|------|---------|
| 1v1 视频 | 双方建立视频连接，画面正常 |
| 音视频切换 | 通话中可切换语音/视频模式 |
| 弱网降级 | 网络差时自动降低分辨率/帧率 |
| 质量统计 | `getStats()` 数据可在端侧查看 |

---

## 10. 实施计划（阶段化）

### Phase 0：仅信令（不启用媒体）

**目标**：验证状态机/多端/幂等/超时/断线重连

| # | 任务 | 涉及文件 | 依赖 |
|---|------|---------|------|
| R0.1 | 新增 `ImCallSignalTypeEnum`/`ImCallStateEnum`/`ImCallEndReasonEnum` | `system-api/.../enums/im/` | - |
| R0.2 | `im_call_record` 执行 ALTER TABLE（5个新字段）+ 更新 `ImCallRecordDO` | DDL + DO | - |
| R0.3 | 重构 `ImCallServiceImpl`：删除 `forwardCallSignal`，新增 `isCalleeAvailable/answerWithCas/endCall/advanceState/markConnected` | `ImCallService.java` + `ImCallServiceImpl.java` | R0.1, R0.2 |
| R0.3.1 | `ImCallRecordMapper` 新增 4 个方法：`answerWithCas/advanceState/selectByStates/countActiveCallsByUser` + XML | `ImCallRecordMapper.java` + mapper XML | R0.2 |
| R0.4 | 新建 framework 层 `CallSignalService` SPI 接口 | `websocket/spi/CallSignalService.java` | R0.3 |
| R0.5 | 新建 `SystemCallSignalServiceImpl`（SPI 实现） | `service/im/spi/SystemCallSignalServiceImpl.java` | R0.3, R0.4 |
| R0.6 | 新建 `CallSignalMessageProcessor` + 注册到 `NettyAutoConfiguration` | `processor/impl/CallSignalMessageProcessor.java` + `NettyAutoConfiguration.java` | R0.4, R0.5 |
| R0.7 | 新建 `ImCallTimeoutJob` | `service/im/job/ImCallTimeoutJob.java` | R0.5 |
| R0.8 | 新建 `AppImCallController`（通话记录查询 + turn-config） | `controller/app/im/AppImCallController.java` | R0.3 |
| R0.9 | 补充 application.yaml `shengyu.im.rtc` 配置节 | `application.yaml` | - |
| R0.10 | 新增 4 个 ErrorCode | `ErrorCodeConstants.java` | - |
| R0.11 | AUTH_REQ 成功后增加 STATE_SYNC 下发逻辑 | 认证处理器 | R0.5 |
| R0.12 | 端侧 `call-service.uts`（Phase 0 仅信令，无媒体） | `services/call-service.uts` | R0.6 |
| R0.13 | 端侧 `call.uvue`（来电/拨号 UI，Phase 0 无媒体画面） | `pages/message/call.uvue` | R0.12 |
| R0.14 | 端侧 `api/call.uts`（REST 封装） | `api/call.uts` | R0.8 |

### Phase 1：接入 WebRTC，1v1 音频 + 离线推送

| # | 任务 | 涉及文件 | 依赖 |
|---|------|---------|------|
| R1.0 | **WebRTC Native Plugin Spike（1-2天）**：验证 uni-app x 接入可行性 | - | - |
| R1.1 | proto 新增 `CALL_RECORD=209` 和 `CallRecordMessage` | `im_message.proto` | - |
| R1.2 | Java `MessageType.CALL_RECORD(209)` 枚举 + `CallRecordMessage` DTO | `MessageType.java` | R1.1 |
| R1.3 | `SystemCallSignalServiceImpl.endCall()` 生成 `CALL_RECORD` 消息 | `SystemCallSignalServiceImpl.java` | R1.1, R1.2 |
| R1.4 | `SystemMessageStorageServiceImpl.buildConversationPreview()` 新增 `CALL_RECORD` 分支 | `SystemMessageStorageServiceImpl.java` | R1.2 |
| R1.5 | 部署 coturn，配置 `application.yaml` turn-servers | `application.yaml` + 运维 | - |
| R1.6 | `GET /system/im/call/turn-config` 实现 | `AppImCallController.java` | R1.5 |
| R1.7 | 端侧 `webrtc-manager.uts`（Native Plugin 封装） | `utils/webrtc-manager.uts` | R1.0 |
| R1.8 | SDP/ICE 信令透传闭环（Processor 定向转发） | `CallSignalMessageProcessor.java` | R1.7 |
| R1.9 | 通过 `ImCallPushService` 实现离线来电推送（详见 §11.9） | `SystemCallSignalServiceImpl.java` | R0.5, P1.6 |
| R1.10 | 端侧离线推送接收 + REST 状态查询恢复来电 UI | `App.uvue` / 推送插件 | R0.8 |
| R1.11 | 端侧 `call-float-window.uts`（悬浮窗） | `utils/call-float-window.uts` | R1.7 |
| R1.12 | 联调：Android + iOS + Web 1v1 音频全链路验收 | 全链路 | R1.1-R1.11 |

### Phase 2：视频、弱网优化、可观测增强

| # | 任务 |
|---|------|
| R2.1 | 视频采集与渲染（摄像头画面、PiP 小窗） |
| R2.2 | 音视频切换（SWITCH_CAMERA 信令 + 媒体轨道切换） |
| R2.3 | 弱网自适应（码率/分辨率调整，ICE Restart） |
| R2.4 | `im_call_event` 事件流水表落地（所有信令落库，用于 callId 维度审计） |
| R2.5 | 质量指标采集与上报（`getStats()` 定期上报） |
| R2.6 | Prometheus 指标埋点（见 §7.2） |

---

## 11. 离线推送方案（Phase 1）

### 11.1 问题描述与方案选型

当被叫方（B）所有设备均无 WS 连接时：
- `NettyMessageSender.sendToUser(calleeId, ...)` 检测到无活跃 session
- CALL_SIGNAL 信令无法投递，B 收不到来电通知

**选型结论：UniPush 2.0（客户端）+ 个推 REST API V2（服务端）**

| 对比维度 | 本方案 | 自己分别对接各厂商 |
|---------|-------|--------------------|
| 接入成本 | 低（一套接口，一个 SDK） | 高（华为/小米/OPPO/vivo/APNs 各一套） |
| 维护复杂度 | 低 | 极高（证书过期/API 变更需逐个处理） |
| iOS 覆盖 | ✅ 个推内部走 APNs | 需自己申请 APNs 证书并对接 |
| Android 厂商覆盖 | ✅ 个推内部聚合主流厂商通道 | 需分别申请各厂商开发者账号 |
| 费用 | 免费（每日 10 万条额度内） | 免费（但接入人力成本高） |
| 前端兼容 | ✅ uni-app 官方 UniPush 插件，零额外开发 | 需为每个厂商编写适配层 |

**架构说明**：
- **前端**：使用 DCloud UniPush 2.0 客户端 SDK（`uni.getPushClientId` / `uni.onPushMessage`）
- **后端**：直接调用**个推 REST API V2**（UniPush 底层即个推，Java 通过 HTTP 调用，项目已有 RestTemplate 和 Hutool HttpUtil 可直接复用）
- **现有 `ImNotifyService`**：当前仅处理站内通知（DB 存储），**不扩展**，新建独立的 `ImCallPushService` 专门处理通话离线推送

---

### 11.2 Phase 0 兜底策略（零成本，立即可用）

推送功能未上线前，B 全部离线时的处理：

```java
// SystemCallSignalServiceImpl.handleCall() 中
List<NettySession> sessions = sessionManager.getSessionsByUserId(calleeId);
if (sessions.isEmpty()) {
    // B 全部离线：立即结束通话，通知 A
    endCall(callId, null, ImCallEndReasonEnum.CALLEE_OFFLINE, ImCallStatusEnum.MISSED);
    // 向 A 回复 BUSY(5) 携带 end_reason=CALLEE_OFFLINE
    sendCallSignalToDevice(callerSession.getDeviceId(), callerId, callId, callType,
        ImCallSignalTypeEnum.BUSY.getCode(), callerId, calleeId, null, tenantId);
    return callId;
}
```

A 端收到 BUSY 后，UI 显示："对方不在线，请稍后再试"。

---

### 11.3 人工准备清单（开工前必须完成）

> 以下步骤需要**人工登录各平台操作**，无法由代码自动完成。

#### 步骤 1：注册 DCloud 开发者账号

- **网址**：https://dev.dcloud.net.cn/
- **操作**：注册账号 → 创建应用 → 记录 **AppID**（形如 `__UNI__XXXXXX`）
- **说明**：已有 uni-app 项目的 AppID 即是，不需要新建

#### 步骤 2：在 DCloud 后台开启 UniPush 2.0

- **网址**：https://dev.dcloud.net.cn/ → 进入应用 → 「uni-push」→ 开启服务
- **操作**：
  1. 选择「UniPush 2.0」
  2. 绑定个推账号（首次会引导注册）
  3. 开启后记录个推后台自动生成的 **AppID / AppKey / MasterSecret**

#### 步骤 3：获取个推推送凭证

- **网址**：https://dev.getui.com/
- **说明**：通过 DCloud 绑定后自动跳转；或直接在个推后台查看
- **需要记录**：
  - `AppID`（推送目标应用标识）
  - `AppKey`（推送鉴权）
  - `MasterSecret`（签名密钥，**仅用于服务端，绝不泄露到前端**）

#### 步骤 4：配置 iOS APNs 证书（iOS 设备离线推送必须）

- **前置条件**：需要 Apple Developer 账号（$99/年，https://developer.apple.com/programs/）
- **操作步骤**：
  1. 登录 https://developer.apple.com/account/resources/certificates/list
  2. 选择应用的 App ID → Capabilities → Push Notifications → 创建证书
  3. 下载 `.cer` 文件，在 Mac Keychain 中导出为 `.p12` 文件（设置密码）
  4. 登录 DCloud 后台 → 应用 → iOS 配置 → 上传 `.p12` 文件和密码

> **证书类型选择**：使用**标准 APNs 证书**（非 VoIP 证书）。原因：VoIP 证书需要集成 iOS CallKit，实现复杂；标准证书推送 + App 内响铃的方案对本项目够用，Phase 2 再考虑 CallKit。

#### 步骤 5：配置 Android 厂商通道（提升离线到达率，可选但推荐）

个推后台已聚合主流厂商，但**需要你提供各厂商的应用凭证**才能走高优先级通道：

| 厂商 | 申请地址 | 需要字段 |
|------|---------|---------|
| 华为 | https://developer.huawei.com/consumer/cn/ | AppID、AppSecret |
| 小米 | https://dev.mi.com/distribute/mipush/ | AppID、AppKey |
| OPPO | https://open.oppomobile.com/ | AppKey、AppSecret |
| vivo | https://dev.vivo.com.cn/ | AppID、AppKey |

> **最低可行版本**：仅配置华为（国内最大份额）+ iOS APNs，覆盖约 65% 用户，可先上线再逐步补充其他厂商。

#### 步骤 6：将配置写入 application.yaml

```yaml
# application-local.yaml 及生产配置
shengyu:
  im:
    push:
      enabled: true              # 推送总开关（false=退化到 Phase 0 兜底）
      getui:
        app-id: "YOUR_GETUI_APP_ID"
        app-key: "YOUR_GETUI_APP_KEY"
        master-secret: "YOUR_GETUI_MASTER_SECRET"
        api-url: "https://restapi.getui.com/v2/${shengyu.im.push.getui.app-id}"
      quota:
        daily-limit: 100000      # 免费日推送上限，超出后降级到 Phase 0
        warn-threshold: 80000    # 达到此数量时打告警日志
```

---

### 11.4 数据库设计（CID 存储）

推送需要知道设备的 **Push Client ID（CID）**，需要新增表存储。

```sql
-- sql/mysql/1.0/im/ddl_im_push_tables.sql
CREATE TABLE `im_push_device` (
  `id`          bigint NOT NULL AUTO_INCREMENT,
  `user_id`     bigint NOT NULL COMMENT '用户ID',
  `device_id`   varchar(64) NOT NULL COMMENT '设备ID（对应 NettySession.deviceId）',
  `push_cid`    varchar(64) NOT NULL COMMENT '个推 CID（由前端上报）',
  `platform`    tinyint NOT NULL COMMENT '平台：1-Android 2-iOS 3-Web',
  `app_version` varchar(32) NULL COMMENT 'App 版本号',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `tenant_id`   bigint NOT NULL DEFAULT 0,
  `deleted`     bit(1) NOT NULL DEFAULT b'0',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uk_user_device` (`user_id`, `device_id`, `tenant_id`),
  INDEX `idx_user_id` (`user_id`, `tenant_id`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM推送设备表（存储个推CID）';
```

---

### 11.5 后端实现

#### 11.5.1 新建 ImCallPushService

**位置**：`system-biz/.../service/im/ImCallPushService.java`（接口）及 `ImCallPushServiceImpl.java`

> 不扩展现有 `ImNotifyService`（其职责是站内消息，推送是另一个通道），职责分离。

```java
// ImCallPushService.java 接口
public interface ImCallPushService {

    /**
     * 向被叫方所有离线设备发送来电推送
     * @param calleeId   被叫用户ID
     * @param callId     通话ID
     * @param callerId   主叫用户ID
     * @param callerName 主叫昵称（用于推送文案）
     * @param callType   1=语音 2=视频
     */
    void sendCallInvite(Long calleeId, String callId, Long callerId,
                        String callerName, Integer callType, Long tenantId);

    /**
     * 上报设备推送 CID（前端登录/启动时调用）
     */
    void registerPushCid(Long userId, String deviceId, String pushCid,
                         Integer platform, Long tenantId);
}
```

#### 11.5.2 ImCallPushServiceImpl（个推 REST API V2 调用）

```java
// system-biz/.../service/im/ImCallPushServiceImpl.java
@Service
@Slf4j
@RequiredArgsConstructor
public class ImCallPushServiceImpl implements ImCallPushService {

    private final ImPushDeviceMapper pushDeviceMapper;
    private final RestTemplate restTemplate;

    @Value("${shengyu.im.push.enabled:false}")
    private boolean pushEnabled;

    @Value("${shengyu.im.push.getui.api-url}")
    private String getuiApiUrl;

    @Value("${shengyu.im.push.getui.app-key}")
    private String appKey;

    @Value("${shengyu.im.push.getui.master-secret}")
    private String masterSecret;

    @Value("${shengyu.im.push.quota.daily-limit:100000}")
    private long dailyLimit;

    // Redis Key：记录当日推送量
    private static final String PUSH_QUOTA_KEY = "im:push:quota:daily:%s";  // %s = 日期 yyyyMMdd

    @Resource
    private RedissonClient redissonClient;

    @Override
    public void sendCallInvite(Long calleeId, String callId, Long callerId,
                                String callerName, Integer callType, Long tenantId) {
        if (!pushEnabled) {
            log.debug("[CallPush] 推送开关关闭，跳过 callId={}", callId);
            return;
        }

        // 1. 查询被叫的所有 CID
        List<ImPushDeviceDO> devices = pushDeviceMapper.selectByUserId(calleeId, tenantId);
        if (devices.isEmpty()) {
            log.info("[CallPush] 被叫无推送设备记录，callId={}, calleeId={}", callId, calleeId);
            return;
        }

        // 2. 配额检查
        if (!checkAndIncrementQuota(devices.size())) {
            log.warn("[CallPush] 当日推送配额已达上限 {}，降级为 Phase0 策略，callId={}", dailyLimit, callId);
            return;
        }

        // 3. 获取个推 Token
        String token = getGetuiToken();
        if (token == null) {
            log.error("[CallPush] 获取个推 Token 失败，callId={}", callId);
            return;
        }

        // 4. 构造推送内容（通知栏消息）
        String title = callType == 2 ? "视频通话邀请" : "语音通话邀请";
        String content = callerName + " 邀请你进行" + (callType == 2 ? "视频" : "语音") + "通话";

        // 5. 按 CID 批量推送（个推单次最多 1000 个 CID）
        List<String> cids = devices.stream().map(ImPushDeviceDO::getPushCid).collect(Collectors.toList());
        boolean success = doPush(token, cids, title, content, buildPayload(callId, callerId, callType));

        log.info("[CallPush] 来电推送结果：callId={}, calleeId={}, devices={}, success={}",
            callId, calleeId, cids.size(), success);
    }

    private boolean doPush(String token, List<String> cids, String title,
                            String content, Map<String, Object> payload) {
        try {
            // 使用个推 REST API V2 - 按CID批量推送
            // POST {api-url}/push/list/cid
            Map<String, Object> requestBody = Map.of(
                "request_id", UUID.randomUUID().toString(),
                "settings", Map.of("ttl", 30000),  // 30 秒 TTL（匹配响铃超时）
                "audience", Map.of("cid", cids),
                "push_message", Map.of(
                    "notification", Map.of(
                        "title", title,
                        "body", content,
                        "click_type", "intent",
                        // 点击通知时跳转 App 内路由
                        "intent", "intent:#Intent;action=android.intent.action.VIEW;component=YOUR_PKG/YOUR_ACTIVITY;S.callId=" + payload.get("callId") + ";end"
                    )
                ),
                // 透传 payload（App 前台/通知点击时均可收到）
                "push_channel", Map.of(
                    "android", Map.of(
                        "ups", Map.of(
                            "notification", Map.of(
                                "title", title,
                                "body", content,
                                "click_action", Map.of(
                                    "action_type", 5,  // 跳转 uni-app 页面
                                    "url", "/pages/message/call?callId=" + payload.get("callId") + "&type=incoming"
                                )
                            ),
                            "options", Map.of(
                                "HW", Map.of("/message/android/notification/importance", "HIGH"),
                                "MI", Map.of("/extra.channel_id", "im_call")
                            )
                        )
                    ),
                    "ios", Map.of(
                        "type", "notify",
                        "payload", JSONUtil.toJsonStr(payload),
                        "aps", Map.of(
                            "alert", Map.of("title", title, "body", content),
                            "sound", "default",
                            "mutable-content", 1
                        )
                    )
                )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.set("token", token);
            headers.setContentType(MediaType.APPLICATION_JSON);

            ResponseEntity<Map> response = restTemplate.exchange(
                getuiApiUrl + "/push/list/cid",
                HttpMethod.POST,
                new HttpEntity<>(requestBody, headers),
                Map.class
            );
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.error("[CallPush] 推送请求失败", e);
            return false;
        }
    }

    /**
     * 获取个推鉴权 Token（有效期 24h，使用 Redis 缓存）
     * POST {api-url}/auth
     */
    private String getGetuiToken() {
        String cacheKey = "im:push:getui:token";
        RBucket<String> bucket = redissonClient.getBucket(cacheKey);
        String cached = bucket.get();
        if (cached != null) return cached;

        try {
            long timestamp = System.currentTimeMillis();
            String sign = DigestUtil.sha256Hex(appKey + timestamp + masterSecret);

            Map<String, Object> body = Map.of(
                "sign", sign,
                "timestamp", String.valueOf(timestamp),
                "appkey", appKey
            );
            ResponseEntity<Map> resp = restTemplate.postForEntity(
                getuiApiUrl + "/auth", body, Map.class);

            if (resp.getStatusCode().is2xxSuccessful() && resp.getBody() != null) {
                String token = (String) ((Map<?, ?>) resp.getBody().get("data")).get("token");
                // 缓存 23 小时（Token 有效期 24h）
                bucket.set(token, Duration.ofHours(23));
                return token;
            }
        } catch (Exception e) {
            log.error("[CallPush] 获取个推 Token 失败", e);
        }
        return null;
    }

    /** 配额检查 + 原子递增（Redis 计数，每日重置） */
    private boolean checkAndIncrementQuota(int count) {
        String key = String.format(PUSH_QUOTA_KEY, LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE));
        RAtomicLong counter = redissonClient.getAtomicLong(key);
        long current = counter.addAndGet(count);
        if (current == count) {
            // 首次写入，设置过期时间到次日 0 点
            counter.expire(Duration.ofSeconds(
                LocalDateTime.now().until(LocalDate.now().plusDays(1).atStartOfDay(), ChronoUnit.SECONDS) + 60
            ));
        }
        if (current > dailyLimit) {
            counter.addAndGet(-count);  // 回滚
            return false;
        }
        if (current > (long)(dailyLimit * 0.8)) {
            log.warn("[CallPush] 当日推送量已达 {}，接近上限 {}", current, dailyLimit);
        }
        return true;
    }

    private Map<String, Object> buildPayload(String callId, Long callerId, Integer callType) {
        return Map.of("type", "CALL_INVITE", "callId", callId,
            "callerId", String.valueOf(callerId), "callType", callType);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void registerPushCid(Long userId, String deviceId, String pushCid,
                                 Integer platform, Long tenantId) {
        // UPSERT：同一 userId+deviceId 更新 CID（设备重装 App 后 CID 可能变化）
        ImPushDeviceDO existing = pushDeviceMapper.selectByUserAndDevice(userId, deviceId, tenantId);
        if (existing == null) {
            pushDeviceMapper.insert(ImPushDeviceDO.builder()
                .userId(userId).deviceId(deviceId).pushCid(pushCid)
                .platform(platform).tenantId(tenantId).build());
        } else if (!existing.getPushCid().equals(pushCid)) {
            existing.setPushCid(pushCid);
            pushDeviceMapper.updateById(existing);
        }
    }
}
```

#### 11.5.3 新增 REST 接口（CID 上报）

在 `AppImCallController`（或新建 `AppImPushController`）中新增：

```java
// POST /system/im/push/register-cid
@PostMapping("/push/register-cid")
public CommonResult<Boolean> registerPushCid(@RequestBody @Valid AppImPushRegisterReqVO reqVO) {
    imCallPushService.registerPushCid(
        SecurityFrameworkUtils.getLoginUserId(),
        reqVO.getDeviceId(),
        reqVO.getPushCid(),
        reqVO.getPlatform(),
        SecurityFrameworkUtils.getLoginUserTenantId()
    );
    return success(true);
}
```

```java
// AppImPushRegisterReqVO.java
@Data
public class AppImPushRegisterReqVO {
    @Schema(description = "设备ID（对应 WS deviceId）")
    @NotBlank private String deviceId;

    @Schema(description = "个推 CID")
    @NotBlank private String pushCid;

    @Schema(description = "平台：1=Android 2=iOS 3=Web")
    @NotNull private Integer platform;
}
```

#### 11.5.4 新增 DAO

```java
// ImPushDeviceMapper.java
public interface ImPushDeviceMapper extends BaseMapperX<ImPushDeviceDO> {
    // XML: SELECT * FROM im_push_device WHERE user_id=#{userId} AND tenant_id=#{tenantId} AND deleted=0
    List<ImPushDeviceDO> selectByUserId(@Param("userId") Long userId, @Param("tenantId") Long tenantId);

    // XML: SELECT * FROM im_push_device WHERE user_id=#{userId} AND device_id=#{deviceId} AND tenant_id=#{tenantId} AND deleted=0 LIMIT 1
    ImPushDeviceDO selectByUserAndDevice(@Param("userId") Long userId, @Param("deviceId") String deviceId, @Param("tenantId") Long tenantId);
}
```

---

### 11.6 SystemCallSignalServiceImpl 调用时机（完整逻辑）

```java
// SystemCallSignalServiceImpl.handleCall() 最终逻辑
@Override
public String handleCall(Long callerId, Long calleeId, Integer callType, Long tenantId) {
    // 1. 忙线检测
    if (!isCalleeAvailable(calleeId, tenantId)) {
        throw exception(CALL_ALREADY_IN_PROGRESS);
    }

    // 2. 落库
    String callId = imCallService.initiateCall(callerId, calleeId, callType);

    // 3. 在线 fanout
    List<NettySession> sessions = sessionManager.getSessionsByUserId(calleeId);

    if (sessions.isEmpty()) {
        // B 全部离线 - Phase 0：直接结束
        if (!pushEnabled) {
            imCallService.endCall(callId, callerId, ImCallEndReasonEnum.CALLEE_OFFLINE, ImCallStatusEnum.MISSED);
            return callId;
        }
        // Phase 1：发推送，通话保持 RINGING 状态等待 B 唤醒接入
        // （ImCallTimeoutJob 会在 30s 后自动结束未接通话）
    } else {
        // 有在线设备，fanout 信令
        for (NettySession s : sessions) {
            sendCallSignalToDevice(s.getDeviceId(), calleeId, callId, callType,
                ImCallSignalTypeEnum.CALL.getCode(), callerId, calleeId, null, tenantId);
        }
        imCallService.advanceState(callId, ImCallStateEnum.INIT, ImCallStateEnum.RINGING);
    }

    // Phase 1：无论是否有在线设备，均发推送（唤醒其他离线设备）
    if (pushEnabled) {
        String callerName = getUserNickname(callerId, tenantId);  // 查用户昵称
        imCallPushService.sendCallInvite(calleeId, callId, callerId, callerName, callType, tenantId);
    }

    return callId;
}
```

---

### 11.7 前端实现（UniPush 2.0 客户端）

#### 11.7.1 manifest.json 配置

```json
// manifest.json（uni-app 项目根目录）
{
  "app-plus": {
    "distribute": {
      "sdkConfigs": {
        "push": {
          "unipush": {
            "enabled": true,
            "appid": "__UNI__XXXXXX"
          }
        }
      }
    }
  }
}
```

> ⚠️ 修改 manifest.json 后必须**重新打自定义基座**才能生效，调试时使用标准基座无法收到推送。

#### 11.7.2 CID 上报（App 启动时）

```typescript
// App.uvue - onLaunch 中
onLaunch() {
  this.initPush()
}

function initPush() {
  // 获取设备推送 CID（个推分配的唯一设备标识）
  uni.getPushClientId({
    success: (res: any) => {
      const cid = res.cid
      // 存本地备用
      uni.setStorageSync('pushCid', cid)
      // 用户已登录则立即上报，否则在登录成功后上报
      if (isLoggedIn()) {
        uploadPushCid(cid)
      }
    },
    fail: (err: any) => {
      console.warn('[Push] 获取 CID 失败（可能是模拟器或未配置推送）:', err)
    }
  })

  // 监听推送消息（App 在前台也会触发）
  uni.onPushMessage((res: any) => {
    handlePushMessage(res.data)
  })
}

// 登录成功后调用
function uploadPushCid(cid: string) {
  const deviceId = getDeviceId()  // 从本地存储获取 WS 连接时的 deviceId
  request({
    url: '/system/im/push/register-cid',
    method: 'POST',
    data: {
      deviceId,
      pushCid: cid,
      platform: getPlatform()  // 1=Android 2=iOS 3=Web
    }
  })
}

function getPlatform(): number {
  // #ifdef APP-ANDROID
  return 1
  // #endif
  // #ifdef APP-IOS
  return 2
  // #endif
  // #ifdef H5
  return 3
  // #endif
}
```

#### 11.7.3 推送消息处理（来电唤醒）

```typescript
// App.uvue 或 call-service.uts
function handlePushMessage(data: any) {
  if (!data || data.type !== 'CALL_INVITE') return

  const callId = data.callId
  if (!callId) return

  // 通过 REST 验证通话是否仍有效（推送可能在通话结束后才到达）
  getCallDetail(callId).then((detail: any) => {
    if (detail && detail.state === 'RINGING') {
      // 通话仍有效，跳转来电页面
      uni.navigateTo({
        url: `/pages/message/call?callId=${callId}&type=incoming&callerId=${data.callerId}&callType=${data.callType}`
      })
    }
    // state 不是 RINGING 说明已超时/取消，静默忽略
  }).catch(() => {
    // 查询失败静默忽略，不影响用户正常使用
  })
}
```

---

### 11.8 免费额度管理与兜底降级

#### 11.8.1 个推免费额度

| 类型 | 限制 |
|------|------|
| 日推送量 | 10 万条/天（超出后单条计费约 ¥0.0001） |
| 月免费推送 | 约 300 万条 |
| 并发推送速率 | 1000 条/秒（免费版） |

> **对通话场景的实际影响**：来电推送仅在 B 离线时发出，企业 SaaS 日常用户多在线，日推送量通常远低于 1000 条，免费额度绰绰有余。

#### 11.8.2 三级降级策略

系统通过 Redis 计数 + 配置开关，自动在三个级别间切换：

```
级别 1（正常）：pushEnabled=true，当日计数 < dailyLimit
  → 正常发送个推通知
  ↓ 当日计数 >= dailyLimit（或 getui token 获取失败）
级别 2（推送降级）：当日配额耗尽
  → 仅向"高价值"场景发推送：TODO（当前通话场景全部发，无法区分优先级）
  → 实际效果：B 离线时通话直接走 Phase 0 兜底（不发推送）
  ↓ pushEnabled=false（运维手动关闭或服务不可用）
级别 3（完全降级，Phase 0）：
  → B 离线 → 立即 ENDED/CALLEE_OFFLINE → A 收到"对方不在线"
```

**`ImCallPushServiceImpl` 已实现降级**：`checkAndIncrementQuota` 返回 false 时自动跳过推送，`handleCall` 的 `sessions.isEmpty()` + `!pushEnabled` 分支处理 Phase 0 逻辑。

#### 11.8.3 付费升级方案

若推送量超出免费额度：
- **首选**：升级个推套餐（¥99-499/月，不换代码，仅改配置）
- **备选**：接入极光推送（JPush，https://www.jiguang.cn/）作为备用通道，接口设计基本一致，`ImCallPushService` 接口隔离了实现，切换只需新增 `ImCallPushServiceImpl` 实现类

---

### 11.9 实施任务清单（Phase 1 推送专项）

| # | 任务 | 类型 | 依赖 |
|---|------|------|------|
| P1.0 | **人工**：注册 DCloud 账号，开启 UniPush 2.0，记录 AppID/AppKey/MasterSecret | 人工 | - |
| P1.1 | **人工**：申请 Apple Developer 证书（如需 iOS 推送），导出 .p12，上传 DCloud 后台 | 人工 | - |
| P1.2 | **人工**（可选）：在个推后台配置华为/小米厂商通道 | 人工 | P1.0 |
| P1.3 | **人工**：将 AppID/AppKey/MasterSecret 写入 `application.yaml` | 人工 | P1.0 |
| P1.4 | DDL：新建 `im_push_device` 表 | 代码 | - |
| P1.5 | 新建 `ImPushDeviceDO` + `ImPushDeviceMapper`（含 XML） | 代码 | P1.4 |
| P1.6 | 新建 `ImCallPushService` 接口 + `ImCallPushServiceImpl` | 代码 | P1.5 |
| P1.7 | `AppImCallController` 新增 `POST /system/im/push/register-cid` 接口 | 代码 | P1.6 |
| P1.8 | `SystemCallSignalServiceImpl.handleCall()` 注入并调用 `ImCallPushService` | 代码 | P1.6 |
| P1.9 | 前端 `App.uvue`：`initPush()` + `uni.getPushClientId()` + CID 上报 | 前端 | P1.7 |
| P1.10 | 前端 `App.uvue`：`uni.onPushMessage` 监听 + `handlePushMessage()` 来电跳转 | 前端 | P1.9 |
| P1.11 | 前端 `manifest.json`：启用 UniPush 2.0，重打自定义基座 | 前端 | P1.0 |
| P1.12 | 联调验证：A 发起通话，B 杀进程，验证 B 收到推送并能正确跳转来电界面 | 测试 | 全部 |

---

## 12. STUN/TURN 国内自建方案（Phase 1）

### 12.1 为什么不能用 Google STUN

`stun.l.google.com:19302` 在中国大陆受 GFW 影响，大概率不可达。使用后 ICE 候选收集失败，WebRTC 直接走不通。

### 12.2 自建 coturn 方案

**coturn** 是最广泛使用的开源 STUN/TURN 服务器，完整实现 RFC 5389（STUN）和 RFC 5766（TURN）。

**部署要求**：
- 云服务器：有公网 IP 的 ECS/CVM
- 端口：开放 `UDP/TCP 3478`（STUN/TURN），`UDP 49152-65535`（媒体中继）
- 推荐配置：2核4G（支持约 200 路并发通话中继）

**最简安装（Ubuntu/Debian）**：

```bash
apt-get install -y coturn
# 编辑 /etc/turnserver.conf
```

**关键配置参数**：

```ini
# /etc/turnserver.conf
listening-port=3478
external-ip=<你的服务器公网IP>
min-port=49152
max-port=65535
lt-cred-mech              # 使用长期凭证（比静态密码安全）
user=${TURN_USERNAME}:${TURN_CREDENTIAL}
realm=your-domain.com
fingerprint
no-multicast-peers
no-loopback-peers
```

**生产配置要点**：
- 推荐使用 `lt-cred-mech`（长期凭证），后端动态生成 HMAC-SHA1 凭证，有效期 24h
- 国内推荐部署 2 个节点（华北 + 华南），DNS 轮询就近接入
- NAT 穿透成功率约 50%（Cone NAT），失败时自动回落到 TURN 中继

**后端动态生成 TURN 凭证（REST API 返回）**：

```java
// AppImCallController.getTurnConfig() 实现
@GetMapping("/turn-config")
public CommonResult<TurnConfigVO> getTurnConfig() {
    long timestamp = System.currentTimeMillis() / 1000 + 86400; // 24h 有效
    String username = timestamp + ":" + SecurityFrameworkUtils.getLoginUserId();
    String credential = HmacUtils.hmacSha1Hex(turnSecret, username);
    return success(TurnConfigVO.builder()
        .iceServers(List.of(
            IceServerVO.builder().urls(stunServers).build(),
            IceServerVO.builder().urls(turnUrls).username(username).credential(credential).build()
        ))
        .build());
}
```

---

## 13. 移动端 UI 设计规范（开工参考）

> 本节为 `call.uvue` 实现提供可落地的界面规格，参考微信 iOS/Android 通话 UI 实际行为、FaceTime PiP 交互标准及业界最佳实践整理，覆盖"来电 → 拨出等待 → 通话中 → 结束"完整生命周期。

### 13.1 界面状态清单与路由

`call.uvue` 是单页面，通过 `callUiState` 内部状态切换视图，**不跳转新页面**，避免来电被路由栈打断。

| UI 状态（`callUiState`） | 对应端侧通话状态 | 触发来源 |
|--------------------------|----------------|---------|
| `INCOMING` | `IDLE`（收到信令 CALL） | WS CALL_SIGNAL(1) 推送 / 离线推送唤醒 |
| `OUTGOING_RINGING` | `OUTGOING_RINGING` | 用户主动发起 |
| `CONNECTING` | `CONNECTING` | 己方 ANSWER 成功 / 对方 ANSWER 成功 |
| `CONNECTED_VOICE` | `CONNECTED`（callType=1） | ICE 连通 |
| `CONNECTED_VIDEO` | `CONNECTED`（callType=2） | ICE 连通 |
| `ENDED` | `ENDED` | HANGUP/REJECT/TIMEOUT/BUSY 任一 |
| `MINIMIZED` | 任何通话中状态 | 用户退出页面 / 点击最小化 |

**路由约定**：
- 来电触发：`call-service.uts` 收到 CALL 信令后，若当前不在 call 页面，`uni.navigateTo({ url: '/pages/message/call?callId=xxx&type=incoming' })`
- 主动拨出：聊天页面或联系人页面按钮触发，携带 `targetUserId` 和 `callType` 跳转

---

### 13.2 来电界面（`callUiState = INCOMING`）

#### 布局结构（ASCII 线框图）

```
┌────────────────────────────────┐
│                                │  ← 状态栏（深色字体，全屏背景覆盖）
│                                │
│        ┌──────────┐            │
│        │          │            │  ← 对方头像（圆形，直径 80px，居中偏上 30%）
│        │  AVATAR  │            │
│        └──────────┘            │
│                                │
│      对方昵称（20px，白色）     │  ← 名字居中
│   "邀请你进行语音/视频通话"     │  ← 状态副文字（14px，白色 70% 透明度）
│                                │
│  （视频来电：本地预览即刻开启）  │
│                                │
│                                │  ← 中间留白区（防误触）
│                                │
│  ┌──────────┐  ┌──────────┐   │
│  │  拒绝    │  │  接听    │   │  ← 按钮区（底部安全区上方 48px）
│  │  红色圆  │  │  绿色圆  │   │
│  └──────────┘  └──────────┘   │
│  （可选）发消息   （可选）语音接听 │  ← 按钮下方文字标签（12px）
│                                │
└────────────────────────────────┘
```

#### 设计规范

| 属性 | 语音来电 | 视频来电 |
|------|----------|----------|
| 背景 | 深色渐变（`#1C1C1C → #000000`，纵向渐变）| 对方暂无预览时同语音；有预览流时铺满对方画面 + 毛玻璃 |
| 对方头像 | 圆形，直径 80px，2px 白色边框 | 同左，头像位置可适当上移（画面区域优先） |
| 接听按钮 | 绿色圆形（直径 64px），电话图标 | 绿色圆形，视频图标 |
| 拒绝按钮 | 红色圆形（直径 64px），挂断图标 | 同左 |
| 按钮横间距 | 两按钮左右均分，各距屏幕边缘约 20% | 同左 |
| 触摸目标 | 最小 44pt(iOS) / 48dp(Android)，按钮之间间距 ≥ 40px | 同左 |

#### 振铃行为

- 进入 `INCOMING` 状态时立刻调用 `uni.vibrate()` + 播放系统铃声
- 离开 `INCOMING`（接听 / 拒绝 / 超时）时停止振铃

---

### 13.3 拨出等待界面（`callUiState = OUTGOING_RINGING`）

#### 布局结构

```
┌────────────────────────────────┐
│                                │
│        ┌──────────┐            │
│        │  AVATAR  │            │  ← 对方头像（圆形，直径 80px）
│        └──────────┘            │     外圈：脉冲波纹动画（2-3 圈扩散）
│      ╰──────────────╯          │
│    ╰──────────────────────╯    │
│                                │
│         对方昵称               │
│    "等待对方接受邀请..."        │  ← 省略号循环动画（...）
│                                │
│  （视频通话：己方摄像头预览    │
│    铺满背景，本人先看到自己）   │
│                                │
│         ┌──────────┐           │
│         │   取消   │           │  ← 红色圆形大按钮，居中
│         └──────────┘           │
│                                │
└────────────────────────────────┘
```

#### 脉冲波纹动画规范

- 3 圈同心圆，从头像外边缘向外扩散
- 透明度：外圈 0.1 → 内圈 0.4，逐圈递减
- 颜色：与接听按钮颜色一致（绿色 `#07C160` 或白色，依背景而定）
- 周期：1.5s 循环，各圈错开 0.5s 延迟
- 实现：`uni-app x` 使用 CSS `@keyframes` + `animation-delay`

---

### 13.4 通话中界面

#### 13.4.1 语音通话（`callUiState = CONNECTED_VOICE`）

```
┌────────────────────────────────┐
│  [最小化 ↙]         [通话中…]  │  ← 顶部工具栏（状态栏下方）
│                                │
│        ┌──────────┐            │
│        │  AVATAR  │            │  ← 对方头像（直径 64px，居中偏上）
│        └──────────┘            │
│         对方昵称               │
│      ⏱  00:05:23               │  ← 通话计时器（绿色，居中）
│                                │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ 静音 │ │扬声器│ │ 键盘 │   │  ← 次控制栏（3个灰色圆角方块）
│  └──────┘ └──────┘ └──────┘   │
│                                │
│         ┌──────────┐           │
│         │   挂断   │           │  ← 红色圆形大按钮，居中
│         └──────────┘           │
└────────────────────────────────┘
```

#### 13.4.2 视频通话（`callUiState = CONNECTED_VIDEO`）

```
┌────────────────────────────────┐
│                                │  ← 对方视频画面铺满全屏
│                        ┌────┐  │
│                        │己方│  │  ← 本地预览小窗（PiP）
│                        │预览│  │     默认位置：右上角，可拖拽吸附四角
│                        └────┘  │
│       [对方名字  00:05:23]      │  ← 状态叠加文字（控制栏显示时可见）
│                                │
├────────────────────────────────┤
│  [关摄] [静音] [翻转] [ 挂断 ] │  ← 底部控制栏（半透明黑底 #00000080）
└────────────────────────────────┘
```

**控制栏自动隐藏**：无操作 4 秒后渐隐，点击任意非按钮区域重新显示。

---

### 13.5 通话结束界面（`callUiState = ENDED`）

**结束文案映射**：

| `endReason` / 场景 | 显示文案 | 时长行 |
|--------------------|---------|--------|
| `HANGUP`（正常挂断） | `通话时长 MM:SS` | 显示 |
| `REJECT` | `对方已拒绝` | 不显示 |
| `TIMEOUT` | `对方未接听` | 不显示 |
| `CANCEL` | `通话已取消` | 不显示 |
| `BUSY` | `对方正在通话中` | 不显示 |
| `CALLEE_OFFLINE` | `对方不在线` | 不显示 |
| 网络断开 | `通话已断开` | 不显示 |

**自动消失机制**：展示 2.5 秒后自动 `uni.navigateBack()` 返回聊天界面。

---

### 13.6 悬浮窗（`callUiState = MINIMIZED`，Phase 1）

**iOS**：`AVPictureInPictureController` 系统级 PiP 窗口（仅能显示己方摄像头画面）

**Android**：`WindowManager` 自绘悬浮窗（需 `SYSTEM_ALERT_WINDOW` 权限），可显示对方头像 + 计时器

---

### 13.7 聊天消息列表中的通话气泡

通话结束后服务端产生 `CALL_RECORD(209)` 消息，端侧在聊天消息列表中渲染为通话气泡。

**字段映射（主叫/被叫双视角，参考微信规范）**：

| `callType` | `status` | 主叫视角文案 | 被叫视角文案 | 颜色 |
|-----------|---------|------------|------------|------|
| 1（语音） | 2（已接通） | `已拨出语音通话 MM:SS` | `语音通话 MM:SS` | 正常 |
| 2（视频） | 2（已接通） | `已拨出视频通话 MM:SS` | `视频通话 MM:SS` | 正常 |
| 1/2 | 1（未接听） | `对方未接听` | `未接来电` | 红色 `#FF4444` |
| 1/2 | 3（已拒绝） | `对方已拒绝` | `已拒绝` | 灰色 |
| 1/2 | 5（已取消） | `已取消` | `对方已取消` | 灰色 |
| 1/2 | 4（忙线） | `对方忙线` | `忙线` | 灰色 |

**气泡实现落点**：

```typescript
// pages/message/components/message-item.uvue
case MessageType.CALL_RECORD:
  const isCallRecord = true
  const isCaller = message.body.callerId === currentUserId
  return renderCallRecordBubble(message.body as CallRecordMessage, isCaller)
```

**点击气泡行为**：展示通话详情弹窗（时长、时间、呼叫类型）+ "再次呼叫"按钮

---

### 13.8 麦克风 / 摄像头权限请求

**权限按通话类型申请**：

| 通话类型 | 必需权限 |
|---------|---------|
| 语音通话 | 麦克风（`RECORD_AUDIO` / `NSMicrophoneUsageDescription`） |
| 视频通话 | 麦克风 + 摄像头（`CAMERA` / `NSCameraUsageDescription`） |

**系统权限配置（AndroidManifest / Info.plist）**：

```xml
<!-- Android: AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

<!-- iOS: Info.plist -->
<key>NSMicrophoneUsageDescription</key><string>需要麦克风权限用于语音/视频通话</string>
<key>NSCameraUsageDescription</key><string>需要摄像头权限用于视频通话</string>
```

---

### 13.9 交互动效规范

| 场景 | 动效 | 时长 | 曲线 |
|------|------|------|------|
| 来电界面进入 | 从底部滑入（translateY 100% → 0） | 300ms | ease-out |
| 来电 → 通话中 | 按钮区淡出 + 控制栏淡入 | 200ms | ease |
| 通话中 → 结束 | 黑色遮罩淡入（opacity 0 → 0.7） | 300ms | ease-in |
| 结束界面自动消失 | 整个遮罩淡出 | 300ms | ease-out |
| 摄像头切换 | 水平翻转（scaleX 1 → -1 → 1） | 300ms | ease |
| 控制栏隐藏/显示 | opacity 渐变 | 300ms | ease |
| 脉冲波纹（等待） | scale(1) → scale(2)，opacity 0.4 → 0 | 1.5s | ease-out，循环 |
| 本地预览拖拽吸附 | spring 动效（弹性回弹） | 400ms | spring(damping=0.7) |

---

### 13.10 平台适配说明（uni-app x）

| 特性 | Web 端 | Android | iOS |
|------|--------|---------|-----|
| WebRTC | 直接用浏览器 API | Native Plugin（libwebrtc） | Native Plugin（WebRTC.framework） |
| 悬浮窗 | 页面内 fixed overlay | `WindowManager` Native Plugin | `AVPictureInPictureController` |
| 系统来电界面 | 不适用 | `ConnectionService` API（Phase 2） | `CallKit` 框架（Phase 2） |
| 振铃 | `HTMLAudioElement` | 系统铃声 / `AudioManager` | `AVAudioSession` |
| 权限申请 | 浏览器 `getUserMedia` 弹框 | `uni.requestPermissions` | Info.plist + 系统弹框 |

---

### 13.11 端侧 UI 文件级实现清单

| 文件 | 职责 | Phase |
|------|------|-------|
| `pages/message/call.uvue` | 主通话页面，管理所有 `callUiState` 切换 | 0 |
| `pages/message/components/call-incoming.uvue` | 来电界面组件 | 0 |
| `pages/message/components/call-outgoing.uvue` | 拨出等待界面组件 | 0 |
| `pages/message/components/call-voice-connected.uvue` | 语音通话中组件 | 0 |
| `pages/message/components/call-video-connected.uvue` | 视频通话中组件 | 1 |
| `pages/message/components/call-ended.uvue` | 通话结束组件 | 0 |
| `pages/message/components/call-record-bubble.uvue` | 聊天记录中的通话气泡组件 | 0 |
| `utils/call-float-window.uts` | 悬浮窗创建/销毁（Native Plugin 调用） | 1 |
| `utils/call-timer.uts` | 通话计时器（计秒 + 格式化 `MM:SS`） | 0 |
| `utils/call-permission.uts` | 权限检查与请求封装 | 0 |

**`call.uvue` 关键 Props / 入口**：

```typescript
// 来电场景（WS 推送触发跳转时传入）
interface IncomingCallParams {
  callId: string
  callType: number          // 1-语音 2-视频
  callerId: string          // Long → string（精度保护）
  callerNickname: string
  callerAvatar: string
}

// 主动拨出场景
interface OutgoingCallParams {
  callType: number
  targetUserId: string      // Long → string（精度保护）
  targetNickname: string
  targetAvatar: string
}
```

---

## 附录 A：现有代码清单（已实现 vs 待实现）

| 组件 | 状态 | 文件路径 |
|------|------|---------|
| proto `CallSignalMessage` | 已实现 | `shengyu-framework/.../proto/im_message.proto:295` |
| `MessageType.CALL_SIGNAL(206)` | 已实现 | `im_message.proto:89`，`MessageType.java` |
| `ImCallTypeEnum` | 已实现 | `system-api/.../enums/im/ImCallTypeEnum.java` |
| `ImCallStatusEnum` | 已实现 | `system-api/.../enums/im/ImCallStatusEnum.java` |
| DDL `im_call_record`（基础字段） | 已实现 | `sql/mysql/1.0/im/ddl_im_tables.sql:442` |
| `ImCallRecordDO` | 已实现（需新增5字段） | `system-biz/.../dal/dataobject/im/ImCallRecordDO.java` |
| `ImCallRecordMapper` | 已实现（需新增4方法） | `system-biz/.../dal/mysql/im/ImCallRecordMapper.java` |
| `ImCallService` 接口 | 已实现（需重构：删 forwardCallSignal，增4方法） | `system-biz/.../service/im/ImCallService.java` |
| `ImCallServiceImpl` | 已实现（需重构，见 §4.6.1） | `system-biz/.../service/im/ImCallServiceImpl.java` |
| ErrorCode 500/501 | 已实现 | `ErrorCodeConstants.java` |
| 会话预览 `[通话]` | 已实现 | `SystemMessageStorageServiceImpl.java:909` |
| 端侧 `CALL_SIGNAL=206` | 已实现 | `utils/websocket.uts:75` |
| Redis / Redisson | 已实现 | `shengyu-framework/shengyu-spring-boot-starter-redis` |
| spi/ 目录 | 已存在 | `system-biz/.../service/im/spi/` |
| job/ 目录 | 已存在 | `system-biz/.../service/im/job/` |
| **`im_call_record` 5个新字段（ALTER TABLE）** | **待实现（R0.2）** | `sql/mysql/1.0/im/ddl_im_tables.sql` |
| **`ImCallRecordMapper` 新增4方法 + XML** | **待实现（R0.3.1）** | `ImCallRecordMapper.java` + XML |
| **`ImCallStateEnum`** | **待实现（R0.1）** | `enums/im/ImCallStateEnum.java` |
| **`ImCallEndReasonEnum`** | **待实现（R0.1）** | `enums/im/ImCallEndReasonEnum.java` |
| **`ImCallSignalTypeEnum`** | **待实现（R0.1）** | `enums/im/ImCallSignalTypeEnum.java` |
| **`CallSignalService` SPI 接口** | **待实现（R0.4）** | `websocket/spi/CallSignalService.java` |
| **`SystemCallSignalServiceImpl`** | **待实现（R0.5）** | `service/im/spi/SystemCallSignalServiceImpl.java` |
| **`CallSignalMessageProcessor`** | **待实现（R0.6）** | `processor/impl/CallSignalMessageProcessor.java` |
| **处理器注册** | **待实现（R0.6）** | `NettyAutoConfiguration.java` |
| **`ImCallTimeoutJob`** | **待实现（R0.7）** | `service/im/job/ImCallTimeoutJob.java` |
| **`AppImCallController`** | **待实现（R0.8）** | `controller/app/im/AppImCallController.java` |
| **application.yaml rtc 配置节** | **待实现（R0.9）** | `application.yaml` |
| **AUTH_REQ 成功后 STATE_SYNC 下发** | **待实现（R0.11）** | 认证处理器 |
| **端侧 `call-service.uts`** | **待实现（R0.12）** | `services/call-service.uts` |
| **端侧 `call.uvue`** | **待实现（R0.13）** | `pages/message/call.uvue` |
| **端侧 `api/call.uts`** | **待实现（R0.14）** | `api/call.uts` |
| **proto `CALL_RECORD=209`** | **待实现（R1.1）** | `im_message.proto` |
| **proto `CallRecordMessage`** | **待实现（R1.1）** | `im_message.proto` |
| **`MessageType.CALL_RECORD(209)` Java 枚举** | **待实现（R1.2）** | `MessageType.java` |
| **TURN 配置 + coturn 部署** | **待实现（R1.5）** | `application.yaml` + 运维 |
| **DDL `im_push_device` 表** | **待实现（P1.4）** | `sql/mysql/1.0/im/ddl_im_push_tables.sql` |
| **`ImPushDeviceDO` + `ImPushDeviceMapper`** | **待实现（P1.5）** | `dal/dataobject/im/` + `dal/mysql/im/` |
| **`ImCallPushService` 接口 + `ImCallPushServiceImpl`** | **待实现（P1.6）** | `service/im/ImCallPushService.java` |
| **`POST /system/im/push/register-cid` 接口** | **待实现（P1.7）** | `controller/app/im/AppImCallController.java` |
| **`SystemCallSignalServiceImpl` 注入 ImCallPushService** | **待实现（P1.8）** | `service/im/spi/SystemCallSignalServiceImpl.java` |
| **端侧 `webrtc-manager.uts`** | **待实现（R1.7）** | `utils/webrtc-manager.uts` |
| **端侧 `call-float-window.uts`** | **待实现（R1.11）** | `utils/call-float-window.uts` |
| **DDL `im_call_event`** | **待实现（Phase 2）** | `sql/mysql/1.0/im/` |

---

## 附录 B：关键依赖关系图（Phase 0）

```
R0.1（枚举）
  └──► R0.2（DDL + DO）
        └──► R0.3（ImCallServiceImpl 重构）
              └──► R0.3.1（Mapper 新4方法）
              └──► R0.4（CallSignalService 接口）
                    └──► R0.5（SystemCallSignalServiceImpl）
                          └──► R0.6（Processor + 注册）
                          └──► R0.7（ImCallTimeoutJob）
                          └──► R0.8（AppImCallController）
                          └──► R0.11（AUTH STATE_SYNC）

R0.9（yaml 配置）── 独立，无依赖
R0.10（ErrorCode）── 独立，无依赖

R0.12（端侧 call-service）依赖 R0.6（Processor 先上线）
R0.13（端侧 call.uvue）依赖 R0.12
R0.14（端侧 api/call.uts）依赖 R0.8
```
