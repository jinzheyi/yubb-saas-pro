# IM Flutter 国际化与语言设置设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 的国际化体系、语言设置页面、设备级语言策略详细设计  

---

## 1. 目标

定义 Flutter IM 的国际化实现方式，并明确语言设置只跟随设备本地，不走服务端跨端同步。

---

## 2. 冻结结论

1. 语言模式仅本地保存
2. 支持：
   - `system`
   - `zh-CN`
   - `en`
3. 修改后立即生效
4. HTTP 请求头同步 `Accept-Language`
5. websocket 认证时同步 `locale`

---

## 3. 架构设计

目录建议：

```text
app/l10n/
  app_locale_controller.dart
  locale_state.dart
  l10n_keys.dart
  l10n_registry.dart
```

### 3.1 `AppLocaleController`

负责：

- 当前语言模式
- 解析后的实际 locale
- 本地持久化
- 语言切换广播

### 3.2 `LocaleState`

建议字段：

- `languageMode`
- `resolvedLocale`
- `isFollowingSystem`

---

## 4. 语言设置页职责

`LanguageSettingsPage` 负责：

- 展示语言选项
- 切换语言模式
- 展示当前实际生效语言

不负责：

- 服务端偏好同步

---

## 5. 页面结构

- `LanguageSettingsScaffold`
  - `LanguageOptionList`
  - `LanguageResolvedPreviewCard`

---

## 6. 语言选项

建议固定为：

- `system`
- `zh-CN`
- `en`

每个选项展示：

- 标题
- 描述
- 当前选中状态

---

## 7. 生效规则

### 7.1 `system`

- 跟随 OS / 浏览器 locale

### 7.2 `zh-CN`

- 强制中文

### 7.3 `en`

- 强制英文

---

## 8. 网络与 websocket 协同

### 8.1 HTTP

- `LocaleInterceptor` 注入 `Accept-Language`

### 8.2 WebSocket

- `AUTH_REQ.locale` 带当前 resolved locale

### 8.3 页面

- 语言切换后无需重新登录
- 若 socket 需要更新 locale，可在下次 reauth 时带新值
- 会话列表、聊天时间线、搜索结果时间文案必须统一走同一 formatter facade

---

## 9. 本地存储

存储 key：

- `app.language_mode`

规则：

- 只本地保存
- 不走服务端统一

---

## 10. controller 设计

### 10.1 `LanguageSettingsController`

建议动作：

- `load()`
- `selectLanguageMode()`
- `resolveLocale()`
- `persistLanguageMode()`

---

## 11. 验收标准

1. 语言切换后页面文案立即变化
2. `Accept-Language` 与 websocket locale 正确更新
3. 新设备不自动继承旧设备语言
4. 不依赖服务端偏好接口
