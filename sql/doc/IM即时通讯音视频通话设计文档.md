---
description: IM 音视频通话（WebRTC 自研）设计文档
owner: IM
status: draft
version: v1.2
updated: 2026-04-02
---

# IM 即时通讯音视频通话设计文档（纯自研 WebRTC 路线）

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
  - callId 维度权威状态机
  - 负责：多端一致、超时、并发控制、幂等
  - 保存通话最终态，产生通话记录消息

### 1.2 数据流

```
1) A 发起通话：CALL_SIGNAL(signalType=1/CALL) -> WS -> 服务端
2) 服务端忙线检测 + 落库(`im_call_record`) + 推进状态：INIT -> RINGING
3) 服务端 fanout 到 B 所有在线设备：CALL_SIGNAL(signalType=1/CALL, callId)
4) B 任一端接受：CALL_SIGNAL(signalType=2/ANSWER) -> WS -> 服务端
5) 服务端 CAS 并发裁决（WHERE state='RINGING' AND accepted_device_id IS NULL）
   → 成功：state=RINGING -> CONNECTING，记录 accepted_device_id
6) 服务端向 B 其他设备推 CALL_SIGNAL(signalType=5/BUSY)
7) 双方通过 CALL_SIGNAL(signalType=7/8/9) 交换 SDP/ICE（服务端纯透传）
   → ICE 连接成功后端侧发 CALL_SIGNAL(signalType=2/ANSWER, extraData={"connected":true})
   → 服务端收到后将 state 推进至 CONNECTED
8) 结束：任一方 CALL_SIGNAL(signalType=4/HANGUP)
   → 服务端落最终态 + 生成 CALL_RECORD(209) 消息 + 广播 HANGUP 给对端
```

---

## 2. 关键约束与原则（企业级）

### 2.1 幂等性

- 所有 `CALL_SIGNAL` 事件必须带 `callId` + `header.messageId`
- 服务端必须按 `messageId` 幂等处理，重复事件不导致状态倒退
- 端侧 `messageId` 生成规则复用 `utils/message-utils.uts#generateMessageId`（snowflake-like 纯数字字符串）

### 2.2 状态机权威性

- 服务端是权威：端侧仅是 UI + 媒体控制
- 状态只允许单向推进，不允许回滚
- 所有状态变更必须经过 `ImCallService` 并落库

### 2.3 多端一致

- 同账号多端可同时响铃（通过 `NettyMessageSender.sendToUser` fanout 到所有在线设备）
- 只能一个端 ANSWER 成功，其余端必须收到 BUSY
- 利用 `NettySession.deviceId` 标识接听设备

### 2.4 超时治理

- INVITED/RINGING 超时：30s，自动推进为 MISSED（`ImCallStatusEnum.MISSED`）
- CONNECTING（SDP/ICE 协商）超时：60s
- 超时机制参考 `NettyAuthLeaseMonitor` 的 `ScheduledExecutorService` 模式

### 2.5 可灰度/可降级

- FeatureFlag：关闭时不展示入口、不处理媒体
- 允许"仅信令联调"模式（媒体不启用）用于灰度排障

### 2.6 与现有 IM 规范对齐（强制）

- **Long 精度**：`callId` 在 proto 中为 `string`（已实现），前端统一用 `string`，后端 VO 按 `@JsonSerialize(using = ToStringSerializer.class)` 输出
- **先存储后投递**：通话结束时生成的 `CALL_RECORD` 消息走「先落库后 fanout」门禁（与 TEXT/IMAGE 等七类消息一致）
- **会话预览**：`CALL_SIGNAL` 在 `buildConversationPreview()` 中已映射为 `"[通话]"`（`SystemMessageStorageServiceImpl:909`）

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
| 4 | HANGUP | 挂断 | 任一方 -> Server -> 对方(多端) |
| 5 | BUSY | 忙线（服务端生成） | Server -> B(未接听端) |
| 6 | SWITCH_CAMERA | 切换摄像头通知 | A <-> B（纯透传） |
| 7 | SDP_OFFER | WebRTC SDP offer | A -> Server -> B |
| 8 | SDP_ANSWER | WebRTC SDP answer | B -> Server -> A |
| 9 | ICE_CANDIDATE | WebRTC ICE candidate | 双向透传 |
| 10 | STATE_SYNC | 断线重连状态同步 | Server -> 端侧 |
| 11 | TIMEOUT | 超时（服务端生成） | Server -> A+B(多端) |

### 3.2 Protobuf 定义（已落地）

```protobuf
// 文件: shengyu-framework/.../proto/im_message.proto
message CallSignalMessage {
  string callId = 1;       // 通话ID（UUID）
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
- `sequence`：仅通话结束时生成通话记录消息才分配 sequence
- `chatId`：仅通话结束时关联会话
- `extra`：可携带 `conversationSnapshot`（与其他消息一致）

**关键区别**：通话信令（signalType 1-9）为**瞬态事件**，不分配 sequence、不进入消息列表。仅通话结束时产生的**通话记录消息**才走标准消息存储链路。

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

### 3.5 事件幂等与状态机

服务端状态机（仅允许单向推进）：

```
INIT -> RINGING -> CONNECTING -> CONNECTED -> ENDED
                                      |
          RINGING -> ENDED（reject/timeout/busy/cancel）
