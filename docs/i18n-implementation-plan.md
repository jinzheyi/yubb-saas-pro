# Flutter 企业级国际化（i18n）完善方案

> **设计原则：纯设备级语言策略（类微信体验）**
> 
> - 各设备语言完全独立，换设备不记忆上次选择
> - Flutter App、Vue3 Web 管理端各自维护语言设置
> - 后端通过 `Accept-Language` 请求头响应，不存储用户语言偏好

---

## 1. 现状全景分析

### 1.1 三端语言架构

| 端 | 语言存储位置 | 是否设备级独立 | 后端同步 |
|---|---|---|---|
| **Flutter App** | `SharedPreferences` (本地) | ✅ 是 | HTTP 请求通过 `Accept-Language` 头传递 |
| **Vue3 Web 管理端** | `localStorage` (浏览器) | ✅ 是 | ❌ 纯本地，不与后端交互 |
| **后端** | 不存储语言偏好 | — | 仅根据 `Accept-Language` 头动态响应 |

### 1.2 前端现状（Flutter）

| 维度 | 现状 | 问题 |
|------|------|------|
| **方案选型** | `flutter_localizations` + `intl` + ARB | ✅ 选型正确 |
| **语言文件** | 2个ARB文件（1031行/文件），zh/en | ⚠️ 超大文件，无模块化拆分 |
| **状态管理** | Riverpod `AppLocaleController` | ✅ 架构合理 |
| **持久化** | `SharedPreferences` + `AuthSession.locale` | ✅ 本地持久化 |
| **HTTP联动** | `LocaleInterceptor` 注入 `Accept-Language` | ✅ 每请求带语言头 |
| **动态切换** | 通过 `MaterialApp.locale` 响应式更新 | ✅ 支持热切换 |
| **占位符格式** | `{count}` 简单占位 | ⚠️ 缺少 ICU MessageFormat 复数 |
| **日期/数字** | 无本地化格式化 | ❌ 完全缺失 |
| **翻译校验** | 无自动化校验 | ❌ 缺少 CI/CD 集成 |
| **双轨调用** | `AppLocalizations.of(context)` + `appStringsProvider` | ⚠️ 调用方式不统一 |

### 1.3 后端现状

| 维度 | 现状 | 说明 |
|------|------|------|
| **LocaleResolver** | `ShengyuLocaleResolver` 扩展 `AcceptHeaderLocaleResolver` | 基于 `Accept-Language` 头解析 |
| **支持语言** | `zh_CN` / `en` | 默认简体中文 |
| **MessageSource** | Spring `MessageSource` 注入到 `ServiceExceptionUtil` | 错误码国际化 |
| **错误消息文件** | `messages.properties` / `messages_en.properties` | 134行，含错误码/校验/IM系统消息/WS消息 |
| **IM系统消息** | `ImSystemMessageI18nSupport` | 支持 eventKey + params 模式 |
| **占位符格式** | `{0}` (MessageFormat) + `{name}` (命名占位符) | ⚠️ 两种格式混用 |
| **WebSocket推送** | 推送 i18n eventKey + params | 支持历史消息按当前语言重渲染 |

### 1.4 Web 管理端现状

| 维度 | 现状 |
|------|------|
| **i18n 框架** | `vue-i18n` (legacy: false) |
| **语言存储** | `localStorage`（通过 `wsCache`） |
| **状态管理** | Pinia `useLocaleStore` |
| **Element Plus 本地化** | 通过 `elLocale` 映射 |
| **支持语言** | `zh-CN` / `en` |
| **与后端联动** | ❌ 无联动，纯前端管理 |

### 1.5 前后端联动链路

```
用户切换语言（设备级）
  ↓
Flutter: AppLocaleController.selectLanguageMode()
  ↓
1. SharedPreferences 持久化（本地设备独立）
2. AuthSession.locale 更新 → SecureStorage
3. appLocaleObjectProvider 更新 → MaterialApp.locale 响应式切换
  ↓
下次HTTP请求
  ↓
LocaleInterceptor 注入 Accept-Language header (如 "zh-CN" 或 "en")
  ↓
后端 ShengyuLocaleResolver 解析 → LocaleContextHolder
  ↓
ServiceExceptionUtil / MessageSource 按语言返回错误消息
```

