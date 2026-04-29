# IM Flutter 架构与工程规范 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 工程结构、编码规范、模块边界、基础设施约束  

---

## 1. 总则

本项目是企业级多端 IM 客户端，不允许以 Demo、单页堆逻辑、弱类型胶水代码的方式推进。

工程规范目标：

- 便于多人协作
- 便于 AI 持续开发
- 便于测试
- 便于多端适配
- 便于长期演进

---

## 2. 工程目录规范

```text
lib/
  app/
    bootstrap/
    router/
    theme/
    l10n/
    shell/
  core/
    auth/
    network/
    websocket/
    storage/
    formatting/
    dict/
    avatar/
    navigation/
    platform/
      push/
      map/
      rtc/
    logging/
    error/
    analytics/
  features/
    login/
    im/
      conversation/
      chat/
      call/
      group/
      contact/
      search/
      favorite/
      receipt/
      media/
    profile/
    workbench/
  shared/
    widgets/
    layout/
    extensions/
    constants/
    enums/
```

---

## 3. 分层职责

### 3.1 presentation

只负责：

- 页面
- 组件
- UI 状态
- 用户动作派发

禁止：

- 直接调用 raw API
- 直接处理 DTO
- 直接读写复杂缓存

### 3.2 application

负责：

- use case
- 协调器
- controller / notifier
- feature 内编排

### 3.3 domain

负责：

- entity
- value object
- repository contract
- business rule
- policy

### 3.4 infrastructure

负责：

- datasource
- dto
- dio
- websocket codec
- local db
- storage implementation
- platform service implementation

---

## 4. 状态管理规范

统一采用：

- `Riverpod`

规则：

1. 页面状态通过 provider 暴露
2. provider 命名遵循 `xxxControllerProvider`
3. controller 状态必须是强类型对象
4. 不允许页面以多个零散 `bool` 拼复杂状态机

---

## 5. 路由规范

统一采用：

- `go_router`

规则：

1. 所有页面必须有明确 path 与 name
2. 所有业务跳转必须有强类型参数对象
3. 聊天页入口必须统一走 `ChatEntryArgs`
4. 禁止在页面中手写 query 字符串协议

---

## 6. 网络层规范

统一采用：

- `Dio`

必须实现：

- `AuthInterceptor`
- `TenantInterceptor`
- `LocaleInterceptor`
- `RequestIdInterceptor`
- `RefreshTokenCoordinator`

规则：

1. 401 刷新必须单飞
2. refresh 成功后等待中的请求统一重放
3. API 错误统一映射到业务异常模型

---

## 7. WebSocket 规范

WebSocket 实现名：

- `ImSocketClient`

必须具备：

- connect
- disconnect
- auth
- reauth
- heartbeat
- reconnect
- close reason handling
- event dispatch
- codec abstraction

规则：

1. socket 层不允许依赖页面
2. socket 层不允许持有消息列表 UI 状态
3. socket 事件先映射成 domain event，再进入 feature controller

### 7.1 外部能力接入规则

所有第三方基础设施能力必须通过 `adapter / facade` 接入。

包括但不限于：

- push
- map
- rtc
- 文件打开与文档服务

---

## 8. 数据模型规范

模型分三层：

1. DTO
2. Entity
3. UIModel

规则：

1. DTO 只存在于 infrastructure
2. Entity 不依赖 Flutter UI 类型
3. UIModel 不反向污染 Entity

---

## 9. 存储规范

### 9.1 secure storage

- token
- refreshToken
- tenantId
- deviceId

### 9.2 kv storage

- 主题
- 语言
- 搜索历史
- 草稿
- 视口恢复

### 9.3 structured storage

- 会话
- 消息
- 引用索引
- 语音播放状态
- 搜索缓存

规则：

1. 所有 storage key 集中定义
2. 禁止在页面/组件内拼接 key

---

## 10. 页面规范

页面文件结构建议：

- `page.dart`
- `controller.dart`
- `state.dart`
- `widgets/`
- `models/`

规则：

1. 单个页面文件不得承载 feature 全部逻辑
2. 单个页面文件超过合理体量时必须拆分 widgets 和 controller
3. 页面组件按 section 切分，不按视觉碎片切分

---

## 11. 组件规范

组件分级：

- `App-level reusable widgets`
- `Feature reusable widgets`
- `Page private widgets`

禁止：

- 为一次性样式抽象无意义组件
- 让通用组件持有业务 feature 特定逻辑

---

## 12. 异常与反馈规范

统一异常模型：

- network error
- auth error
- permission error
- business deny
- data inconsistency
- platform capability error

统一反馈方式：

- 页面级空态
- 行内错误
- toast/snackbar
- blocking dialog

---

## 13. 日志规范

日志分类：

- app
- auth
- network
- socket
- conversation
- chat
- media
- group

规则：

1. 关键链路必须带上下文 id
2. 错误日志必须可定位 feature 和动作
3. 禁止无意义大段 print

---

## 14. 多端适配规范

平台差异统一通过 adapter/service 封装：

- file picker
- image picker
- recorder
- audio player
- video player
- clipboard
- browser opener
- qr scanner
- app visibility
- window metrics

---

## 15. 测试规范

### 15.1 单元测试

覆盖：

- repository mapper
- controller 状态机
- business policy
- route args parser

### 15.2 集成测试

覆盖：

- 登录
- 会话列表
- 聊天页窗口加载
- 消息发送
- 搜索跳转
- 群设置关键动作

### 15.3 金丝雀验证

重点：

- token refresh -> ws reauth
- chat anchor locate
- revoke merge by rev
- read watermark

---

## 16. AI 协作开发规范

为了后续 AI 连续开发，必须保持：

1. 文档只写目标态设计
2. 目录和命名稳定
3. controller/state/entity/repository 契约先行
4. 一次只改单 feature 的有限边界

---

## 17. 禁止事项

1. 禁止页面直连 API
2. 禁止页面直接解析 JSON
3. 禁止在 Widget 中写复杂业务流程
4. 禁止让 WebSocket 客户端持有 UI 状态
5. 禁止用 `int/double` 存 ID 和 sequence
6. 禁止未抽象平台差异就直接写 if-platform 分支到业务层