```

- `INIT`：`initiateCall()` 落库时置
- `RINGING`：fanout 到被叫方后置
- `CONNECTING`：被叫 ANSWER 并通过并发裁决后置
- `CONNECTED`：SDP/ICE 协商成功后置（端侧上报 `onIceConnectionStateChange(connected)`）
- `ENDED`：挂断/拒绝/超时/忙线，由 `endReason` 区分

---

## 4. 服务端数据模型与实现

### 4.1 已有数据库表

**`im_call_record`**（已落地，DDL 见 `sql/mysql/1.0/im/ddl_im_tables.sql:442`）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint PK | 自增主键 |
| call_id | varchar(64) UK | 通话唯一标识（UUID） |
| call_type | tinyint | 1-语音 2-视频 |
| caller_id | bigint | 呼叫方 |
| callee_id | bigint | 被叫方 |
| start_time | datetime | 呼叫发起时间 / 接通时间 |
| end_time | datetime | 通话结束时间 |
| duration | int | 通话时长（秒） |
| status | tinyint | 1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消 |
| tenant_id | bigint | 租户 |

索引：`idx_tenant_call_id`（UK）、`idx_caller`、`idx_callee`、`idx_tenant`

### 4.2 待新增字段（Phase 1 补充）

```sql
ALTER TABLE `im_call_record` ADD COLUMN `state` varchar(20) NOT NULL DEFAULT 'INIT'
  COMMENT '状态机状态(INIT/RINGING/CONNECTING/CONNECTED/ENDED)' AFTER `status`;
ALTER TABLE `im_call_record` ADD COLUMN `end_reason` varchar(20) NULL DEFAULT NULL
  COMMENT '结束原因(HANGUP/REJECT/TIMEOUT/BUSY/CANCEL/ERROR)' AFTER `state`;
ALTER TABLE `im_call_record` ADD COLUMN `accepted_device_id` varchar(64) NULL DEFAULT NULL
  COMMENT '接听设备ID' AFTER `end_reason`;
ALTER TABLE `im_call_record` ADD COLUMN `chat_id` bigint NULL DEFAULT NULL
  COMMENT '关联会话ID' AFTER `accepted_device_id`;
ALTER TABLE `im_call_record` ADD COLUMN `record_message_id` bigint NULL DEFAULT NULL
  COMMENT '通话记录消息ID（通话结束时生成的消息）' AFTER `chat_id`;
```

### 4.3 待新增事件表（Phase 1 可选，Phase 2 必须）

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

### 4.5 待新增枚举

```java
// ImCallStateEnum.java
public enum ImCallStateEnum {
    INIT("INIT", "初始化"),
    RINGING("RINGING", "响铃中"),
    CONNECTING("CONNECTING", "连接中"),
    CONNECTED("CONNECTED", "通话中"),
    ENDED("ENDED", "已结束");
}

// ImCallEndReasonEnum.java
public enum ImCallEndReasonEnum {
    HANGUP("HANGUP", "正常挂断"),
    REJECT("REJECT", "被拒绝"),
    TIMEOUT("TIMEOUT", "超时未接"),
    BUSY("BUSY", "忙线"),
    CANCEL("CANCEL", "主叫取消"),
    ERROR("ERROR", "异常结束");
}

// ImCallSignalTypeEnum.java
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
| `ImCallService` | `system-biz/.../service/im/ImCallService.java` | 接口，含 initiate/accept/reject/hangup/forward/query |
| `ImCallServiceImpl` | `system-biz/.../service/im/ImCallServiceImpl.java` | 实现，含基础 CRUD 与时长计算 |
| `ImCallRecordDO` | `system-biz/.../dal/dataobject/im/ImCallRecordDO.java` | 数据对象 |
| `ImCallRecordMapper` | `system-biz/.../dal/mysql/im/ImCallRecordMapper.java` | DAO，含 selectByCallId/selectByUserId/selectByTwoUsers |

### 4.6.1 `ImCallServiceImpl` 现有问题与重构要点

当前实现存在以下企业级缺陷，开工时必须修复：

| 问题 | 位置 | 修复方案 |
|------|------|---------|
| `acceptCall` 直接 `updateById`，多端并发接听无保护 | `:71-73` | 改为 CAS UPDATE + 行数校验 |
| `initiateCall` 未检测被叫方是否已在通话中 | `:33-53` | 调用前查 `im_call_record WHERE callee_id=? AND state IN ('RINGING','CONNECTING','CONNECTED')` |
| 所有方法无状态机 guard（如 ENDED 状态仍可调 hangup） | 各方法 | 每个方法前加 `assertState(allowedStates)` |
| `initiateCall` 用 `IdUtil.simpleUUID()` 生成 callId，但 `im_call_record` 没有 state 字段初始值 | `:38` | 新增字段后初始值置 `INIT`，fanout 后置 `RINGING` |
| `forwardCallSignal` 仅做日志，无实际转发 | `:134-148` | 废弃此方法，转发逻辑统一在 Processor 完成 |

重构后 `ImCallServiceImpl` 的关键新方法签名：

```java
// 忙线检测（Phase 0 必须）
boolean isCalleeAvailable(Long calleeId, Long tenantId);

// 统一结束入口（Phase 0 必须）
ImCallEndResult endCall(String callId, Long userId, String endReason, Integer finalStatus);

// CAS 并发裁决接听（Phase 0 必须）
CallAnswerResult answerWithCas(String callId, Long userId, String deviceId);

// 状态推进（Phase 0 必须）
void advanceState(String callId, String fromState, String toState);
```

### 4.7 并发裁决（多端 accept）

`CALL_SIGNAL(signalType=2/ANSWER)` 到达服务端时：
1. 查 `im_call_record` 当前 `state`
2. 若 state 已 `CONNECTED/ENDED`：返回当前最终态（STATE_SYNC）
3. 若 state 在 `RINGING` 且 `accepted_device_id IS NULL`：
   - CAS 更新 `accepted_device_id = ?` + `state = CONNECTING`（`WHERE call_id = ? AND state = 'RINGING' AND accepted_device_id IS NULL`）
   - 成功：向接听设备转发 ANSWER 确认，向主叫 fanout ANSWER
   - 失败：向当前设备回复 BUSY
4. 向被叫其他设备发送 BUSY（取消响铃）

### 4.8 超时任务

**架构决策**：超时监控必须同时访问 `ImCallService`（module-system）和 `NettyMessageSender`（framework）。两者均有需要，因此**放在 module-system 层**，通过 Spring `@Scheduled` 实现，调用 `NettyMessageSender` Bean（已在 module-system 中可注入）。

位置：`system-biz/.../service/im/ImCallTimeoutMonitor.java`