**关键确认：**
- ✅ `AdminUserDO` 没有 `locale` 字段 → 符合设备级策略
- ✅ `updateLocale()` 仅更新本地 `AuthSession` → 不涉及后端 API
- ✅ 各端语言互不影响 → 符合微信体验

---

## 2. 完善方案（按优先级排序）

### Phase 1: 基础架构优化（高优先级）

#### 1.1 ARB 文件模块化拆分

**目标：** 将 1031 行的巨型 ARB 文件按业务模块拆分，提升可维护性和可扩展性（便于后续添加日文/韩文）

**拆分策略：**

由于 Flutter 官方 `gen_l10n` 不支持多 ARB 文件自动合并，采用 **命名空间前缀 + 注释分区** 的方式实现逻辑拆分：

```arb
// === AUTH MODULE (认证模块) ===
"auth.usernameLabel": "账号",
"auth.passwordLabel": "密码",
"auth.loginAction": "登录",

// === CHAT MODULE (聊天模块) ===
"chat.inputMessage": "输入消息",
"chat.messageSending": "发送中",

// === GROUP MODULE (群聊模块) ===
"group.settingsTitle": "群聊设置",
"group.membersTitle": "群成员",
```

**命名规范：**

```
{module}.{feature}.{key}
```

| 模块前缀 | 说明 | 示例 |
|---------|------|------|
| `auth` | 登录/认证 | `auth.usernameLabel` |
| `common` | 通用按钮/动作 | `common.confirmAction` |
| `conv` | 会话列表 | `conv.emptyConversation` |
| `chat` | 聊天页面 | `chat.messageSending` |
| `chat.media` | 聊天媒体 | `chat.media.empty` |
| `contacts` | 通讯录 | `contacts.profileTitle` |
| `group` | 群聊管理 | `group.settingsTitle` |
| `workbench` | 工作台 | `workbench.approval` |
| `profile` | 个人中心 | `profile.logout` |
| `favorite` | 收藏 | `favorite.pageTitle` |
| `settings` | 设置页面 | `settings.language` |
| `system` | 系统消息/错误 | `system.unknownError` |
| `browser` | 安全浏览器 | `browser.title` |
| `file` | 文件预览 | `file.previewTitle` |

#### 1.2 统一翻译调用方式

**现状问题：**
- 部分页面使用 `AppLocalizations.of(context)!`
- `appStringsProvider` 在 Riverpod 场景中使用

**统一约定：**

```dart
// ✅ Widget build 方法中统一使用 context
@override
Widget build(BuildContext context) {
  final strings = AppLocalizations.of(context)!;
  return Text(strings.appName);
}

// ✅ 非 Widget 场景（Riverpod Provider / 工具类）使用 provider
final strings = ref.watch(appStringsProvider);

// ❌ 禁止在 build 方法中混用 provider
```

**保留 `appStringsProvider` 的场景：**
- 非 Widget 类的 Provider 需要翻译文本
- 工具类方法需要国际化（如错误消息格式化）

---

### Phase 2: 高级国际化特性（高优先级）

#### 2.1 ICU MessageFormat 复数支持

**现状：** 使用 `{count}` 简单占位，英文无法正确处理单复数

**改造方案：**

```arb
// app_en.arb
"chatSelectedCount": "{count, plural, =0{No messages selected} =1{1 message selected} other{{count} messages selected}}",
"@chatSelectedCount": {
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}

// app_zh.arb（中文不需要区分复数）
"chatSelectedCount": "已选择 {count} 条",
"@chatSelectedCount": {
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}
```

**需要改造的占位符清单（英文需要复数形式）：**

| Key | 说明 |
|-----|------|
| `contacts.countPeople` | {count}人 |
| `chat.selectedCount` | 已选择 {count} 条 |
| `chat.forwardTarget.messageCount` | {count}条消息 |
| `chat.readReceipt.read` | 已读 {count} |
| `chat.readReceipt.unread` | 未读 {count} |
| `chat.readReceipt.total` | 总接收人数 {count} |
| `chat.maxSelectReached` | 最多选择 {count} 条 |
| `chat.maxStickerReached` | 最多添加{count}张表情 |
| `chatPresence.minutesAgoActive` | {count}分钟前活跃 |
| `group.membersTitleWithCount` | 群成员({count}) |
| `group.membersConfirmSelected` | 确定({count}) |
| `group.settings.removeSelected` | 移除所选成员 ({count}) |
| `group.settings.membersCount` | 共 {count} 位成员 |
| `group.settings.pendingCount` | {count} 条待处理 |
| `chatHistory.daysAgoAt` | {count}天前 {time} |
| `chatGroupMember.addedMany` | 等{otherCount}人加入了群聊 |

