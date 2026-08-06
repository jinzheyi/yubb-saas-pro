# IM 音视频通话系统 - 分步实现计划

## Context

基于微信 2026 最新版截图和详细设计文档，当前 Flutter 通话模块基础设施层已完整实现（Janus RTC、信令、状态管理、多设备同步等），但 UI 层与微信存在差距，且缺少部分关键功能（来电横幅、成员选择页、群聊通话状态栏、配置文件等）。本计划分步实现所有未完成的 UI 和功能，达到企业级微信同级别用户体验。

## 当前实现状态

| 层级 | 状态 | 说明 |
|------|------|------|
| 基础设施（RTC/信令/状态管理） | ✅ 完整 | Janus客户端、CallController、Repository、网络监控、多设备同步 |
| 1v1 通话 UI | 🔶 部分 | 基础布局已有，需对齐微信细节（圆角矩形头像、3按钮控制栏、高斯模糊背景） |
| 群通话 UI | 🔶 部分 | 网格布局已有，需对齐微信细节（说话者指示器、顶部栏） |
| 来电横幅通知 | ❌ 缺失 | 聊天列表顶部来电横幅 |
| 成员选择页 | ❌ 缺失 | 发起群通话前的成员选择 |
| 群聊通话状态栏 | ❌ 缺失 | 群聊中显示"X人正在通话"+加入按钮 |
| 配置文件 | ❌ 缺失 | 最大参与人数、超时时间等可配置项 |
| 通话记录气泡 |  部分 | 基础实现已有，需完善样式 |

---

## 分步实现计划

### 第1步：创建通话配置文件 + 通用微信风格组件

**目标**：建立可配置基础，提取通用 UI 组件

**新建文件**：
- `lib/features/im/call/domain/entities/call_config.dart` — 通话配置实体（最大参与人数9、超时30秒等）
- `lib/features/im/call/infrastructure/config/call_config_provider.dart` — Riverpod Provider

**修改文件**：
- `lib/features/im/call/presentation/providers/call_providers.dart` — 注册配置 Provider

**配置项**：
```dart
class CallConfig {
  final int maxGroupCallParticipants; // 9（可配置）
  final Duration callInviteTimeout;   // 30秒
  final Duration ringtoneDuration;    // 30秒
  final bool enableCallRecording;     // true
  final bool enableScreenShare;       // true
  final bool enableCallTransfer;      // true
  final bool enableBackgroundBlur;    // true
}
```

**同步更新设计文档**：在 3.1.1.7 之后新增 3.1.1.8 配置说明章节

---

### 第2步：修复 IncomingCallPage — 对齐微信来电 UI

**修改文件**：
- `lib/features/im/call/presentation/pages/incoming_call_page.dart`

**UI 变更**（基于微信截图）：
1. 背景：径向渐变 → 纯色 `#3A3A3A`
2. 头像：圆形 100x100 → 圆角矩形 120x120（borderRadius: 12）
3. 按钮布局：居中 spaceEvenly → 左右 spaceBetween
4. 按钮尺寸：65x65 → 70x70
5. 群通话来电：显示"还有N人参与通话" + 参与者头像行

---

### 第3步：修复 CallSessionPage — 对齐微信 1v1 通话中 UI

**修改文件**：
- `lib/features/im/call/presentation/pages/call_session_page.dart`

**UI 变更**（基于微信截图）：
1. 语音通话背景：径向渐变 → 对方头像高斯模糊（BackdropFilter sigmaX/Y: 30）
2. 头像：圆形 100x100 → 圆角矩形 120x120
3. 顶部栏：最小化+时长+锁 → 屏幕共享图标+时长+加号
4. 控制栏：4按钮+独立挂断 → 3按钮横排（麦克风/挂断/扬声器）
5. 按钮文字：静音/取消静音 → 麦克风已开/麦克风已关
6. 按钮颜色：激活=白色，未激活=#555555，挂断=#E54D4F

---

### 第4步：修复 OutgoingCallPage — 对齐微信去电 UI

**修改文件**：
- `lib/features/im/call/presentation/pages/outgoing_call_page.dart`

**UI 变更**：
1. 背景：对齐微信深色纯色
2. 头像：圆角矩形 120x120
3. 按钮：3按钮横排（麦克风/取消/扬声器）
4. 状态文字："等待对方接听..."

---

### 第5步：修复 GroupCallSessionPage + ParticipantGrid — 对齐微信群通话 UI

**修改文件**：
- `lib/features/im/call/presentation/pages/group_call_session_page.dart`
- `lib/features/im/call/presentation/widgets/group_call_participant_grid.dart`

**UI 变更**：
1. 顶部栏：标题+人数+时长 → 屏幕共享+时长+加号
2. 控制栏：对齐微信 3按钮横排
3. 说话者指示器：蓝色边框 → 绿色光环（语音）/ 绿色声波图标（视频）
4. 网格布局规则：2人=1x2左右分屏，3-4人=2x2，5-6人=2x3，7-9人=3x3
5. 说话者光环呼吸动画

---

### 第6步：新建来电横幅通知 Widget + 集成到会话列表

**新建文件**：
- `lib/features/im/call/presentation/widgets/call_incoming_banner.dart` — 来电横幅 Widget

**修改文件**：
- `lib/features/im/conversation/presentation/pages/conversation_list_page.dart` — 集成横幅
- `lib/features/im/call/presentation/providers/call_providers.dart` — 新增横幅状态 Provider

