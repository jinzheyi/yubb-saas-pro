# Flutter IM 企业级 HTTP 缓存与网络优化方案（对标飞书/企业微信）

> 版本：v1.1
> 创建时间：2026-06-22
> 最后更新：2026-06-22
> 目标：HTTP 接口网络请求达到飞书/企业微信原生级用户体验
> 范围：Flutter 客户端 HTTP 层 + 本地缓存层 + 数据同步层
> 基于：`im-enterprise-architecture-optimization-v2.md` 的延续深化

---

## 〇、当前实际状态总结（基于 2026-06-22 代码扫描）

> **重要说明**：本节基于实际代码扫描结果，明确区分已完成和待完成的优化项，避免重复工作。

### ✅ 已完成的企业级优化（无需重复）

| 功能 | 实现文件 | 实现状态 | 说明 |
|------|---------|---------|------|
| **草稿消息持久化** | `reedit_hint_local_store.dart` | ✅ 完整实现 | SharedPreferences 存储，支持 deadlineTs |
| **已读回执内存缓存** | `read_receipt_summary_store.dart` | ✅ 完整实现 | 10min TTL, 200条上限，批量预取，防抖 |
| **增量同步逻辑** | `conversation_repository_impl.dart` | ✅ 完整实现 | cursorVersion 增量同步，hasMore 分页 |
| **消息断线补偿接口** | `message_remote_data_source.dart` | ✅ 完整实现 | fetchMessagesAfterSequence |
| **批量标记已读** | `message_repository_impl.dart` | ✅ 完整实现 | markConversationRead 批量接口 |
| **语音播放状态查询** | `message_repository_impl.dart` | ✅ 完整实现 | getVoicePlayedStatus 批量接口 |
| **弱网检测与重试** | `weak_network_interceptor.dart` | ✅ 完整实现 | 网络监控 + 弱网重试 2 次 |
| **Token 自动刷新** | `auth_interceptor.dart` | ✅ 完整实现 | 401 自动刷新 + RefreshTokenCoordinator |
| **网络状态监听** | `network_monitor_service.dart` | ✅ 完整实现 | connectivity_plus + 30s 探测 |
| **消息发送队列** | `message_cache_queue.dart` | ✅ 基础实现 | 内存队列 + 指数退避重试（需持久化） |

### 🔴 待完成的核心优化（P0 优先级）

| 功能 | 当前状态 | 需要改造 | 预期收益 |
|------|---------|---------|---------|
| **Repository 本地优先** | 纯远程调用 | MessageRepositoryImpl + ConversationRepositoryImpl 添加 LocalDataSource | 聊天页秒开（<100ms） |
| **cursorVersion 持久化** | 仅在内存 state | 持久化到 SharedPreferences | App 重启后无需全量拉取会话 |
| **待发消息队列持久化** | 内存 Queue | MessageCacheQueue 写入 Drift | App 被杀后消息不丢失 |
| **HTTP 响应缓存** | 无缓存 | 添加 HttpCacheInterceptor | 减少 60-80% HTTP 流量 |
| **请求去重** | 无去重 | 添加 RequestDedupInterceptor | 避免快速切换时的重复请求 |
| **请求取消** | 无取消 | 添加 RequestCancellationManager | 页面销毁后取消未完成请求 |

### 🟡 待完成的增强优化（P1/P2 优先级）

| 功能 | 当前状态 | 需要改造 | 优先级 |
|------|---------|---------|--------|
| **已读回执持久化** | 内存缓存 | 持久化到 Drift | P1 |
| **联系人/群组本地缓存** | 无本地缓存 | 添加 Users/Groups/GroupMembers 表 | P1 |
| **消息全文检索** | 纯服务端搜索 | 添加 FTS5 虚拟表 | P1 |
| **收藏本地缓存** | 纯远程 | 添加 Favorites 表 | P1 |
| **消息预加载服务** | 半成品框架 | 完善 MessagePreloadService | P1 |
| **表情贴纸缓存** | 纯远程 | 添加 Stickers 表 | P2 |
| **文件断点续传** | 无断点续传 | 添加 UploadTasks 表 | P2 |
| **文件预览缓存** | 无本地缓存 | 添加 FilePreviewCacheManager | P2 |
| **通话记录缓存** | 纯远程 | 添加 CallRecords 表 | P2 |
| **语音播放状态缓存** | 纯远程 | SharedPreferences 缓存已播放 ID | P2 |
| **缓存容量管理** | 无限制 | 添加 CacheCapacityManager | P2 |

### 📊 后端接口支持情况（实际扫描结果）

| 前端优化需求 | 后端接口 | 支持状态 | 说明 |
|------------|---------|---------|------|
| 会话增量同步 | `GET /system/im/conversation/sync` | ✅ 已支持 | 返回 cursorVersion + items + hasMore |
| 消息断线补偿 | `GET /system/im/message/pull` | ✅ 已支持 | 支持按 sequence 拉取 |
| 批量标记已读 | `PUT /system/im/message/mark-read` | ✅ 已支持 | 支持 messageIds 批量 |
| 语音播放状态 | `GET /system/im/message/voice-played-status` | ✅ 已支持 | 返回已播放的 messageId 列表 |
| 已读回执批量 | `GET /system/im/read-receipt/summary/batch` | ✅ 已支持 | 一次查询多条消息摘要 |
| 搜索限流 | 多个搜索接口 | ✅ 已支持 | 429 + Retry-After |
| ETag/Cache-Control | 所有接口 | ❌ 未设置 | 仅图片接口有缓存头 |
| 304 Not Modified | 所有接口 | ❌ 未支持 | 后端未检查 If-None-Match |
| 消息预加载标记 | `/message/window` | ❌ 未支持 | 无 isPreload 参数 |
| 文件分片上传 | `/group/file/upload` | ❌ 未支持 | 仅支持单文件上传 |

---

## 一、现状审查（源码级确认）

### 1.1 HTTP 网络层现状