```java
@Slf4j
@Component
@RequiredArgsConstructor
public class ImCallTimeoutMonitor {

    private final ImCallRecordMapper callRecordMapper;
    private final NettyMessageSender messageSender;
    private final ImCallServiceImpl callService;

    // 扫描 RINGING / CONNECTING 超时的通话，每 5 秒执行一次
    @Scheduled(fixedDelay = 5000)
    public void scanTimeout() {
        List<ImCallRecordDO> ringingList = callRecordMapper.selectByStates(
            List.of("RINGING"), LocalDateTime.now().minusSeconds(ringTimeoutSec));
        for (ImCallRecordDO record : ringingList) {
            TenantUtils.execute(record.getTenantId(), () -> {
                callService.endCall(record.getCallId(), null, "TIMEOUT", ImCallStatusEnum.MISSED.getStatus());
                broadcastTimeout(record);
            });
        }
        // 同理处理 CONNECTING 超时（connectTimeoutSec）
    }

    private void broadcastTimeout(ImCallRecordDO record) {
        // 向主叫和被叫所有设备广播 CALL_SIGNAL(signalType=11/TIMEOUT)
        messageSender.sendToUser(record.getCallerId(), MessageType.CALL_SIGNAL, buildTimeoutBody(record), ...);
        messageSender.sendToUser(record.getCalleeId(), MessageType.CALL_SIGNAL, buildTimeoutBody(record), ...);
    }
}
```

`ImCallRecordMapper` 需新增：
```java
// 查询指定状态且 start_time 早于 deadline 的通话
List<ImCallRecordDO> selectByStates(@Param("states") List<String> states,
                                    @Param("deadline") LocalDateTime deadline);
```

SQL：`WHERE state IN (...) AND start_time < #{deadline} AND deleted = 0`

---

## 5. 服务端待实现清单（按文件级）

### 5.0 架构分层约束（必读，开工前冻结）

**关键约束**：`shengyu-framework` 不允许依赖 `shengyu-module-system`。`CallSignalMessageProcessor` 在 framework 层，`ImCallService` 在 module-system 层，两者不能直接调用。

**解决方案：复用已有 SPI 模式**，类似 `MessageStorageService`（framework 层定义接口，module-system 层注入实现）：

```
framework 层定义：
  CallSignalService（接口，位置：shengyu-framework/.../websocket/spi/CallSignalService.java）

module-system 层实现：
  SystemCallSignalServiceImpl（位置：system-biz/.../service/im/spi/SystemCallSignalServiceImpl.java）
  → 注入 ImCallService、ImCallRecordMapper、NettyMessageSender
  → 通过 @Component 自动注册到 framework 的 CallSignalMessageProcessor
```

`CallSignalService` 接口定义（framework 层）：

```java
public interface CallSignalService {
    /** 处理主叫发起呼叫，返回生成的 callId */
    String handleCall(Long callerId, Long calleeId, Integer callType, String tenantId);
    /** 处理被叫接听，返回裁决结果：ACCEPTED / BUSY */
    CallAnswerResult handleAnswer(String callId, Long userId, String deviceId);
    /** 处理拒绝 */
    void handleReject(String callId, Long userId, String reason);
    /** 处理挂断（主叫取消 / 正常挂断），返回通话记录 */
    ImCallEndResult handleHangup(String callId, Long userId);
    /** 查询当前通话状态（断线重连 STATE_SYNC 用） */
    CallStateResult queryState(String callId, Long userId);
    /** 校验是否允许发起通话（忙线检测） */
    boolean isCalleeAvailable(Long calleeId);
}

// 裁决结果
public enum CallAnswerResult { ACCEPTED, BUSY, NOT_FOUND }
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
        CallSignalService callSignalService,  // SPI 接口，由 module-system 注入实现
        MessageProcessorFactory processorFactory) {
    CallSignalMessageProcessor processor = new CallSignalMessageProcessor(
        sessionManager, messageSender, callSignalService);
    processorFactory.registerProcessor(MessageType.CALL_SIGNAL, processor);
    log.info("[Netty] 注册通话信令处理器");
    return processor;
}
```

**注意**：`CallSignalMessageProcessor` 不注入 `MessageStorageService`——通话信令为瞬态事件，不走「先存储后投递」门禁。仅通话结束时产生通话记录消息才走标准存储链路。

**各 signalType 处理逻辑（权威伪代码）**：

```
signalType=1 CALL（主叫发起）：
  1. callSignalService.isCalleeAvailable(calleeId) → 否则回复 BUSY 给主叫并退出
  2. callId = callSignalService.handleCall(callerId, calleeId, callType, tenantId)
  3. 构造 CALL_SIGNAL(signalType=1, callId=callId) 发送给：
     - messageSender.sendToUser(calleeId, ...) // fanout 到被叫所有在线设备
  4. 回显给主叫（确认呼叫已发出，携带 callId）

signalType=2 ANSWER（被叫接听）：
  1. result = callSignalService.handleAnswer(callId, userId, session.deviceId)
  2. if result == ACCEPTED:
     - 向主叫 sendToUser(callerId, CALL_SIGNAL(signalType=2, callId))
     - 向被叫其他设备 sendToUser(calleeId, CALL_SIGNAL(signalType=5/BUSY))  // 排除 accepted deviceId
  3. if result == BUSY:
     - 仅向当前设备回复 CALL_SIGNAL(signalType=5/BUSY)

signalType=3 REJECT（被叫拒绝）：
  1. callSignalService.handleReject(callId, userId, rejectReason)
  2. 向主叫 sendToUser(callerId, CALL_SIGNAL(signalType=3, rejectReason))
  3. 向被叫其他设备 sendToUser(calleeId, CALL_SIGNAL(signalType=11/TIMEOUT 或 4/HANGUP))  // 取消其他端响铃

signalType=4 HANGUP（挂断 / 主叫取消）：
  1. result = callSignalService.handleHangup(callId, userId)
  2. 向对端 sendToUser(otherUserId, CALL_SIGNAL(signalType=4, endReason))
  3. 向自己其他设备 sendToUser(userId, CALL_SIGNAL(signalType=4))
  4. 通话记录消息生成（见 §5.4）

signalType=7 SDP_OFFER / signalType=8 SDP_ANSWER（WebRTC 协商，纯透传）：
  1. callSignalService.queryState(callId, userId) → 验证通话状态为 CONNECTING
  2. 直接向对端 accepted device 转发原消息（保留 extraData）
  3. 不落库，不修改状态

signalType=9 ICE_CANDIDATE（纯透传）：
  1. 直接向对端转发，不做状态校验（ICE 可在任意时刻交换）

signalType=10 STATE_SYNC（服务端主动下发，Processor 不处理客户端发来的此类型）：
  1. 收到则忽略（服务端才会主动发此消息）

signalType=6 SWITCH_CAMERA（纯透传）：
  1. 直接向对端转发
```

