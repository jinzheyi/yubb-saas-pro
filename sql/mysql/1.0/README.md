# 数据库变更管理规范

## 目录结构

```
sql/mysql/1.0/
├── shengyu-saas.sql          # 主SQL文件(包含所有现有业务表)
├── quartz.sql                # Quartz 定时任务表
├── README.md                 # 本文件(数据库变更管理规范)
└── im/                       # IM 即时通讯模块
    ├── ddl_im_tables.sql     # IM 模块所有表结构定义(6张表) 📝设计中
    ├── dml_im_init_data.sql  # IM 模块初始化数据(字典等) 📝设计中
    └── README.md             # IM 模块说明文档
```

**说明**:
- 每个业务模块一个目录
- 每个模块包含一个 DDL 文件(所有表结构)和一个 DML 文件(初始化数据)
- 后续变更直接在对应文件中修改,保持文件的连续性

## 文件命名规范

### DDL 文件(表结构定义)
- 格式: `ddl_<模块名>_tables.sql`
- 示例: `ddl_im_tables.sql`, `ddl_workflow_tables.sql`
- 说明: 一个模块一个 DDL 文件,包含该模块所有表结构

### DML 文件(数据操作)
- 格式: `dml_<模块名>_init_data.sql`
- 示例: `dml_im_init_data.sql`, `dml_workflow_init_data.sql`
- 说明: 一个模块一个 DML 文件,包含该模块的初始化数据

### 变更文件(ALTER)
- 格式: `alter_<模块名>_<变更描述>_<日期>.sql`
- 示例: `alter_im_add_quote_field_20260211.sql`
- 说明: 用于表结构变更(添加字段、修改字段、添加索引等)
- 注意: 变更文件是临时的,变更完成后应该合并到主 DDL 文件中

## 文件头部注释规范

每个 SQL 文件必须包含以下注释信息:

```sql
/*
 <模块名称> - <表名称>
 
 功能说明: <简要说明表的用途>
 创建日期: YYYY-MM-DD
 版本: v1.0
 作者: <可选>
 
 注意事项: <可选,特殊说明>
*/

SET NAMES utf8mb4;

-- 表结构定义...
```

## 表结构设计规范

### 必须字段
每个业务表必须包含以下字段:

```sql
`id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
`creator` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '创建者',
`create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
`updater` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL DEFAULT '' COMMENT '更新者',
`update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
`deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
`tenant_id` bigint NOT NULL DEFAULT 0 COMMENT '租户编号',
PRIMARY KEY (`id`) USING BTREE
```

### 索引规范
1. 主键索引: 使用 `id` 字段
2. 唯一索引: 命名格式 `idx_<字段1>_<字段2>` 或 `uk_<字段1>_<字段2>`
3. 普通索引: 命名格式 `idx_<字段1>_<字段2>`
4. 租户索引: 每个表必须有 `idx_tenant` 索引
5. 索引注释: 必须添加 COMMENT 说明索引用途

示例:
```sql
UNIQUE INDEX `idx_user_target`(`user_id` ASC, `target_id` ASC, `conversation_type` ASC, `tenant_id` ASC) USING BTREE COMMENT '用户+目标+类型唯一索引',
INDEX `idx_user_time`(`user_id` ASC, `last_message_time` DESC) USING BTREE COMMENT '用户+时间索引',
INDEX `idx_tenant`(`tenant_id` ASC) USING BTREE COMMENT '租户索引'
```

### 字段规范
1. 字符集: 统一使用 `utf8mb4`
2. 排序规则: 统一使用 `utf8mb4_unicode_ci`
3. 注释: 每个字段必须有 COMMENT
4. 默认值: 尽量设置合理的默认值
5. NOT NULL: 优先使用 NOT NULL,避免 NULL 值

### 表引擎和字符集
```sql
ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '<表注释>' ROW_FORMAT = DYNAMIC;
```

## 变更流程

### 1. 新增表
1. 在对应业务模块的 DDL 文件中添加新表定义
2. 按照规范编写表结构
3. 更新设计文档(如有)
4. 提交代码审查

示例:
```sql
-- 在 ddl_im_tables.sql 文件末尾添加新表
DROP TABLE IF EXISTS `im_new_table`;
CREATE TABLE `im_new_table` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  -- 其他字段...
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '新表说明' ROW_FORMAT = DYNAMIC;
```

### 2. 修改表结构
1. 在对应业务模块目录下创建 `alter_<模块名>_<变更描述>_<日期>.sql` 文件
2. 编写 ALTER 语句
3. 执行变更后,将变更合并到主 DDL 文件中
4. 更新设计文档(如有)
5. 提交代码审查

