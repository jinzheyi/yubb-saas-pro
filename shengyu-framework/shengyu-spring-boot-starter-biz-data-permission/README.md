# 数据权限模块 (Data Permission)

## 📖 简介

本模块提供基于部门的数据权限控制功能，支持平台端和租户端各自的数据权限逻辑。通过 `@DataPermission` 注解，可以轻松实现细粒度的数据访问控制。

## ✨ 核心特性

- ✅ **多端支持** - 同时支持平台端和租户端的数据权限
- ✅ **自动适配** - 根据用户类型自动选择对应的权限提供者
- ✅ **灵活配置** - 支持部门维度和用户维度的权限过滤
- ✅ **透明集成** - 通过注解方式，对业务代码无侵入
- ✅ **性能优化** - 内置缓存机制，避免重复查询
- ✅ **易于扩展** - 基于策略模式，便于添加新的用户类型

## 🚀 快速开始

### 1. 添加依赖

```xml
<dependency>
    <groupId>com.shengyu.boot</groupId>
    <artifactId>shengyu-spring-boot-starter-biz-data-permission</artifactId>
</dependency>
```

### 2. 使用注解

```java
@Service
public class UserServiceImpl {
    
    @DataPermission(enable = true)
    public List<UserDO> getUserList() {
        return userMapper.selectList();
    }
}
```

### 3. 配置表字段

```java
@Configuration
public class DataPermissionConfiguration {
    
    @Bean
    public DeptDataPermissionRuleCustomizer deptDataPermissionRuleCustomizer() {
        return rule -> {
            rule.addDeptColumn(UserDO.class);
            rule.addUserColumn(UserDO.class);
        };
    }
}
```

就这么简单！数据权限会自动根据当前登录用户类型应用。

## 📚 文档导航

### 🎯 快速入门
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - 快速参考卡片，5分钟上手

### 📖 详细文档
- **[REFACTOR_README.md](REFACTOR_README.md)** - 重构详细说明，了解架构设计
- **[LOGIN_USER_UNIFIED.md](LOGIN_USER_UNIFIED.md)** - 登录用户统一获取说明
- **[USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)** - 完整使用示例和最佳实践

### 🔄 迁移升级
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - 从旧版本迁移的指南
- **[CHANGELOG.md](CHANGELOG.md)** - 版本变更日志

### 📝 总结文档
- **[REFACTOR_SUMMARY.md](REFACTOR_SUMMARY.md)** - 重构完整总结

## 🎨 架构设计

```
@DataPermission 注解
    ↓
DeptDataPermissionRule (规则引擎)
    ↓
根据用户类型选择 Provider
    ├── SystemDeptDataPermissionProvider (租户端)
    │   └── PermissionApi
    └── PlatformDeptDataPermissionProvider (平台端)
        └── PlatformPermissionApi
    ↓
生成 SQL 过滤条件
    ↓
MyBatis 拦截器应用到 SQL
```

## 🔑 核心概念

### 用户类型映射

| 用户类型 | 枚举值 | 权限提供者 | 底层API |
|---------|--------|-----------|---------|
| 平台端管理员 | `PLATFORM` (0) | `PlatformDeptDataPermissionProvider` | `PlatformPermissionApi` |
| 租户端管理员 | `ADMIN` (2) | `SystemDeptDataPermissionProvider` | `PermissionApi` |
| 会员 | `MEMBER` (1) | 无 | 不应用数据权限 |

### 权限范围类型

| 类型 | 条件 | SQL 示例 |
|-----|------|---------|
| **全部数据** | `all = true` | 无额外条件 |
| **指定部门** | `deptIds = [1,2,3]` | `WHERE dept_id IN (1,2,3)` |
| **仅自己** | `self = true` | `WHERE user_id = 100` |
| **部门+自己** | `deptIds + self` | `WHERE (dept_id IN (1,2,3) OR user_id = 100)` |

## 💡 使用示例

### 租户端示例

```java
@Service
public class SystemUserServiceImpl {
    
    @DataPermission(enable = true)
    public List<UserDO> getUserList() {
        // 自动应用租户端数据权限
        // 使用 SystemDeptDataPermissionProvider
        return userMapper.selectList();
    }
}
```

### 平台端示例

```java
@Service
public class PlatformTenantServiceImpl {
    
    @DataPermission(enable = true)
    public List<TenantDO> getTenantList() {
        // 自动应用平台端数据权限
        // 使用 PlatformDeptDataPermissionProvider
        return tenantMapper.selectList();
    }
}
```