**发送 CALL_SIGNAL 的统一工具方法**（Processor 内部）：

```java
private void sendCallSignal(Long toUserId, String callId, Integer callType,
                             Integer signalType, Long callerId, Long calleeId,
                             String rejectReason, String extraData, Long tenantId) {
    CallSignalMessage body = CallSignalMessage.newBuilder()
        .setCallId(callId)
        .setCallType(callType)
        .setSignalType(signalType)
        .setCallerId(callerId)
        .setCalleeId(calleeId)
        .setRejectReason(rejectReason != null ? rejectReason : "")
        .setExtraData(extraData != null ? extraData : "")
        .build();
    messageSender.sendToUser(toUserId, MessageType.CALL_SIGNAL, body,
        callerId, calleeId, null, tenantId, generateMessageId(), null, null, null, null);
}
```

### 5.2 REST API（待新建）

位置：`shengyu-module-system/.../controller/app/im/AppImCallController.java`

| 能力 | HTTP URL | 方法 | 说明 |
|------|----------|------|------|
| 通话记录列表 | GET /system/im/call/records | getCallRecords | 按 userId 分页查询 |
| 两人通话记录 | GET /system/im/call/records-between | getCallRecordsBetween | 按 userId1+userId2 查询 |
| 通话详情 | GET /system/im/call/detail?callId= | getCallDetail | 按 callId 查询 |
| TURN 配置 | GET /system/im/call/turn-config | getTurnConfig | 返回 STUN/TURN 服务器配置 |

**说明**：通话的发起/接听/拒绝/挂断全部走 WS 信令，不走 REST。REST 仅用于查询通话记录和获取 TURN 配置。

### 5.3 TURN 配置（待实现）

```yaml
# application.yaml 新增
shengyu:
  im:
    rtc:
      enabled: false  # 灰度开关
      stun-servers:
        - "stun:stun.l.google.com:19302"
      turn-servers:
        - url: "turn:turn.example.com:3478"
          username: "${TURN_USERNAME}"
          credential: "${TURN_CREDENTIAL}"
      ringing-timeout-seconds: 30
      connecting-timeout-seconds: 60
```

### 5.4 通话记录消息生成

**决策（冻结）**：**新增 `CALL_RECORD = 209`**，不复用 CALL_SIGNAL(206)。理由：信令消息为瞬态，记录消息需要 sequence、进消息列表、展示 UI，语义完全不同，复用会导致 `buildConversationPreview` 逻辑混乱。

**proto 需补充**（`im_message.proto`）：

```protobuf
CALL_RECORD = 209;  // 通话记录消息（通话结束后生成，进消息列表）

message CallRecordMessage {
  string callId = 1;
  int32 callType = 2;   // 1-语音 2-视频
  int32 duration = 3;   // 通话时长（秒）
  int32 status = 4;     // 1-未接听 2-已接听 3-已拒绝 4-忙线 5-已取消
  string endReason = 5; // HANGUP/REJECT/TIMEOUT/BUSY/CANCEL
  int64 callerId = 6;
  int64 calleeId = 7;
}
```

**触发时机**：`ImCallServiceImpl.endCall()` 最后调用 `MessageStorageService.saveMessageWithResult()`，消息由服务端构造（非端侧发送）。

**会话预览**（`SystemMessageStorageServiceImpl.buildConversationPreview()`）需补充：

```java
case CALL_RECORD:
    CallRecordMessage record = CallRecordMessage.parseFrom(body.getBody());
    if (record.getStatus() == ImCallStatusEnum.ANSWERED.getStatus()) {
        return record.getCallType() == 1 ? "[语音通话]" : "[视频通话]";
    }
    return "[未接听]";
```

**完整 body JSON 示例**（JSON 双栈）：

```json
{
  "callId": "abc-123-def",
  "callType": 1,
  "duration": 120,
  "status": 2,
  "endReason": "HANGUP",
  "callerId": "100001",
  "calleeId": "100002"
}
```

### 5.5 已有 ErrorCode

```java
// ErrorCodeConstants.java
CALL_RECORD_NOT_EXISTS = new ErrorCode(1_002_030_500, "通话记录不存在");
CALL_PERMISSION_DENIED = new ErrorCode(1_002_030_501, "无权操作该通话");
```

待新增：
```java
CALL_ALREADY_IN_PROGRESS = new ErrorCode(1_002_030_502, "对方正在通话中");
CALL_STATE_INVALID = new ErrorCode(1_002_030_503, "通话状态不允许此操作");
CALL_FEATURE_DISABLED = new ErrorCode(1_002_030_504, "音视频通话功能未启用");
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

| 文件 | 位置 | 职责 |
|------|------|------|
| `call-service.uts` | `services/call-service.uts` | 通话状态管理、信令收发、超时计时 |
| `webrtc-manager.uts` | `utils/webrtc-manager.uts` | PeerConnection 生命周期、SDP/ICE 管理 |
| `call.uts` | `api/call.uts` | REST API 封装（通话记录查询、TURN 配置获取） |
| `call.uvue` | `pages/message/call.uvue` | 通话 UI 页面（来电/通话中/结束） |

### 6.3 端侧通话状态机

```
IDLE -> OUTGOING_RINGING -> CONNECTING -> CONNECTED -> ENDED
IDLE -> INCOMING_RINGING -> CONNECTING -> CONNECTED -> ENDED
```

### 6.4 WebRTC 集成要点

- **Android/iOS**：uni-app x 需要 Native Plugin 封装 WebRTC
  - Android: `org.webrtc:google-webrtc` 或 libwebrtc
  - iOS: WebRTC.framework
- **Web**：直接使用 `RTCPeerConnection` API
  - 条件编译：`// #ifdef WEB` / `// #ifdef APP-ANDROID` / `// #ifdef APP-IOS`
