# 圣钰管理系统 - UniApp 移动端

基于 UniApp X 开发的圣钰管理系统移动端应用。

## 功能特性

### 1. 登录鉴权
- ✅ 账号密码登录
- ✅ 手机号验证码登录
- ✅ **滑块验证码验证**
- ✅ 租户识别
- ✅ 记住我功能
- ✅ Token 自动管理
- ✅ **Token 自动刷新机制**
- ✅ 登录状态检查

### 2. 底部导航
- ✅ 消息
- ✅ 通讯录
- ✅ 工作台
- ✅ 我的

### 3. 核心功能
- ✅ 用户信息管理
- ✅ 权限信息加载
- ✅ 退出登录
- ✅ 网络请求封装
- ✅ 状态管理
- ✅ **请求队列机制**
- ✅ **无感知 Token 刷新**

## 项目结构

```
shengyu-ui-admin-uniappx/
├── api/                    # API 接口
│   └── login.uts          # 登录相关接口
├── components/             # 组件
│   └── captcha/           # 验证码组件
│       └── slider-captcha.uvue  # 滑块验证码
├── pages/                  # 页面
│   ├── login/             # 登录页
│   ├── message/           # 消息页
│   ├── contacts/          # 通讯录页
│   ├── workbench/         # 工作台页
│   └── profile/           # 我的页面
├── static/                 # 静态资源
│   ├── logo.png           # Logo
│   └── tabbar/            # 底部导航图标
├── store/                  # 状态管理
│   └── user.uts           # 用户状态
├── utils/                  # 工具函数
│   └── request.uts        # 网络请求封装（含 Token 刷新）
├── App.uvue               # 应用入口
├── main.uts               # 主入口
├── pages.json             # 页面配置
└── manifest.json          # 应用配置
```

## 技术栈

- **框架**: UniApp X
- **语言**: UTS (TypeScript-like)
- **UI**: 原生组件
- **状态管理**: 自定义状态管理
- **网络请求**: uni.request 封装

## 核心功能说明

### 1. 滑块验证码

#### 功能特点
- 滑块拖动验证
- 验证码图片展示
- 滑动轨迹记录
- 验证成功/失败提示
- 刷新验证码功能

#### 使用方式
```vue
<slider-captcha 
	ref="captchaRef" 
	captchaType="blockPuzzle"
	@success="handleCaptchaSuccess"
	@fail="handleCaptchaFail"
/>
```

### 2. Token 自动刷新机制

#### 刷新流程
```
请求失败(401) → 检查是否正在刷新 → 获取 RefreshToken 
→ 调用刷新接口 → 保存新 Token → 重试原请求 → 处理请求队列
```

#### 核心特性
- **无感知刷新**: 用户无需手动操作
- **请求队列**: 刷新期间的请求自动排队
- **自动重试**: 刷新成功后自动重试原请求
- **失败处理**: RefreshToken 过期自动跳转登录

#### 实现原理
```typescript
// 401 错误时自动触发
if (response.statusCode == 401) {
	return handle401Error(response)
}

// Token 刷新
async function handle401Error(response) {
	// 1. 检查是否正在刷新
	if (isRefreshing) {
		// 加入请求队列
		return new Promise((resolve, reject) => {
			requestQueue.push({ resolve, reject, config })
		})
	}
	
	// 2. 开始刷新
	isRefreshing = true
	const tokenData = await refreshAccessToken()
	setToken(tokenData)
	
	// 3. 重试原请求
	const retryResponse = await uni.request(config)
	
	// 4. 处理队列中的请求
	requestQueue.forEach(item => {
		uni.request(item.config).then(res => {
			item.resolve(res)
		})
	})
	
	// 5. 清空队列
	requestQueue = []
	isRefreshing = false
}
```

## 配置说明

### 1. 修改后端地址

编辑 `utils/request.uts`，修改 `BASE_URL`：

```typescript
const BASE_URL = 'http://your-server-address:port'
```

### 2. 租户配置

默认租户名称为"圣钰科技"，可在登录页面修改。

### 3. 验证码配置

编辑 `pages/login/login.uvue`，配置验证码启用状态：

```typescript
// 是否启用验证码（默认启用）
const captchaEnable = ref<boolean>(true)
```

### 4. TabBar 图标

请参考 `static/tabbar/README.md` 准备底部导航图标。

## 开发指南

### 1. 安装依赖

使用 HBuilderX 打开项目即可，无需额外安装依赖。

### 2. 运行项目

