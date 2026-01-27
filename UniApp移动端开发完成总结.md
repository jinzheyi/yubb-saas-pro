# UniApp 移动端开发完成总结

## 项目概述

基于 UniApp X 框架，为圣钰管理系统开发了完整的移动端应用，实现了登录鉴权和主要功能模块。

## 完成功能

### 1. 登录鉴权系统 ✅

#### 1.1 账号密码登录
- 租户名称输入（默认：圣钰科技）
- 账号输入
- 密码输入
- 记住我功能
- 自动获取租户ID

#### 1.2 手机号验证码登录
- 手机号输入
- 验证码发送（60秒倒计时）
- 验证码输入
- 短信登录接口对接

#### 1.3 登录状态管理
- Token 自动存储和管理
- 租户ID 自动管理
- 用户信息缓存
- 登录状态检查
- 自动跳转登录页

### 2. 底部导航系统 ✅

实现了四个主要功能模块的底部导航：

#### 2.1 消息页面
- 消息列表展示
- 未读消息角标
- 消息时间显示
- 点击查看详情（待开发）

#### 2.2 通讯录页面
- 联系人列表展示
- 搜索功能
- 部门信息显示
- 点击查看详情（待开发）

#### 2.3 工作台页面
- 快捷入口（审批、报表、文件、设置）
- 待办事项列表
- 待办数量角标
- 功能入口（待开发）

#### 2.4 我的页面
- 用户信息展示
- 功能菜单（个人信息、修改密码、系统设置、帮助中心、关于我们）
- 退出登录功能

### 3. 核心功能模块 ✅

#### 3.1 网络请求封装 (utils/request.uts)
- 统一的请求拦截器
- 自动添加 Token
- 自动添加租户ID
- 统一的响应处理
- 401 自动跳转登录
- 错误提示处理

#### 3.2 状态管理 (store/user.uts)
- 用户信息管理
- 登录状态检查
- 权限信息加载
- 本地存储同步

#### 3.3 API 接口 (api/login.uts)
- 账号密码登录
- 手机号登录
- 发送验证码
- 获取租户ID
- 获取用户权限信息
- 退出登录

## 技术架构

### 技术栈
- **框架**: UniApp X
- **语言**: UTS (TypeScript-like)
- **UI**: 原生组件
- **状态管理**: 自定义状态管理
- **网络请求**: uni.request 封装

### 项目结构
```
shengyu-ui-admin-uniappx/
├── api/                    # API 接口层
│   └── login.uts          # 登录相关接口
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
│   └── request.uts        # 网络请求封装
├── App.uvue               # 应用入口
├── main.uts               # 主入口
├── pages.json             # 页面配置
└── manifest.json          # 应用配置
```

## 核心代码说明

### 1. 网络请求封装

```typescript
// 自动添加 Token 和租户ID
function requestInterceptor(config: UTSJSONObject): UTSJSONObject {
	const token = uni.getStorageSync(TOKEN_KEY)
	const tenantId = uni.getStorageSync(TENANT_ID_KEY)
	// 添加到请求头
}

// 统一响应处理
function responseInterceptor(response: any): any {
	// 200: 成功
	// 401: 未授权，跳转登录
	// 其他: 错误提示
}
```

### 2. 登录流程

```typescript
async function handleLogin() {
	// 1. 验证表单
	// 2. 获取租户ID
	await fetchTenantId()
	// 3. 调用登录接口
	const tokenData = await login(data)
	// 4. 保存 Token
	setToken(tokenData)
	// 5. 加载用户信息
	await loadUserPermission()
	// 6. 跳转首页
	uni.switchTab({ url: '/pages/message/message' })
}
```

### 3. 登录状态检查

```typescript
// App.uvue 中自动检查
function checkLoginStatus() {
	const currentPage = getCurrentPages()[0]
	if (currentPage.route != 'pages/login/login' && !isLoggedIn()) {
		uni.reLaunch({ url: '/pages/login/login' })
	}
}
```

## 页面配置

### pages.json 配置
- 登录页设置为首页
- 配置了 4 个 TabBar 页面
- 自定义导航栏样式
- 全局样式配置

### TabBar 配置
```json
{
	"tabBar": {
		"color": "#999999",
		"selectedColor": "#667eea",
		"list": [
			{ "pagePath": "pages/message/message", "text": "消息" },
			{ "pagePath": "pages/contacts/contacts", "text": "通讯录" },
			{ "pagePath": "pages/workbench/workbench", "text": "工作台" },
			{ "pagePath": "pages/profile/profile", "text": "我" }
		]
	}
}
```

## 对接后端接口

### 需要配置的接口地址

修改 `utils/request.uts` 中的 `BASE_URL`：
```typescript
const BASE_URL = 'http://your-server-address:port'
```

### 已对接的接口

1. **POST /system/auth/login** - 账号密码登录
2. **POST /system/auth/sms-login** - 手机号登录
3. **POST /system/auth/send-sms-code** - 发送验证码
4. **GET /system/tenant/get-id-by-name** - 获取租户ID
5. **GET /system/auth/get-permission-info** - 获取用户权限信息
6. **POST /system/auth/logout** - 退出登录

## 使用说明

### 1. 开发环境
- 使用 HBuilderX 打开项目
- 修改 `utils/request.uts` 中的后端地址
- 运行到浏览器或手机模拟器

### 2. 登录测试
- 默认租户：圣钰科技
- 支持账号密码登录
- 支持手机号验证码登录

### 3. 功能测试
- 登录后自动跳转到消息页
- 底部导航可切换四个主页面
- 退出登录会清除所有状态

## 待完善功能

### 短期计划
- [ ] 完善消息功能（集成 WebSocket）
- [ ] 完善通讯录功能（联系人详情、搜索优化）
- [ ] 完善工作台功能（审批流程、报表查看）
- [ ] 个人信息编辑
- [ ] 修改密码功能

### 中期计划
- [ ] 推送通知
- [ ] 离线缓存
- [ ] 文件上传下载
- [ ] 图片预览
- [ ] 扫码功能

### 长期计划
- [ ] 主题切换
- [ ] 多语言支持
- [ ] 性能优化
- [ ] 单元测试

## 注意事项

### 1. TabBar 图标
- 当前使用 logo.png 作为临时图标
- 建议准备专业的 TabBar 图标（81x81 像素）
- 参考 `static/tabbar/README.md`

### 2. 网络请求
- 确保后端服务已启动
- 检查网络连接
- 注意跨域配置（移动端无跨域问题）

### 3. 登录状态
- Token 存储在本地
- 401 会自动跳转登录
- 退出登录会清除所有状态

### 4. 租户隔离
- 每次请求自动携带租户ID
- 登录时自动获取租户ID
- 支持多租户切换

## 参考文档

- [UniApp X 官方文档](https://doc.dcloud.net.cn/uni-app-x/)
- [UTS 语法说明](https://doc.dcloud.net.cn/uni-app-x/uts/)
- [UniApp X API](https://doc.dcloud.net.cn/uni-app-x/api/)
- [Vue3 登录逻辑参考](shengyu-ui/shengyu-ui-admin-vue3/src/views/Login/)

## 总结

成功完成了 UniApp 移动端的基础框架搭建和核心功能开发：

1. ✅ 完整的登录鉴权系统（账号登录 + 手机号登录）
2. ✅ 四个主要功能模块的页面和导航
3. ✅ 网络请求封装和状态管理
4. ✅ 与后端 API 的完整对接
5. ✅ 登录状态管理和自动跳转
6. ✅ 用户信息管理和权限加载

项目已具备基本的运行条件，可以进行功能测试和后续开发。