示例:
```sql
/*
 IM 即时通讯 - 消息表字段变更
 
 变更说明: 添加引用消息ID字段
 创建日期: 2026-02-11
 版本: v1.0
*/

SET NAMES utf8mb4;

-- 添加引用消息ID字段
ALTER TABLE `im_message` 
ADD COLUMN `quote_message_id` bigint NULL DEFAULT NULL COMMENT '引用消息ID' AFTER `recall_by`;

-- 添加索引
ALTER TABLE `im_message` 
ADD INDEX `idx_quote`(`quote_message_id` ASC) USING BTREE COMMENT '引用消息索引';
```

**注意**: 变更执行后,应该将变更合并到 `ddl_im_tables.sql` 文件中,保持 DDL 文件的完整性。

### 3. 初始化数据
1. 在对应业务模块的 DML 文件中添加初始化数据
2. 编写 INSERT 语句(使用 BEGIN/COMMIT 包裹)
3. 提交代码审查

示例:
```sql
-- 在 dml_im_init_data.sql 文件中添加新的字典数据
BEGIN;

INSERT INTO `system_dict_type` (...) VALUES (...);
INSERT INTO `system_dict_data` (...) VALUES (...);

COMMIT;
```

## 注意事项

1. **禁止直接修改 `shengyu-saas.sql` 文件**: 该文件是主SQL文件,包含所有现有业务表,不应直接修改
2. **一个模块一个 DDL 文件**: 不要为每个表创建单独的文件,保持文件的连续性和可维护性
3. **变更合并**: ALTER 变更执行后,应该合并到主 DDL 文件中
4. **文件独立性**: 每个 SQL 文件应该可以独立执行,不依赖其他文件
5. **幂等性**: DDL 文件应该包含 `DROP TABLE IF EXISTS` 语句,确保可重复执行
6. **事务控制**: DML 文件应该使用 `BEGIN` 和 `COMMIT` 包裹,确保数据一致性
7. **向后兼容**: 表结构变更应该考虑向后兼容性,避免破坏现有功能
8. **性能考虑**: 大表添加索引时应该在业务低峰期执行
9. **备份**: 执行变更前应该备份数据库
10. **设计阶段**: 当前处于设计阶段,SQL 文件仅用于设计和讨论,尚未执行

## 版本管理

- 主版本号: 1.0 (对应项目版本)
- 子目录: 按业务模块划分
- 文件版本: 通过文件名中的日期标识

## 执行顺序

1. 先执行 DDL 文件(创建表结构)
2. 再执行 DML 文件(初始化数据)
3. 最后执行 ALTER 文件(变更表结构)

## 示例: 完整的模块创建流程

假设要创建一个新的"工单"模块:

```bash
# 1. 创建模块目录
mkdir -p sql/mysql/1.0/ticket/

# 2. 创建 DDL 文件(所有表结构)
touch sql/mysql/1.0/ticket/ddl_ticket_tables.sql

# 3. 创建 DML 文件(初始化数据)
touch sql/mysql/1.0/ticket/dml_ticket_init_data.sql

# 4. 创建模块说明文档
touch sql/mysql/1.0/ticket/README.md

# 5. 编写 SQL 文件内容(按照规范)
# - ddl_ticket_tables.sql: 包含 ticket, ticket_comment, ticket_attachment 等所有表
# - dml_ticket_init_data.sql: 包含工单类型、状态等字典数据

# 6. 更新设计文档

# 7. 提交代码审查
```

**DDL 文件示例** (`ddl_ticket_tables.sql`):
```sql
/*
 工单模块 - 数据库表结构定义
 
 功能说明: 工单模块所有表结构定义
 创建日期: 2026-02-11
 版本: v1.0
*/

SET NAMES utf8mb4;

-- 工单表
DROP TABLE IF EXISTS `ticket`;
CREATE TABLE `ticket` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '工单ID',
  -- 其他字段...
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工单表' ROW_FORMAT = DYNAMIC;

-- 工单评论表
DROP TABLE IF EXISTS `ticket_comment`;
CREATE TABLE `ticket_comment` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '评论ID',
  -- 其他字段...
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci COMMENT = '工单评论表' ROW_FORMAT = DYNAMIC;

-- 更多表...
```

## 相关文档

- [IM即时通讯架构设计文档-v2.0](../../doc/IM即时通讯架构设计文档-v2.0.md)
- [IM即时通讯开发任务清单-v2.0](../../doc/IM即时通讯开发任务清单-v2.0.md)
- [数据库设计规范](../../doc/数据库设计规范.md) (如有)
