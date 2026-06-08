# Flutter 主题模式（Theme Mode）企业级实现方案

> **设计原则：纯设备级主题策略（类似国际化）**
> 
> - 主题模式存储在设备本地（SharedPreferences），不跟随账号
> - 换设备/换账号不影响主题设置
> - 退出登录不清除主题偏好
> - 与国际化（i18n）作用域完全一致

---

## 1. 现状全景分析

### 1.1 主题相关架构

| 组件 | 文件 | 状态 |
|------|------|------|
| **控制器** | `theme_mode_controller.dart` | ✅ 正确实现（Riverpod StateNotifierProvider） |
| **持久化** | `StorageKeyRegistry` + `SharedPreferences` | ✅ key 定义正确 `app.theme_mode` |
| **启动加载** | `app_bootstrap_provider.dart` | ✅ 启动时从 SharedPreferences 恢复 |
| **主题应用** | `app_bootstrap.dart` → `MaterialApp.router` | ✅ 响应式 watch 主题模式 |
| **设置页面** | `theme_settings_page.dart` | ✅ 已实现完整交互（含确认机制） |
| **Light Theme** | `app_theme.dart` | ✅ 完整配置 |
| **Dark Theme** | `app_theme.dart` | ✅ 已完善对齐 light theme |

### 1.2 三端主题架构对比

| 端 | 主题存储位置 | 是否设备级独立 | 账号切换影响 |
|---|---|---|---|
| **Flutter App** | `SharedPreferences` (本地) | ✅ 是 | ❌ 不受影响 |
| **Vue3 Web 管理端** | `localStorage` (浏览器) | ✅ 是 | ❌ 不受影响 |
| **后端** | ~~不存储主题偏好~~ | ~~已清理~~ | ~~已移除~~ |

### 1.3 已实现的基础设施（无需修改）

#### `theme_mode_controller.dart` — 控制器

```dart
enum AppThemeModeChoice { light, dark, system }

class AppThemeState {
  final AppThemeModeChoice choice;
  final ThemeMode themeMode;
  // choice → themeMode 自动映射
}

class AppThemeController extends StateNotifier<AppThemeState> {
  Future<void> load() async // 从 SharedPreferences 恢复
  Future<void> selectThemeMode(ThemeMode mode) async // 设置并持久化
}
```

#### `StorageKeyRegistry` — 存储 Key

```dart
static const String appThemeMode = 'app.theme_mode';
```

#### `app_bootstrap_provider.dart` — 启动加载

```dart
final appThemeModeProvider = Provider<ThemeMode>(...);
// 启动时调用 AppThemeController.load() 恢复设置
```

#### `TokenStorage.clear()` — 清除逻辑

```dart
static Future<void> clear() async {
  // ... 清除 token, userId, tenantId 等
  // ✅ 故意不清除 SharedPreferences 中的主题设置
}
```

#### 作用域确认

