# 多语言国际化 SQL 草案

## 文档关系

- 本文档是从属草案，服务于主文档：
  - `sql/doc/多语言国际化设计任务文档.md`
- 主文档负责：
  - 目标
  - 边界
  - 分层
  - 实施顺序
- 本文档负责：
  - SQL 草案
  - 表结构建议
  - 索引/唯一约束建议

若本文档与主文档冲突，以主文档为准；落库前需同步回写主文档。

## 1. 设计原则

- 平台级资源与租户级资源分表处理，不能混用。
- 错误码国际化属于平台级资源，不带 `tenant_id`。
- 通知模板国际化属于租户级资源，必须带 `tenant_id`。
- 用户语言偏好按用户主体分别落库：
  - `system_users`
  - `platform_users`

## 2. 用户偏好字段草案

### 2.1 `system_users`

```sql
ALTER TABLE system_users
    ADD COLUMN language_mode VARCHAR(16) NOT NULL DEFAULT 'system' COMMENT '语言模式(system/zh-CN/en)';
```

### 2.2 `platform_users`

```sql
ALTER TABLE platform_users
    ADD COLUMN language_mode VARCHAR(16) NOT NULL DEFAULT 'system' COMMENT '语言模式(system/zh-CN/en)';
```

### 2.3 字段约束建议

- 合法值：
  - `system`
  - `zh-CN`
  - `en`
- 首期默认值：
  - `system`

## 3. 平台错误码国际化表草案

### 3.1 建表草案

```sql
CREATE TABLE platform_error_code_i18n (
    id BIGINT NOT NULL COMMENT '主键',
    code INT NOT NULL COMMENT '错误码',
    locale VARCHAR(16) NOT NULL COMMENT '语言标识',
    message VARCHAR(512) NOT NULL COMMENT '国际化文案',
    creator VARCHAR(64) DEFAULT '' COMMENT '创建者',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) DEFAULT '' COMMENT '更新者',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_code_locale_deleted (code, locale, deleted)
) COMMENT='平台错误码国际化表';
```

### 3.2 说明

- 不带 `tenant_id`
- `code` 对应 `platform_error_code.code`
- `locale` 建议统一使用：
  - `zh-CN`
  - `en`

## 4. 租户通知模板国际化表草案

### 4.1 建表草案

```sql
CREATE TABLE system_notify_template_i18n (
    id BIGINT NOT NULL COMMENT '主键',
    template_id BIGINT NOT NULL COMMENT '模板ID',
    locale VARCHAR(16) NOT NULL COMMENT '语言标识',
    title VARCHAR(256) NOT NULL COMMENT '标题',
    content TEXT NOT NULL COMMENT '内容',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) DEFAULT '' COMMENT '创建者',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) DEFAULT '' COMMENT '更新者',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted BIT(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
    PRIMARY KEY (id),
    UNIQUE KEY uk_template_locale_tenant_deleted (template_id, locale, tenant_id, deleted)
) COMMENT='站内信模板国际化表';
```

### 4.2 说明

- 必须带 `tenant_id`
- `template_id` 对应 `system_notify_template.id`
- 不允许跨租户共用同一条业务翻译记录

## 5. IM 系统消息存储草案

## 5.1 推荐方案

- 不强制新增 `im_message` 字段
- 复用现有 `extra` JSON

建议结构：

```json
{
  "i18n": {
    "version": 1,
    "eventKey": "im.system.group_owner_transferred",
    "params": {
      "newOwnerId": "2038796635523633155",
      "newOwnerName": "Alice"
    }
  }
}
```

## 5.2 说明

- 只用于系统消息
- 不用于用户原始聊天内容
- 老历史消息不强制补齐

## 6. 落库前检查清单

- 是否已与 `多语言国际化设计任务文档.md` 口径一致
- 是否已明确平台级 / 租户级 / 用户级归属
- 是否已确认当前数据库方言和索引命名规范
- 是否已确认 `language_mode` 默认值和历史数据回填策略