**UI 规格**（基于微信截图）：
```
┌─────────────────────────────────┐
│ ┌─────────────────────────────┐ │
│ │ [头像48x48] 昵称    (📞)(📱) │ │
│ │      邀请你语音通话..         │ │
│ └─────────────────────────────┘ │
```
- 背景色：`#2A2A2A`，圆角 12px
- 拒绝/接听按钮：40x40 圆形
- 群通话：额外显示参与者头像行

---

### 第7步：新建群通话成员选择页

**新建文件**：
- `lib/features/im/call/presentation/pages/group_call_member_select_page.dart`
- `lib/features/im/call/presentation/controllers/group_member_select_controller.dart`
- `lib/app/router/route_args/group_call_member_select_args.dart`

**修改文件**：
- `lib/app/router/route_names.dart` — 新增路由名
- `lib/app/router/app_router.dart` — 新增路由
- `lib/features/im/call/presentation/providers/call_providers.dart` — 新增 Provider

**UI 规格**（基于微信截图）：
```
┌─────────────────────────────────
│ [<]      选择成员      [确定(2)] │
│                                 │
│      [头像1] [头像2]             │
│                                 │
│ 🔍 搜索                          │
│ ─────────────────────────────── │
│ [头像] 云淡风轻          ✓       │
│ [头像] 妈妈              ○       │
│ [头像] 老婆              ✓       │
│                                 │
│ ─────────────────────────────┐ │
│ │ 💬 使用企业微信发起通话       │ │
│ │    支持100人音视频...         │ │
│ └─────────────────────────────┘ │
```

---

### 第8步：新建群聊通话状态栏 + 集成到聊天页

**新建文件**：
- `lib/features/im/call/presentation/widgets/group_call_status_bar.dart`

**修改文件**：
- `lib/features/im/chat/presentation/pages/chat_page.dart` — 集成状态栏
- `lib/features/im/call/presentation/providers/call_providers.dart` — 新增状态栏 Provider

**UI 规格**（基于微信截图）：

收起模式：
```
┌─────────────────────────────────┐
│ (📞) 2人正在语音通话        [∨] │
└─────────────────────────────────┘
```

展开模式：
```
┌─────────────────────────────────┐
│ (📞) 2人正在语音通话        [∧] │
│ ┌─────────────────────────────┐ │
│ │     [头像1] [头像2]          │ │
│ ├─────────────────────────────┤ │
│ │          加入                │ │
│ └───────────────────────────── │
```

---

### 第9步：完善通话记录消息气泡

**修改文件**：
- `lib/features/im/call/presentation/widgets/call_record_message_bubble.dart`

**变更**：
1. 对齐微信系统消息样式（灰色居中文字）
2. 消息格式：`{发起人}发起了{语音/视频}通话`、`{语音/视频}通话已经结束`
3. 邀请成员格式：`"{发起人}"邀请你和"{成员}"加入了群聊`
4. 点击气泡可回看通话详情

---

### 第10步：同步更新设计文档

**修改文件**：
- `docs/im-rtc-call-system-design.md`

**更新内容**：
1. 核心功能清单更新实现状态标记
2. 新增 3.1.1.8 配置说明章节
3. 每个 UI 页面补充最终实现截图对照
4. 补充成员选择页、来电横幅、通话状态栏的完整设计规范
5. 更新 API 接口文档（如有变更）

---

## 执行顺序与依赖关系

```
第1步（配置+组件）
  ├── 第2步（来电页）──── 依赖第1步的通用组件
  ├── 第3步（1v1通话中）── 依赖第1步的通用组件
  ├── 第4步（去电页）──── 依赖第1步的通用组件
  └── 第5步（群通话）──── 依赖第1步的通用组件
        │
        ├── 第6步（来电横幅）── 依赖第2步的来电状态
        ├── 第7步（成员选择）── 依赖第5步的群通话逻辑
        └── 第8步（通话状态栏）── 依赖第5步的群通话状态
              │
              └── 第9步（记录气泡）── 独立
                    │
                    ── 第10步（文档更新）── 全部完成后
```

## 关键文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `call_config.dart` | 新建 | 通话配置实体 |
| `call_config_provider.dart` | 新建 | 配置 Provider |
| `call_incoming_banner.dart` | 新建 | 来电横幅 Widget |
| `group_call_member_select_page.dart` | 新建 | 成员选择页 |
| `group_member_select_controller.dart` | 新建 | 成员选择控制器 |
| `group_call_member_select_args.dart` | 新建 | 路由参数 |
| `group_call_status_bar.dart` | 新建 | 群聊通话状态栏 |
| `incoming_call_page.dart` | 修改 | 对齐微信来电 UI |
| `call_session_page.dart` | 修改 | 对齐微信 1v1 通话 UI |
| `outgoing_call_page.dart` | 修改 | 对齐微信去电 UI |
| `group_call_session_page.dart` | 修改 | 对齐微信群通话 UI |
| `group_call_participant_grid.dart` | 修改 | 说话者指示器 |
| `call_record_message_bubble.dart` | 修改 | 完善消息气泡 |
| `conversation_list_page.dart` | 修改 | 集成来电横幅 |
| `chat_page.dart` | 修改 | 集成通话状态栏 |
| `call_providers.dart` | 修改 | 新增 Provider |
| `route_names.dart` | 修改 | 新增路由名 |
| `app_router.dart` | 修改 | 新增路由 |
| `im-rtc-call-system-design.md` | 修改 | 同步更新文档 |

## 验证方式

每步完成后：
1. `flutter analyze` — 无错误无警告
2. 真机/模拟器运行验证 UI 效果
3. 与设计文档中的微信截图对比
4. 功能流程测试（发起→接听→通话中→挂断→记录）