- **STUN/TURN 配置**：通话前 `GET /system/im/call/turn-config` 获取

### 6.5 音频/视频采集约束

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
- `CallSignalMessageProcessor` 入口统一 `log.info("[CallSignal] callId={}, signalType={}, from={}, to={}")`
- 状态变更时 `log.info("[CallState] callId={}, {} -> {}", callId, oldState, newState)`

### 7.2 指标（建议，Phase 2）

| 指标名 | 说明 |
|--------|------|
| `im_call_invite_total` | 发起通话总数 |
| `im_call_answer_total` | 接听总数 |
| `im_call_connect_success_total` | SDP/ICE 连接成功数 |
| `im_call_end_total` | 通话结束总数（by endReason label） |
| `im_call_timeout_total` | 超时总数 |
| `im_call_duration_seconds` | 通话时长直方图 |

### 7.3 Trace

- 按 `callId` 聚合事件流（查 `im_call_event` 表）
- 端侧 WebRTC `getStats()` 数据可选上报

---

## 8. 灰度与开关

- **tenant 级开关**：`shengyu.im.rtc.enabled`（默认 false）
- **端侧入口控制**：获取配置后决定是否展示通话按钮
- **仅信令模式**：`shengyu.im.rtc.signal-only-mode=true`（Phase 0 联调用）
- 后续可扩展：user 白名单、deviceType 策略

---

## 9. 验收用例

### Phase 0（仅信令）

| 用例 | 验收标准 |
|------|---------|
| A 呼叫 B | B 所有在线设备收到 CALL_SIGNAL(signalType=1)，`im_call_record` 落库 |
| B 接听 | A 收到 ANSWER，状态推进 RINGING -> CONNECTING |
| B 拒绝 | A 收到 REJECT，状态推进 ENDED(REJECT) |
| 超时 | B 不操作 30s，A+B 收到 TIMEOUT，状态 ENDED(TIMEOUT) |
| 多端裁决 | B 两台设备，仅一台 ANSWER 成功，另一台收到 BUSY |
| 主叫取消 | A 在 B 接听前 HANGUP，B 收到结束通知 |
| 幂等 | 相同 messageId 重复发送不影响状态 |

### Phase 1（音频通话）

| 用例 | 验收标准 |
|------|---------|
| 1v1 音频 | 双方建立 WebRTC 连接，音频正常传输 |
| 挂断 | 任一方挂断，双方 UI 结束，`im_call_record` 记录时长 |
| 断线恢复 | B 断网 10s 恢复，能通过 STATE_SYNC 恢复最终态 |
| 通话记录 | 通话结束后聊天记录中出现通话记录消息 |

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

**目标**：验证状态机/多端/幂等/超时

**任务**：

| # | 任务 | 涉及文件 | 依赖 |
|---|------|---------|------|
| R0.1 | 新增 `ImCallSignalTypeEnum`/`ImCallStateEnum`/`ImCallEndReasonEnum` | `system-api/.../enums/im/` | - |
| R0.2 | `im_call_record` 新增 state/endReason/acceptedDeviceId/chatId 字段 | DDL + `ImCallRecordDO` | - |
| R0.3 | 重构 `ImCallServiceImpl`：加入状态机推进、CAS 并发裁决 | `ImCallServiceImpl.java` | R0.1, R0.2 |
| R0.4 | 新建 `CallSignalMessageProcessor` + 注册到 `NettyAutoConfiguration` | `processor/impl/` + `config/` | R0.3 |
| R0.5 | 新建 `ImCallTimeoutMonitor` | `session/` | R0.3 |
| R0.6 | 新建 `AppImCallController`（通话记录查询） | `controller/app/im/` | R0.3 |
| R0.7 | 端侧 `call-service.uts` + WS 信令收发 | `services/` + `api/` | R0.4 |
| R0.8 | 端侧 `call.uvue` 来电/拨号 UI | `pages/message/` | R0.7 |

### Phase 1：接入 WebRTC，1v1 音频

| # | 任务 | 涉及文件 | 依赖 |
|---|------|---------|------|
| R1.1 | TURN 配置与 REST API | `application.yaml` + Controller | R0.6 |
| R1.2 | 端侧 `webrtc-manager.uts` Native Plugin 封装 | `utils/` | R0.7 |
| R1.3 | SDP/ICE 信令透传闭环 | Processor + 端侧 | R0.4, R1.2 |
| R1.4 | 通话记录消息生成（CALL_RECORD） | `SystemMessageStorageServiceImpl` | R0.3 |
| R1.5 | 联调：Android + iOS + Web 1v1 音频 | 全链路 | R1.1-R1.4 |

### Phase 2：视频、弱网优化、可观测增强

| # | 任务 |
|---|------|
| R2.1 | 视频采集与渲染 |
| R2.2 | 音视频切换 |
| R2.3 | 弱网自适应（码率/分辨率调整） |
| R2.4 | `im_call_event` 事件流水表落地 |
| R2.5 | 质量指标采集与上报 |

---

## 附录 A：现有代码清单（已实现 vs 待实现）