```
┌──────────────────────────────────────────┐
│              设备级别 (SharedPreferences)   │
│                                          │
│  ┌────────────┐  ┌────────────────────┐  │
│  │  主题模式   │  │     语言设置        │  │
│  │  (device)  │  │   (device)          │  │
│  └────────────┘  └────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │       账号级别 (AuthSession)        │  │
│  │  token, userId, tenantId, deviceId │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## 2. 技术方案选型

### 2.1 调研方案对比

| 方案 | 优点 | 缺点 | 适合本项目 |
|------|------|------|-----------|
| **SharedPreferences + Riverpod** (已采用) | 项目已有基础设施，最小改动 | 需手动序列化 | ✅ 是 |
| **hydrated_bloc** | BLoC 下自动序列化 | 需引入 BLoC，项目用 Riverpod | ❌ 不匹配 |
| **flutter_theme_orchestrator** | 支持调度、动画、持久化 | 引入过重，功能过剩 | ❌ 过度设计 |
| **flutter_theme_changer_erfan** | 主打动态颜色切换 | 非 light/dark 模式场景 | ❌ 不匹配 |

### 2.2 结论

项目已有的 `shared_preferences` + `Riverpod StateNotifierProvider` 方案是企业级最佳实践，原因：
1. `SharedPreferences` 天然就是设备级存储，不跟随账号
2. Riverpod 状态管理已正确集成，响应式更新 themeMode
3. `MaterialApp.router` 的 `themeMode` 参数支持动态切换
4. 与国际化作用域一致，代码结构对称

---

## 3. 已修复的问题清单

### 3.1 P0 — i18n key 错误

**文件：** `theme_settings_page.dart`

**问题：** 跟随系统选项复用了语言设置的 i18n key：
- `languageModeSystemTitle`（语言相关）误用于主题设置
- `languageModeSystemDescription`（语言相关）误用于主题设置
- `'立即生效'` 硬编码未走 i18n

**修复：**
- 新增 `themeModeSystemTitle` / `themeModeSystemDescription` / `themePreviewApplyBtn` 三个 key
- 同步补充到 4 个 `.arb` 文件（zh/en/ja/ko）
- 页面代码替换为正确的 key

### 3.2 P1 — Dark Theme 定义不完整

**文件：** `app_theme.dart`

**原定义（仅 4 行）：**
```dart
static ThemeData get dark => ThemeData(
  fontFamily: 'AppSans',
  colorScheme: ColorScheme.fromSeed(brightness: Brightness.dark, seedColor: ...),
  useMaterial3: true,  // 与 light 不一致
);
```

**修复后完整定义：**
| 配置项 | Light 值 | Dark 值 |
|--------|----------|---------|
| `scaffoldBackgroundColor` | `#FFFFFF` | `#121620` |
| `appBarTheme.backgroundColor` | `#FFFFFF` | `#1E2430` |
| `appBarTheme.iconTheme.color` | `#8F96A3` | `Colors.white` |
| `appBarTheme.titleTextStyle.color` | `#202531` | `Colors.white` |
| `inputDecorationTheme.fillColor` | `#F5F7FB` | `#2A3140` |
| `cardColor` | `#FFFFFF` | `#1E2430` |
| `bottomSheetTheme.backgroundColor` | `#FFFFFF` | `#1E2430` |
| `dividerColor` | `#F0F2F6` | `#2A3140` |
| `useMaterial3` | `false` | `false` |

### 3.3 P2 — 主题切换动画

**文件：** `app_bootstrap.dart`

**新增：**
```dart
themeAnimationDuration: const Duration(milliseconds: 300),
themeAnimationCurve: Curves.easeInOut,
```

### 3.4 P0 — 确认按钮机制（类似国际化设置）

**文件：** `theme_settings_page.dart`

**原行为：** 点击选项立即生效，无确认机制

**修复后行为：**
1. 点击选项仅更新待选状态（`_pendingMode`），不立即持久化
2. 右上角显示"确认"按钮，仅在有未保存更改时可用
3. 返回键检测到未保存更改时弹出确认对话框
4. 点击确认后调用 `controller.selectThemeMode()` 持久化
5. 与 `language_settings_page.dart` 行为完全一致

**交互流程：**
```
用户点击选项 → _pendingMode 更新 → UI 显示选中状态（未持久化）
       ↓
用户点击"确认" → controller.selectThemeMode() → 持久化到 SharedPreferences
       ↓
用户点击返回 → 检测 hasChanges → 弹出确认对话框 → 放弃/继续编辑
```

---

## 4. 后端清理清单

### 4.1 已移除的文件

| 文件 | 说明 |
|------|------|
| `AppUserThemeUpdateReqVO.java` | 主题更新请求 VO，已删除 |

### 4.2 已移除的字段

| 文件 | 移除字段 |
|------|---------|
| `AdminUserDO.java` | `themeMode` |
| `AppUserDetailRespVO.java` | `themeMode` |
| `UserRespVO.java` | `themeMode` |

