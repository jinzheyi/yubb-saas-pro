# 多语言国际化 Key 命名规范

## 文档关系

- 本文档是从属规范，服务于主文档：
  - `sql/doc/国际化/多语言国际化设计任务文档.md`
- 本文档负责：
  - key 命名约束
  - eventKey 命名约束
  - 首批 key 范围建议

若与主文档冲突，以主文档为准；新增命名规则需同步回主文档。

## 1. 总原则

- key 表达“语义”，不要表达“中文原文”。
- key 一旦对外使用，尽量保持稳定，不跟着页面标题频繁改名。
- 同类资源用同一前缀，避免后续搜索和治理困难。
- 页面文案 key、错误提示 key、IM 系统消息 eventKey 必须分层，不能混用。

## 2. 命名分层

### 2.1 前端页面文案

建议前缀：

- `common.*`
- `settings.language.*`
- `message.*`
- `group.*`

示例：

- `settings.language.title`
- `settings.language.followSystem`
- `settings.language.simplifiedChinese`
- `settings.language.english`

### 2.2 后端通用错误/提示

建议前缀：

- `web.request.*`
- `sys.api.*`
- `im.error.*`

示例：

- `web.request.param.missing`
- `web.request.param.invalid`
- `web.request.internal_error`
- `im.error.group_not_exists`
- `im.error.member_not_exists`

### 2.3 IM 系统消息 eventKey

建议前缀：

- `im.system.*`

示例：

- `im.system.message_recalled_by_self`
- `im.system.message_recalled_by_other`
- `im.system.group_owner_transferred`
- `im.system.group_member_joined`
- `im.system.group_member_removed`

### 2.4 通知模板 key

建议前缀：

- `notify.template.*`

示例：

- `notify.template.approval_result.title`
- `notify.template.approval_result.content`

## 3. 命名规则

- 小写英文
- 单词间使用 `.`
- 动作放后，不要过度缩写

推荐：

- `im.system.group_owner_transferred`

不推荐：

- `im.group.transferOwner.tip`
- `tip_group_owner_transfer`

## 4. 参数命名规则

- 参数名使用英文语义名
- 与业务字段尽量保持一致
- 不使用位置型参数名如 `arg1`、`arg2`

推荐：

```json
{
  "newOwnerName": "Alice",
  "operatorName": "Bob"
}
```

不推荐：

```json
{
  "name1": "Alice",
  "name2": "Bob"
}
```

## 5. 首批 key 清单建议

### 5.1 设置页语言切换

- `settings.language.title`
- `settings.language.followSystem`
- `settings.language.simplifiedChinese`
- `settings.language.english`
- `settings.language.switchSuccess`

### 5.2 后端通用异常

- `web.request.param.missing`
- `web.request.param.invalid`
- `web.request.not_found`
- `web.request.method_not_allowed`
- `web.request.file_too_large`
- `web.request.internal_error`

### 5.3 IM 错误提示

- `im.error.group_not_exists`
- `im.error.member_not_exists`
- `im.error.conversation_not_exists`
- `im.error.group_unavailable`

### 5.4 IM 系统消息

- `im.system.message_recalled_by_self`
- `im.system.message_recalled_by_other`
- `im.system.group_owner_transferred`
- `im.system.group_member_joined`
- `im.system.group_member_quit`
- `im.system.group_member_removed`
- `im.system.group_dissolved`
- `im.system.group_muted`
- `im.system.group_unmuted`

## 6. 边界提醒

- 用户原始聊天内容不使用 eventKey
- 用户备注、群公告、申请理由不使用 eventKey
- eventKey 只给系统生成内容使用

## 7. 维护规则

- 新增 key 前先搜索现有前缀，避免重复造轮子
- 新增 eventKey 时，必须同步补：
  - 后端事件生产位
  - 前端渲染位
  - 文档清单
- 修改既有 key 时，必须评估历史消息兼容性