**未来日/韩文适配要点：**
- 日文：与中文类似，无复数变化，但需要注意量词表达
- 韩文：无复数变化，但需要注意敬语表达

#### 2.2 选择性别（Select）支持

```arb
// app_en.arb
"chatPresence.weekdayActiveAt": "{weekday, select, Monday{Monday} Tuesday{Tuesday} Wednesday{Wednesday} Thursday{Thursday} Friday{Friday} Saturday{Saturday} Sunday{Sunday}} at {time}",
"@chatPresence.weekdayActiveAt": {
  "placeholders": {
    "weekday": {},
    "time": {}
  }
}
```

#### 2.3 日期/数字本地化格式化

**创建统一格式化工具类：**

```dart
// lib/core/i18n/locale_formatter.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 企业级本地化格式化工具
/// 
/// 所有日期/数字/货币格式化必须通过此类，禁止硬编码格式
final class LocaleFormatter {
  LocaleFormatter._();

  /// 格式化日期时间（根据当前语言环境）
  static String formatDateTime(BuildContext context, DateTime dateTime, {bool showTime = true}) {
    final locale = Localizations.localeOf(context).languageCode;
    if (showTime) {
      return DateFormat.yMd(locale).add_Hm().format(dateTime);
    }
    return DateFormat.yMd(locale).format(dateTime);
  }

  /// 格式化相对时间（聊天场景常用）
  /// 
  /// 规则：
  /// - 1分钟内：显示具体时间 HH:mm
  /// - 1小时内：显示 X分钟前（英文：Xm ago）
  /// - 今天：显示今天 HH:mm
  /// - 昨天：显示昨天 HH:mm
  /// - 7天内：显示周几 HH:mm
  /// - 超过7天：显示 yyyy-M-d
  static String formatRelativeTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDiff = today.difference(target).inDays;

    if (diff.inMinutes < 1) return DateFormat.Hm(locale).format(dateTime);
    if (diff.inHours < 1) {
      return locale == 'zh' ? '${diff.inMinutes}分钟前' : '${diff.inMinutes}m ago';
    }
    if (daysDiff == 0) return l10n.chatTimeToday(time: DateFormat.Hm(locale).format(dateTime));
    if (daysDiff == 1) return l10n.chatTimeYesterday(time: DateFormat.Hm(locale).format(dateTime));
    if (daysDiff < 7) {
      final weekday = DateFormat.E(locale).format(dateTime);
      return l10n.chatPresenceWeekdayActiveAt(weekday: weekday, time: DateFormat.Hm(locale).format(dateTime));
    }
    return DateFormat.yMd(locale).format(dateTime);
  }

  /// 格式化整数（根据语言环境添加千分位）
  static String formatNumber(BuildContext context, int number) {
    final locale = Localizations.localeOf(context).languageCode;
    return NumberFormat.decimalPattern(locale).format(number);
  }

  /// 格式化文件大小
  static String formatFileSize(BuildContext context, int bytes) {
    final locale = Localizations.localeOf(context).languageCode;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${NumberFormat('#,##0.0', locale).format(bytes / 1024)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${NumberFormat('#,##0.0', locale).format(bytes / (1024 * 1024))} MB';
    }
    return '${NumberFormat('#,##0.00', locale).format(bytes / (1024 * 1024 * 1024))} GB';
  }
}
```

---

### Phase 3: 可扩展语言支持（中优先级）

#### 3.1 新增日文/韩文支持

**l10n.yaml 配置更新：**

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/l10n/generated
nullable-getter: false
preferred-supported-locales:
  - zh
  - en
  - ja
  - ko
synthetic-package: false
```

**新增文件：**

```
lib/l10n/arb/
├── app_en.arb      # 英文（模板语言，必须存在）
├── app_zh.arb      # 简体中文
├── app_ja.arb      # 日文（新增）
└── app_ko.arb      # 韩文（新增）
```

**语言模式枚举更新：**

```dart
// lib/app/l10n/app_locale_controller.dart
enum AppLanguageMode { system, zhCn, en, ja, ko }

