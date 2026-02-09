# UniAppX 项目完整分析

## 项目概述

**项目名称**: shengyu-ui-admin-uniappx  
**项目类型**: UniAppX 跨平台移动应用（即时通讯 + 企业管理）  
**技术栈**: UniAppX + Vue3 + TypeScript (UTS)  
**支持平台**: Android、iOS、Web (H5)

## 一、项目架构

### 1.1 目录结构

```
shengyu-ui-admin-uniappx/
├── .agent/              # Google Antigravity AI 配置
├── .claude/             # Claude Code AI 配置
├── .cursor/             # Cursor AI 配置
├── .trae/               # Trae AI 配置
├── .vscode/             # VSCode 配置
├── api/                 # API 接口定义
│   └── login.uts        # 登录相关接口
├── components/          # 公共组件
│   └── captcha/         # 验证码组件
├── config/              # 配置文件
│   └── app.config.uts   # 应用配置（API地址、租户开关等）
├── hooks/               # 组合式函数
│   └── useI18n.uts      # 国际化 Hook
├── locales/             # 国际化语言包
│   ├── zh-CN.uts        # 简体中文
│   └── en.uts           # 英文
├── pages/               # 页面目录
│   ├── login/           # 登录页
│   ├── message/         # 消息页（聊天列表、聊天详情）
│   ├── contacts/        # 通讯录页
│   ├── workbench/       # 工作台页
│   └── profile/         # 个人中心页
├── static/              # 静态资源
│   ├── iconfont/        # 图标字体
│   ├── images/          # 图片资源
│   └── tabbar/          # 底部导航图标
├── store/               # 状态管理
│   ├── user.uts         # 用户状态（Token、权限、角色）
│   └── locale.uts       # 国际化状态
├── utils/               # 工具函数
│   ├── request.uts      # 网络请求封装
│   ├── dict.uts         # 字典工具
│   ├── file.uts         # 文件工具
│   ├── upload.uts       # 上传工具
│   ├── emojiData.uts    # 表情数据
│   ├── emojiParser.uts  # 表情解析器
│   └── stickerManager.uts # 自定义表情管理
├── App.uvue             # 应用入口
├── main.uts             # 主入口文件
├── manifest.json        # 应用配置清单
├── pages.json           # 页面路由配置
└── uni.scss             # 全局样式变量
```

### 1.2 核心技术特点

1. **UniAppX 原生渲染**
   - 使用 UTS (UniTypeScript) 语言
   - 原生性能，接近原生应用体验
   - 支持 Android、iOS、Web 三端

2. **严格参考 PC 端实现**
   - API 接口、Token 机制、租户系统完全对齐 PC 端
   - 确保前后端一致性

3. **多 AI 工具支持**
   - 配置了 Cursor、Claude、Trae、Antigravity 等 AI 工具
   - 提供 MCP (Model Context Protocol) 配置
   - 优化 AI 代码生成准确性

## 二、核心功能模块

### 2.1 用户认证系统

**文件**: `store/user.uts`, `api/login.uts`

**功能特性**:
- ✅ 账号密码登录（支持滑块验证码）
- ✅ 手机号登录（短信验证码）
- ✅ Token 自动刷新机制
- ✅ 多租户支持（租户 ID 使用字符串避免精度丢失）
- ✅ 权限和角色管理
- ✅ 登录状态持久化

**关键实现**:
```typescript
// Token 管理
export function setToken(token: TokenType)
export function getAccessToken(): string | null
export function getRefreshToken(): string | null

// 租户管理（大整数使用字符串）
export function getTenantId(): string | null
export function setTenantId(tenantId: number | string | null)

// 权限检查
export function hasPermission(permission: string): boolean
export function hasRole(role: string): boolean
```

### 2.2 网络请求封装

**文件**: `utils/request.uts`

**功能特性**:
- ✅ 请求/响应拦截器
- ✅ 自动添加 Token 和租户 ID
- ✅ Token 过期自动刷新
- ✅ 请求队列管理（刷新 Token 时）
- ✅ 白名单机制（登录、验证码等接口）
- ✅ 错误统一处理