| 组件 | 状态 | 文件路径 |
|------|------|---------|
| proto `CallSignalMessage` | 已实现 | `shengyu-framework/.../proto/im_message.proto:295` |
| `MessageType.CALL_SIGNAL(206)` | 已实现 | `im_message.proto:89` |
| `ImCallTypeEnum` | 已实现 | `system-api/.../enums/im/ImCallTypeEnum.java` |
| `ImCallStatusEnum` | 已实现 | `system-api/.../enums/im/ImCallStatusEnum.java` |
| DDL `im_call_record` | 已实现 | `sql/mysql/1.0/im/ddl_im_tables.sql:442` |
| `ImCallRecordDO` | 已实现 | `system-biz/.../dal/dataobject/im/ImCallRecordDO.java` |
| `ImCallRecordMapper` | 已实现 | `system-biz/.../dal/mysql/im/ImCallRecordMapper.java` |
| `ImCallService` 接口 | 已实现 | `system-biz/.../service/im/ImCallService.java` |
| `ImCallServiceImpl` | 已实现（需重构） | `system-biz/.../service/im/ImCallServiceImpl.java` |
| ErrorCode | 已实现 | `ErrorCodeConstants.java:1_002_030_500-501` |
| 会话预览 `[通话]` | 已实现 | `SystemMessageStorageServiceImpl.java:909` |
| 端侧 `CALL_SIGNAL=206` | 已实现 | `utils/websocket.uts:75` |
| `CallSignalMessageProcessor` | **待实现** | `processor/impl/CallSignalMessageProcessor.java` |
| 处理器注册 | **待实现** | `NettyAutoConfiguration.java` |
| `ImCallTimeoutMonitor` | **待实现** | `session/ImCallTimeoutMonitor.java` |
| `AppImCallController` | **待实现** | `controller/app/im/AppImCallController.java` |
| TURN 配置 | **待实现** | `application.yaml` |
| 端侧 `call-service.uts` | **待实现** | `services/call-service.uts` |
| 端侧 `webrtc-manager.uts` | **待实现** | `utils/webrtc-manager.uts` |
| 端侧 `call.uvue` | **待实现** | `pages/message/call.uvue` |
| 端侧 `api/call.uts` | **待实现** | `api/call.uts` |
| `ImCallStateEnum` | **待实现** | `enums/im/ImCallStateEnum.java` |
| `ImCallEndReasonEnum` | **待实现** | `enums/im/ImCallEndReasonEnum.java` |
| `ImCallSignalTypeEnum` | **待实现** | `enums/im/ImCallSignalTypeEnum.java` |
| DDL `im_call_event` | **待实现（Phase 2）** | `sql/mysql/1.0/im/` |

---

## 11. 移动端 UI 设计规范（开工参考）

> 本节为 `call.uvue` 实现提供可落地的界面规格，参考微信 iOS/Android 通话 UI 实际行为、FaceTime PiP 交互标准及业界最佳实践整理，覆盖"来电 → 拨出等待 → 通话中 → 结束"完整生命周期。

### 11.1 界面状态清单与路由

`call.uvue` 是单页面，通过 `callUiState` 内部状态切换视图，**不跳转新页面**，避免来电被路由栈打断。

| UI 状态（`callUiState`） | 对应端侧通话状态 | 触发来源 |
|--------------------------|----------------|---------|
| `INCOMING` | `IDLE`（收到信令 CALL） | WS CALL_SIGNAL(1) 推送 |
| `OUTGOING_RINGING` | `OUTGOING_RINGING` | 用户主动发起 |
| `CONNECTING` | `CONNECTING` | 己方 ANSWER 成功 / 对方 ANSWER 成功 |
| `CONNECTED_VOICE` | `CONNECTED`（callType=1） | ICE 连通 |
| `CONNECTED_VIDEO` | `CONNECTED`（callType=2） | ICE 连通 |
| `ENDED` | `ENDED` | HANGUP/REJECT/TIMEOUT/BUSY 任一 |
| `MINIMIZED` | 任何通话中状态 | 用户退出页面 / 点击最小化 |

**路由约定**：
- 来电触发：`call-service.uts` 收到 CALL 信令后，若当前不在 call 页面，`uni.navigateTo({ url: '/pages/message/call' })` 并传入 `callId`
- 主动拨出：聊天页面或联系人页面按钮触发，携带 `targetUserId` 和 `callType` 跳转

---

### 11.2 来电界面（`callUiState = INCOMING`）

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
| 拒接后"发消息"入口 | 拒绝按钮下方显示"发消息"（12px 文字按钮，可选实现） | 同左 |

#### 振铃行为

- 进入 `INCOMING` 状态时立刻调用 `uni.vibrate()` + 播放系统铃声
- 离开 `INCOMING`（接听 / 拒绝 / 超时）时停止振铃

---

### 11.3 拨出等待界面（`callUiState = OUTGOING_RINGING`）

#### 布局结构