// AppLocaleController._resolveLocale 更新
static Locale _resolveLocale(AppLanguageMode mode) {
  return switch (mode) {
    AppLanguageMode.system => _sanitizeLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    ),
    AppLanguageMode.zhCn => const Locale('zh', 'CN'),
    AppLanguageMode.en => const Locale('en'),
    AppLanguageMode.ja => const Locale('ja'),
    AppLanguageMode.ko => const Locale('ko'),
  };
}
```

**后端 `ShengyuLocaleResolver` 同步更新：**

```java
// com.shengyu.framework.web.config.ShengyuLocaleResolver
private static final Locale LOCALE_ZH_CN = Locale.SIMPLIFIED_CHINESE;
private static final Locale LOCALE_EN = Locale.ENGLISH;
private static final Locale LOCALE_JA = Locale.JAPANESE;
private static final Locale LOCALE_KO = Locale.KOREAN;

private static final List<Locale> SUPPORTED_LOCALES = Arrays.asList(
    LOCALE_ZH_CN,
    LOCALE_EN,
    LOCALE_JA,
    LOCALE_KO
);

@Override
public Locale resolveLocale(HttpServletRequest request) {
    String acceptLanguage = request.getHeader("Accept-Language");
    if (acceptLanguage == null || acceptLanguage.trim().isEmpty()) {
        return getDefaultLocale();
    }
    String normalized = acceptLanguage.trim().toLowerCase(Locale.ROOT);
    if (normalized.startsWith("zh")) return LOCALE_ZH_CN;
    if (normalized.startsWith("ja")) return LOCALE_JA;
    if (normalized.startsWith("ko")) return LOCALE_KO;
    if (normalized.startsWith("en")) return LOCALE_EN;
    return getDefaultLocale();
}
```

**新增后端翻译文件：**

```
shengyu-framework/shengyu-spring-boot-starter-web/src/main/resources/
├── messages.properties         # 中文（默认）
├── messages_en.properties      # 英文
├── messages_ja.properties      # 日文（新增）
└── messages_ko.properties      # 韩文（新增）
```

#### 3.2 日/韩文特殊处理要点

| 语言 | 特殊处理 | 注意事项 |
|------|---------|---------|
| **日文** | 日期格式 `yyyy年MM月dd日` | 片假名/平假名混排注意字体 |
| **韩文** | 日期格式 `yyyy년 MM월 dd일` | 敬语/非敬语选择（企业应用建议敬语） |
| **共同** | 无复数变化 | 但需要检查所有 plural 规则 |

---

### Phase 4: WebSocket 系统消息本地渲染（中优先级）

#### 4.1 架构调整

**现状问题：**
- 后端 `ImSystemMessageI18nSupport.render()` 根据当前请求的语言渲染系统消息
- 但 WebSocket 推送是服务端主动推给客户端的，使用的是服务端当前用户的默认语言
- 用户切换语言后，历史系统消息不会自动按新语言重渲染

**改进方案：服务端推送 eventKey + params，客户端本地渲染**

```dart
// lib/core/i18n/system_message_renderer.dart
import 'package:flutter/material.dart';
import 'package:shengyu_ui_admin_im/l10n/generated/app_localizations.dart';

/// 系统消息本地渲染器
/// 
/// 当收到 WebSocket 推送的系统消息时，根据 eventKey + params 
/// 使用当前语言本地渲染
final class SystemMessageRenderer {
  SystemMessageRenderer._();

