# IM Flutter 后端协同实施优先级清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 开工前后端协同改造的执行优先级、任务边界、完成定义  

---

## 1. 目标

把后端协同改造从“原则文档”推进到“可执行清单”，方便后续逐项落地。

---

## 2. P0 必做

### P0-1 出口层字符串化策略落地

任务：

- 建立 app 端 Response VO 字符串化规范
- 列出关键 VO 中的 ID / version / sequence 字段
- convert 层统一 `Long -> String`

范围：

- conversation
- message
- badge
- group
- contact
- search
- favorite
- read receipt

DoD：

- Flutter 主链路接口不再直接消费 `Long` 标识字段
- 新增 app 端 VO 时自动遵守统一规则

### P0-2 聊天气泡偏好边界冻结

任务：

- 保留 `/system/user/chat-bubble`
- 主题与语言从跨端一致性主链路剥离

DoD：

- Flutter 文档与后端接口边界一致
- 后续不再新增语言跨端同步接口

### P0-3 starter 中间件边界冻结

任务：

- 明确 `shengyu-spring-boot-starter-websocket` 不承载 IM 业务状态机
- 明确 call 业务闭环在业务模块实现

DoD：

- 后续改造不把会话/通话业务逻辑塞入 starter

---

## 3. P1 应做

### P1-1 session 系统事件正式化

任务：

- 统一 `reauth-required`
- 统一 `kicked`
- 统一 `invalidated`
- 统一 `revoked`

DoD：

- Flutter 不依赖 close reason 文本猜测状态

### P1-2 位置 provider 抽象化

任务：

- 将位置检索服务抽象为 provider-neutral facade

DoD：

- 后端服务内不再把供应商名称固化进业务语义

### P1-3 音视频业务层建模

任务：

- 新增 `AppImCallController`
- 新增 `ImCallService`
- 新增 `ImCallStateMachine`

DoD：

- Flutter 音视频文档可对接正式后端业务接口

---

## 4. P2 可延后

- app-level socket event envelope 进一步统一
- revoke / kicked 细化维度
- 多端更精细的 session 运维能力

---

## 5. 推荐执行顺序

1. 出口层字符串化
2. session 系统事件正式化
3. 音视频业务层建模
4. 位置 provider 抽象化