**请求流程**:
```
发起请求 → 请求拦截器（添加 Token/租户ID）
         → 发送请求
         → 响应拦截器（处理业务码）
         → 401 错误？→ 刷新 Token → 重试请求
         → 返回数据
```

### 2.3 国际化系统

**文件**: `store/locale.uts`, `hooks/useI18n.uts`, `locales/`

**功能特性**:
- ✅ 中英文双语支持
- ✅ 自动检测系统语言
- ✅ 响应式语言切换
- ✅ 支持嵌套键路径（如 `common.login`）

**使用方式**:
```typescript
import { useI18n } from '@/hooks/useI18n.uts'

const { t, locale, switchLocale } = useI18n()

// 翻译
const text = t('common.login', '登录')

// 切换语言
switchLocale('en')
```

### 2.4 即时通讯功能

**文件**: `pages/message/`

**已实现功能**:
- ✅ 消息列表页
- ✅ 聊天详情页（仿微信）
- ✅ 多种消息类型：
  - 文本消息（支持表情）
  - 图片消息
  - 视频消息
  - 语音消息
  - 文件消息
  - 位置消息
  - 自定义表情包
- ✅ 消息操作菜单（长按）：
  - 复制、转发、删除、收藏、多选、引用
  - 横向排列，支持自动换行
  - 带图标展示
- ✅ 多选模式：
  - 复选框在最左侧
  - 头部显示"已选择 X 条"
  - 底部工具栏（转发、删除）
  - 选中消息高亮显示
- ✅ 表情系统：
  - 系统表情包
  - 自定义收藏表情
  - 表情解析和渲染
- ✅ 输入功能：
  - 文本输入（支持表情）
  - 语音输入（按住说话）
  - 全屏编辑模式
  - 更多功能菜单（相册、拍摄、位置、文件等）

**聊天页面特色**:
- 仿微信 UI 设计
- 水印层（防截图）
- 时间戳智能显示（5分钟内不重复）
- 消息气泡自适应宽度
- 语音消息宽度根据时长动态调整
- 支持图片预览、视频播放

### 2.5 验证码系统

**文件**: `components/captcha/`

**功能特性**:
- ✅ 滑块验证码（账号登录）
- ✅ 短信验证码（手机号登录）
- ✅ AES 加密传输
- ✅ 支持开关配置（`CAPTCHA_ENABLE`）
- ✅ 三端兼容（Android、iOS、Web）

## 三、页面路由配置

### 3.1 TabBar 页面（底部导航）

| 页面 | 路径 | 图标 | 功能 |
|------|------|------|------|
| 消息 | pages/message/message | \uea98 | 消息列表 |
| 通讯录 | pages/contacts/contacts | \uea94 | 联系人列表 |
| 工作台 | pages/workbench/workbench | \uea80 | 工作台功能 |
| 我的 | pages/profile/profile | \uea97 | 个人中心 |

### 3.2 其他页面

| 页面 | 路径 | 功能 |
|------|------|------|
| 登录 | pages/login/login | 用户登录 |
| 聊天 | pages/message/chat | 聊天详情 |
| 聊天设置 | pages/message/chat-settings | 聊天设置 |
| 发起群聊 | pages/contacts/initiate-group | 创建群聊 |

## 四、配置说明

### 4.1 应用配置 (`config/app.config.uts`)

```typescript
// 验证码开关
export const CAPTCHA_ENABLE = 'true'

// 租户开关
export const TENANT_ENABLE = 'true'

// API 基础地址
export const BASE_URL = 'http://localhost:48080'

// 请求超时时间
export const TIMEOUT = 30000

// 短信验证码倒计时
export const SMS_CODE_COUNTDOWN = 60
```

### 4.2 权限配置 (`manifest.json`)

**Android 权限**:
- 录音权限（语音消息）
- 相机权限（拍照）
- 音频设置权限
- 存储读写权限