### 4.3 已移除的 API 端点

| Controller | 端点 | 说明 |
|-----------|------|------|
| `AppUserController.java` | `PUT /system/user/theme` | 更新当前用户主题偏好 |

### 4.4 已移除的 Service 方法

| 文件 | 方法 |
|------|------|
| `AdminUserService.java` | `updateUserThemePreference(Long id, String themeMode)` |
| `AdminUserServiceImpl.java` | `updateUserThemePreference(Long id, String themeMode)` |

### 4.5 已移除的验证消息

| 文件 | 移除的 key |
|------|-----------|
| `messages.properties` | `validation.preference.theme_mode.required`, `validation.preference.theme_mode.invalid` |
| `messages_en.properties` | `validation.preference.theme_mode.required`, `validation.preference.theme_mode.invalid` |

### 4.6 数据库迁移脚本

**文件：** `sql/mysql/1.0/im/migration_group_lifecycle.sql`

```sql
-- ========================================
-- 主题模式改为设备本地存储，不再持久化到数据库
-- 说明：主题模式与国际化作用域一致，存储在 SharedPreferences，不跟随账号
-- ========================================
ALTER TABLE `system_users` DROP COLUMN `theme_mode`;
```

**文件：** `sql/mysql/1.0/im/ddl_user_preferences.sql`

```sql
-- 主题模式已改为设备本地存储（SharedPreferences），不再持久化到数据库
-- 原 theme_mode 字段已在 migration_group_lifecycle.sql 中通过 DROP COLUMN 清理

ALTER TABLE `system_users`
    ADD COLUMN IF NOT EXISTS `chat_bubble_color` ... AFTER `avatar`,
    ADD COLUMN IF NOT EXISTS `chat_bubble_mode` ... AFTER `chat_bubble_color`;
```

---

## 5. 多语言文案

### 5.1 新增翻译 Key

| Key | 中文 (zh) | 英文 (en) | 日文 (ja) | 韩文 (ko) |
|-----|-----------|-----------|-----------|-----------|
| `themeModeSystemTitle` | 跟随系统 | Follow system | Follow system | Follow system |
| `themeModeSystemDescription` | 跟随设备系统外观设置 | Follow the device system appearance setting | Follow the device system appearance setting | Follow the device system appearance setting |
| `themePreviewApplyBtn` | 立即生效 | Apply Immediately | Apply Immediately | Apply Immediately |

### 5.2 已有翻译 Key（无需修改）

| Key | 中文 |
|-----|------|
| `settingsThemeMode` | 主题模式 |
| `themeModeLightTitle` | 浅色模式 |
| `themeModeLightDescription` | 始终使用浅色页面与聊天背景 |
| `themeModeDarkTitle` | 深色模式 |
| `themeModeDarkDescription` | 始终使用深色页面与聊天背景 |
| `themePreviewTitle` | 当前预览 |
| `themePreviewMessage` | 接近老项目风格的主链路页面预览 |

### 5.3 已有共享翻译 Key（主题/语言共用）

| Key | 中文 | 说明 |
|-----|------|------|
| `confirmAction` | 确认 | 语言/主题设置共用 |
| `cancelAction` | 取消 | 语言/主题设置共用 |
| `discardChangesConfirm` | 是否放弃未保存的更改？ | 语言/主题设置共用 |
| `continueEditAction` | 继续编辑 | 语言/主题设置共用 |
| `discardAction` | 放弃 | 语言/主题设置共用 |

---

## 6. 数据流

```
用户点击主题选项（theme_settings_page.dart）
  ↓
_pendingMode 更新 → setState() → UI 显示选中状态（未持久化）
  ↓
用户点击"确认"按钮
  ↓
AppThemeController.selectThemeMode(ThemeMode)
  ↓
1. state = AppThemeState(choice: mapped choice)
  → setState() → ref.watch → MaterialApp.router.themeMode 响应式更新
2. prefs.setInt('app.theme_mode', mode.index)
  → 持久化到 SharedPreferences
  ↓
下次启动
  ↓
AppBootstrapInitializer._initAppTheme()
  → controller.load() → 从 SharedPreferences 恢复
  → MaterialApp.router 使用恢复后的主题
```

