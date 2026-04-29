# IM Flutter 第一阶段测试清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：第一阶段必须创建的测试文件、覆盖范围、优先级  

---

## 1. 目标

第一阶段测试只聚焦核心主链路，不追求全量覆盖，但必须覆盖最容易回归的企业级关键点。

---

## 2. 测试目录建议

```text
test/
  unit/
    core/
    features/
  widget/
    features/
  integration/
```

---

## 3. 第一阶段必须建的单元测试

### 3.1 core

- `test/unit/core/auth/refresh_token_coordinator_test.dart`
- `test/unit/core/network/auth_interceptor_test.dart`
- `test/unit/core/websocket/im_socket_client_test.dart`
- `test/unit/core/storage/storage_key_registry_test.dart`

覆盖重点：

- refresh 单飞
- 队列重放
- reauth 触发
- key 生成稳定

### 3.2 conversation

- `test/unit/features/im/conversation/conversation_sort_policy_test.dart`
- `test/unit/features/im/conversation/sync_conversations_incrementally_use_case_test.dart`
- `test/unit/features/im/conversation/conversation_dto_mapper_test.dart`

覆盖重点：

- 排序
- cursorVersion 推进
- conversationVersion 防回滚

### 3.3 chat

- `test/unit/features/im/chat/open_chat_use_case_test.dart`
- `test/unit/features/im/chat/load_chat_window_use_case_test.dart`
- `test/unit/features/im/chat/send_message_use_case_test.dart`
- `test/unit/features/im/chat/message_merge_policy_test.dart`
- `test/unit/features/im/chat/message_dto_mapper_test.dart`

覆盖重点：

- latest / anchor / restore
- 发送结果归并
- `rev` 保护

---

## 4. 第一阶段必须建的 widget 测试

- `test/widget/features/im/conversation/conversation_list_page_test.dart`
- `test/widget/features/im/chat/chat_page_test.dart`
- `test/widget/features/im/chat/message_bubble_factory_test.dart`

覆盖重点：

- 列表基本渲染
- 聊天页基本渲染
- 各消息类型映射到正确组件

---

## 5. 第一阶段集成测试建议

- `test/integration/login_to_conversation_flow_test.dart`
- `test/integration/open_chat_latest_flow_test.dart`
- `test/integration/open_chat_anchor_flow_test.dart`
- `test/integration/send_text_message_flow_test.dart`

覆盖重点：

- 登录进入主壳
- 点击会话进入聊天页
- 锚点打开
- 文本发送

---

## 6. 第一阶段测试优先级

### P0

- refresh coordinator
- conversation sync
- open chat
- send text
- message merge by rev

### P1

- widget 渲染
- route args
- storage key

### P2

- 集成测试的更多分支

---

## 7. Mock 规范

第一阶段建议：

- repository 接口可 mock
- datasource 层可 fake
- socket client 提供 fake event stream

---

## 8. 第一阶段暂不测的内容

暂不优先：

- 所有媒体类型真机行为
- 群治理全动作
- 搜索分页全部分支
- 收藏再转发

---

## 9. 验收标准

第一阶段进入正式开发前，至少应保证：

1. 关键单元测试文件已建
2. P0 用例能跑
3. 聊天页主状态机至少有核心测试