**iOS 权限描述**:
- 麦克风权限
- 相机权限
- 相册权限

## 五、状态管理

### 5.1 用户状态 (`store/user.uts`)

**存储内容**:
- Access Token
- Refresh Token
- 租户 ID（字符串类型，避免大整数精度丢失）
- 部门 ID
- 用户信息（头像、昵称、部门）
- 权限列表
- 角色列表

**关键方法**:
```typescript
// Token 管理
setToken(token: TokenType)
getAccessToken(): string | null
removeToken()

// 用户信息
setUserInfo(userInfo: UserInfoVO)
getUserInfo(): UserInfoVO | null
clearUserCache() // 清除所有缓存并跳转登录

// 权限检查
hasPermission(permission: string): boolean
hasAnyPermission(permissionList: string[]): boolean
hasAllPermissions(permissionList: string[]): boolean

// 角色检查
hasRole(role: string): boolean
hasAnyRole(roleList: string[]): boolean
```

### 5.2 国际化状态 (`store/locale.uts`)

**支持语言**:
- zh-CN: 简体中文
- en: English

**关键方法**:
```typescript
getCurrentLocale(): LocaleType
setCurrentLocale(locale: LocaleType)
t(key: string, defaultValue?: string): string
switchLocale(locale: LocaleType)
initLocale() // 初始化，自动检测系统语言
```

## 六、工具函数

### 6.1 网络请求 (`utils/request.uts`)

```typescript
// 基础请求
request(options: UTSJSONObject): Promise<any>

// 快捷方法
get(url: string, params?: UTSJSONObject): Promise<any>
post(url: string, data?: UTSJSONObject): Promise<any>
postRaw(url: string, data?: UTSJSONObject): Promise<any> // 返回完整响应
```

### 6.2 表情系统

**表情数据** (`utils/emojiData.uts`):
- 系统表情包列表
- 表情代码映射

**表情解析器** (`utils/emojiParser.uts`):
- 解析文本中的表情代码
- 转换为图片标签

**自定义表情管理** (`utils/stickerManager.uts`):
- 获取收藏表情列表
- 添加/删除收藏表情

### 6.3 文件处理

**文件工具** (`utils/file.uts`):
- 文件大小格式化
- 文件类型判断

**上传工具** (`utils/upload.uts`):
- 文件上传封装
- 进度回调

## 七、样式规范

### 7.1 全局样式 (`App.uvue`)

**颜色变量**:
- 主色：`#3370FF`
- 主文本：`#1F2329`
- 描述文本：`#646A73`
- 占位文本：`#8F959E`
- 页面背景：`#F5F7FA`
- 白色背景：`#FFFFFF`

**圆角规范**:
- 小圆角：4px
- 中圆角：8px
- 大圆角：12px

### 7.2 图标字体

**iconfont 配置**:
- 字体文件：`static/iconfont/iconfont.ttf`
- 配置文件：`static/iconfont/iconfont.json`
- 使用方式：`<text class="iconfont">&#xe602;</text>`

**常用图标**:
- 删除：`\ue602`
- 转发：`\ue63d`
- 撤回：`\ue643`
- 复制：`\ue7cb`
- 引用：`\ue6f4`
- 多选：`\ue69d`
- 收藏：`\ue83f`

## 八、开发规范

### 8.1 命名规范

- **文件命名**: kebab-case（如 `chat-settings.uvue`）
- **组件命名**: PascalCase（如 `CaptchaSlider`）
- **函数命名**: camelCase（如 `getUserInfo`）
- **常量命名**: UPPER_SNAKE_CASE（如 `BASE_URL`）

### 8.2 代码规范

1. **严格类型检查**: 使用 UTS 类型系统
2. **错误处理**: 统一使用 try-catch 和 Promise
3. **注释规范**: 函数必须有 JSDoc 注释
4. **导入顺序**: 
   - Vue 相关
   - UniApp 相关
   - 第三方库
   - 项目内部模块

### 8.3 提交规范

