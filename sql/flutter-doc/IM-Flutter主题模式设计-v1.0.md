# IM Flutter 主题模式设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 的主题体系、主题设置页、设备级主题策略详细设计  

---

## 1. 目标

定义 Flutter IM 的主题模式实现方式，并明确主题模式只跟随设备本地，不走服务端跨端同步。

---

## 2. 冻结结论

1. 主题模式仅本地保存
2. 支持：
   - `system`
   - `light`
   - `dark`
3. 修改后立即生效
4. 可展示当前实际应用结果预览
5. 聊天气泡主题与全局主题分离

---

## 3. 架构设计

目录建议：

```text
app/theme/
  app_theme.dart
  app_colors.dart
  app_spacing.dart
  app_radius.dart
  app_typography.dart
  theme_mode_controller.dart
```

### 3.1 `ThemeModeController`

负责：

- 当前主题模式
- 解析后的实际主题
- 本地持久化
- 主题切换广播

### 3.2 `ThemeState`

建议字段：

- `themeMode`
- `resolvedTheme`
- `tokens`
- `isFollowingSystem`

---

## 4. 主题设置页职责

`ThemeSettingsPage` 负责：

- 展示主题模式选项
- 切换主题模式
- 展示当前实际应用主题
- 展示轻量预览卡片

---

## 5. 页面结构

- `ThemeSettingsScaffold`
  - `ThemeOptionList`
  - `ThemePreviewCard`

---

## 6. 主题选项

建议固定为：

- `system`
- `light`
- `dark`

每个选项展示：

- 标题
- 描述
- 当前选中状态

---

## 7. 生效规则

### 7.1 `system`

- 跟随 OS 亮暗模式

### 7.2 `light`

- 强制浅色

### 7.3 `dark`

- 强制深色

---

## 8. 本地存储

存储 key：

- `app.theme_mode`

规则：

- 只本地保存
- 不依赖服务端跨端统一

---

## 9. 与聊天气泡偏好边界

### 9.1 全局主题

- 决定页面底色、文本、分割线、输入区等全局 token

### 9.2 聊天气泡偏好

- 属于独立服务端同步能力
- 不与全局主题模式混用

---

## 10. controller 设计

### 10.1 `ThemeSettingsController`

建议动作：

- `load()`
- `selectThemeMode()`
- `resolveTheme()`
- `persistThemeMode()`

---

## 11. 验收标准

1. 主题切换后全局 UI 立即更新
2. `system` 模式能跟随设备变化
3. 新设备不自动继承旧设备主题
4. 聊天气泡偏好不与主题模式耦合

