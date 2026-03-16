# 03 WebSocket 与实时闭环

本章覆盖：连接管理、重连、心跳、前后台切换、网络切换、消息投递与 ACK（协议层后续章节可扩展）。

## 3.1 现状（仓库对齐）

- WebSocket 工具：`shengyu-ui/shengyu-ui-admin-uniappx/utils/websocket.uts`

## 3.2 规范（Principles）

- **单连接管理**：同一账号/租户下仅允许一个“主连接管理器”。
- **可恢复**：必须具备
  - 指数退避重连
  - 心跳与超时检测
  - 前后台切换处理（避免后台耗电与无效重连）
- **可观测**：必须输出连接状态机日志（连接/断开/重连/失败原因）。

## 3.3 模板/封装落点（Where & How）

- 连接状态机建议：
  - idle -> connecting -> connected -> closing -> closed -> reconnecting
- 建议统一导出：
  - `connect()` / `disconnect()` / `send()`
  - `onMessage()` / `onStateChange()`

## 3.4 Reviewer Checklist

- 禁止项：页面直接创建 WebSocket 连接对象。
- 必须项：所有发送必须经过统一 send，禁止散落 `socket.send`。

## 3.5 常见问题（Troubleshooting）

- **频繁重连**：检查心跳间隔与服务器超时配置是否匹配；检查网络切换事件处理。
- **消息丢失**：需要协议层 ACK 与重放机制（后续专项）。