  static String render(BuildContext context, {
    required String eventKey,
    Map<String, String> params = const {},
    String? fallbackContent,
  }) {
    final l10n = AppLocalizations.of(context)!;
    
    switch (eventKey) {
      case 'im.system.group_owner_transferred':
        return l10n.chatGroupOwnerTransferredTo(
          name: params['newOwnerName'] ?? '',
        );
      case 'im.system.group_member_added_one':
        return l10n.chatGroupMemberAddedOne(
          firstName: params['firstName'] ?? '',
        );
      case 'im.system.group_member_added_two':
        return l10n.chatGroupMemberAddedTwo(
          firstName: params['firstName'] ?? '',
          secondName: params['secondName'] ?? '',
        );
      case 'im.system.group_member_added_many':
        return l10n.chatGroupMemberAddedMany(
          firstName: params['firstName'] ?? '',
          secondName: params['secondName'] ?? '',
          otherCount: params['otherCount'] ?? '0',
        );
      case 'im.system.group_member_removed':
        return l10n.chatGroupMemberRemovedNamed(
          name: params['memberName'] ?? '',
        );
      case 'im.system.group_member_muted':
        return l10n.chatGroupMemberMutedNamed(
          name: params['memberName'] ?? '',
        );
      case 'im.system.group_member_unmuted':
        return l10n.chatGroupMemberUnmutedNamed(
          name: params['memberName'] ?? '',
        );
      case 'im.recall.self':
        return l10n.chatRecallSelfTip;
      case 'im.recall.other':
        return l10n.chatRecallOtherTip(
          operatorName: params['operatorName'] ?? '',
        );
      case 'im.system.group_notice_updated':
        return l10n.chatGroupNoticeUpdated;
      default:
        return fallbackContent ?? '';
    }
  }
}
```

#### 4.2 后端消息格式约定

**WebSocket 推送的消息体结构：**

```json
{
  "header": {
    "messageType": "SYSTEM",
    "messageId": "msg_123",
    "timestamp": 1699999999999
  },
  "body": {
    "type": "GROUP_MEMBER_ADDED",
    "content": "张三加入了群聊",
    "extra": {
      "i18n": {
        "version": 1,
        "eventKey": "im.system.group_member_added_one",
        "params": {
          "firstName": "张三"
        }
      }
    }
  }
}
```

**客户端渲染逻辑：**

```dart
// 解析系统消息
String renderSystemMessage(BuildContext context, SystemMessage message) {
  final i18nData = message.extra?.i18n;
  if (i18nData != null) {
    return SystemMessageRenderer.render(
      context,
      eventKey: i18nData.eventKey,
      params: i18nData.params,
      fallbackContent: message.content,
    );
  }
  return message.content;
}
```

---

### Phase 5: 翻译质量保障（中优先级）

#### 5.1 翻译完整性校验脚本

```bash
#!/bin/bash
# scripts/check_i18n.sh
# 检查 ARB 文件翻译完整性

EN_FILE="lib/l10n/arb/app_en.arb"
ZH_FILE="lib/l10n/arb/app_zh.arb"

# 提取英文 key（排除 @@ 开头的元数据 key）
en_keys=$(grep -oP '"\K[^"@]+' "$EN_FILE" | grep -v '^@' | sort)
zh_keys=$(grep -oP '"\K[^"@]+' "$ZH_FILE" | grep -v '^@' | sort)

# 检查缺失翻译
missing=$(comm -23 <(echo "$en_keys") <(echo "$zh_keys"))
if [ -n "$missing" ]; then
  echo "❌ 中文翻译缺失以下 key:"
  echo "$missing"
  exit 1
fi

# 检查多余 key（中文有但英文没有）
extra=$(comm -13 <(echo "$en_keys") <(echo "$zh_keys"))
if [ -n "$extra" ]; then
  echo "⚠️  英文缺少以下 key（可能是新增翻译）:"
  echo "$extra"
fi

echo "✅ 翻译完整性检查通过"
exit 0
```

#### 5.2 Pre-commit Hook 集成

```bash
#!/bin/bash
# .husky/pre-commit
# 提交前检查翻译文件完整性

echo "🔍 Checking i18n files..."

# 检查是否有 ARB 文件变更
arb_changed=$(git diff --cached --name-only | grep -c '\.arb$' || true)

if [ "$arb_changed" -gt 0 ]; then
  echo "📝 ARB files changed, running i18n check..."
  bash scripts/check_i18n.sh
  if [ $? -ne 0 ]; then
    echo "❌ i18n check failed. Please fix missing translations before committing."
    exit 1
  fi
  
  echo "🔧 Running flutter gen-l10n..."
  flutter gen-l10n
  if [ $? -ne 0 ]; then
    echo "❌ flutter gen-l10n failed. Please check ARB file syntax."
    exit 1
  fi
  
  # 自动添加生成的文件
  git add lib/l10n/generated/
fi
```

#### 5.3 CI/CD 集成

```yaml
# .github/workflows/i18n_check.yml
name: i18n Integrity Check

on:
  pull_request:
    paths:
      - '**/*.arb'
  push:
    branches: [main, develop]
    paths:
      - '**/*.arb'

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Check translation integrity
        run: bash scripts/check_i18n.sh
      
      - name: Run flutter gen-l10n
        run: flutter gen-l10n
      
      - name: Verify generated files
        run: dart analyze lib/l10n/generated/