```
┌────────────────────────────────┐
│                                │
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

#### 取消按钮

- 样式：红色圆形，直径 64px，电话挂断图标（话筒斜向下）
- 位置：垂直居中偏下（约屏幕高度 75% 处），水平居中
- 文字标签：按钮下方 8px，"取消"（12px，白色 70% 透明）

---

### 11.4 通话中界面

#### 11.4.1 语音通话（`callUiState = CONNECTED_VOICE`）

```
┌────────────────────────────────┐
│  [最小化 ↙]         [通话中…]  │  ← 顶部工具栏（状态栏下方）
│                                │
│                                │
│        ┌──────────┐            │
│        │  AVATAR  │            │  ← 对方头像（直径 64px，居中偏上）
│        └──────────┘            │
│         对方昵称               │
│      ⏱  00:05:23               │  ← 通话计时器（绿色，居中）
│                                │
│                                │  ← 大面积空白区（防误触）
│                                │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ 静音 │ │扬声器│ │ 键盘 │   │  ← 次控制栏（3个灰色圆角方块，可选）
│  └──────┘ └──────┘ └──────┘   │
│                                │
│         ┌──────────┐           │
│         │   挂断   │           │  ← 红色圆形大按钮，居中
│         └──────────┘           │
└────────────────────────────────┘
```

**次控制栏按钮规范**：

| 按钮 | 图标 | 激活状态视觉 |
|------|------|------------|
| 静音 | 麦克风图标 | 激活时图标变白 + 背景变深，图标加斜线 |
| 扬声器 | 扬声器图标 | 激活时同上 |
| 键盘 | 九宫格图标 | 点击展开数字键盘浮层 |

#### 11.4.2 视频通话（`callUiState = CONNECTED_VIDEO`）

```
┌────────────────────────────────┐
│                                │  ← 对方视频画面铺满全屏（SurfaceView/VideoView）
│                        ┌────┐  │
│                        │己方│  │  ← 本地预览小窗（PiP）
│                        │预览│  │     默认位置：右上角
│                        └────┘  │     尺寸：宽屏高比 9:16，约 90×120pt
│                                │     圆角：8pt，阴影深度 4dp
│       [对方名字  00:05:23]      │  ← 状态叠加文字（仅在控制栏显示时可见）
│                                │
│                                │
│                                │
│                                │
├────────────────────────────────┤
│  [关摄] [静音] [翻转] [ 挂断 ] │  ← 底部控制栏（半透明黑底 #00000080）
└────────────────────────────────┘
```

**本地预览小窗（PiP）行为规范**：

| 属性 | 规范 |
|------|------|
| 默认位置 | 右上角，距右边缘 12px，距安全区顶部 12px |
| 可拖拽 | 支持拖拽，松手后**吸附到最近的四角** |
| 四角安全边距 | 距屏幕边缘 12px，距安全区上下 12px |
| 拖拽时样式 | 轻微放大至 1.05x + 投影增强（elevation +2dp） |
| 点击己方小窗 | 主副画面交换（大画面 ↔ 小窗内容互换） |
| 对方无画面时 | 小窗退化为对方头像占位图 |

**底部控制栏按钮规范**：

| 按钮 | 图标 | 状态说明 |
|------|------|---------|
| 关闭摄像头 | 摄像机图标 | 关闭时图标加斜线，己方小窗变黑屏+头像 |
| 静音麦克风 | 麦克风图标 | 静音时图标加斜线 |
| 前后摄像头切换 | 摄像机+旋转箭头 | 点击后执行 0.3s 水平翻转过渡动画 |
| 挂断 | 电话挂断图标 | 常态红色圆形大按钮，不缩小 |

**控制栏自动隐藏**：
- 无操作 4 秒后控制栏渐隐（透明度 1.0 → 0，动画时长 0.3s）
- 点击屏幕任意非按钮区域重新显示（反向渐显）

---

### 11.5 通话结束界面（`callUiState = ENDED`）

```
┌────────────────────────────────┐
│                                │
│   （在通话中界面上叠加遮罩层） │
│                                │
│          对方头像               │  ← 渐淡，透明度从 1.0 → 0.4
│                                │
│       [结束状态文案]            │
│     通话时长  05:23            │  ← 仅在正常接通时显示
│                                │
│                                │
│                                │
└────────────────────────────────┘
```

**结束文案映射**：

| `endReason` / 场景 | 显示文案 | 时长行是否显示 |
|--------------------|---------|--------------|
| `HANGUP`（正常挂断） | `通话时长 MM:SS` | 显示 |
| `REJECT`（对方拒绝） | `对方已拒绝` | 不显示 |
| `TIMEOUT`（无人接听） | `对方未接听` | 不显示 |
| `CANCEL`（主叫取消） | `通话已取消` | 不显示 |
| `BUSY`（对方忙线） | `对方正在通话中` | 不显示 |
| 网络断开 | `通话已断开` | 不显示 |

**自动消失机制**：
- 展示 2.5 秒后自动 `uni.navigateBack()` 返回聊天界面
- 若用户在 2.5 秒内点击"再次通话"，重置状态并立刻发起

---

### 11.6 悬浮窗（`callUiState = MINIMIZED`）

#### 触发时机
1. 用户在通话中按下 Home 键 / 手势上划退到后台
2. 用户点击通话界面内"最小化"按钮（顶部左上角 `[↙]`）

#### 平台差异

**iOS（`AVPictureInPictureController`）**：
- 系统级 PiP 窗口，小圆角矩形浮在所有 App 上方
- 内容：**仅能显示己方摄像头画面**（系统权限限制，无法显示对方）
- 语音通话降级：显示头像 + 计时器的自定义视图（非系统 PiP）
- 点击悬浮窗：拉起 `call.uvue` 页面回到全屏

**Android（`WindowManager` 自绘）**：
- 自绘悬浮窗（需 `SYSTEM_ALERT_WINDOW` 权限）
- 内容：对方头像 + 通话计时器（语音）；双方缩略画面（视频，Phase 2）
- 初始位置：右上角，可全屏拖拽
- 尺寸：64×64dp 圆形（语音）/ 90×120dp 圆角矩形（视频）

#### 组件落点

悬浮窗逻辑提取到独立组件，避免与 `call.uvue` 主逻辑耦合：

```
utils/call-float-window.uts   ← 悬浮窗创建/销毁/更新（platform-specific）
// #ifdef APP-IOS
  → 调用 Native Plugin: RTCPiPController.startPiP() / stopPiP()
// #endif
// #ifdef APP-ANDROID
  → 调用 Native Plugin: FloatWindowManager.show() / hide() / update()
// #endif
```

---

### 11.7 聊天消息列表中的通话气泡

通话结束后服务端产生 `CALL_RECORD(209)` 消息，端侧在聊天消息列表中渲染为通话气泡。

#### 气泡样式规范

```
┌────────────────────────────────────┐
│  [📞/📹 图标]  通话类型  时长/状态  │   ← 宽度约 160px，高度 48px
└────────────────────────────────────┘
```

**字段映射**：

| `callType` | `status` | 图标 | 图标朝向 | 文案 | 文字颜色 |
|-----------|---------|------|---------|------|---------|
| 1（语音） | 2（已接通） | 电话图标 | 右上 45°（拨出方）/ 左下 -45°（来电方） | `语音通话 MM:SS` | 正常 |
| 2（视频） | 2（已接通） | 摄像机图标 | 同上 | `视频通话 MM:SS` | 正常 |
| 1/2 | 1（未接听） | 电话图标 | 左下（来电方未接听） | `未接听` | `#FF4444`（红） |
| 1/2 | 3（已拒绝） | 电话图标 | — | `已拒绝` | 灰色 |
| 1/2 | 5（已取消） | 电话图标 | — | `已取消` | 灰色 |
| 1/2 | 4（忙线） | 电话图标 | — | `对方忙线` | 灰色 |