| 组件 | 文件 | 现状 | 评价 |
|------|------|------|------|
| **Dio 客户端** | [dio_client.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/dio_client.dart) | 单例工厂 + Riverpod Provider | ✅ 合理 |
| **连接池** | [dio_adapter_config_io.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/dio_adapter_config_io.dart) | maxConnectionsPerHost=10, idleTimeout=30s | ✅ 合理 |
| **超时配置** | [app_config.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/app/config/app_config.dart#L82-L83) | connectTimeout=15s, receiveTimeout=15s | 🟡 偏长 |
| **认证拦截器** | [auth_interceptor.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/interceptors/auth_interceptor.dart) | Token 注入 + 401 自动刷新 + RefreshTokenCoordinator | ✅ 优秀 |
| **租户拦截器** | [tenant_interceptor.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/interceptors/tenant_interceptor.dart) | tenant-id 注入 | ✅ |
| **语言拦截器** | [locale_interceptor.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/interceptors/locale_interceptor.dart) | Accept-Language 注入 | ✅ |
| **请求ID拦截器** | [request_id_interceptor.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/interceptors/request_id_interceptor.dart) | X-Request-Id 注入 | ✅ |
| **弱网拦截器** | [weak_network_interceptor.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/weak_network_interceptor.dart) | 无网友好提示 + 弱网重试 2 次 | ✅ 基础完善 |
| **上传专用Dio** | [upload_dio_client.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/upload_dio_client.dart) | 独立实例 + 5 分钟超时 | ✅ 合理 |
| **网络监控** | [network_monitor_service.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/network/network_monitor_service.dart) | connectivity_plus + 30s 探测 + 防抖 | ✅ 完善 |

### 1.2 数据层/缓存层现状

| 组件 | 文件 | 现状 | 评价 |
|------|------|------|------|
| **本地数据库** | [im_database.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/im_database.dart) | Drift (SQLite) 单例，2 张表 | 🟡 表太少 |
| **消息表** | [messages_table.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/tables/messages_table.dart) | 完整字段 + 2 个索引 | ✅ 结构合理 |
| **会话表** | [conversations_table.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/tables/conversations_table.dart) | 基础字段 | 🟡 缺少同步游标字段 |
| **消息DAO** | [message_dao.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/daos/message_dao.dart) | CRUD + watch 流 | ✅ 基本完善 |
| **会话DAO** | [conversation_dao.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/daos/conversation_dao.dart) | CRUD + watch 流 | ✅ 基本完善 |
| **消息Repository** | [message_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/infrastructure/repositories/message_repository_impl.dart) | **纯远程调用，无本地缓存层** | 🔴 核心缺失 |
| **会话Repository** | [conversation_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/conversation/infrastructure/repositories/conversation_repository_impl.dart) | **纯远程调用，无本地缓存层** | 🔴 核心缺失 |
| **消息缓存队列** | [message_cache_queue.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/data/message_cache_queue.dart) | 内存 Queue，重启丢失 | 🔴 需持久化 |
| **图片缓存** | [im_cache_manager.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/cache/im_cache_manager.dart) | flutter_cache_manager 100 个/30 天 | 🟡 基础可用 |
| **音频缓存** | 同上 | flutter_cache_manager 50 个/30 天 | 🟡 基础可用 |
| **聊天窗口加载** | [load_chat_window_use_case.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/application/usecases/load_chat_window_use_case.dart) | 有预加载框架但**未实际使用本地数据** | 🔴 半成品 |
| **历史消息加载** | [load_older_messages_use_case.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/application/usecases/load_older_messages_use_case.dart) | 纯远程，无本地优先 | 🔴 核心缺失 |
| **会话列表加载** | [load_conversation_list_use_case.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/conversation/application/usecases/load_conversation_list_use_case.dart) | 纯远程，无本地优先 | 🔴 核心缺失 |

### 1.3 核心问题总结

```
当前数据流（每次都是网络优先）：

  UI → UseCase → Repository → RemoteDataSource → HTTP → 解析 → 返回 UI
                                     ↓
                              （Drift 数据库存在但未被 Repository 使用）

飞书/企微数据流（本地优先 + 增量同步）：

  UI → UseCase → Repository → 本地 Drift（秒级响应）
                    ↓                    ↑
              RemoteDataSource → HTTP → 写回 Drift（后台静默更新）
```

**🔴 P0 级缺失项：**

| 序号 | 缺失能力 | 影响 | 对标 |
|------|----------|------|------|
| 1 | Repository 无本地缓存层 | 每次打开聊天都等网络，无法秒开 | 飞书 L1/L2 缓存 |
| 2 | HTTP 无响应缓存 | GET 请求每次都完整传输 | ETag/304 |
| 3 | 无请求去重 | 快速切换聊天可能重复请求同一接口 | 飞书请求合并 |
| 4 | 无请求取消 | 页面销毁后请求仍在进行，浪费资源 | CancelToken |
| 5 | 待发消息队列无持久化 | App 被杀后待发消息丢失 | 企微本地队列 |
| 6 | 联系人/群组无本地缓存 | 每次展示都需网络或从消息提取 | 飞书 L2 缓存 |
| 7 | 消息全文检索无 FTS5 | 搜索需走服务端，无法离线搜索 | 飞书本地搜索 |
| 8 | 无缓存容量管理 | 长期使用数据库膨胀 | 飞书弹性策略 |

---

## 二、企业级 HTTP 缓存优化方案

### 2.1 HTTP 响应缓存拦截器（ETag / Cache-Control）

**对标来源：** 飞书 API 全面支持 ETag 条件请求；企业微信 iPad 协议使用 seq 增量同步。

**原理：**
```
首次请求：
  GET /api/im/conversation/list
  → 200 OK + ETag: "v3-a8f5e6c2" + Cache-Control: max-age=60
  → 响应体写入本地 Drift 缓存

后续请求（60s 内）：
  GET /api/im/conversation/list
  → 直接返回本地缓存，不发网络请求（强缓存命中）

60s 后请求：
  GET /api/im/conversation/list
  If-None-Match: "v3-a8f5e6c2"
  → 304 Not Modified（空 body，节省 80-95% 带宽）
  → 或 200 OK + 新数据 + 新 ETag
```

**实现方案：**

```dart
/// lib/core/network/interceptors/http_cache_interceptor.dart
///
/// HTTP 响应缓存拦截器
/// 对标飞书/企业微信：GET 请求自动缓存 + ETag 条件请求 + 离线回退
class HttpCacheInterceptor extends Interceptor {
  HttpCacheInterceptor(this._cacheStore);

  final HttpCacheStore _cacheStore;

  /// 缓存白名单：只有这些 GET 接口启用缓存
  /// 其他接口（如发送消息、标记已读）不缓存
  static const Set<String> _cacheablePaths = {
    '/im/conversation/list',
    '/im/conversation/sync',
    '/im/message/window',
    '/im/message/pull',
    '/im/group/member/list',
    '/system/user/get',
    '/system/user/profile',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 仅对 GET 请求 + 白名单路径启用缓存
    if (options.method != 'GET' || !_isCacheable(options.path)) {
      handler.next(options);
      return;
    }

    // 检查本地缓存
    final cached = _cacheStore.get(options.uri.toString());
    if (cached == null) {
      handler.next(options);
      return;
    }

    // 强缓存命中（未过期）
    if (!cached.isExpired) {
      // 构造缓存响应，直接返回，不发网络请求
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: cached.data,
        extra: {'fromCache': true, 'cacheTime': cached.cachedAt},
      ));
      return;
    }

    // 缓存过期但有 ETag → 条件请求
    if (cached.etag != null) {
      options.headers['If-None-Match'] = cached.etag;
    }
    if (cached.lastModified != null) {
      options.headers['If-Modified-Since'] = cached.lastModified;
    }

    // 标记需要检查 304
    options.extra['checkNotModified'] = true;
    options.extra['cachedData'] = cached.data;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;

    // 304 Not Modified → 返回缓存数据
    if (response.statusCode == 304 && options.extra['checkNotModified'] == true) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: options.extra['cachedData'],
        extra: {'fromCache': true, 'notModified': true},
      ));
      return;
    }

    // 正常响应 → 写入缓存
    if (response.statusCode == 200 && options.method == 'GET') {
      _saveToCache(options, response);
    }

    handler.next(response);
  }

  void _saveToCache(RequestOptions options, Response response) {
    final cacheControl = response.headers['cache-control']?.firstOrNull;
    final etag = response.headers['etag']?.firstOrNull;
    final lastModified = response.headers['last-modified']?.firstOrNull;
    final maxAge = _parseMaxAge(cacheControl);

    _cacheStore.put(
      url: options.uri.toString(),
      data: response.data,
      etag: etag,
      lastModified: lastModified,
      maxAge: maxAge ?? const Duration(seconds: 60),
    );
  }

  bool _isCacheable(String path) {
    return _cacheablePaths.any((p) => path.contains(p));
  }

  int? _parseMaxAge(String? cacheControl) {
    if (cacheControl == null) return null;
    final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }
}
```

**缓存存储层（基于 Drift）：**

```dart
/// lib/infrastructure/database/tables/http_cache_table.dart
///
/// HTTP 响应缓存表
class HttpCache extends Table {
  TextColumn get url => text()();                    // 请求 URL（含参数）
  TextColumn get data => text()();                   // 响应体 JSON 字符串
  TextColumn get etag => text().nullable()();        // ETag 值
  TextColumn get lastModified => text().nullable()(); // Last-Modified 值
  DateTimeColumn get cachedAt => dateTime()();       // 缓存时间
  DateTimeColumn get expiresAt => dateTime()();      // 过期时间
  IntColumn get size => integer()();                 // 缓存大小（字节）

  @override
  Set<Column> get primaryKey => {url};
}
```

**各接口的推荐缓存策略：**

| 接口 | Cache-Control | ETag | 说明 |
|------|---------------|------|------|
| `GET /im/conversation/list` | `max-age=30` | ✅ | 会话列表，30s 强缓存 |
| `GET /im/conversation/sync` | `no-cache` | ✅ | 增量同步，每次条件请求 |
| `GET /im/message/window` | `max-age=10` | ✅ | 消息窗口，10s 强缓存 |
| `GET /im/message/pull` | `no-cache` | ✅ | 消息拉取，条件请求 |
| `GET /im/group/member/list` | `max-age=300` | ✅ | 群成员，5 分钟强缓存 |
| `GET /system/user/profile` | `max-age=600` | ✅ | 用户资料，10 分钟强缓存 |
| `POST /im/message/send` | `no-store` | ❌ | 发送消息，不缓存 |
| `PUT /im/message/mark-read` | `no-store` | ❌ | 标记已读，不缓存 |

---

### 2.2 请求去重拦截器

**问题：** 用户快速切换聊天窗口时，同一会话的 `getMessageWindow` 可能被并发调用多次。

**对标：** 飞书客户端对相同参数的 GET 请求进行合并（in-flight deduplication）。

```dart
/// lib/core/network/interceptors/request_dedup_interceptor.dart
///
/// 请求去重拦截器
/// 对相同 URL + 相同参数的 GET 请求进行合并，避免重复网络请求
class RequestDedupInterceptor extends Interceptor {
  /// 进行中的请求：url → Completer
  final Map<String, Completer<Response>> _inflightRequests = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET') {
      handler.next(options);
      return;
    }

    final key = _buildDedupKey(options);

    // 检查是否有相同的进行中请求
    final existing = _inflightRequests[key];
    if (existing != null && !existing.isCompleted) {
      // 等待已有请求完成，复用其结果
      existing.future.then(
        (response) => handler.resolve(response),
        onError: (e) => handler.reject(e as DioException),
      );
      return; // 不发新请求
    }

    // 注册新的进行中请求
    final completer = Completer<Response>();
    _inflightRequests[key] = completer;
    options.extra['_dedupKey'] = key;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _completeDedup(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _failDedup(err.requestOptions, err);
    handler.next(err);
  }

  void _completeDedup(RequestOptions options, Response response) {
    final key = options.extra['_dedupKey'] as String?;
    if (key != null) {
      _inflightRequests.remove(key)?.complete(response);
    }
  }

  void _failDedup(RequestOptions options, DioException err) {
    final key = options.extra['_dedupKey'] as String?;
    if (key != null) {
      _inflightRequests.remove(key)?.completeError(err);
    }
  }

  String _buildDedupKey(RequestOptions options) {
    final params = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final query = params.map((e) => '${e.key}=${e.value}').join('&');
    return '${options.method}:${options.path}?$query';
  }
}
```

---

### 2.3 请求取消机制（页面生命周期绑定）

**问题：** 用户进入聊天页 A → 快速返回 → 进入聊天页 B，此时 A 的消息请求仍在进行。

**对标：** 飞书/企微在页面销毁时自动取消未完成的请求。

```dart
/// lib/core/network/request_cancellation_manager.dart
///
/// 请求取消管理器
/// 将 CancelToken 与页面生命周期绑定，页面销毁时自动取消
class RequestCancellationManager {
  /// 页面级 CancelToken 注册表
  final Map<String, CancelToken> _pageTokens = {};

  /// 为页面创建 CancelToken
  CancelToken createForPage(String pageKey) {
    final token = CancelToken();
    _pageTokens[pageKey] = token;
    return token;
  }

  /// 页面销毁时取消所有关联请求
  void cancelPage(String pageKey) {
    _pageTokens.remove(pageKey)?.cancel('Page disposed');
  }

  /// 获取页面的 CancelToken（如果存在）
  CancelToken? getTokenForPage(String pageKey) {
    return _pageTokens[pageKey];
  }
}
```

**在 UseCase 中使用：**

```dart
class LoadChatWindowUseCase {
  Future<ChatWindowResult> call(
    OpenChatCommand command, {
    CancelToken? cancelToken,
  }) async {
    // 先查本地缓存（秒级响应）
    final local = await _localDataSource.getMessagesByChatId(
      command.chatId,
      limit: 50,
    );
    if (local.isNotEmpty) {
      // 先返回本地数据给 UI 渲染
      _notifyLocalResult(local);
    }

    // 再请求远程（可取消）
    return _repository.getMessageWindow(command, cancelToken: cancelToken);
  }
}
```

---

### 2.4 Repository 本地优先改造（核心改造）

**这是达到飞书级体验的最关键改造。**

**当前问题：** `MessageRepositoryImpl` 和 `ConversationRepositoryImpl` 只有 `RemoteDataSource` 依赖，Drift 数据库虽然存在但未被 Repository 使用。

**改造目标：** 实现 "Local-First + Background-Sync" 模式。

```dart
/// 改造后的 MessageRepositoryImpl
/// 本地优先 + 后台同步
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;  // 新增：本地数据源

  @override
  Future<ChatWindowResult> getMessageWindow(OpenChatCommand command) async {
    // 1. 先查本地（秒级响应）
    final localMessages = await _localDataSource.getMessagesByChatId(
      command.chatId,
      limit: 50,
    );

    // 2. 后台拉取远程数据（不阻塞返回）
    unawaited(() async {
      try {
        final remoteDto = await _remoteDataSource.fetchLatestWindow(command);
        final remoteMessages = MessageDtoMapper.toEntities(remoteDto);
        // 写入本地缓存
        await _localDataSource.insertMessages(remoteMessages);
        // 通知 UI 更新（通过 Stream）
        _messageStreamController.add(remoteMessages);
      } catch (e) {
        // 远程失败时静默，本地数据仍可用
      }
    }());

    // 3. 如果有本地数据，立即返回
    if (localMessages.isNotEmpty) {
      return MessageDtoMapper.toWindowResultFromLocal(localMessages);
    }

    // 4. 本地无数据时等待远程
    final dto = await _remoteDataSource.fetchLatestWindow(command);
    await _localDataSource.insertMessages(MessageDtoMapper.toEntities(dto));
    return MessageDtoMapper.toWindowResult(dto);
  }

  @override
  Future<ChatWindowResult> getOlderMessages({
    required String chatId,
    required String? beforeSequence,
  }) async {
    // 1. 先查本地历史
    final localOlder = await _localDataSource.getOlderMessages(
      chatId: chatId,
      beforeSequence: beforeSequence,
      limit: 50,
    );

    // 2. 后台拉取远程
    unawaited(() async {
      try {
        final dto = await _remoteDataSource.fetchOlderMessages(
          chatId: chatId,
          beforeSequence: beforeSequence,
        );
        await _localDataSource.insertMessages(MessageDtoMapper.toEntities(dto));
      } catch (_) {}
    }());

    // 3. 本地有数据先返回
    if (localOlder.isNotEmpty) {
      return MessageDtoMapper.toWindowResultFromLocal(localOlder);
    }

    // 4. 本地无数据等待远程
    final dto = await _remoteDataSource.fetchOlderMessages(
      chatId: chatId,
      beforeSequence: beforeSequence,
    );
    await _localDataSource.insertMessages(MessageDtoMapper.toEntities(dto));
    return MessageDtoMapper.toWindowResult(dto);
  }
}
```

**同理改造 ConversationRepositoryImpl：**

```dart
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ConversationRemoteDataSource _remoteDataSource;
  final ConversationLocalDataSource _localDataSource;  // 新增

  @override
  Future<List<Conversation>> getConversationList() async {
    // 1. 先查本地（秒级响应）
    final local = await _localDataSource.getAllConversations();

    // 2. 后台增量同步
    unawaited(_syncConversationsInBackground());

    // 3. 有本地数据立即返回
    if (local.isNotEmpty) {
      return local;
    }

    // 4. 首次无缓存时走远程
    final items = await _remoteDataSource.fetchConversationList();
    final entities = items.map(ConversationDtoMapper.toEntity).toList();
    await _localDataSource.upsertConversations(entities);
    return entities;
  }

  Future<void> _syncConversationsInBackground() async {
    try {
      final lastCursor = await _localDataSource.getLastCursorVersion();
      final result = await _remoteDataSource.syncConversationList(
        cursorVersion: lastCursor ?? '0',
        limit: 200,
      );
      final entities = result.items.map(ConversationDtoMapper.toEntity).toList();
      await _localDataSource.upsertConversations(entities);
      await _localDataSource.saveCursorVersion(result.cursorVersion);
    } catch (_) {}
  }
}
```

---

### 2.5 消息预加载服务（秒开核心）

**对标：** 飞书进入聊天页 0 等待，核心在于预加载。

```dart
/// lib/features/im/chat/application/services/message_preload_service.dart
///
/// 消息预加载服务
/// 在用户浏览会话列表时，提前加载活跃会话的消息到本地缓存
class MessagePreloadService {
  MessagePreloadService(this._repository, this._localDataSource);

  final MessageRepository _repository;
  final MessageLocalDataSource _localDataSource;

  /// 预加载最近 N 个活跃会话的消息
  ///
  /// 触发时机：
  /// 1. App 启动 + WebSocket 连接成功后
  /// 2. 增量同步完成后
  /// 3. 用户停留在会话列表页 500ms 后（防抖）
  Future<void> preloadActiveConversations({int topN = 5}) async {
    // 1. 获取最近活跃的 N 个会话
    final conversations = await _localDataSource.getTopConversations(topN);

    // 2. 检查哪些会话的本地消息需要刷新
    for (final conv in conversations) {
      final lastPreloadTime = await _localDataSource.getLastPreloadTime(conv.chatId);
      // 5 分钟内不重复预加载
      if (lastPreloadTime != null &&
          DateTime.now().difference(lastPreloadTime).inMinutes < 5) {
        continue;
      }

      // 3. 后台静默预加载（不阻塞 UI）
      unawaited(_preloadSingle(conv.chatId));
    }
  }

  Future<void> _preloadSingle(String chatId) async {
    try {
      final dto = await _repository.getMessageWindow(
        OpenChatCommand(chatId: chatId, isPreload: true),
      );
      await _localDataSource.recordPreloadTime(chatId);
    } catch (_) {
      // 预加载失败静默忽略
    }
  }
}
```

---

### 2.6 联系人/群组信息本地缓存

**问题：** 当前每次展示联系人头像/名称都需要从消息中提取或网络请求。

```dart
/// lib/infrastructure/database/tables/users_table.dart
///
/// 用户资料缓存表
class Users extends Table {
  TextColumn get userId => text()();
  TextColumn get nickname => text()();
  TextColumn get avatar => text().nullable()();
  TextColumn get department => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

/// lib/infrastructure/database/tables/groups_table.dart
///
/// 群组信息缓存表
class Groups extends Table {
  TextColumn get groupId => text()();
  TextColumn get groupName => text()();
  TextColumn get groupAvatar => text().nullable()();
  IntColumn get memberCount => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {groupId};
}

/// lib/infrastructure/database/tables/group_members_table.dart
///
/// 群成员关系表（用于 @ 提及自动补全）
class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get userId => text()();
  TextColumn get nickname => text()();       // 群内昵称
  IntColumn get role => integer()();         // 群角色

  @override
  String get tableName => 'group_members';

  // 复合主键
  @override
  Set<Column> get primaryKey => {groupId, userId};
}
```

**缓存策略：**
- 用户资料：7 天 TTL，后台静默刷新
- 群组信息：1 天 TTL，群消息到达时自动更新
- 群成员列表：1 小时 TTL，进入群设置页时刷新

---

### 2.7 待发消息队列持久化

**当前问题：** `MessageCacheQueue` 使用内存 `Queue`，App 被杀或重启后所有待发消息丢失。

```dart
/// lib/infrastructure/database/tables/pending_messages_table.dart
///
/// 待发送消息持久化表
class PendingMessages extends Table {
  TextColumn get id => text()();                    // UUID
  TextColumn get chatId => text()();                // 会话 ID
  TextColumn get clientMessageId => text()();       // 客户端消息 ID
  TextColumn get content => text()();               // 消息内容
  TextColumn get receiverId => text().nullable()(); // 接收者 ID
  TextColumn get groupId => text().nullable()();    // 群组 ID
  TextColumn get extraJson => text().nullable()();  // 额外参数
  IntColumn get type => integer()();                // 消息类型
  IntColumn get retryCount => integer()();          // 已重试次数
  DateTimeColumn get createdAt => dateTime()();     // 创建时间
  DateTimeColumn get lastRetryAt => dateTime().nullable()(); // 最后重试时间

  @override
  Set<Column> get primaryKey => {id};
}
```

**改造 MessageCacheQueue：**

```dart
/// 改造要点：
/// 1. enqueue() 时同步写入 Drift pending_messages 表
/// 2. App 启动时从 Drift 恢复队列
/// 3. 发送成功后从 Drift 删除
/// 4. 超过 24h 的消息定时清理
class PersistentMessageCacheQueue {
  // enqueue 时：
  Future<void> enqueue(PendingMessage message) async {
    _queue.add(message);
    // 持久化到 Drift
    await ImDatabase.instance.pendingMessageDao.insertPendingMessage(
      PendingMessageCompanion(
        id: Value(message.id),
        chatId: Value(message.chatId),
        clientMessageId: Value(message.clientMessageId),
        content: Value(message.content),
        // ...
      ),
    );
  }

  // 发送成功后：
  Future<void> _onSendSuccess(PendingMessage message) async {
    _queue.removeFirst();
    // 从 Drift 删除
    await ImDatabase.instance.pendingMessageDao.deletePendingMessage(message.id);
  }

  // App 启动恢复：
  Future<void> restoreFromDatabase() async {
    final pending = await ImDatabase.instance.pendingMessageDao.getAllPendingMessages();
    for (final msg in pending) {
      // 检查过期
      if (DateTime.now().difference(msg.createdAt) > messageExpiry) {
        await ImDatabase.instance.pendingMessageDao.deletePendingMessage(msg.id);
        continue;
      }
      _queue.add(PendingMessage.fromDbModel(msg));
    }
  }
}
```

---

### 2.8 消息全文检索（FTS5）

**对标：** 飞书支持本地消息全文搜索，无需服务端。

```dart
/// lib/infrastructure/database/tables/messages_fts_table.dart
///
/// 消息全文检索虚拟表（SQLite FTS5）
/// 支持中文分词（需配合 simple 分词器或 jieba）
class MessagesFts extends Table {
  TextColumn get messageId => text()();
  TextColumn get content => text()();       // 消息文本内容
  TextColumn get senderName => text()();    // 发送者名称
  TextColumn get chatId => text()();        // 会话 ID
  DateTimeColumn get sentAt => dateTime()(); // 发送时间

  @override
  String get tableName => 'messages_fts';

  @override
  List<String> get customConstraints => [
    'UNIQUE(messageId)',
  ];

  /// FTS5 虚拟表配置
  /// 注意：Drift 不直接支持 FTS5 虚拟表，需要通过 raw SQL 创建
  /// 在 migration onCreate 中执行：
  /// CREATE VIRTUAL TABLE messages_fts USING fts5(
  ///   content, sender_name, chat_id,
  ///   tokenize='unicode61'
  /// );
}
```

**搜索性能目标：** 10 万条消息中搜索 < 50ms。

---

### 2.9 缓存容量自动管理

**对标：** 飞书的"弹性内存策略"——内存充足时预加载，不足时释放。

```dart
/// lib/infrastructure/cache/cache_capacity_manager.dart
///
/// 缓存容量管理器
/// 定时清理 + LRU 淘汰 + 容量上限
class CacheCapacityManager {
  /// 消息存储上限
  static const int maxMessagesPerChat = 5000;     // 单会话最多 5000 条
  static const int maxTotalMessages = 100000;     // 总计最多 10 万条
  static const Duration messageRetention = Duration(days: 90); // 90 天保留

  /// HTTP 缓存上限
  static const int maxHttpCacheEntries = 500;     // 最多 500 条缓存
  static const Duration httpCacheMaxAge = Duration(hours: 24); // 24h 过期

  /// 定时清理（每天凌晨 3 点执行）
  Future<void> runDailyCleanup() async {
    final db = ImDatabase.instance;

    // 1. 清理超过 90 天的消息
    await db.messageDao.deleteOlderThan(
      DateTime.now().subtract(messageRetention),
    );

    // 2. 单会话超过 5000 条时淘汰最早的
    final chatIds = await db.messageDao.getAllChatIds();
    for (final chatId in chatIds) {
      final count = await db.messageDao.getMessageCount(chatId);
      if (count > maxMessagesPerChat) {
        await db.messageDao.deleteOldest(
          chatId: chatId,
          keepCount: maxMessagesPerChat,
        );
      }
    }

    // 3. 总消息超过 10 万条时按 LRU 淘汰
    final totalCount = await db.messageDao.getTotalMessageCount();
    if (totalCount > maxTotalMessages) {
      await db.messageDao.deleteLeastRecentlyUsed(
        keepCount: maxTotalMessages,
      );
    }

    // 4. 清理过期 HTTP 缓存
    await db.httpCacheDao.deleteExpired();

    // 5. 清理过期待发送消息
    await db.pendingMessageDao.deleteExpired(
      DateTime.now().subtract(const Duration(hours: 24)),
    );
  }
}
```

---

### 2.10 HTTP 超时优化

**当前问题：** `connectTimeout=15s, receiveTimeout=15s` 偏长。

**对标：** 飞书/企微的 HTTP 超时策略更精细。

```dart
/// 优化后的超时配置
abstract final class AppConfig {
  /// 普通接口超时（对标飞书：快速失败 + 本地缓存兜底）
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// 上传接口超时
  static const Duration uploadConnectTimeout = Duration(seconds: 10);
  static const Duration uploadReceiveTimeout = Duration(minutes: 5);

  /// 弱网环境超时延长
  /// 由 WeakNetworkInterceptor 根据 NetworkMonitorService 动态调整
  static const Duration weakNetworkConnectTimeout = Duration(seconds: 15);
  static const Duration weakNetworkReceiveTimeout = Duration(seconds: 30);
}
```

---

## 三、改造后数据流架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Flutter IM Client                               │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                        UI Layer (Riverpod)                        │   │
│  │  ConversationListPage    ChatPage    SearchPage    ContactsPage   │   │
│  └────────────────────────────┬─────────────────────────────────────┘   │
│                               │                                         │
│  ┌────────────────────────────▼─────────────────────────────────────┐   │
│  │                      UseCase Layer                                │   │
│  │  LoadConversationList  LoadChatWindow  LoadOlderMessages  ...    │   │
│  │                                                                  │   │
│  │  策略：Local-First + Background-Sync                             │   │
│  │  1. 先查本地 Drift（秒级响应）                                    │   │
│  │  2. 有本地数据立即返回 UI 渲染                                    │   │
│  │  3. 后台静默拉取远程数据                                          │   │
│  │  4. 远程数据写回本地 + 通知 UI 更新                               │   │
│  └──────────────┬─────────────────────────────────┬─────────────────┘   │
│                 │                                  │                     │
│  ┌──────────────▼──────────┐    ┌─────────────────▼─────────────────┐  │
│  │   Local DataSource      │    │     Remote DataSource              │  │
│  │   (Drift SQLite)        │    │     (HTTP via Dio)                 │  │
│  │                         │    │                                    │  │
│  │  Messages               │    │  MessageRemoteDataSource           │  │
│  │  Conversations          │    │  ConversationRemoteDataSource      │  │
│  │  Users (新增)           │    │  UserRemoteDataSource (新增)       │  │
│  │  Groups (新增)          │    │  GroupRemoteDataSource (新增)      │  │
│  │  GroupMembers (新增)    │    │                                    │  │
│  │  PendingMessages (新增) │    │                                    │  │
│  │  HttpCache (新增)       │    │                                    │  │
│  │  MessagesFts (新增)     │    │                                    │  │
│  └─────────────────────────┘    └──────────────┬──────────────────────┘  │
│                                                 │                        │
│  ┌──────────────────────────────────────────────▼────────────────────┐  │
│  │                    Dio HTTP Interceptor Chain                      │  │
│  │                                                                    │  │
│  │  ┌─────────────┐  ┌──────────┐  ┌────────────┐  ┌─────────────┐  │  │
│  │  │ Auth        │→ │ Tenant   │→ │ Locale     │→ │ RequestId   │  │  │
│  │  │ Interceptor │  │ Intercept│  │ Intercept  │  │ Intercept   │  │  │
│  │  └─────────────┘  └──────────┘  └────────────┘  └─────────────┘  │  │
│  │                                                                    │  │
│  │  ┌─────────────────┐  ┌──────────────┐  ┌──────────────────────┐  │  │
│  │  │ HttpCache       │→ │ RequestDedup │→ │ WeakNetwork          │  │  │
│  │  │ Interceptor     │  │ Interceptor  │  │ Interceptor          │  │  │
│  │  │ (新增)          │  │ (新增)       │  │ (已有)               │  │  │
│  │  └─────────────────┘  └──────────────┘  └──────────────────────┘  │  │
│  │                                                                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Cache Capacity Manager (新增)                    │  │
│  │  定时清理 + LRU 淘汰 + 容量上限 + 过期检查                         │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Message Preload Service (新增)                   │  │
│  │  预加载 Top N 活跃会话消息 + 头像预加载 + 联系人预加载             │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 四、实施计划

### Phase 1：HTTP 缓存拦截器 + 请求去重（1 周）

| 序号 | 任务 | 文件 | 优先级 |
|------|------|------|--------|
| 1 | HttpCacheInterceptor 实现 | `lib/core/network/interceptors/http_cache_interceptor.dart` | P0 |
| 2 | HttpCache 表定义 + DAO | `lib/infrastructure/database/tables/http_cache_table.dart` | P0 |
| 3 | RequestDedupInterceptor 实现 | `lib/core/network/interceptors/request_dedup_interceptor.dart` | P0 |
| 4 | 拦截器注册到 DioClientFactory | `lib/core/network/dio_client.dart` | P0 |
| 5 | 服务端 API 添加 ETag 响应头 | 后端 `AppImConversationController` 等 | P1 |

### Phase 2：Repository 本地优先改造（1.5 周）

| 序号 | 任务 | 文件 | 优先级 |
|------|------|------|--------|
| 1 | MessageLocalDataSource 实现 | `lib/features/im/chat/infrastructure/datasources/message_local_data_source.dart` | P0 |
| 2 | ConversationLocalDataSource 实现 | `lib/features/im/conversation/infrastructure/datasources/conversation_local_data_source.dart` | P0 |
| 3 | MessageRepositoryImpl 改造 | 增加 `_localDataSource` 依赖 | P0 |
| 4 | ConversationRepositoryImpl 改造 | 增加 `_localDataSource` 依赖 | P0 |
| 5 | LoadChatWindowUseCase 改造 | 使用 Repository 的本地优先能力 | P0 |
| 6 | LoadConversationListUseCase 改造 | 使用 Repository 的本地优先能力 | P0 |
| 7 | LoadOlderMessagesUseCase 改造 | 本地优先 + 远程补充 | P0 |

### Phase 3：待发消息持久化 + 请求取消（1 周）

| 序号 | 任务 | 文件 | 优先级 |
|------|------|------|--------|
| 1 | PendingMessages 表定义 + DAO | `lib/infrastructure/database/tables/pending_messages_table.dart` | P0 |
| 2 | MessageCacheQueue 持久化改造 | 增加 Drift 读写 | P0 |
| 3 | RequestCancellationManager 实现 | `lib/core/network/request_cancellation_manager.dart` | P1 |
| 4 | ChatPage 生命周期绑定 CancelToken | `lib/features/im/chat/presentation/pages/chat_page.dart` | P1 |

### Phase 4：联系人/群组缓存 + 预加载 + FTS5（1.5 周）

| 序号 | 任务 | 文件 | 优先级 |
|------|------|------|--------|
| 1 | Users/Groups/GroupMembers 表定义 | `lib/infrastructure/database/tables/` | P1 |
| 2 | UserLocalDataSource + GroupLocalDataSource | 新增 | P1 |
| 3 | MessagePreloadService 实现 | `lib/features/im/chat/application/services/` | P1 |
| 4 | MessagesFts 全文检索表 + DAO | FTS5 虚拟表 | P2 |
| 5 | 头像分级缓存优化 | 调整 ImCacheManager 配置 | P2 |

### Phase 5：缓存容量管理 + 超时优化（0.5 周）

| 序号 | 任务 | 文件 | 优先级 |
|------|------|------|--------|
| 1 | CacheCapacityManager 实现 | `lib/infrastructure/cache/cache_capacity_manager.dart` | P2 |
| 2 | MessageDao 增加清理方法 | `deleteOlderThan`, `deleteOldest`, `deleteLeastRecentlyUsed` | P2 |
| 3 | HttpCacheDao 增加过期清理 | `deleteExpired` | P2 |
| 4 | HTTP 超时配置优化 | `app_config.dart` | P2 |

---

## 五、预期效果对标

| 指标 | 当前 | 优化后 | 飞书/企微 |
|------|------|--------|-----------|
| **打开聊天页延迟** | 500-2000ms（等网络） | < 100ms（本地缓存） | < 100ms |
| **会话列表加载** | 300-1000ms（等网络） | < 50ms（本地缓存） | < 50ms |
| **重复请求率** | ~30%（快速切换） | < 1%（请求去重） | < 1% |
| **离线可用率** | 0%（纯网络） | 90%+（本地缓存） | 99%+ |
| **消息搜索** | 服务端搜索（需网络） | 本地 FTS5（< 50ms） | 本地搜索 |
| **弱网消息发送** | 丢失（内存队列） | 不丢（持久化队列） | 不丢 |
| **HTTP 带宽** | 100%（全量传输） | -60%（ETag 304） | -80% |
| **数据库膨胀** | 无限制 | 10 万条上限 + 90 天保留 | 弹性管理 |

---

## 六、服务端配合事项

为充分发挥客户端缓存能力，服务端需要配合：

### 6.1 API 响应添加缓存头

```java
// Spring Boot 拦截器统一添加缓存头
@Component
public class CacheHeaderInterceptor implements HandlerInterceptor {
    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response,
                           Object handler, ModelAndView modelAndView) {
        String path = request.getRequestURI();

        if (path.contains("/im/conversation/list")) {
            response.setHeader("Cache-Control", "max-age=30");
            response.setHeader("ETag", generateETag(response));
        } else if (path.contains("/im/group/member/list")) {
            response.setHeader("Cache-Control", "max-age=300");
            response.setHeader("ETag", generateETag(response));
        }
        // ... 其他接口
    }
}
```

### 6.2 支持 304 Not Modified

```java
// 在 Controller 中检查 If-None-Match
@GetMapping("/list")
public ResponseEntity<?> getConversationList(
    @RequestHeader(value = "If-None-Match", required = false) String ifNoneMatch) {

    String currentETag = computeETag(userId);
    if (currentETag.equals(ifNoneMatch)) {
        return ResponseEntity.status(304).build(); // 304 Not Modified
    }

    List<ConversationVO> list = conversationService.getList(userId);
    return ResponseEntity.ok()
        .eTag(currentETag)
        .cacheControl(CacheControl.maxAge(30, TimeUnit.SECONDS))
        .body(list);
}
```

---

## 七、风险与注意事项

| 风险 | 说明 | 缓解措施 |
|------|------|----------|
| **数据一致性** | 本地缓存可能短暂过期 | UI 显示"数据更新于 X 秒前"提示 + 下拉刷新 |
| **数据库迁移** | 新增表需要 schemaVersion 升级 | 使用 Drift MigrationStrategy 平滑迁移 |
| **存储空间** | 缓存数据占用设备存储 | CacheCapacityManager 定期清理 + 设置页提供清理入口 |
| **FTS5 中文分词** | SQLite 默认分词器不支持中文 | 使用 unicode61 分词器或引入 ICU 扩展 |
| **内存占用** | 预加载增加内存使用 | 限制预加载数量 + 监听系统内存告警 |
| **服务端 ETag** | 需要服务端配合生成 ETag | 可先客户端自行计算响应体 hash 作为 ETag |

---

## 八、全功能模块企业级优化扫描

> 本节记录所有 IM 功能模块的企业级优化需求与方案。

### 8.1 功能模块扫描清单

| 模块 | 核心文件 | 现状 | 优化需求 | 优先级 |
|------|----------|------|----------|--------|
| **消息聊天** | `chat_controller.dart`, `chat_timeline_controller.dart` | 有消息队列但无持久化 | 本地优先 + 预加载 | P0 |
| **会话列表** | `conversation_list_controller.dart` | 纯远程，有增量同步 | 本地优先 + 游标持久化 | P0 |
| **收藏** | `favorite_repository_impl.dart` | **纯远程，无本地缓存** | 本地缓存 + 离线查看 | P1 |
| **群组设置** | `group_settings_repository_impl.dart` | 有内存缓存(30s TTL) | 持久化 + 预加载 | P1 |
| **搜索** | `common_global_search_page.dart` | **纯服务端搜索** | 本地 FTS5 + 混合搜索 | P1 |
| **表情贴纸** | `sticker_repository_impl.dart` | **纯远程，无缓存** | 本地缓存 + 预加载 | P2 |
| **文件上传** | `multipart_upload_repository_impl.dart` | 无断点续传 | 断点续传 + 进度持久化 | P2 |
| **文件预览** | `file_download_service.dart` | 无本地缓存 | 下载缓存 + 离线预览 | P2 |
| **通话** | `call_repository_impl.dart` | 纯远程 + WebSocket | 通话记录本地缓存 | P2 |

### 8.2 收藏模块企业级优化

**现状问题：** [favorite_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/favorite/infrastructure/repositories/favorite_repository_impl.dart) 纯远程调用，每次打开收藏页都需要网络请求。

**优化方案：**

```dart
/// lib/infrastructure/database/tables/favorites_table.dart
///
/// 收藏本地缓存表
class Favorites extends Table {
  TextColumn get favoriteId => text()();
  TextColumn get messageId => text()();
  IntColumn get messageType => integer()();
  TextColumn get messagePreview => text().nullable()();
  TextColumn get messageContent => text().nullable()();
  TextColumn get messageExtra => text().nullable()();
  TextColumn get messageSnapshot => text().nullable()();
  DateTimeColumn get sendTime => dateTime()();
  DateTimeColumn get favoriteTime => dateTime()();
  TextColumn get senderId => text()();
  TextColumn get senderNickname => text().nullable()();
  TextColumn get senderAvatar => text().nullable()();
  BoolColumn get isSelf => boolean()();
  DateTimeColumn get cachedAt => dateTime()();  // 缓存时间

  @override
  Set<Column> get primaryKey => {favoriteId};
}

/// 改造后的 FavoriteRepositoryImpl
class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final FavoriteRemoteDataSource _remoteDataSource;
  final FavoriteLocalDataSource _localDataSource;  // 新增

  @override
  Future<FavoritePageResult> getFavorites({
    String keyword = '',
    String tab = 'default',
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    // 1. 先查本地（秒级响应）
    final local = await _localDataSource.getFavorites(
      keyword: keyword,
      tab: tab,
      pageNo: pageNo,
      pageSize: pageSize,
    );

    // 2. 后台静默刷新（仅第一页时）
    if (pageNo == 1) {
      unawaited(_syncFavoritesInBackground(keyword, tab));
    }

    // 3. 有本地数据立即返回
    if (local.isNotEmpty) {
      return local;
    }

    // 4. 首次无缓存时走远程
    final page = await _remoteDataSource.getFavorites(
      keyword: keyword,
      tab: tab,
      pageNo: pageNo,
      pageSize: pageSize,
    );
    final result = FavoritePageResult(
      items: page.items.map(...).toList(),
      total: page.total,
      hasMore: page.hasMore,
    );
    await _localDataSource.upsertFavorites(result.items);
    return result;
  }

  Future<void> _syncFavoritesInBackground(String keyword, String tab) async {
    try {
      final page = await _remoteDataSource.getFavorites(
        keyword: keyword,
        tab: tab,
        pageNo: 1,
        pageSize: 50,  // 多拉一些用于缓存
      );
      await _localDataSource.upsertFavorites(
        page.items.map(...).toList(),
      );
    } catch (_) {}
  }
}
```

### 8.3 群组设置模块企业级优化

**现状问题：** [group_settings_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/group_settings/infrastructure/repositories/group_settings_repository_impl.dart) 有内存缓存(30s TTL)，但 App 重启后缓存丢失。

**优化方案：**

```dart
/// 改造要点：
/// 1. 群成员列表持久化到 Drift（Groups + GroupMembers 表）
/// 2. 群信息（名称、头像、公告）持久化
/// 3. 进入群设置页时先展示本地缓存，后台静默刷新
/// 4. WebSocket 推送群变更时自动更新本地缓存

class GroupSettingsRepositoryImpl implements GroupSettingsRepository {
  GroupSettingsRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,  // 新增
  );

  final GroupSettingsRemoteDataSource _remoteDataSource;
  final GroupLocalDataSource _localDataSource;

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    // 1. 先查本地（秒级响应）
    final local = await _localDataSource.getGroupMembers(groupId);

    // 2. 后台静默刷新
    unawaited(_syncGroupMembersInBackground(groupId));

    // 3. 有本地数据立即返回
    if (local.isNotEmpty) {
      return local;
    }

    // 4. 首次无缓存时走远程
    final members = await _remoteDataSource.getGroupMembers(groupId);
    await _localDataSource.upsertGroupMembers(groupId, members);
    return members;
  }

  @override
  Future<GroupSettingsSnapshot> getGroupSettings(String groupId) async {
    // 群信息本地优先
    final local = await _localDataSource.getGroupSettings(groupId);
    unawaited(_syncGroupSettingsInBackground(groupId));
    if (local != null) return local;

    final settings = await _remoteDataSource.getGroupSettings(groupId);
    await _localDataSource.upsertGroupSettings(groupId, settings);
    return settings;
  }
}
```

### 8.4 搜索模块企业级优化

**现状问题：** [common_global_search_page.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/search/presentation/pages/common_global_search_page.dart) 完全依赖服务端搜索，离线无法搜索历史消息。

**优化方案：**

```dart
/// 混合搜索策略：本地 FTS5 + 服务端搜索
///
/// 搜索流程：
/// 1. 用户输入关键词 → 先查本地 FTS5（< 50ms）
/// 2. 同时发起服务端搜索（网络请求）
/// 3. 本地结果立即展示，服务端结果到达后合并
/// 4. 离线时仅展示本地搜索结果

class SearchService {
  SearchService(this._localDataSource, this._remoteDataSource);

  final MessageLocalDataSource _localDataSource;
  final SearchRemoteDataSource _remoteDataSource;

  /// 混合搜索
  Future<SearchResult> search({
    required String keyword,
    String? chatId,
    int limit = 20,
  }) async {
    // 1. 本地 FTS5 搜索（秒级响应）
    final localFuture = _localDataSource.searchMessages(
      keyword: keyword,
      chatId: chatId,
      limit: limit,
    );

    // 2. 服务端搜索（并行）
    final remoteFuture = _remoteDataSource.searchMessages(
      keyword: keyword,
      chatId: chatId,
      limit: limit,
    ).catchError((_) => <Message>[]);  // 网络失败时静默

    // 3. 等待两个结果
    final results = await Future.wait([localFuture, remoteFuture]);
    final localMessages = results[0] as List<Message>;
    final remoteMessages = results[1] as List<Message>;

    // 4. 合并去重（以 messageId 为键）
    final merged = <String, Message>{};
    for (final msg in [...localMessages, ...remoteMessages]) {
      merged[msg.messageId] = msg;
    }

    return SearchResult(
      messages: merged.values.take(limit).toList(),
      fromLocal: remoteMessages.isEmpty,  // 标记是否仅本地结果
    );
  }
}
```

### 8.5 表情贴纸模块企业级优化

**现状问题：** [sticker_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/infrastructure/repositories/sticker_repository_impl.dart) 纯远程调用，每次打开表情面板都需要网络。

**优化方案：**

```dart
/// lib/infrastructure/database/tables/stickers_table.dart
///
/// 表情贴纸本地缓存表
class Stickers extends Table {
  TextColumn get stickerId => text()();
  TextColumn get url => text()();
  TextColumn get name => text().nullable()();
  TextColumn get md5 => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sortNo => integer()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {stickerId};
}

/// 改造后的 StickerRepositoryImpl
class StickerRepositoryImpl implements StickerRepository {
  StickerRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final StickerRemoteDataSource _remoteDataSource;
  final StickerLocalDataSource _localDataSource;

  @override
  Future<StickerCatalog> getStickerCatalog() async {
    // 1. 先查本地
    final local = await _localDataSource.getStickers();
    // 2. 后台刷新
    unawaited(_syncStickersInBackground());
    // 3. 有本地数据立即返回
    if (local.isNotEmpty) {
      return StickerCatalog(items: local);
    }
    // 4. 首次走远程
    final catalog = await _remoteDataSource.getStickerCatalog();
    await _localDataSource.upsertStickers(catalog.items);
    return catalog;
  }
}
```

### 8.6 文件上传断点续传优化

**现状问题：** [multipart_upload_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/file/infrastructure/repositories/multipart_upload_repository_impl.dart) 无断点续传，网络中断后需要重新上传。

**优化方案：**

```dart
/// lib/infrastructure/database/tables/upload_tasks_table.dart
///
/// 上传任务持久化表（支持断点续传）
class UploadTasks extends Table {
  TextColumn get uploadId => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get fileType => text().nullable()();
  IntColumn get chunkSize => integer()();
  IntColumn get totalChunks => integer()();
  TextColumn get uploadedChunks => text()();  // JSON: [1, 2, 3] 已上传的分片号
  IntColumn get status => integer()();  // 0: pending, 1: uploading, 2: completed, 3: failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {uploadId};
}

/// 断点续传实现
class MultipartUploadRepositoryImpl implements MultipartUploadRepository {
  MultipartUploadRepositoryImpl(this._dataSource, this._localDataSource);

  final MultipartUploadDataSource _dataSource;
  final UploadTaskLocalDataSource _localDataSource;

  @override
  Future<MultipartUploadInitResult> initMultipartUpload({
    required String name,
    required int size,
    String? type,
    String? directory,
    int? chunkSize,
  }) async {
    // 检查是否有未完成的上传任务
    final existing = await _localDataSource.getPendingUpload(name, size);
    if (existing != null) {
      // 恢复上传进度
      return MultipartUploadInitResult(
        uploadId: existing.uploadId,
        chunkSize: existing.chunkSize,
        uploadedChunks: existing.getUploadedChunks(),
        resumed: true,
      );
    }

    // 新上传任务
    final result = await _dataSource.initMultipartUpload(
      name: name,
      size: size,
      type: type,
      directory: directory,
      chunkSize: chunkSize,
    );

    // 持久化上传任务
    await _localDataSource.saveUploadTask(
      uploadId: result.uploadId,
      fileName: name,
      fileSize: size,
      chunkSize: result.chunkSize,
      totalChunks: result.totalChunks,
    );

    return result;
  }

  @override
  Future<MultipartChunkResult> uploadChunk({
    required String uploadId,
    required int chunkNumber,
    required Uint8List chunkData,
    void Function(int, int)? onProgress,
  }) async {
    final result = await _dataSource.uploadChunk(
      uploadId: uploadId,
      chunkNumber: chunkNumber,
      chunkData: chunkData,
      onProgress: onProgress,
    );

    // 记录已上传的分片
    await _localDataSource.markChunkUploaded(uploadId, chunkNumber);

    return result;
  }
}
```

### 8.7 文件预览离线缓存优化

**现状问题：** [file_download_service.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/file_preview/application/services/file_download_service.dart) 无本地缓存，每次预览都需要下载。

**优化方案：**

```dart
/// 文件预览缓存管理器
class FilePreviewCacheManager {
  /// 缓存目录
  final Directory _cacheDir;

  /// 缓存上限（500MB）
  static const int maxCacheSize = 500 * 1024 * 1024;

  /// 文件过期时间（7 天）
  static const Duration fileExpiry = Duration(days: 7);

  /// 获取缓存文件路径（如果存在且未过期）
  Future<File?> getCachedFile(String fileUrl) async {
    final cacheKey = _generateCacheKey(fileUrl);
    final cacheFile = File('${_cacheDir.path}/$cacheKey');

    if (!await cacheFile.exists()) return null;

    // 检查过期
    final stat = await cacheFile.stat();
    if (DateTime.now().difference(stat.modified) > fileExpiry) {
      await cacheFile.delete();
      return null;
    }

    return cacheFile;
  }

  /// 缓存文件
  Future<void> cacheFile(String fileUrl, List<int> bytes) async {
    final cacheKey = _generateCacheKey(fileUrl);
    final cacheFile = File('${_cacheDir.path}/$cacheKey');
    await cacheFile.writeAsBytes(bytes);

    // 检查缓存容量
    await _evictIfNecessary();
  }

  /// LRU 淘汰
  Future<void> _evictIfNecessary() async {
    final files = await _cacheDir.list().toList();
    int totalSize = 0;
    final fileStats = <File, FileStat>{};

    for (final entity in files) {
      if (entity is File) {
        final stat = await entity.stat();
        fileStats[entity] = stat;
        totalSize += stat.size;
      }
    }

    if (totalSize <= maxCacheSize) return;

    // 按访问时间排序，删除最旧的
    final sorted = fileStats.entries.toList()
      ..sort((a, b) => a.value.accessed.compareTo(b.value.accessed));

    for (final entry in sorted) {
      if (totalSize <= maxCacheSize * 0.8) break;  // 淘汰到 80%
      await entry.key.delete();
      totalSize -= entry.value.size;
    }
  }

  String _generateCacheKey(String url) {
    final hash = md5.convert(utf8.encode(url)).toString();
    return hash;
  }
}
```

### 8.8 通话模块企业级优化

**现状问题：** [call_repository_impl.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/call/infrastructure/repositories/call_repository_impl.dart) 纯远程调用，通话记录无本地缓存。

**优化方案：**

```dart
/// lib/infrastructure/database/tables/call_records_table.dart
///
/// 通话记录本地缓存表
class CallRecords extends Table {
  TextColumn get callSessionId => text()();
  TextColumn get chatId => text()();
  IntColumn get callType => integer()();  // 0: voice, 1: video
  IntColumn get status => integer()();  // 0: missed, 1: accepted, 2: rejected, 3: completed
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get duration => integer()();  // 秒
  TextColumn get participants => text()();  // JSON: [userId1, userId2]
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {callSessionId};
}

/// 通话记录本地优先
class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl(
    this._remoteDataSource,
    this._socketDataSource,
    this._mapper,
    this._localDataSource,  // 新增
  );

  final CallRemoteDataSource _remoteDataSource;
  final CallSocketDataSource _socketDataSource;
  final CallDtoMapper _mapper;
  final CallRecordLocalDataSource _localDataSource;

  /// 获取通话记录列表（本地优先）
  Future<List<CallRecord>> getCallRecords({
    required String chatId,
    int limit = 20,
  }) async {
    final local = await _localDataSource.getCallRecords(chatId, limit);
    unawaited(_syncCallRecordsInBackground(chatId));
    if (local.isNotEmpty) return local;

    final records = await _remoteDataSource.getCallRecords(chatId, limit);
    await _localDataSource.upsertCallRecords(records);
    return records;
  }
}
```

### 8.9 WebSocket 层企业级优化

**现状分析：** [im_socket_client.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/core/websocket/im_socket_client.dart) 已实现心跳、重连、ACK 机制，但缺少消息批量入库和断线补偿。

**优化方案：**

```dart
/// WebSocket 消息批量入库优化
/// 
/// 当前问题：每条 WebSocket 消息单独触发 UI 更新，高频消息时性能下降
/// 
/// 优化策略：
/// 1. 消息缓冲队列：50ms 窗口批量处理（已实现 _enqueueMessageForBatch）
/// 2. 批量写入数据库：减少 Drift 事务次数
/// 3. 批量通知 UI：一次性更新多条消息

class WebSocketMessageBatchWriter {
  WebSocketMessageBatchWriter(this._localDataSource);

  final MessageLocalDataSource _localDataSource;

  /// 批量写入消息到数据库
  /// 
  /// 优化点：
  /// - 单次事务写入多条消息（减少 I/O）
  /// - 使用 INSERT OR REPLACE 避免冲突
  /// - 异步写入不阻塞 WebSocket 消息处理
  Future<void> writeMessagesBatch(List<Message> messages) async {
    if (messages.isEmpty) return;

    // 批量写入（单次事务）
    await _localDataSource.insertMessages(messages);

    // 批量更新 FTS5 索引
    await _localDataSource.updateFtsIndex(messages);
  }
}

/// WebSocket 断线消息补偿机制
/// 
/// 问题：WebSocket 断开期间，用户可能收到消息但客户端未感知
/// 
/// 解决方案：
/// 1. 重连成功后，拉取断开期间的离线消息
/// 2. 使用 cursorVersion 或 lastMessageSequence 作为游标
/// 3. 增量拉取缺失消息并合并到本地

class WebSocketOfflineMessageCompensator {
  WebSocketOfflineMessageCompensator(
    this._remoteDataSource,
    this._localDataSource,
  );

  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;

  /// 重连成功后触发离线消息补偿
  Future<void> compensateOfflineMessages({
    required String chatId,
    required String lastSequence,
  }) async {
    try {
      // 1. 拉取 lastSequence 之后的消息
      final missingMessages = await _remoteDataSource.fetchMessagesAfterSequence(
        chatId: chatId,
        afterSequence: lastSequence,
        limit: 100,
      );

      if (missingMessages.isEmpty) return;

      // 2. 写入本地数据库
      await _localDataSource.insertMessages(missingMessages);

      // 3. 通知 UI 更新（通过 Stream）
      _messageStreamController.add(missingMessages);
    } catch (e) {
      // 补偿失败静默，等待下次重连
      debugPrint('[OfflineCompensator] compensate failed: $e');
    }
  }
}
```

### 8.10 数据库层企业级优化

**现状问题：** [im_database.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/database/im_database.dart) 仅有 2 张表（Messages、Conversations），缺少索引优化和批量写入优化。

**优化方案：**

```dart
/// 数据库表结构扩展
/// 
/// 需要新增的表：
/// 1. HttpCache - HTTP 响应缓存（已设计）
/// 2. PendingMessages - 待发送消息队列（已设计）
/// 3. Users - 用户资料缓存（已设计）
/// 4. Groups - 群组信息缓存（已设计）
/// 5. GroupMembers - 群成员关系（已设计）
/// 6. Favorites - 收藏缓存（已设计）
/// 7. Stickers - 表情贴纸缓存（已设计）
/// 8. UploadTasks - 上传任务进度（已设计）
/// 9. CallRecords - 通话记录（已设计）
/// 10. MessagesFts - 消息全文检索（已设计）

/// 索引优化方案
/// 
/// 当前索引：
/// - messages: (chatId, sentAt), (chatId, sequence)
/// 
/// 建议新增索引：
/// 1. messages: (clientMessageId) - 用于快速查找本地发送的消息
/// 2. messages: (messageId) - 用于快速查找特定消息
/// 3. conversations: (chatId) - 主键索引
/// 4. conversations: (updatedAt) - 用于排序
/// 5. group_members: (groupId, userId) - 复合索引，用于 @ 提及查询
/// 6. http_cache: (expiresAt) - 用于过期清理

/// 批量写入优化
/// 
/// 使用 Drift 的 batch 方法减少事务开销
class MessageLocalDataSource {
  MessageLocalDataSource(this._db);

  final ImDatabase _db;

  /// 批量插入消息（单次事务）
  Future<void> insertMessages(List<Message> messages) async {
    await _db.batch((batch) {
      for (final message in messages) {
        batch.insert(
          _db.messages,
          MessageCompanion(
            messageId: Value(message.messageId),
            chatId: Value(message.chatId),
            content: Value(message.content),
            senderId: Value(message.senderId),
            sentAt: Value(message.sentAt),
            // ... 其他字段
          ),
          mode: InsertMode.replace, // INSERT OR REPLACE
        );
      }
    });
  }

  /// 批量更新 FTS5 索引
  Future<void> updateFtsIndex(List<Message> messages) async {
    await _db.batch((batch) {
      for (final message in messages) {
        batch.insert(
          _db.messagesFts,
          MessagesFtsCompanion(
            messageId: Value(message.messageId),
            content: Value(message.content),
            senderName: Value(message.senderName),
            chatId: Value(message.chatId),
            sentAt: Value(message.sentAt),
          ),
          mode: InsertMode.replace,
        );
      }
    });
  }
}

/// 数据库版本迁移策略
/// 
/// 使用 Drift 的 MigrationStrategy 平滑升级
@DriftDatabase(
  tables: [
    Messages,
    Conversations,
    HttpCache,
    PendingMessages,
    Users,
    Groups,
    GroupMembers,
    Favorites,
    Stickers,
    UploadTasks,
    CallRecords,
  ],
)
class ImDatabase extends _$ImDatabase {
  @override
  int get schemaVersion => 2; // 升级到版本 2

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // 创建 FTS5 虚拟表
        await customStatement(
          'CREATE VIRTUAL TABLE messages_fts USING fts5(content, sender_name, chat_id, tokenize="unicode61")',
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 版本 1 → 2：新增缓存表
          await m.createTable(_db.httpCache);
          await m.createTable(_db.pendingMessages);
          await m.createTable(_db.users);
          await m.createTable(_db.groups);
          await m.createTable(_db.groupMembers);
          await m.createTable(_db.favorites);
          await m.createTable(_db.stickers);
          await m.createTable(_db.uploadTasks);
          await m.createTable(_db.callRecords);
          
          // 创建索引
          await m.createIndex(_db.idxMessagesClientMessageId);
          await m.createIndex(_db.idxConversationsUpdatedAt);
        }
      },
    );
  }
}
```

### 8.11 UI 渲染层企业级优化

**现状分析：** 
- [message_key_cache.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/utils/message_key_cache.dart) 已实现 LRU 缓存（100 条）
- [chat_realtime_binding.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/providers/chat_realtime_binding.dart) 已实现 50ms 批量节流

**优化方案：**

```dart
/// 消息列表虚拟化优化
/// 
/// 当前问题：消息列表使用 ListView，所有消息都会构建 Widget
/// 
/// 优化方案：
/// 1. 使用 ListView.builder + itemExtent 固定高度
/// 2. 或使用 flutter_slidable 实现滑动操作
/// 3. 消息气泡使用 const Widget 减少重建

class OptimizedChatMessageList extends StatelessWidget {
  const OptimizedChatMessageList({
    required this.messages,
    required this.onMessageTap,
  });

  final List<Message> messages;
  final void Function(Message) onMessageTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemExtent: 80.0, // 固定高度，避免动态计算
      cacheExtent: 500.0, // 预构建可视区域外 500px
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(
          key: ValueKey(message.messageId),
          message: message,
          onTap: () => onMessageTap(message),
        );
      },
    );
  }
}

/// 图片懒加载优化
/// 
/// 当前问题：图片消息使用 CachedNetworkImage，未优化缩略图
/// 
/// 优化方案：
/// 1. 列表中使用缩略图（thumbnail），点击进入详情页加载原图
/// 2. 使用 ImageCache 预加载可见区域的图片
/// 3. 图片解码使用 compute() 离屏解码，避免阻塞 UI

class OptimizedImageMessageBubble extends StatelessWidget {
  const OptimizedImageMessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = message.extra.thumbnailUrl;
    final originalUrl = message.content;

    return GestureDetector(
      onTap: () => _openImageDetail(context, originalUrl),
      child: CachedNetworkImage(
        imageUrl: thumbnailUrl ?? originalUrl,
        memCacheWidth: 200, // 限制内存缓存尺寸
        memCacheHeight: 200,
        placeholder: (context, url) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  void _openImageDetail(BuildContext context, String originalUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailPage(imageUrl: originalUrl),
      ),
    );
  }
}

/// 消息气泡工厂优化
/// 
/// 使用 const Widget 减少重建
class MessageBubbleFactory {
  static Widget build(Message message) {
    switch (message.type) {
      case MessageType.text:
        return TextMessageBubble(message: message);
      case MessageType.image:
        return ImageMessageBubble(message: message);
      case MessageType.voice:
        return VoiceMessageBubble(message: message);
      // ... 其他类型
    }
  }
}

/// 消息气泡使用 const 构造
class TextMessageBubble extends StatelessWidget {
  const TextMessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isOutgoing ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: message.isOutgoing ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
```

### 8.12 图片/媒体缓存企业级优化

**现状分析：** [im_cache_manager.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/infrastructure/cache/im_cache_manager.dart) 已实现三级缓存（内存 → 磁盘 → 网络），但缺少缩略图预生成。

**优化方案：**

```dart
/// 缩略图预生成服务
/// 
/// 对标飞书：进入聊天页前预生成缩略图，首屏加载秒开
/// 
/// 实现策略：
/// 1. 图片上传时，服务端生成缩略图（推荐）
/// 2. 客户端接收到图片消息后，异步生成缩略图并缓存
/// 3. 列表中使用缩略图，详情页加载原图

class ThumbnailPreGenerator {
  ThumbnailPreGenerator(this._cacheManager);

  final CacheManager _cacheManager;

  /// 预生成缩略图
  /// 
  /// 触发时机：
  /// 1. 接收到图片消息时
  /// 2. 进入聊天页前（预加载活跃会话的图片）
  Future<void> preGenerateThumbnail({
    required String imageUrl,
    required int width,
    required int height,
  }) async {
    try {
      // 1. 下载原图
      final originalFile = await _cacheManager.getSingleFile(imageUrl);
      if (originalFile == null) return;

      // 2. 解码图片
      final image = await compute(decodeImage, originalFile.path);
      if (image == null) return;

      // 3. 生成缩略图（保持宽高比）
      final thumbnail = await compute(
        resizeImage,
        (image, 200, 200),
      );
      if (thumbnail == null) return;

      // 4. 编码为 JPEG（压缩质量 80%）
      final thumbnailBytes = await compute(
        encodeJpeg,
        (thumbnail, quality: 80),
      );

      // 5. 缓存缩略图
      final thumbnailPath = '${originalFile.path}_thumb';
      await File(thumbnailPath).writeAsBytes(thumbnailBytes);
    } catch (e) {
      debugPrint('[ThumbnailGenerator] pre-generate failed: $e');
    }
  }
}

/// 图片分级缓存策略
/// 
/// 对标飞书：根据图片使用频率分级缓存
/// 
/// 分级策略：
/// - L1（热数据）：最近 7 天访问的图片，内存 + 磁盘缓存
/// - L2（温数据）：7-30 天访问的图片，仅磁盘缓存
/// - L3（冷数据）：30 天以上未访问，清理磁盘缓存
/// 
/// 实现：使用 flutter_cache_manager 的 stalePeriod + 定时清理任务

class TieredImageCacheManager {
  TieredImageCacheManager(this._cacheManager);

  final CacheManager _cacheManager;

  /// 定时清理冷数据（每天凌晨 3 点）
  Future<void> runDailyCleanup() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // 清理 30 天以上未访问的图片
    await _cacheManager.removeCacheFilesCreatedBefore(thirtyDaysAgo);
  }

  /// 获取图片（优先热数据）
  Future<File?> getImage(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    if (fileInfo == null) return null;

    // 更新访问时间（用于 LRU 淘汰）
    await _touchFile(fileInfo.file);

    return fileInfo.file;
  }

  Future<void> _touchFile(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {}
  }
}

/// 音频缓存优化
/// 
/// 当前问题：音频文件较大，50 个缓存上限可能不够
/// 
/// 优化方案：
/// 1. 增加缓存上限到 200 个
/// 2. 增加磁盘容量限制到 500MB
/// 3. 音频文件使用 Opus 编码（压缩率更高）

class OptimizedAudioCacheManager {
  static final CacheManager instance = CacheManager(
    Config(
      'imAudioCache',
      maxNrOfCacheObjects: 200, // 增加到 200
      maxCacheSize: 500 * 1024 * 1024, // 500MB
      stalePeriod: const Duration(days: 30),
    ),
  );
}
```

### 8.13 增量同步游标持久化

**现状问题：** [conversation_list_controller.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/conversation/presentation/controllers/conversation_list_controller.dart) 的 cursorVersion 存储在内存中，App 重启后丢失。

**优化方案：**

```dart
/// 增量同步游标持久化
/// 
/// 当前问题：cursorVersion 存储在 StateNotifier 中，App 重启后丢失
/// 
/// 优化方案：
/// 1. 将 cursorVersion 持久化到 SharedPreferences 或 Drift
/// 2. App 启动时从本地恢复游标
/// 3. 每次同步成功后更新本地游标

class ConversationCursorStore {
  ConversationCursorStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _cursorKey = 'im_conversation_cursor_version';

  /// 获取游标
  Future<String?> getCursorVersion() async {
    return _prefs.getString(_cursorKey);
  }

  /// 保存游标
  Future<void> saveCursorVersion(String cursorVersion) async {
    await _prefs.setString(_cursorKey, cursorVersion);
  }

  /// 清除游标（退出登录时）
  Future<void> clearCursorVersion() async {
    await _prefs.remove(_cursorKey);
  }
}

/// 改造 ConversationListController
class ConversationListController extends StateNotifier<ConversationListState> {
  ConversationListController(
    this._conversationSyncCoordinator,
    this._syncConversationsIncrementallyUseCase,
    this._conversationRepository,
    this._cursorStore, // 新增
    this.activeConversationService,
  ) : super(const ConversationListState());

  final ConversationCursorStore _cursorStore;

  /// 初始化时从本地恢复游标
  Future<void> initialize() async {
    final savedCursor = await _cursorStore.getCursorVersion();
    if (savedCursor != null) {
      state = state.copyWith(cursorVersion: savedCursor);
    }
  }

  @override
  Future<AppError?> syncIncrementally() async {
    try {
      final result = await _syncConversationsIncrementallyUseCase(
        cursorVersion: state.cursorVersion,
      );
      if (!mounted) return null;

      final nextConversations = result.items.isEmpty
          ? state.conversations
          : _mergeSyncedConversations(
              current: state.conversations,
              incoming: result.items,
            );

      state = state.copyWith(
        status: ConversationListStatus.ready,
        conversations: nextConversations,
        cursorVersion: result.cursorVersion,
      );

      // 持久化游标
      await _cursorStore.saveCursorVersion(result.cursorVersion);

      return null;
    } catch (error, stackTrace) {
      if (!mounted) return null;
      final appError = AppErrorMapper.map(error, stackTrace);
      state = state.copyWith(
        status: ConversationListStatus.failed,
        error: appError,
      );
      return appError;
    }
  }
}
```

### 8.14 多账号缓存隔离

**现状问题：** 当前数据库使用单例 `ImDatabase.instance`，多账号切换时数据混用。

**优化方案：**

```dart
/// 多账号缓存隔离
/// 
/// 问题：当前数据库单例，多账号切换时数据混用
/// 
/// 解决方案：
/// 1. 数据库名称包含 userId：`yubb_im_$userId.db`
/// 2. SharedPreferences key 包含 userId：`im_cursor_$userId`
/// 3. 文件缓存目录包含 userId：`/cache/$userId/`

class MultiAccountDatabaseManager {
  static ImDatabase? _currentDatabase;
  static String? _currentUserId;

  /// 获取当前用户的数据库
  static ImDatabase getDatabase(String userId) {
    if (_currentUserId == userId && _currentDatabase != null) {
      return _currentDatabase!;
    }

    // 切换用户时关闭旧数据库
    _currentDatabase?.close();

    // 创建新数据库
    _currentDatabase = ImDatabase(
      driftDatabase(name: 'yubb_im_$userId'),
    );
    _currentUserId = userId;

    return _currentDatabase!;
  }

  /// 退出登录时清理
  static Future<void> logout(String userId) async {
    if (_currentUserId == userId) {
      await _currentDatabase?.close();
      _currentDatabase = null;
      _currentUserId = null;
    }
  }
}

/// 多账号 SharedPreferences 隔离
class MultiAccountPreferences {
  MultiAccountPreferences(this._prefs, this._userId);

  final SharedPreferences _prefs;
  final String _userId;

  String _buildKey(String key) => '${key}_$_userId';

  Future<String?> getString(String key) async {
    return _prefs.getString(_buildKey(key));
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(_buildKey(key), value);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(_buildKey(key));
  }
}

/// 多账号文件缓存隔离
class MultiAccountCacheManager {
  MultiAccountCacheManager(this._userId);

  final String _userId;

  /// 获取用户专属缓存目录
  Directory getUserCacheDirectory() {
    final baseDir = Directory.systemTemp.createTempSync('im_cache');
    final userDir = Directory('${baseDir.path}/$_userId');
    if (!userDir.existsSync()) {
      userDir.createSync(recursive: true);
    }
    return userDir;
  }

  /// 退出登录时清理用户缓存
  Future<void> clearUserCache() async {
    final userDir = getUserCacheDirectory();
    if (userDir.existsSync()) {
      await userDir.delete(recursive: true);
    }
  }
}
```

### 8.15 弱网环境自适应优化

**现状分析：**
- 已有 `NetworkMonitorService` 监听网络状态（WiFi/Mobile/None）
- 已有弱网检测（ping > 500ms 判定为弱网）
- 但缺少业务层的自适应策略

**优化方案：**

```dart
/// 弱网环境自适应策略
/// 
/// 对标飞书/企业微信：弱网下自动降级，保证核心功能可用
/// 
/// 策略：
/// - 强网（WiFi/4G+，ping < 200ms）：全功能，预加载图片/视频
/// - 弱网（3G/弱信号，200ms < ping < 1000ms）：延迟加载图片，禁用视频自动播放
/// - 极弱网（2G/极差，ping > 1000ms）：仅加载文本，禁用所有媒体预加载
/// - 离线（无网络）：仅展示本地缓存，消息进入待发送队列

class NetworkAdaptiveStrategy {
  NetworkAdaptiveStrategy(this._networkMonitor);

  final NetworkMonitorService _networkMonitor;

  /// 获取当前网络质量等级
  NetworkQuality get currentQuality {
    final status = _networkMonitor.currentStatus;
    final pingMs = _networkMonitor.pingDelayMs;

    if (status == NetworkStatus.none) return NetworkQuality.offline;
    if (pingMs > 1000) return NetworkQuality.veryWeak;
    if (pingMs > 500) return NetworkQuality.weak;
    if (pingMs > 200) return NetworkQuality.moderate;
    return NetworkQuality.strong;
  }

  /// 是否应该预加载图片
  bool shouldPreloadImages() {
    return currentQuality == NetworkQuality.strong;
  }

  /// 是否应该自动播放视频
  bool shouldAutoPlayVideos() {
    return currentQuality == NetworkQuality.strong;
  }

  /// 是否应该预加载语音
  bool shouldPreloadVoice() {
    return currentQuality.index >= NetworkQuality.moderate.index;
  }

  /// 消息发送策略
  MessageSendStrategy get sendStrategy {
    switch (currentQuality) {
      case NetworkQuality.strong:
      case NetworkQuality.moderate:
        return MessageSendStrategy.immediate;
      case NetworkQuality.weak:
        return MessageSendStrategy.retryWithBackoff;
      case NetworkQuality.veryWeak:
      case NetworkQuality.offline:
        return MessageSendStrategy.queueForLater;
    }
  }
}

enum NetworkQuality {
  offline,      // 无网络
  veryWeak,     // 极弱网（ping > 1000ms）
  weak,         // 弱网（500ms < ping < 1000ms）
  moderate,     // 中等（200ms < ping < 500ms）
  strong,       // 强网（ping < 200ms）
}

enum MessageSendStrategy {
  immediate,           // 立即发送
  retryWithBackoff,    // 指数退避重试
  queueForLater,       // 加入待发送队列
}

/// 弱网提示 UI
/// 
/// 当检测到弱网时，在聊天页顶部显示提示条
class WeakNetworkBanner extends StatelessWidget {
  const WeakNetworkBanner({required this.quality});

  final NetworkQuality quality;

  @override
  Widget build(BuildContext context) {
    if (quality == NetworkQuality.strong) return const SizedBox.shrink();

    final message = switch (quality) {
      NetworkQuality.offline => '网络已断开，消息将在恢复后发送',
      NetworkQuality.veryWeak => '网络极弱，消息发送可能延迟',
      NetworkQuality.weak => '网络较弱，部分功能可能受限',
      _ => '',
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.16 消息去重与一致性保障

**现状问题：**
- `MessageDeduplicator` 基于内存，App 重启后缓存丢失
- WebSocket 推送的消息状态可能与本地不一致

**优化方案：**

```dart
/// 持久化消息去重器
/// 
/// 问题：当前 MessageDeduplicator 基于内存，App 重启后缓存丢失
/// 
/// 解决方案：
/// 1. 将已处理的消息 ID 持久化到 Drift（最近 1000 条）
/// 2. 启动时从本地恢复去重缓存
/// 3. 定期清理过期条目

class PersistentMessageDeduplicator {
  PersistentMessageDeduplicator(this._localDataSource);

  final MessageLocalDataSource _localDataSource;
  static const int _maxSize = 1000;

  /// 检查消息是否重复
  Future<bool> isDuplicate(String messageId) async {
    if (messageId.isEmpty || messageId == '0') return false;

    // 1. 检查本地数据库
    final exists = await _localDataSource.messageExists(messageId);
    if (exists) return true;

    // 2. 记录该消息 ID
    await _localDataSource.recordProcessedMessage(messageId);

    // 3. 清理过期条目
    await _localDataSource.cleanupProcessedMessages(_maxSize);

    return false;
  }
}

/// 消息状态一致性保障
/// 
/// 问题：WebSocket 推送的消息状态可能与本地不一致
/// 
/// 解决方案：
/// 1. 使用 clientMessageId 作为本地唯一标识
/// 2. 服务端返回 messageId 后，更新本地记录
/// 3. 定期全量同步（每天凌晨）校正状态

class MessageStateConsistencyManager {
  MessageStateConsistencyManager(
    this._localDataSource,
    this._remoteDataSource,
  );

  final MessageLocalDataSource _localDataSource;
  final MessageRemoteDataSource _remoteDataSource;

  /// 发送消息后，等待服务端 ACK 并更新状态
  Future<void> reconcileMessageState({
    required String clientMessageId,
    required String serverMessageId,
  }) async {
    // 1. 查找本地消息
    final localMessage = await _localDataSource.getMessageByClientMessageId(
      clientMessageId,
    );
    if (localMessage == null) return;

    // 2. 更新 messageId 和状态
    await _localDataSource.updateMessageState(
      clientMessageId: clientMessageId,
      messageId: serverMessageId,
      status: MessageStatus.sent,
    );
  }

  /// 每日全量同步（校正本地与服务器状态）
  Future<void> runDailyReconciliation() async {
    try {
      // 1. 获取本地所有 pending 状态的消息
      final pendingMessages = await _localDataSource.getPendingMessages();

      // 2. 批量查询服务器状态
      final serverStates = await _remoteDataSource.batchQueryMessageStatus(
        messageIds: pendingMessages.map((m) => m.messageId).toList(),
      );

      // 3. 更新本地状态
      for (final entry in serverStates.entries) {
        await _localDataSource.updateMessageState(
          messageId: entry.key,
          status: entry.value,
        );
      }
    } catch (e) {
      debugPrint('[Reconciliation] daily sync failed: $e');
    }
  }
}
```

### 8.17 草稿消息持久化（✅ 已实现）

**现状分析：** [reedit_hint_local_store.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/application/services/reedit_hint_local_store.dart) 已实现基于 SharedPreferences 的草稿持久化，支持：
- 按 `tenantId + userId + chatId + messageId` 四维键存储草稿内容
- 支持截止时间（deadlineTs）追踪
- JSON 序列化存储 `{c: content, d: deadlineTs}`

**无需额外优化**，当前实现已满足飞书/企微级别的草稿持久化需求。

### 8.18 滚动位置与时间线状态持久化

**现状问题：**
- 用户退出聊天页后，滚动位置丢失
- 返回时需要重新滚动到之前的位置

**优化方案：**

```dart
/// 聊天页滚动位置持久化
/// 
/// 对标飞书/企业微信：退出聊天页后返回，自动滚动到之前的位置
/// 
/// 实现：
/// 1. 记录当前可见消息的 messageId 和滚动偏移
/// 2. 使用 SharedPreferences 存储（轻量级）
/// 3. Key 格式：`scroll_$chatId`
/// 4. 进入聊天页时恢复位置

class ChatScrollPositionStore {
  ChatScrollPositionStore(this._prefs);

  final SharedPreferences _prefs;

  /// 保存滚动位置
  Future<void> saveScrollPosition({
    required String chatId,
    required String anchorMessageId,
    required double offset,
  }) async {
    final data = {
      'anchorMessageId': anchorMessageId,
      'offset': offset,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString('scroll_$chatId', jsonEncode(data));
  }

  /// 获取滚动位置
  Future<ChatScrollPosition?> getScrollPosition(String chatId) async {
    final raw = _prefs.getString('scroll_$chatId');
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = data['savedAt'] as int;
      
      // 超过 24 小时的记录视为过期
      if (DateTime.now().millisecondsSinceEpoch - savedAt > 86400000) {
        return null;
      }

      return ChatScrollPosition(
        anchorMessageId: data['anchorMessageId'] as String,
        offset: (data['offset'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 清除滚动位置
  Future<void> clearScrollPosition(String chatId) async {
    await _prefs.remove('scroll_$chatId');
  }
}

class ChatScrollPosition {
  const ChatScrollPosition({
    required this.anchorMessageId,
    required this.offset,
  });

  final String anchorMessageId;
  final double offset;
}

/// 聊天页集成滚动位置恢复
class ChatPage extends StatefulWidget {
  const ChatPage({required this.chatId});

  final String chatId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final ChatScrollPositionStore _scrollStore = ChatScrollPositionStore(
    SharedPreferences.getInstance(),
  );

  @override
  void initState() {
    super.initState();
    _restoreScrollPosition();
  }

  Future<void> _restoreScrollPosition() async {
    final position = await _scrollStore.getScrollPosition(widget.chatId);
    if (position == null) return;

    // 等待消息列表加载完成
    await Future.delayed(const Duration(milliseconds: 300));

    // 滚动到锚点消息
    // 实际实现需要找到 anchorMessageId 对应的 Widget 并滚动
    // 这里简化为滚动到指定偏移
    _scrollController.jumpTo(position.offset);
  }

  @override
  void dispose() {
    // 保存当前滚动位置
    final offset = _scrollController.offset;
    // 实际实现需要获取当前可见消息的 messageId
    unawaited(_scrollStore.saveScrollPosition(
      chatId: widget.chatId,
      anchorMessageId: 'current_message_id', // 需要动态获取
      offset: offset,
    ));
    _scrollController.dispose();
    super.dispose();
  }
}
```

### 8.19 已读回执与语音播放状态缓存

**现状分析：**
- [read_receipt_summary_store.dart](file:///c:/Users/jxctkj/IdeaProjects/shengyu/yubb-saas-pro/shengyu-ui/shengyu-ui-admin-flutter/lib/features/im/chat/presentation/controllers/read_receipt_summary_store.dart) 已实现**内存缓存**（10分钟 TTL，最多200条）
- 支持批量预取（prefetchSummaries）、防抖（250ms）、请求去重（_inFlight）
- **但未持久化到 Drift**，App 重启后缓存丢失
- 语音播放状态（markVoicePlayed）为纯远程调用，无本地缓存

**优化方案：**

```dart
/// 已读回执持久化升级
/// 
/// 当前：ReadReceiptSummaryStore 使用内存缓存（10min TTL，200条上限）
/// 优化：将摘要持久化到 Drift，App 重启后仍可用
/// 
/// 实现步骤：
/// 1. 新增 read_receipt_summaries 表（messageId, chatId, readCount, unreadCount, totalCount, updatedAt）
/// 2. ReadReceiptSummaryStore.ensureSummary() 改为 Local-First：先查 Drift，再走远程
/// 3. WebSocket 推送已读状态时，同步更新 Drift + 内存缓存
/// 4. 保留现有内存缓存逻辑作为 L1，Drift 作为 L2

class ReadReceiptLocalCache {
  ReadReceiptLocalCache(this._db);

  final ImDatabase _db;

  /// 获取已读回执摘要（从 Drift）
  Future<ReadReceiptSummary?> getSummary(String messageId) async {
    return _db.readReceiptSummaryDao.getSummary(messageId);
  }

  /// 保存已读回执摘要（写入 Drift）
  Future<void> saveSummary(ReadReceiptSummary summary) async {
    await _db.readReceiptSummaryDao.upsertSummary(summary);
  }

  /// 批量保存（WebSocket 推送时）
  Future<void> saveSummaries(List<ReadReceiptSummary> summaries) async {
    await _db.batch((batch) {
      for (final summary in summaries) {
        batch.insert(
          _db.readReceiptSummaries,
          ReadReceiptSummaryCompanion(
            messageId: Value(summary.messageId),
            chatId: Value(summary.chatId),
            readCount: Value(summary.readCount),
            unreadCount: Value(summary.unreadCount),
            totalCount: Value(summary.totalCount),
            updatedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.replace,
        );
      }
    });
  }
}

/// 语音播放状态本地缓存
/// 
/// 当前：markVoicePlayed / getVoicePlayedStatus 均为纯远程调用
/// 优化：将已播放的语音消息 ID 缓存到 SharedPreferences
/// 
/// 实现：
/// 1. 将已播放的语音消息 ID 缓存到 SharedPreferences
/// 2. 播放语音时，立即更新本地状态 + 异步调用远程
/// 3. 进入聊天页时，从本地加载已播放状态，后台静默同步远程

class VoicePlayedStatusCache {
  VoicePlayedStatusCache(this._prefs);

  final SharedPreferences _prefs;

  /// 检查语音是否已播放
  Future<bool> isPlayed(String messageId) async {
    final playedIds = await _getPlayedIds();
    return playedIds.contains(messageId);
  }

  /// 标记语音为已播放
  Future<void> markPlayed(String messageId) async {
    final playedIds = await _getPlayedIds();
    if (playedIds.contains(messageId)) return;

    playedIds.add(messageId);
    
    // 限制缓存大小（最近 1000 条）
    if (playedIds.length > 1000) {
      playedIds.removeRange(0, playedIds.length - 1000);
    }

    await _prefs.setStringList('voice_played_ids', playedIds);
  }

  /// 批量获取播放状态
  Future<Map<String, bool>> batchGetStatus(List<String> messageIds) async {
    final playedIds = await _getPlayedIds();
    return {
      for (final id in messageIds) id: playedIds.contains(id),
    };
  }

  Future<Set<String>> _getPlayedIds() async {
    final list = _prefs.getStringList('voice_played_ids');
    return list?.toSet() ?? <String>{};
  }
}
```

### 8.20 待持续扫描项

| 扫描项 | 状态 | 说明 |
|--------|------|------|
| WebSocket 消息与 HTTP 缓存的一致性 | 🔲 待扫描 | WS 推送的消息需要同步更新 HTTP 缓存 |
| 数据库加密（SQLCipher） | 🔲 待扫描 | 等保三级要求 |
| Protobuf 序列化替代 JSON | 🔲 待扫描 | 已有 codec 协商基础 |
| 消息引用/转发的本地缓存 | 🔲 待扫描 | quotePreviewEntry 需要缓存 |
| 聊天背景/主题缓存 | 🔲 待扫描 | 用户个性化设置持久化 |
| 消息表情回应缓存 | 🔲 待扫描 | reaction 数据本地缓存 |
| 消息撤回本地缓存 | 🔲 待扫描 | recalledMessage 数据持久化 |
| 消息转发本地缓存 | 🔲 待扫描 | forwardedMessage 数据持久化 |
| 消息收藏本地缓存 | 🔲 待扫描 | favoritedMessage 数据持久化 |
| 联系人列表本地缓存 | 🔲 待扫描 | contactList 数据持久化 |
| 部门/组织架构缓存 | 🔲 待扫描 | departmentTree 数据持久化 |
| 系统通知消息缓存 | 🔲 待扫描 | systemNotification 数据持久化 |
| 消息搜索历史缓存 | 🔲 待扫描 | searchHistory 本地存储 |
| 常用语/快捷回复缓存 | 🔲 待扫描 | quickReply 本地存储 |

---

## 九、前后端接口对齐分析

> 本节分析前端优化方案与后端 API 的实际支持情况，确保方案设计基于真实接口能力。

### 9.1 后端 Controller 接口清单

基于对 `shengyu-module-system-biz` 后端代码的扫描，移动端 IM 相关 Controller 包括：

| Controller | 路径前缀 | 核心能力 |
|-----------|---------|---------|
| **AppImConversationController** | `/system/im/conversation` | 会话列表、增量同步、标记已读、未读数 |
| **AppImMessageController** | `/system/im/message` | 消息发送、历史查询、窗口加载、增量拉取、已读标记、语音播放状态 |
| **AppImFavoriteController** | `/system/im/favorite` | 收藏增删、分页查询、搜索、详情、重发 |
| **AppImGroupController** | `/system/im/group` | 群组管理、成员管理、邀请码、加群申请、群公告 |
| **AppImStickerController** | `/system/im/sticker` | 表情列表、上传、收藏、排序、移除、最近使用 |
| **AppImReadReceiptController** | `/system/im/read-receipt` | 已读回执摘要、批量查询、详情分页 |
| **AppImContactController** | `/system/im/contact` | 联系人列表、搜索、详情、部门查询、星标联系人 |
| **AppImSearchController** | `/system/im/search` | 热门搜索词、全局搜索（聚合联系人/群聊/消息/媒体） |
| **AppImGroupFileController** | `/system/im/group-file` | 群文件上传、下载、删除、分页查询 |
| **AppImCallController** | `/system/im/call` | 通话记录查询（待确认） |
| **AppImBadgeController** | `/system/im/badge` | 未读角标数据 |
| **AppImDeviceController** | `/system/im/device` | 设备管理、在线状态 |

### 9.2 关键接口能力确认

#### ✅ 已支持的前端优化需求

**1. 会话增量同步（cursorVersion）**
- **后端接口**：`GET /system/im/conversation/sync?cursorVersion={version}&limit={limit}`
- **返回结构**：`AppImConversationSyncRespVO` 包含 `cursorVersion`、`items`、`hasMore`
- **前端现状**：`ConversationRepositoryImpl.syncConversationsIncrementally()` 已实现增量同步逻辑
- **优化点**：cursorVersion 需持久化到 SharedPreferences/Drift（当前仅在内存 state 中）

**2. 消息增量拉取（断线补偿）**
- **后端接口**：`GET /system/im/message/pull`（参数：`AppImMessagePullReqVO`）
- **用途**：WebSocket 断线重连后拉取缺失消息
- **前端现状**：`MessageRemoteDataSource` 已实现 `fetchMessagesAfterSequence()`
- **优化点**：需集成到 WebSocket 重连逻辑中（`WebSocketOfflineMessageCompensator`）

**3. 批量标记已读**
- **后端接口**：`PUT /system/im/message/mark-read?messageIds={ids}`
- **支持能力**：按 messageIds 批量标记
- **前端现状**：`MessageRepositoryImpl` 已调用此接口
- **优化点**：无，已完善

**4. 语音播放状态批量查询**
- **后端接口**：`GET /system/im/message/voice-played-status?chatId={id}&messageIds={ids}`
- **返回**：已播放的 messageId 列表
- **前端现状**：`MessageRepositoryImpl.getVoicePlayedStatus()` 已实现
- **优化点**：可本地缓存已播放状态，减少重复查询

**5. 已读回执批量查询**
- **后端接口**：`GET /system/im/read-receipt/summary/batch?messageIds={ids}`
- **支持能力**：一次请求查询多条消息的已读摘要
- **前端现状**：`ReadReceiptSummaryStore.prefetchSummaries()` 已使用批量接口
- **优化点**：可持久化到 Drift，App 重启后仍可用

**6. 搜索限流保护**
- **后端接口**：多个搜索接口均集成 `ImSearchRateLimitService`
- **返回**：429 Too Many Requests + `Retry-After` 头
- **前端现状**：`WeakNetworkInterceptor` 已处理 429 响应
- **优化点**：无，已完善

**7. 会话同步限流保护**
- **后端接口**：`GET /system/im/conversation/sync` 集成 `ImConversationSyncRateLimitService`
- **返回**：429 Too Many Requests + `Retry-After` 头
- **前端现状**：已处理 429 响应
- **优化点**：无，已完善

#### ⚠️ 需要后端配合的优化需求

**1. ETag / Cache-Control 响应头**
- **当前状态**：后端 Controller 未主动设置 ETag 或 Cache-Control 头
- **前端需求**：`HttpCacheInterceptor` 依赖这些头部实现强缓存和条件请求
- **后端改造建议**：
  ```java
  // 在 AppImConversationController.getConversationList() 中添加
  @GetMapping("/list")
  public ResponseEntity<CommonResult<List<AppImConversationRespVO>>> getConversationList(...) {
      List<AppImConversationRespVO> list = conversationService.getConversationList(userId, pageNo, pageSize);
      String etag = generateETag(list); // 基于内容 hash
      return ResponseEntity.ok()
          .eTag(etag)
          .cacheControl(CacheControl.maxAge(30, TimeUnit.SECONDS))
          .body(success(list));
  }
  ```
- **替代方案**：前端自行计算响应体 hash 作为 ETag（无需后端改造）

**2. 304 Not Modified 支持**
- **当前状态**：后端未检查 `If-None-Match` 请求头
- **前端需求**：`HttpCacheInterceptor` 发送条件请求时期望 304 响应
- **后端改造建议**：
  ```java
  @GetMapping("/list")
  public ResponseEntity<?> getConversationList(
      @RequestHeader(value = "If-None-Match", required = false) String ifNoneMatch) {
      String currentETag = computeETag(userId);
      if (currentETag.equals(ifNoneMatch)) {
          return ResponseEntity.status(304).build();
      }
      // ... 正常返回
  }
  ```
- **替代方案**：前端仅使用强缓存（max-age），不使用条件请求

**3. 消息窗口接口优化**
- **当前接口**：`GET /system/im/message/window`（参数：`AppImMessageWindowReqVO`）
- **前端需求**：支持 `isPreload` 标记，预加载时不触发已读状态更新
- **后端改造建议**：在 `AppImMessageWindowReqVO` 中添加 `isPreload` 字段，Service 层判断后跳过已读更新逻辑

#### ❌ 后端暂不支持的优化需求

**1. 消息全文检索（FTS5）**
- **前端方案**：本地 SQLite FTS5 虚拟表
- **后端现状**：`AppImMessageController.searchMessages()` 基于数据库 LIKE 查询
- **说明**：前端本地 FTS5 与后端无关，可独立实现

**2. 联系人/群组信息本地缓存**
- **前端方案**：Users / Groups / GroupMembers 表
- **后端现状**：`AppImContactController.getContactList()` 返回完整联系人列表
- **说明**：前端本地缓存与后端无关，可独立实现

**3. 待发消息队列持久化**
- **前端方案**：PendingMessages 表
- **后端现状**：无影响
- **说明**：纯前端优化，后端无需改造

**4. 文件断点续传**
- **前端方案**：UploadTasks 表记录分片进度
- **后端现状**：`AppImGroupFileController` 支持分片上传（待确认）
- **说明**：需确认后端是否支持分片上传接口

### 9.3 前后端接口对齐总结

| 前端优化方案 | 后端支持情况 | 是否需要后端改造 | 优先级 |
|------------|------------|----------------|--------|
| 会话增量同步（cursorVersion 持久化） | ✅ 已支持 | 否 | P0 |
| 消息增量拉取（断线补偿） | ✅ 已支持 | 否 | P0 |
| Repository 本地优先改造 | ✅ 无影响 | 否 | P0 |
| 请求去重拦截器 | ✅ 无影响 | 否 | P0 |
| 请求取消机制 | ✅ 无影响 | 否 | P1 |
| 待发消息队列持久化 | ✅ 无影响 | 否 | P0 |
| 已读回执持久化 | ✅ 已支持批量查询 | 否 | P1 |
| 语音播放状态缓存 | ✅ 已支持批量查询 | 否 | P2 |
| 联系人/群组本地缓存 | ✅ 已支持列表查询 | 否 | P1 |
| 消息预加载服务 | ⚠️ 需 isPreload 标记 | 建议改造 | P1 |
| HTTP 响应缓存（ETag/304） | ⚠️ 未设置缓存头 | 建议改造（可替代） | P1 |
| 消息全文检索（FTS5） | ✅ 无影响 | 否 | P2 |
| 文件断点续传 | ⚠️ 待确认分片上传支持 | 需确认 | P2 |

### 9.4 后端改造建议优先级

**P0（无需改造）**：
- 会话增量同步、消息增量拉取、批量标记已读、已读回执批量查询、语音播放状态查询等接口已完善
- 前端可独立实现的优化：Repository 本地优先、请求去重、待发消息持久化、FTS5、联系人缓存

**P1（建议改造）**：
- **消息窗口接口添加 isPreload 参数**：预加载时不触发已读状态更新
- **ETag / Cache-Control 响应头**：提升 HTTP 缓存效率（可先用前端替代方案）

**P2（待确认）**：
- **文件分片上传接口**：确认后端是否支持，若不支持需改造

---

## 十、修正后的功能模块扫描清单（基于真实代码状态）

> 本节基于实际代码扫描结果，修正 8.1 节的评估。

| 模块 | 核心文件 | 真实现状 | 优化需求 | 优先级 |
|------|----------|---------|---------|--------|
| **消息聊天** | `message_repository_impl.dart`, `message_cache_queue.dart` | 纯远程调用 + 内存队列（无持久化） | Repository 本地优先 + 队列持久化 | P0 |
| **会话列表** | `conversation_repository_impl.dart`, `conversation_list_controller.dart` | 纯远程调用 + cursorVersion 在内存 | Repository 本地优先 + 游标持久化 | P0 |
| **收藏** | `favorite_repository_impl.dart` | **纯远程，无本地缓存** | 本地缓存 + 离线查看 | P1 |
| **群组设置** | `group_settings_repository_impl.dart` | 有内存缓存(30s TTL) + 请求去重 | 持久化到 Drift | P1 |
| **搜索** | `common_global_search_page.dart` | **纯服务端搜索** | 本地 FTS5 + 混合搜索 | P1 |
| **表情贴纸** | `sticker_repository_impl.dart` | **纯远程，无缓存** | 本地缓存 + 预加载 | P2 |
| **文件上传** | `multipart_upload_repository_impl.dart` | 无断点续传 | 断点续传 + 进度持久化 | P2 |
| **文件预览** | `file_download_service.dart` | 无本地缓存 | 下载缓存 + 离线预览 | P2 |
| **通话** | `call_repository_impl.dart` | 纯远程 + WebSocket | 通话记录本地缓存 | P2 |
| **已读回执** | `read_receipt_summary_store.dart` | **有内存缓存（10min TTL, 200条）** | 持久化到 Drift | P1 |
| **草稿消息** | `reedit_hint_local_store.dart` | **✅ 已实现 SharedPreferences 持久化** | 无需优化 | - |
| **语音播放状态** | `message_repository_impl.dart` | 纯远程调用 | 本地缓存（SharedPreferences） | P2 |

---

## 参考来源

- 飞书知识库三级缓存架构（L1 内存池 → L2 SQLite WAL → L3 网络）
- 企业微信 Differential Sync 框架（seq 增量同步）
- HTTP ETag/Cache-Control 最佳实践（RFC 9110, RFC 5861）
- ttl_etag_cache Flutter 包（TTL + ETag + AES-256 加密缓存）
- dio_flow Flutter 包（MetricsInterceptor + CacheInterceptor + RateLimitInterceptor）
- Flutter 离线优先架构（Local-First + Event Sourcing + CRDT）