- **运行到浏览器**: 点击 HBuilderX 菜单 -> 运行 -> 运行到浏览器
- **运行到手机**: 点击 HBuilderX 菜单 -> 运行 -> 运行到手机或模拟器
- **运行到小程序**: 点击 HBuilderX 菜单 -> 运行 -> 运行到小程序模拟器

### 3. 打包发布

- **App 打包**: 点击 HBuilderX 菜单 -> 发行 -> 原生 App-云打包
- **小程序打包**: 点击 HBuilderX 菜单 -> 发行 -> 小程序-微信

## API 接口说明

### 登录接口

#### 账号密码登录
```
POST /system/auth/login
{
  "username": "账号",
  "password": "密码",
  "captchaVerification": "验证码验证结果"
}
```

#### 手机号登录
```
POST /system/auth/sms-login
{
  "mobile": "手机号",
  "code": "验证码"
}
```

#### 发送验证码
```
POST /system/auth/send-sms-code
{
  "mobile": "手机号",
  "scene": 21
}
```

#### 获取租户ID
```
GET /system/tenant/get-id-by-name?name=租户名称
```

#### 获取用户权限信息
```
GET /system/auth/get-permission-info
Headers: {
  "Authorization": "Bearer {token}",
  "tenant-id": "{tenantId}"
}
```

#### 刷新访问令牌
```
POST /system/auth/refresh-token?refreshToken={refreshToken}
Headers: {
  "tenant-id": "{tenantId}"
}
```

#### 退出登录
```
POST /system/auth/logout
Headers: {
  "Authorization": "Bearer {token}"
}
```

### 验证码接口

#### 获取图形验证码
```
POST /system/captcha/get
{
  "captchaType": "blockPuzzle"
}
```

#### 校验图形验证码
```
POST /system/captcha/check
{
  "captchaType": "blockPuzzle",
  "pointJson": "{\"x\":100,\"y\":5}",
  "token": "验证码token"
}
```

## 状态管理

### 用户状态 (store/user.uts)

```typescript
// 设置用户信息
setUserInfo(info: UTSJSONObject)

// 获取用户信息
getUserInfo(): UTSJSONObject | null

// 清除用户信息
clearUserInfo()

// 检查是否已登录
isLoggedIn(): boolean

// 加载用户权限信息
loadUserPermission(): Promise<void>
```

### Token 管理 (utils/request.uts)

```typescript
// 设置 Token
setToken(tokenData: UTSJSONObject)

// 获取 Token
getToken(): string | null

// 获取 RefreshToken
getRefreshToken(): string | null

// 移除 Token
removeToken()

// 设置租户ID
setTenantId(tenantId: number)

// 获取租户ID
getTenantId(): string | null
```

## 注意事项

1. **网络请求**: 确保后端服务已启动且可访问
2. **跨域问题**: 移动端不存在跨域问题，但需要确保后端接口正确配置
3. **Token 过期**: 401 状态码会自动触发 Token 刷新，刷新失败会跳转到登录页
4. **租户隔离**: 每次请求都会自动携带租户ID
5. **图标资源**: 需要准备 TabBar 图标文件
6. **验证码**: 可通过配置启用/禁用验证码功能

## 安全机制

### 1. 双 Token 机制
- **AccessToken**: 短期有效，用于日常请求
- **RefreshToken**: 长期有效，用于刷新 AccessToken

### 2. 自动刷新
- AccessToken 过期时自动使用 RefreshToken 刷新
- 刷新期间的请求自动排队等待
- 刷新成功后自动重试所有排队请求

### 3. 验证码保护
- 登录时需要完成滑块验证
- 防止暴力破解
- 支持刷新验证码

## 后续开发计划

- [ ] 完善消息功能（集成 WebSocket）
- [ ] 完善通讯录功能
- [ ] 完善工作台功能
- [ ] 添加个人信息编辑
- [ ] 添加修改密码功能
- [ ] 添加系统设置功能
- [ ] 添加推送通知
- [ ] 添加离线缓存
- [ ] 添加主题切换
- [ ] 添加多语言支持
- [ ] 优化验证码体验
- [ ] 添加 Token 预刷新机制

## 参考文档

- [UniApp X 官方文档](https://doc.dcloud.net.cn/uni-app-x/)
- [UTS 语法说明](https://doc.dcloud.net.cn/uni-app-x/uts/)
- [UniApp X API](https://doc.dcloud.net.cn/uni-app-x/api/)
- [快速启动指南](./QUICK-START.md)
- [验证码和Token刷新机制说明](../验证码和Token刷新机制完成总结.md)

## 技术支持

如有问题，请联系技术支持团队。