**图标朝向规则**（参考系统电话记录图标惯例）：
- 拨出方视角（己方 = 呼叫者）：图标斜向右上 45°
- 接入方视角（己方 = 被呼叫者）：图标斜向左上 45°（来电接通）或斜向左下 -45°（漏接）

**未接听气泡特殊处理**：
- 气泡背景色添加轻微红色提示（`#FFF0F0` 或在深色模式下 `#3D1F1F`）
- 文字颜色变红 `#FF4444`
- 未接听通话应在会话列表预览中显示为 `[未接听]` 红色文字

**点击气泡行为**：点击通话气泡 → 展示通话详情弹窗（时长、时间、呼叫类型）+ "再次呼叫"按钮

#### 气泡实现落点

在聊天消息渲染器中新增 `CALL_RECORD = 209` 分支：

```typescript
// pages/message/components/message-item.uvue（或同等渲染组件）
case MessageType.CALL_RECORD:
  return renderCallRecordBubble(message.body as CallRecordMessage)
```

---

### 11.8 麦克风 / 摄像头权限请求流程

#### 时机（Just-in-Time，即时请求）

```
用户点击"发起通话"按钮
       ↓
call-service.uts: checkAndRequestPermissions(callType)
       ↓
   已授权？
  ├─ Yes → 直接发起
  └─ No  → 显示说明弹窗 → 系统权限弹框
               ↓
           用户拒绝 → 显示引导弹窗（"去设置"按钮）→ 跳转系统设置
```

**权限按通话类型申请**：

| 通话类型 | 必需权限 |
|---------|---------|
| 语音通话 | 麦克风（`RECORD_AUDIO` / `NSMicrophoneUsageDescription`） |
| 视频通话 | 麦克风 + 摄像头（`CAMERA` / `NSCameraUsageDescription`） |

**uni-app x 权限 API**：

```typescript
// call-service.uts 权限检查伪代码
async function checkAndRequestPermissions(callType: number): Promise<boolean> {
  const permissions = callType === 2
    ? ['android.permission.CAMERA', 'android.permission.RECORD_AUDIO']
    : ['android.permission.RECORD_AUDIO']
  // #ifdef APP-ANDROID
  const result = await uni.requestPermissions({ permissions })
  // #endif
  // #ifdef APP-IOS
  // iOS 通过 AVCaptureDevice.requestAccess() Native Plugin 调用
  // #endif
  return result.every(r => r.authStatus === 'authorized')
}
```

**系统权限 Info.plist / AndroidManifest 字段**（开工时在配置文件补充）：

```xml
<!-- Android: AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />  <!-- 悬浮窗 -->

<!-- iOS: Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限用于语音/视频通话</string>
<key>NSCameraUsageDescription</key>
<string>需要摄像头权限用于视频通话</string>
```

---

### 11.9 交互动效规范

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

### 11.10 平台适配说明（uni-app x）

| 特性 | Web 端 | Android | iOS |
|------|--------|---------|-----|
| WebRTC | 直接用浏览器 API | Native Plugin（libwebrtc） | Native Plugin（WebRTC.framework） |
| 悬浮窗 | 不支持（页面内 overlay） | `WindowManager` Native Plugin | `AVPictureInPictureController` |
| 系统来电界面 | 不适用 | `ConnectionService` API（可选，Phase 2） | `CallKit` 框架（可选，Phase 2） |
| 振铃 | `HTMLAudioElement` | 系统铃声 / `AudioManager` | `AVAudioSession` |
| 权限申请 | 浏览器 `getUserMedia` 弹框 | `uni.requestPermissions` | Info.plist + 系统弹框 |
| PiP 小窗内显示对方画面 | 支持 | 支持（自绘 `WindowManager`） | 不支持（需特殊企业权限） |

**Phase 0 / Phase 1 仅实现**：
```
// #ifdef APP-ANDROID
  → 实现 Android 悬浮窗
// #endif
// #ifdef APP-IOS
  → 实现 iOS PiP（仅己方预览）
// #endif
// #ifdef WEB
  → 页面内 fixed overlay 模拟
// #endif
```

---

### 11.11 端侧 UI 文件级实现清单（补充 §6.2）

| 文件 | 职责 | Phase |
|------|------|-------|
| `pages/message/call.uvue` | 主通话页面，管理所有 `callUiState` 切换，渲染各状态视图 | Phase 0 |
| `pages/message/components/call-incoming.uvue` | 来电界面组件（可拆为独立组件） | Phase 0 |
| `pages/message/components/call-outgoing.uvue` | 拨出等待界面组件 | Phase 0 |
| `pages/message/components/call-voice-connected.uvue` | 语音通话中组件 | Phase 0 |
| `pages/message/components/call-video-connected.uvue` | 视频通话中组件 | Phase 1 |
| `pages/message/components/call-ended.uvue` | 通话结束组件 | Phase 0 |
| `pages/message/components/call-record-bubble.uvue` | 聊天记录中的通话气泡组件 | Phase 0 |
| `utils/call-float-window.uts` | 悬浮窗创建/销毁（平台 Native Plugin 调用） | Phase 1 |
| `utils/call-timer.uts` | 通话计时器（计秒 + 格式化 `MM:SS`） | Phase 0 |
| `utils/call-permission.uts` | 权限检查与请求封装 | Phase 0 |

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
  targetUserId: string
  targetNickname: string
  targetAvatar: string
}
```