- feat: 新功能
- fix: 修复 bug
- docs: 文档更新
- style: 代码格式调整
- refactor: 重构
- perf: 性能优化
- test: 测试相关
- chore: 构建/工具相关

## 九、已完成功能清单

### 9.1 基础功能
- ✅ 用户登录（账号/手机号）
- ✅ Token 自动刷新
- ✅ 多租户支持
- ✅ 国际化（中英文）
- ✅ 权限和角色管理

### 9.2 即时通讯
- ✅ 消息列表
- ✅ 聊天详情（仿微信）
- ✅ 多种消息类型
- ✅ 表情系统
- ✅ 消息操作菜单（带图标）
- ✅ 多选模式
- ✅ 语音输入
- ✅ 全屏编辑

### 9.3 UI 优化
- ✅ 仿微信设计
- ✅ 响应式布局
- ✅ 动画效果
- ✅ 深色菜单
- ✅ 消息高亮

## 十、待开发功能

### 10.1 即时通讯
- ⏳ 消息撤回（2分钟内）
- ⏳ 消息引用回复
- ⏳ 消息转发
- ⏳ 消息收藏
- ⏳ WebSocket 实时通讯
- ⏳ 消息已读/未读状态
- ⏳ 群聊功能
- ⏳ 语音通话
- ⏳ 视频通话

### 10.2 通讯录
- ⏳ 联系人列表
- ⏳ 好友申请
- ⏳ 群组管理
- ⏳ 组织架构

### 10.3 工作台
- ⏳ 待办事项
- ⏳ 审批流程
- ⏳ 考勤打卡
- ⏳ 公告通知

### 10.4 个人中心
- ⏳ 个人资料编辑
- ⏳ 账号设置
- ⏳ 隐私设置
- ⏳ 关于我们

## 十一、技术亮点

1. **原生性能**: UniAppX 原生渲染，性能接近原生应用
2. **类型安全**: UTS 提供完整的类型检查
3. **三端统一**: 一套代码，Android、iOS、Web 三端运行
4. **严格对齐**: 与 PC 端 API、Token、租户系统完全一致
5. **AI 友好**: 配置多种 AI 工具，提高开发效率
6. **精度处理**: 租户 ID 使用字符串避免大整数精度丢失
7. **用户体验**: 仿微信设计，用户无学习成本
8. **安全性**: AES 加密、Token 刷新、权限控制

## 十二、部署说明

### 12.1 开发环境

1. 安装 HBuilderX
2. 导入项目
3. 配置 API 地址（`config/app.config.uts`）
4. 运行到模拟器或真机

### 12.2 打包发布

**Android**:
```bash
# 在 HBuilderX 中
发行 → 原生 App-云打包 → Android
```

**iOS**:
```bash
# 在 HBuilderX 中
发行 → 原生 App-云打包 → iOS
```

**H5**:
```bash
# 在 HBuilderX 中
发行 → H5
```

## 十三、常见问题

### Q1: 租户 ID 精度丢失？
**A**: 已使用字符串类型存储和传输租户 ID，避免 JavaScript 大整数精度问题。

### Q2: Token 过期如何处理？
**A**: 自动刷新机制，使用 Refresh Token 获取新的 Access Token，无感刷新。

### Q3: 如何添加新的消息类型？
**A**: 在 `pages/message/chat.uvue` 中添加新的消息类型判断和渲染逻辑。

### Q4: 如何自定义主题色？
**A**: 修改 `App.uvue` 中的全局样式变量。

### Q5: 如何添加新的语言？
**A**: 在 `locales/` 目录下添加新的语言文件，并在 `store/locale.uts` 中注册。

## 十四、项目文档

- [快速开始](./QUICK-START.md)
- [验证码实现说明](./验证码实现说明.md)
- [消息页面实现说明](./消息页面实现说明.md)
- [消息操作功能实现](./实现消息撤回、删除、转发、引用与多选功能.md)

---

**最后更新**: 2026-02-09  
**维护者**: 开发团队
