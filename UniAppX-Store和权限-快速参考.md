# UniApp X Store 和权限管理 - 快速参考

## 📦 核心模块

| 模块 | 文件路径 | 主要功能 |
|------|---------|---------|
| 用户 Store | `store/user.uts` | Token、租户、权限、角色管理 |
| 请求工具 | `utils/request.uts` | 网络请求、自动拦截 |
| 登录 API | `api/login.uts` | 登录、权限获取 |

---

## 🔐 Token 管理

```typescript
import { setToken, getAccessToken, removeToken } from '@/store/user.uts'

// 保存 Token（登录后）
setToken({
	accessToken: 'xxx',
	refreshToken: 'yyy',
	tenantId: 1,
	deptId: 100
})

// 获取 Token
const token = getAccessToken()

// 移除 Token（登出）
removeToken()
```

---

## 🏢 租户管理

```typescript
import { getTenantId, setTenantId } from '@/store/user.uts'

// 获取租户 ID
const tenantId = getTenantId()

// 设置租户 ID
setTenantId(1)
```

**注意**：
- 租户 ID 在登录时自动保存（从 Token 中获取）
- 所有请求自动添加 `tenant-id` 请求头
- 无需手动获取租户 ID

---

## 👤 用户信息管理

```typescript
import { setUserInfo, getUserInfo, updateUserAvatar } from '@/store/user.uts'

// 保存用户信息
setUserInfo({
	user: { id: 1, avatar: 'xxx', nickname: '张三', deptId: 100 },
	permissions: ['system:user:create', 'system:user:update'],
	roles: ['admin', 'manager'],
	menus: [...]
})

// 获取用户信息
const userInfo = getUserInfo()

// 更新用户头像
updateUserAvatar('https://example.com/avatar.jpg')
```

---

## 🔑 权限检查

### 单个权限

```typescript
import { hasPermission } from '@/store/user.uts'

if (hasPermission('system:user:create')) {
	// 有权限
}
```

### 任一权限

```typescript
import { hasAnyPermission } from '@/store/user.uts'

if (hasAnyPermission(['system:user:create', 'system:user:update'])) {
	// 有任一权限
}
```

### 所有权限

```typescript
import { hasAllPermissions } from '@/store/user.uts'

if (hasAllPermissions(['system:user:create', 'system:user:update'])) {
	// 有所有权限
}
```

---

## 👥 角色检查

### 单个角色

```typescript
import { hasRole } from '@/store/user.uts'

if (hasRole('admin')) {
	// 是管理员
}
```

### 任一角色

```typescript
import { hasAnyRole } from '@/store/user.uts'

if (hasAnyRole(['admin', 'manager'])) {
	// 是管理员或经理
}
```

### 所有角色

```typescript
import { hasAllRoles } from '@/store/user.uts'

if (hasAllRoles(['admin', 'manager'])) {
	// 同时是管理员和经理
}
```

---

## 🌐 网络请求

### GET 请求

```typescript
import { get } from '@/utils/request.uts'

// 自动添加 Token 和租户 ID
const data = await get('/system/user/list')
```

### POST 请求

```typescript
import { post } from '@/utils/request.uts'

// 自动添加 Token 和租户 ID
const result = await post('/system/user/create', {
	username: '张三',
	email: 'zhangsan@example.com'
})
```

### 特殊请求（返回完整响应）

```typescript
import { postRaw } from '@/utils/request.uts'

// 用于验证码等特殊接口
const response = await postRaw('/system/captcha/get', {
	captchaType: 'blockPuzzle'
})
```

---

## 🔄 登录流程

```typescript
import { login, getPermissionInfo } from '@/api/login.uts'
import { setToken, setUserInfo } from '@/store/user.uts'

// 1. 登录
const tokenData = await login({
	username: 'admin',
	password: '123456',
	captchaVerification: 'xxx'
})

// 2. 保存 Token（自动保存租户 ID 和部门 ID）
setToken(tokenData)

// 3. 获取用户信息
const userInfo = await getPermissionInfo()

// 4. 保存用户信息（自动保存权限和角色）
setUserInfo(userInfo)

// 5. 跳转首页
uni.switchTab({ url: '/pages/index/index' })
```