### ThemeMode ↔ AppThemeModeChoice 映射

| ThemeMode | AppThemeModeChoice | 存储值 (int) |
|-----------|-------------------|-------------|
| `ThemeMode.light` | `light` | 0 |
| `ThemeMode.dark` | `dark` | 1 |
| `ThemeMode.system` | `system` | 2 |

---

## 7. 设置页面 UI 结构

```
ThemeSettingsPage
├── AppBar: "主题模式"
│   ├── 返回按钮（有未保存更改时弹出确认对话框）
│   └── "确认"按钮（仅在有未保存更改时可用）
└── ListView
    ├── Container (白色圆角卡片)
    │   ├── _ThemeOptionTile: "跟随系统" + 描述 + radio icon
    │   ├── Divider
    │   ├── _ThemeOptionTile: "浅色模式" + 描述 + radio icon
    │   └── _ThemeOptionTile: "深色模式" + 描述 + radio icon
    │
    └── _ThemePreviewCard (预览卡片)
        ├── "当前预览" 标题
        └── Container (模拟聊天界面)
            ├── 头像 + 用户名占位
            ├── 左侧消息气泡（模拟接收消息）
            └── 右侧消息气泡 "立即生效"（蓝色背景）
```

---

## 8. 验证结果

| 检查项 | 结果 |
|--------|------|
| `flutter analyze` | ✅ No issues found |
| `flutter gen-l10n` | ✅ 4 种语言生成成功 |
| 编译兼容性 | ✅ 无警告 |

---

## 9. 修改文件清单

### Flutter 端

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `theme_settings_page.dart` | 重构 | ConsumerWidget → ConsumerStatefulWidget，添加 _pendingMode 机制 |
| `app_zh.arb` | 新增 | 3 个中文翻译 key |
| `app_en.arb` | 新增 | 3 个英文翻译 key |
| `app_ja.arb` | 新增 | 3 个日文翻译 key |
| `app_ko.arb` | 新增 | 3 个韩文翻译 key |
| `app_theme.dart` | 完善 | dark theme 从 4 行扩展为完整配置 |
| `app_bootstrap.dart` | 新增 | 主题切换 300ms 动画 |
| `app_localizations_*.dart` (generated) | 自动生成 | l10n 重新生成 |

### 后端

| 文件 | 修改类型 | 说明 |
|------|---------|------|
| `AdminUserDO.java` | 移除 | `themeMode` 字段 |
| `AppUserDetailRespVO.java` | 移除 | `themeMode` 字段 |
| `UserRespVO.java` | 移除 | `themeMode` 字段 |
| `AppUserThemeUpdateReqVO.java` | 删除 | 整个文件删除 |
| `AppUserController.java` | 移除 | `/theme` 端点 + `setThemeMode` 调用 |
| `AdminUserService.java` | 移除 | `updateUserThemePreference` 方法 |
| `AdminUserServiceImpl.java` | 移除 | `updateUserThemePreference` 实现 |
| `messages.properties` | 移除 | 主题验证消息 2 条 |
| `messages_en.properties` | 移除 | 主题验证消息 2 条 |
| `ddl_user_preferences.sql` | 修改 | 移除 `theme_mode` 列创建 |
| `migration_group_lifecycle.sql` | 新增 | `DROP COLUMN theme_mode` 清理脚本 |

---

## 10. 参考资源

- [Flutter ThemeMode 官方文档](https://api.flutter.dev/flutter/material/ThemeMode.html)
- [Flutter ThemeData 完整配置](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [shared_preferences 持久化](https://pub.dev/packages/shared_preferences)
- [Riverpod StateNotifierProvider](https://riverpod.dev/docs/concepts/state_notifier_provider)