### 获取登录用户

```java
// ✅ 推荐：统一获取（支持两种用户类型）
LoginBase loginUser = SecurityFrameworkUtils.getLoginUserBase();

// ⚠️ 特定场景：分别获取
LoginUser tenantUser = SecurityFrameworkUtils.getLoginUser();
PlatformLoginUser platformUser = SecurityFrameworkUtils.getPlatformLoginUser();
```

## 🔧 配置说明

### 配置部门字段

```java
// 使用默认字段名 dept_id
rule.addDeptColumn(UserDO.class);

// 自定义字段名
rule.addDeptColumn(CustomDO.class, "department_id");

// 直接指定表名
rule.addDeptColumn("sys_user", "dept_id");
```

### 配置用户字段

```java
// 使用默认字段名 user_id
rule.addUserColumn(UserDO.class);

// 自定义字段名
rule.addUserColumn(CustomDO.class, "creator_id");

// 直接指定表名
rule.addUserColumn("sys_user", "user_id");
```

## 🐛 调试技巧

### 查看生成的 SQL

```yaml
logging:
  level:
    com.shengyu.module.*.dal.mysql: debug
```

### 查看数据权限信息

```java
LoginBase loginUser = SecurityFrameworkUtils.getLoginUserBase();
DeptDataPermissionRespDTO permission = loginUser.getContext(
    DeptDataPermissionRule.class.getSimpleName(), 
    DeptDataPermissionRespDTO.class
);
log.info("数据权限: {}", JsonUtils.toJsonString(permission));
```

## ⚠️ 注意事项

### ✅ 推荐做法
1. 在 Service 层使用 `@DataPermission` 注解
2. 为数据权限字段添加数据库索引
3. 使用统一的字段命名（dept_id、user_id）
4. 使用 `getLoginUserBase()` 统一获取登录用户

### ❌ 避免做法
1. 不要在 Controller 层使用 `@DataPermission`
2. 不要在事务方法外层使用 `@DataPermission`
3. 不要频繁切换数据权限的启用状态
4. 不要在循环中调用带数据权限的方法

## 📈 性能优化

### 1. 添加数据库索引

```sql
-- 部门字段索引
ALTER TABLE sys_user ADD INDEX idx_dept_id (dept_id);

-- 用户字段索引
ALTER TABLE sys_user ADD INDEX idx_user_id (user_id);

-- 组合索引
ALTER TABLE sys_user ADD INDEX idx_dept_user (dept_id, user_id);
```

### 2. 利用缓存机制

数据权限信息会自动缓存在 `LoginBase.context` 中，同一请求内不会重复查询。

## 🆘 常见问题

### Q: 数据权限不生效？
**A:** 检查以下几点：
1. 方法上是否有 `@DataPermission(enable = true)` 注解
2. 表是否已配置 `addDeptColumn` 或 `addUserColumn`
3. 当前用户类型是否为 PLATFORM 或 ADMIN
4. 对应的 PermissionApi 是否正确实现

### Q: 如何临时禁用数据权限？
**A:** 使用 `@DataPermission(enable = false)` 或不添加注解。

### Q: 平台端和租户端的权限规则不同怎么办？
**A:** 这正是重构的目的！各自实现自己的 `getDeptDataPermission()` 方法即可。

### Q: 会员用户会应用数据权限吗？
**A:** 不会。只有 PLATFORM 和 ADMIN 类型的用户才会应用数据权限。

## 🔗 相关链接

- **项目官网：** http://shengyukj.top/
- **Gitee 仓库：** https://gitee.com/jinzheyi/yubb-saas-pro
- **技术支持：** jin_zheyicn@qq.com

## 📄 许可证

MIT License

## 👥 贡献者

圣钰科技团队

---

**版本：** 2.0.0

**最后更新：** 2026-01-26

**状态：** ✅ 生产就绪

---

## 🎓 推荐阅读顺序

1. **新手入门：** README.md (本文) → QUICK_REFERENCE.md → USAGE_EXAMPLE.md
2. **深入理解：** REFACTOR_README.md → LOGIN_USER_UNIFIED.md
3. **迁移升级：** MIGRATION_GUIDE.md → CHANGELOG.md
4. **完整总结：** REFACTOR_SUMMARY.md

祝你使用愉快！🎉