---

## 🚪 登出流程

```typescript
import { logout } from '@/api/login.uts'
import { clearUserCache } from '@/store/user.uts'

// 1. 调用登出接口
await logout()

// 2. 清除本地缓存
clearUserCache()

// 3. 跳转登录页
uni.reLaunch({ url: '/pages/login/login' })
```

---

## ⚙️ 配置

### 租户开关

在 `config/app.config.uts` 中配置：

```typescript
// 启用租户功能（请求时自动添加 tenant-id）
export const TENANT_ENABLE = 'true'

// 禁用租户功能
export const TENANT_ENABLE = 'false'
```

---

## 🔍 请求拦截器

### 自动添加的请求头

1. **Authorization**：`Bearer {accessToken}`
2. **tenant-id**：租户 ID（如果 `TENANT_ENABLE === 'true'`）
3. **Cache-Control**：`no-cache`（GET 请求）
4. **Pragma**：`no-cache`（GET 请求）

### 白名单

以下接口不需要 Token：

- `/login`
- `/refresh-token`
- `/system/tenant/get-id-by-name`

---

## 📊 响应处理

### 业务成功（code === 0）

```typescript
// 返回 data.data
const data = await get('/system/user/list')
```

### 业务失败

| Code | 说明 | 处理 |
|------|------|------|
| 401 | Token 过期 | 自动刷新 Token |
| 500 | 服务器错误 | 显示 Toast |
| 901 | 演示模式 | 显示 Toast |
| 其他 | 业务错误 | 显示 Toast |

---

## 🔄 Token 自动刷新

### 流程

1. 请求返回 401
2. 检查是否正在刷新 Token
3. 如果是，将请求加入队列
4. 如果否，开始刷新 Token
5. 刷新成功后，重试原请求和队列中的请求
6. 刷新失败，跳转登录页

### 无需手动处理

Token 刷新完全自动化，无需手动处理。

---

## 💡 使用技巧

### 1. 在页面中检查权限

```vue
<template>
	<view>
		<button v-if="canCreate" @click="handleCreate">创建用户</button>
		<button v-if="canUpdate" @click="handleUpdate">更新用户</button>
	</view>
</template>

<script setup lang="uts">
	import { hasPermission } from '@/store/user.uts'
	
	const canCreate = computed(() => hasPermission('system:user:create'))
	const canUpdate = computed(() => hasPermission('system:user:update'))
</script>
```

### 2. 在页面中检查角色

```vue
<template>
	<view>
		<view v-if="isAdmin">管理员专属内容</view>
		<view v-if="isManager">经理专属内容</view>
	</view>
</template>

<script setup lang="uts">
	import { hasRole } from '@/store/user.uts'
	
	const isAdmin = computed(() => hasRole('admin'))
	const isManager = computed(() => hasRole('manager'))
</script>
```

### 3. 在请求前检查登录状态

```typescript
import { isLoggedIn } from '@/store/user.uts'

if (!isLoggedIn()) {
	uni.reLaunch({ url: '/pages/login/login' })
	return
}

// 继续执行业务逻辑
```

---

## ⚠️ 注意事项

1. **租户 ID 自动拼接**：无需手动获取租户 ID，登录时自动保存
2. **Token 自动刷新**：Token 过期时自动刷新，无需手动处理
3. **权限和角色**：登录时自动保存，可直接使用检查函数
4. **请求拦截**：所有请求自动添加 Token 和租户 ID

---

## 📚 完整文档

详细使用说明请查看：`今日工作完成-2026-01-28-UniAppX-Store和权限管理.md`

---

**更新日期**：2026-01-28  
**版本**：v1.0.0
