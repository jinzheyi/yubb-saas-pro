# IM Flutter 通用业务工具与基础规则 v1.0

> 文档日期：2026-04-29  
> 文档定位：跨页面复用的业务工具规则、格式化规则、导航态规则、字典与头像基础约束  

---

## 1. 目标

把跨页面、跨模块都会用到的基础业务规则统一冻结，避免后续 AI 在不同页面各写一套。

本文件不关心旧实现细节，只定义 Flutter 目标态该如何做。

---

## 2. Auth 基础规则

### 2.1 Token 存储

- `accessToken`
- `refreshToken`

必须分离存储。

要求：

1. 敏感凭证进入安全存储层。
2. 内存态和持久态分离管理。
3. 清理登录态时必须同时清除：
   - token
   - 用户快照
   - 与用户强绑定的短期缓存

### 2.2 登录态判断

客户端登录态不能只靠“本地有 token”做最终判断。

冻结规则：

1. 本地 token 仅表示“可尝试恢复会话”。
2. App 启动后必须经过 bootstrap 校验：
   - access token 可用
   - refresh token 可续期
   - permission info 可拉取
3. 任何 401 刷新失败都必须进入失效态并回登录。

### 2.3 单飞刷新

HTTP 401 刷新必须单飞。

要求：

1. 同一时间只允许一个 refresh 请求。
2. 等待中的请求进入重放队列。
3. refresh 成功后统一重放。
4. refresh 失败后统一失败，不允许各自再发 refresh。

### 2.4 HTTP -> WebSocket 联动

refresh 成功后必须触发同连接 `reauth`，而不是被动等待断线重连。

---

## 3. 时间与时间线规则

### 3.1 绝对时间格式化

基础时间格式器必须支持：

- `YYYY-MM-DD`
- `HH:mm:ss`
- `YYYY-MM-DD HH:mm:ss`

但页面层不直接拼接时间格式字符串，应通过统一 formatter facade 输出。

### 3.2 相对时间格式化

会话列表、搜索结果、系统列表统一使用相对时间语义：

1. 刚刚
2. 分钟前
3. 今天 `HH:mm`
4. 昨天 `昨天 HH:mm`
5. 一周内 `周X HH:mm`
6. 年内 `M-D HH:mm`
7. 跨年 `YYYY-M-D HH:mm`

必须走国际化文案，不允许组件内硬编码。

### 3.3 聊天页时间分隔规则

聊天页消息时间分隔采用：

- 首条消息显示时间
- 与上一条消息间隔超过 5 分钟显示时间
- 否则不显示

这是时间线规则，不属于纯 UI 决策，必须沉到统一 helper / policy。

### 3.4 时间输入约束

所有消息时间、会话时间、服务端时间统一先标准化为毫秒时间戳再进入 formatter。

禁止：

1. 页面直接处理秒级 / 毫秒级混杂时间戳
2. 页面直接解析多种后端时间字符串

---

## 4. 字典规则

### 4.1 字典定位

字典属于基础业务数据，不属于页面私有状态。

建议建立：

- `DictRepository`
- `DictCacheStore`
- `DictFacade`

### 4.2 字典缓存规则

要求：

1. 按 `dictType` 缓存
2. 支持全量预热和按需读取
3. 支持本地持久化
4. 支持版本或过期控制

### 4.3 字典输出规则

页面层只消费统一方法：

- `getOptions(dictType)`
- `getLabel(dictType, value)`
- `getTagStyle(dictType, value)`

禁止页面自行：

- 手动遍历数组找 label
- 自己解释 `colorType/cssClass`
- 把字典值类型混着比较

### 4.4 值类型规则

字典原始值统一按字符串比较语义处理，再在 facade 层做：

- string
- int
- bool

的安全转换。

---

## 5. 头像规则

### 5.1 头像文本

头像占位文本统一规则：

1. 中文名优先取前 2 个字
2. 英文名优先取首字母或双首字母
3. 空名称返回 `?`

### 5.2 头像背景色

默认头像背景色不能随机，必须稳定可复现。

冻结规则：

1. 基于业务 ID 稳定映射
2. 用户、群、其他业务对象允许不同 salt
3. 色值应偏浅、可读、品牌兼容

### 5.3 页面层职责

页面只消费：

- `avatarUrl`
- `avatarText`
- `avatarBgColor`

不自己做 hash、取色、姓名裁剪。

---

## 6. 导航参数与临时态规则

### 6.1 轻参数与重参数分离

路由 query/path 中只放轻量参数：

- `chatId`
- `messageId`
- `fileId`
- `userId`
- `groupId`
- `mode`

复杂对象、超长对象、临时跳转上下文不直接放 URL。

### 6.2 临时导航态

对复杂跳转参数采用短期 `nav state` 机制：

1. 先落本地短期缓存
2. 生成 `stateId`
3. 路由只传 `stateId`
4. 目标页消费后立即失效

适用场景：

- 合并转发预览
- 搜索高级筛选
- 大对象跳转
- 多步选择器回传

### 6.3 TTL 规则

导航临时态必须具备：

- TTL
- 上限数量
- 自动清理
- 单次消费

---

## 7. `fileId` 导航规则

文件、媒体、预览类跳转参数优先只传：

- `fileId`
- `name`

`url` 只允许作为权宜兜底，不是主导航参数。

---

## 8. 文件基础工具规则

### 8.1 文件能力识别

统一建立文件能力识别器，输出：

- `isImage`
- `isVideo`
- `isAudio`
- `isDocument`
- `extension`
- `mimeType`
- `iconKey`

页面不自行根据后缀写判断分支。

### 8.2 文件大小格式化

统一输出格式：

- `B`
- `KB`
- `MB`
- `GB`
- `TB`

保留固定格式，不允许不同页面各自四舍五入规则不同。

---

## 9. Flutter 建议落点

```text
core/
  auth/
    auth_session_store.dart
    auth_bootstrap_coordinator.dart
  formatting/
    app_time_formatter.dart
    chat_time_separator_policy.dart
  dict/
    dict_facade.dart
    dict_repository.dart
    dict_cache_store.dart
  avatar/
    avatar_presenter.dart
  navigation/
    nav_state_store.dart
    route_arg_codec.dart
  file/
    file_type_resolver.dart
```

---

## 10. 与现有专题的关系

本文件提供的是通用基础规则，专题文档以本文件为下位补充。

重点受影响专题：

- 登录与鉴权
- WebSocket / reauth
- 聊天页时间线
- 会话列表时间展示
- 文件上传与文件预览
- 国际化
- 页面路由与复杂跳转

---

## 11. 验收标准

1. token 刷新、请求重放、WS reauth 由统一基础设施承接
2. 聊天页与会话列表的时间文案规则一致
3. 字典不在页面层散落二次解释逻辑
4. 默认头像文本和颜色在多端一致
5. 复杂页面跳转不依赖超长 URL 传参

---

## 12. 模板承接

本文件是规则总纲。

若进入代码生成阶段，`dict / nav-state / avatar / time formatter` 的基础代码骨架以：

- `IM-Flutter核心基础能力代码模板-v1.0.md`

为准。