```

---

## 3. 实施步骤

### Step 1: ARB 文件命名空间重构（2天）
- [ ] 制定 `{module}.{feature}.{key}` 命名规范
- [ ] 按模块添加注释分区（保持单文件，逻辑拆分）
- [ ] 添加占位符类型声明（`"type": "int"` 等）
- [ ] 补全所有 `@keyName` 元数据
- [ ] 全局更新所有翻译调用点

### Step 2: 复数/选择语法改造（1天）
- [ ] 识别所有需要 plural 的 key
- [ ] 改造为 ICU MessageFormat plural/select 语法
- [ ] 验证中英文渲染效果

### Step 3: 日期/数字格式化工具（1天）
- [ ] 创建 `LocaleFormatter` 工具类
- [ ] 全局替换硬编码日期/数字格式
- [ ] 验证各语言显示效果

### Step 4: WebSocket 系统消息本地渲染（1天）
- [ ] 创建 `SystemMessageRenderer`
- [ ] 对接 WebSocket 消息体 i18n 字段
- [ ] 验证历史消息按当前语言重渲染

### Step 5: 翻译质量保障（1天）
- [ ] 编写翻译完整性校验脚本
- [ ] 集成到 pre-commit hook
- [ ] 配置 CI/CD 检查

### Step 6: 日文/韩文支持预留（0.5天，按需实施）
- [ ] 更新 `l10n.yaml` 配置
- [ ] 更新 `AppLanguageMode` 枚举
- [ ] 更新 `ShengyuLocaleResolver` 支持 ja/ko
- [ ] 创建空的 `app_ja.arb` / `app_ko.arb` 模板

---

## 4. 架构设计要点

### 4.1 纯设备级语言策略

```
┌─────────────────────────────────────────────────────────────┐
│                        用户                                  │
│                                                              │
│    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │
│    │  手机 App    │    │  Web 管理端  │    │  电脑客户端  │   │
│    │  zh-CN       │    │  en          │    │  ja          │   │
│    │  (本地存储)   │    │  (本地存储)   │    │  (本地存储)   │   │
│    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘   │
│           │                  │                  │           │
│           │ Accept-Language   │ Accept-Language   │           │
│           │ zh-CN            │ en               │           │
│           ▼                  ▼                  ▼           │
│    ┌─────────────────────────────────────────────────────┐  │
│    │                  后端 API                            │  │
│    │  ShengyuLocaleResolver → LocaleContextHolder         │  │
│    │  MessageSource 根据 Accept-Language 返回对应语言     │  │
│    │  （不存储用户语言偏好）                               │  │
│    └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 性能要点

1. **ARB 文件大小控制：** 单文件不超过 800 行，超过时考虑代码生成工具
2. **避免重复调用：** 在 build 方法顶部统一获取 `AppLocalizations.of(context)!`
3. **DateFormat 实例复用：** 使用缓存避免重复创建格式化器
4. **HTTP 拦截器轻量：** `LocaleInterceptor` 仅读取本地状态，无 IO 操作

### 4.3 企业级规范

1. **语言切换无感：** 通过 Riverpod 响应式更新 locale，不重启 App
2. **翻译缺失回退：** 翻译为空时返回模板语言（英文），不崩溃
3. **首次启动：** 默认跟随系统语言，不强制要求用户选择
4. **AOT 编译优化：** 发布时 tree-shaking 去除未使用的 locale

### 4.4 后端联动规范

1. **Accept-Language 一致性：** Flutter locale 与 HTTP header 值必须同步
2. **WebSocket 消息必须携带 i18n 元数据：** eventKey + params 模式
3. **错误码翻译走 MessageSource：** 枚举中不硬编码翻译文本
4. **占位符统一：** 后端 IM 系统消息统一使用 `{name}` 命名占位符

### 4.5 扩展性设计

**新增语言只需 4 步：**

1. 创建 `app_xx.arb` 翻译文件
2. 更新 `AppLanguageMode` 枚举
3. 更新 `ShengyuLocaleResolver` 解析规则
4. 运行 `flutter gen-l10n` 重新生成

---

## 5. 参考资源

- [Flutter 官方国际化文档](https://docs.flutter.dev/ui/internationalization/intro)
- [ICU MessageFormat 规范](https://unicode-org.github.io/icu/userguide/format_parse/messages/)
- [intl 包文档](https://pub.dev/packages/intl)
- [Spring MessageSource 国际化](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/context/MessageSource.html)
