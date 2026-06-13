# Flutter IM 企业级性能优化任务清单

> 基于文档: [flutter-im-enterprise-performance-plan.md](../flutter-im-enterprise-performance-plan.md)  
> 创建日期: 2026-06-12  
> 状态: 待执行

---

## 任务总览

| 阶段 | 任务数 | 预计总工作量 | 目标 |
|------|--------|-------------|------|
| P0 致命瓶颈 | 4 | 8-11 天 | 冷启动 < 50ms, 滑动 60fps |
| P1 严重瓶颈 | 4 | 5-7 天 | 主线程无阻塞, rebuild 降 70% |
| P2 体验打磨 | 4 | 3 天 | 列表流畅, 跳转无等待 |
| P3 架构演进 | 4 | 5-7 天 | 稳定性增强, 网络优化 |
| P4 终极打磨 | 7 | 5-7 天 | Widget 树扁平化, 内存稳定 |
| P5 启动+商业 | 3 | 3-4 天 | 首次启动动画, 广告预留 |

---

## P0 级任务（致命瓶颈，必须优先解决）

### P0-1: 引入 Drift 本地数据库

| 属性 | 内容 |
|------|------|
| **优先级** | P0（最高） |
| **预计工作量** | 4-5 天 |
| **依赖关系** | 无（独立任务，其他 P0 任务部分依赖此任务完成） |
| **验收标准** | 1. 消息表、会话表 Schema 创建并支持迁移<br>2. 打开聊天页优先从本地加载，首帧 < 50ms<br>3. 切换聊天页返回时状态保持，无需重新网络请求<br>4. 支持离线查看历史消息<br>5. WebSocket 收到消息后异步写入数据库 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 添加 `drift` 依赖，配置 build_runner | 0.5 天 |
| 2 | 定义消息表 (Messages) Schema | 0.5 天 |
| 3 | 定义会话表 (Conversations) Schema | 0.5 天 |
| 4 | 实现 DriftDatabase 单例及连接管理 | 0.5 天 |
| 5 | 实现消息 CRUD Repository | 1 天 |
| 6 | 改造 `LoadChatWindowUseCase`: 本地优先加载 + 增量同步 | 1 天 |
| 7 | 改造 `ChatRealtimeBinding`: 消息异步写入数据库 | 0.5 天 |
| 8 | Provider 生命周期改造: 移除 autoDispose + 状态缓存池 | 0.5 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/database/im_database.dart` |
| 新增 | `lib/infrastructure/database/tables/messages_table.dart` |
| 新增 | `lib/infrastructure/database/tables/conversations_table.dart` |
| 新增 | `lib/infrastructure/repositories/message_repository.dart` |
| 新增 | `lib/infrastructure/repositories/conversation_repository.dart` |
| 修改 | `lib/domain/usecases/load_chat_window_usecase.dart` |
| 修改 | `lib/presentation/bindings/chat_realtime_binding.dart` |
| 修改 | `lib/presentation/providers/chat_timeline_controller.dart` |
| 修改 | `lib/presentation/providers/chat_controller_provider.dart` |
| 修改 | `pubspec.yaml` |

---

### P0-2: 图片三级缓存

| 属性 | 内容 |
|------|------|
| **优先级** | P0 |
| **预计工作量** | 1-2 天 |
| **依赖关系** | 无（可与 P0-1 并行） |
| **验收标准** | 1. 图片消息二次加载即时渲染（命中内存缓存）<br>2. 磁盘缓存减少 80% 以上重复网络请求<br>3. 列表滚动无闪烁<br>4. 全局 ImageCache 配置上限（200张/100MB）<br>5. 头像使用缓存加载 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 添加 `cached_network_image` 和 `flutter_cache_manager` 依赖 | 0.5 天 |
| 2 | 全局 ImageCache 配置（main.dart） | 0.25 天 |
| 3 | 实现 IM 专用 CacheManager（图片+音频分离） | 0.25 天 |
| 4 | 替换所有 `NetworkImage` 为 `CachedNetworkImage` | 0.5 天 |
| 5 | 图片消息气泡支持缩略图优先加载 | 0.25 天 |
| 6 | 头像组件替换为缓存加载 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/cache/im_cache_manager.dart` |
| 修改 | `lib/main.dart`（添加 ImageCache 配置） |
| 修改 | `lib/presentation/widgets/message_bubbles/image_message_bubble.dart` |
| 修改 | `lib/presentation/widgets/chat_avatar.dart` |
| 修改 | `lib/presentation/widgets/conversation_tile.dart` |
| 修改 | `lib/infrastructure/utils/image_resolver.dart` |
| 修改 | `pubspec.yaml` |

---

### P0-3: SliverList + 渲染隔离

| 属性 | 内容 |
|------|------|
| **优先级** | P0 |
| **预计工作量** | 2-3 天 |
| **依赖关系** | 部分依赖 P0-2（图片缓存替换可同步进行） |
| **验收标准** | 1. 消息列表使用 CustomScrollView + SliverList 渲染<br>2. 单条消息变化时 rebuild 范围缩小至单条<br>3. 列表滑动帧率稳定 60fps（DevTools 验证）<br>4. Widget 树深度从 8 层降至 5 层以内<br>5. 移除 AnimatedContainer，改用条件样式 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 将 `ListView.builder` 替换为 `CustomScrollView + SliverList.builder` | 1 天 |
| 2 | 拆分 `_MessageRow` 为 `_MessageTile` + `_MessageContent`，减少嵌套 | 0.5 天 |
| 3 | 移除 `_ChatMessageBubble` 中的 `AnimatedContainer` | 0.5 天 |
| 4 | 头像、气泡内容精细化 `RepaintBoundary` 包裹 | 0.5 天 |
| 5 | `ValueKey` 优化：使用消息稳定标识 | 0.25 天 |
| 6 | 配置 `cacheExtent` 优化预渲染 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/chat_timeline.dart` |
| 修改 | `lib/presentation/widgets/message_tile.dart`（或 `_MessageRow` 所在文件） |
| 修改 | `lib/presentation/widgets/chat_message_bubble.dart` |
| 修改 | `lib/presentation/widgets/message_bubbles/_chat_message_bubble.dart` |
| 修改 | `lib/presentation/widgets/chat_avatar.dart` |

---

### P0-4: 语音音频本地缓存

| 属性 | 内容 |
|------|------|
| **优先级** | P0 |
| **预计工作量** | 1 天 |
| **依赖关系** | 依赖 P0-2（CacheManager 基础设施） |
| **验收标准** | 1. 语音消息播放前优先使用本地缓存<br>2. 缓存未命中时后台下载至本地后播放<br>3. 语音播放 < 100ms 开始播放（命中缓存时）<br>4. 音频缓存过期策略: 30天 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 在 `ImCacheManager` 中增加音频专用 CacheManager | 0.25 天 |
| 2 | 改造 `AudioPlaybackService`: 播放前检查本地缓存 | 0.5 天 |
| 3 | 实现音频后台下载逻辑 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/infrastructure/cache/im_cache_manager.dart` |
| 修改 | `lib/infrastructure/services/audio_playback_service.dart` |
| 修改 | `lib/presentation/widgets/message_bubbles/voice_message_bubble.dart` |

---

## P1 级任务（严重瓶颈）

### P1-1: WebSocket 消息批量节流

| 属性 | 内容 |
|------|------|
| **优先级** | P1 |
| **预计工作量** | 1-2 天 |
| **依赖关系** | 建议在 P0-1 完成后实施 |
| **验收标准** | 1. 群聊刷屏场景 rebuild 频率从 10次/s 降至 2-3次/s<br>2. 消息到达感知延迟 < 100ms<br>3. 50ms 批量窗口稳定工作 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 在 `ChatTimelineController` 中添加批量消息缓冲机制 | 0.5 天 |
| 2 | 在 `ChatRealtimeBinding` 中添加 WebSocket 消息批量接收 | 0.5 天 |
| 3 | 实现 `_flushPendingMessages` 批量合并逻辑 | 0.5 天 |
| 4 | 保留单条消息添加路径（低频率场景优化） | 0.25 天 |
| 5 | 单元测试: 验证批量合并去重逻辑 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/providers/chat_timeline_controller.dart` |
| 修改 | `lib/presentation/bindings/chat_realtime_binding.dart` |

---

### P1-2: Isolate 离屏计算

| 属性 | 内容 |
|------|------|
| **优先级** | P1 |
| **预计工作量** | 2-3 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 100条消息合并从 50-100ms 降至 < 5ms（主线程）<br>2. 消息数 > 20 条时自动使用 Isolate<br>3. 消息数 < 20 条时主线程直接执行（避免序列化开销）<br>4. 主线程仅负责 UI 渲染 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `_mergeWindowMessagesOffThread`（消息合并 Isolate） | 1 天 |
| 2 | 实现 `_parseMessagesBatch`（DTO 批量解析 Isolate） | 0.5 天 |
| 3 | 实现 Extra JSON 批量解析 Isolate | 0.5 天 |
| 4 | 添加数据量阈值判断逻辑 | 0.25 天 |
| 5 | 性能测试验证 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/isolates/message_merge_isolate.dart` |
| 新增 | `lib/infrastructure/isolates/message_parse_isolate.dart` |
| 修改 | `lib/presentation/providers/chat_timeline_controller.dart` |
| 修改 | `lib/infrastructure/mappers/message_dto_mapper.dart` |

---

### P1-3: Riverpod Selector 精确订阅

| 属性 | 内容 |
|------|------|
| **优先级** | P1 |
| **预计工作量** | 1 天 |
| **依赖关系** | 无（独立任务，但需要对现有 provider 进行全面审查） |
| **验收标准** | 1. 减少 60-70% 的不必要 rebuild（Widget Inspector 验证）<br>2. ChatPage 各子组件独立订阅，不互相影响<br>3. 状态更新到渲染的延迟降低 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 审查所有 `ref.watch` 调用，识别全量订阅点 | 0.25 天 |
| 2 | ChatPage 改造: 使用 `select` 拆分消息列表、loading、pageStatus | 0.25 天 |
| 3 | ChatTimeline 改造: 仅订阅 messages 字段 | 0.25 天 |
| 4 | ChatComposer 改造: 仅订阅 composer 相关字段 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/pages/chat_page.dart` |
| 修改 | `lib/presentation/widgets/chat_timeline.dart` |
| 修改 | `lib/presentation/widgets/chat_composer.dart` |
| 修改 | 其他使用 `ref.watch(chatTimelineStateProvider)` 的组件 |

---

### P1-4: ChatPage 生命周期优化

| 属性 | 内容 |
|------|------|
| **优先级** | P1 |
| **预计工作量** | 1 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 首帧渲染时间减少 30-40%<br>2. 键盘弹出响应 < 16ms<br>3. 无 Timer/Subscription 泄漏风险<br>4. 初始化任务串行化，关键路径优先 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `initState` 串行化: 关键初始化 + PostFrameCallback 延迟非关键任务 | 0.5 天 |
| 2 | 键盘响应优化: 使用 `_KeyboardAwarePadding` 局部包裹 | 0.25 天 |
| 3 | Timer 资源池化管理: 统一 `ChatPageTimerManager` | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/presentation/utils/chat_page_timer_manager.dart` |
| 新增 | `lib/presentation/widgets/keyboard_aware_padding.dart` |
| 修改 | `lib/presentation/pages/chat_page.dart` |

---

## P2 级任务（体验打磨）

### P2-1: 会话列表预览缓存

| 属性 | 内容 |
|------|------|
| **优先级** | P2 |
| **预计工作量** | 1 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 会话列表滑动流畅，无卡顿<br>2. 预览计算缓存命中后减少 80% 字符串处理<br>3. 消息内容变更时缓存自动失效 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `ConversationPreviewCache` | 0.25 天 |
| 2 | `Conversation` 增加 `previewVersion` 计算 | 0.25 天 |
| 3 | `ConversationTile` 使用缓存预览结果 | 0.25 天 |
| 4 | 缓存失效策略: LRU，最大 200 条 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/cache/conversation_preview_cache.dart` |
| 修改 | `lib/domain/models/conversation.dart` |
| 修改 | `lib/presentation/widgets/conversation_tile.dart` |

---

### P2-2: 消息预加载

| 属性 | 内容 |
|------|------|
| **优先级** | P2 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 依赖 P0-1（Drift 数据库完成后才能实现本地预加载） |
| **验收标准** | 1. 点击会话到进入聊天页无感知延迟<br>2. 预加载不阻塞 UI 交互<br>3. 预加载失败不影响正常进入 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `ConversationTile` 点击时触发后台预加载 | 0.25 天 |
| 2. 延迟跳转 50ms，给预加载留出时间 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/conversation_tile.dart` |
| 修改 | `lib/domain/usecases/load_chat_window_usecase.dart` |
| 修改 | `lib/presentation/pages/conversation_list_page.dart` |

---

### P2-3: 引用链预计算

| 属性 | 内容 |
|------|------|
| **优先级** | P2 |
| **预计工作量** | 1 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. build 中不再执行 `_buildQuotePreviewChain` 遍历<br>2. 引用链在 Controller 层预计算并缓存<br>3. 消息合并时自动触发引用链预计算 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 定义 `MessageWithQuotePreview` 和 `QuotePreviewEntry` | 0.25 天 |
| 2 | 在 `ChatTimelineController` 中实现 `_quotePreviewCache` | 0.25 天 |
| 3 | 消息合并时触发 `_precomputeQuotePreview` | 0.25 天 |
| 4 | 消息气泡渲染时直接读取预计算结果 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/domain/models/message_with_quote_preview.dart` |
| 修改 | `lib/presentation/providers/chat_timeline_controller.dart` |
| 修改 | `lib/presentation/widgets/message_bubbles/quote_preview_widget.dart` |

---

### P2-4: Watermark/Emoji 优化

| 属性 | 内容 |
|------|------|
| **优先级** | P2 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. Watermark 不再每次 build 创建 12 个 Text widget<br>2. Emoji builder 使用静态缓存，不重复编译正则 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `_ChatWatermarkLayer` 添加 widget 缓存 | 0.25 天 |
| 2 | `ChatEmojiSpecialTextSpanBuilder` 预编译为全局单例 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/chat_watermark_layer.dart` |
| 修改 | `lib/presentation/widgets/chat_composer.dart` |
| 修改 | `lib/infrastructure/utils/chat_emoji_special_text_span_builder.dart` |

---

## P3 级任务（架构演进）

### P3-1: 消息去重幂等

| 属性 | 内容 |
|------|------|
| **优先级** | P3 |
| **预计工作量** | 1 天 |
| **依赖关系** | 建议在 P1-1（批量节流）完成后实施 |
| **验收标准** | 1. WebSocket 重复消息不会导致重复渲染<br>2. 去重缓存最大 1000 条，LRU 淘汰<br>3. 数据库写入层面也做去重（unique key 约束） |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `MessageDeduplicator` 类 | 0.5 天 |
| 2 | 在 `ChatRealtimeBinding` 中集成去重逻辑 | 0.25 天 |
| 3 | 数据库 unique key 约束已存在则跳过 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/utils/message_deduplicator.dart` |
| 修改 | `lib/presentation/bindings/chat_realtime_binding.dart` |
| 修改 | `lib/infrastructure/database/tables/messages_table.dart` |

---

### P3-2: 骨架屏

| 属性 | 内容 |
|------|------|
| **优先级** | P3 |
| **预计工作量** | 1-2 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 聊天页初始化时展示骨架屏，而非 Loading 转圈<br>2. 骨架屏模拟真实消息布局（头像 + 气泡占位）<br>3. 数据加载完成后平滑过渡 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `_MessageSkeleton` 组件 | 0.5 天 |
| 2 | 聊天页 loading 态替换为骨架屏列表 | 0.5 天 |
| 3 | 会话列表也增加骨架屏 | 0.5 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/presentation/widgets/message_skeleton.dart` |
| 新增 | `lib/presentation/widgets/conversation_skeleton.dart` |
| 修改 | `lib/presentation/pages/chat_page.dart` |
| 修改 | `lib/presentation/pages/conversation_list_page.dart` |

---

### P3-3: Dio 连接池配置

| 属性 | 内容 |
|------|------|
| **优先级** | P3 |
| **预计工作量** | 1 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. Dio 配置连接池: `maxConnectionsPerHost = 10`<br>2. 配置 idle timeout 为 30s<br>3. 上传文件使用独立 Dio 实例（避免阻塞聊天消息） |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 改造 `DioClientFactory` 添加连接池配置 | 0.5 天 |
| 2 | 创建上传专用 Dio 实例 | 0.25 天 |
| 3 | 配置连接超时和接收超时 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/infrastructure/network/dio_client_factory.dart` |
| 新增 | `lib/infrastructure/network/upload_dio_client.dart` |

---

### P3-4: 文件分片上传

| 属性 | 内容 |
|------|------|
| **优先级** | P3 |
| **预计工作量** | 2-3 天 |
| **依赖关系** | 依赖 P3-3（Dio 连接池配置） |
| **验收标准** | 1. 大文件（>10MB）自动分片上传<br>2. 支持断点续传<br>3. 上传进度实时反馈<br>4. 上传失败可重试 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现分片上传服务 `ChunkUploadService` | 1 天 |
| 2 | 上传进度状态管理 | 0.5 天 |
| 3 | 断点续传逻辑 | 0.5 天 |
| 4 | UI 进度条集成 | 0.5 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/services/chunk_upload_service.dart` |
| 新增 | `lib/domain/models/upload_task.dart` |
| 修改 | `lib/presentation/providers/upload_progress_provider.dart` |
| 修改 | `lib/presentation/widgets/upload_progress_indicator.dart` |

---

## P4 级任务（终极打磨）

### P4-1: ChatPage build 拆分

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 1-2 天 |
| **依赖关系** | 依赖 P1-3（Selector 精确订阅） |
| **验收标准** | 1. ChatPage rebuild 频率降低 70-80%<br>2. 各子组件独立订阅，不互相影响<br>3. build 中的逻辑判断移至状态变更监听器 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 拆分 ChatPage 为 `_ChatAppBar` + `_ChatBody` + `_ChatComposerBar` | 0.5 天 |
| 2 | 提取 `_syncMessageKeys` 逻辑至 `listenManual` 监听器 | 0.5 天 |
| 3 | MediaQuery 局部监听: 仅包裹底部区域 | 0.5 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/pages/chat_page.dart` |
| 新增 | `lib/presentation/widgets/chat_app_bar.dart` |
| 新增 | `lib/presentation/widgets/chat_body.dart` |
| 新增 | `lib/presentation/widgets/chat_composer_bar.dart` |

---

### P4-2: ChatComposer Emoji 缓存

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. `ChatEmojiSpecialTextSpanBuilder` 不再每次 build 创建新实例<br>2. 每次 build 减少约 2-5ms |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `ChatComposer` 中添加静态常量缓存 emojiBuilder | 0.25 天 |
| 2 | 全局 `EmojiTextSpanBuilder` 单例（compact + normal 两种规格） | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/chat_composer.dart` |
| 新增 | `lib/infrastructure/utils/emoji_text_span_builder.dart` |

---

### P4-3: ConversationTile 重构

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 1 天 |
| **依赖关系** | 依赖 P2-1（预览缓存） |
| **验收标准** | 1. StatefulWidget 改为 StatelessWidget<br>2. 预览计算缓存命中后减少 80% 字符串处理<br>3. 鼠标长按逻辑移至 `_MouseLongPressHandler` |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `ConversationTile` 改为 StatelessWidget | 0.25 天 |
| 2 | 拆分 `_TileContent` + `_ConversationAvatar` + `_TileInfo` | 0.5 天 |
| 3 | 鼠标长按逻辑提取为 `_MouseLongPressHandler` | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/conversation_tile.dart` |
| 新增 | `lib/presentation/widgets/mouse_long_press_handler.dart` |

---

### P4-4: VoiceMessageBubble 简化

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 消除对 `ConsumerWidget` 的依赖<br>2. 减少 10-20% 的语音消息 rebuild 频率<br>3. strings 从父组件传入 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | `VoiceMessageBubble` 改为 StatelessWidget | 0.25 天 |
| 2 | `appStringsProvider` 改为从父组件传入 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/widgets/message_bubbles/voice_message_bubble.dart` |
| 修改 | `lib/presentation/widgets/message_tile.dart` |

---

### P4-5: Watermark CustomPaint

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. Widget 数量从 15+ 降至 3 个<br>2. 使用 `CustomPaint` 替代 `Wrap` + 12个 `Text`<br>3. 仅 text 变化时才重绘 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `_WatermarkPainter` 自定义绘制 | 0.25 天 |
| 2 | `_ChatWatermarkLayer` 替换为 CustomPaint 方案 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/presentation/painters/watermark_painter.dart` |
| 修改 | `lib/presentation/widgets/chat_watermark_layer.dart` |

---

### P4-6: GlobalKey 缓存管理

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 内存占用稳定，不随消息数量无限增长<br>2. 最多缓存 100 个 Key，LRU 淘汰<br>3. 加载历史消息后触发回收 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `MessageKeyCache` 类 | 0.25 天 |
| 2 | 在 ChatPage 中替换原有 `_messageItemKeys` | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/cache/message_key_cache.dart` |
| 修改 | `lib/presentation/pages/chat_page.dart` |

---

### P4-7: 构建配置优化

| 属性 | 内容 |
|------|------|
| **优先级** | P4 |
| **预计工作量** | 0.5 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. APK 体积减少 30-50%<br>2. 启动速度提升 10-20%<br>3. ProGuard 混淆不破坏功能 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 配置 `--tree-shake-icons` 和 `--split-per-abi` | 0.25 天 |
| 2 | 配置 Android ProGuard/R8 | 0.25 天 |
| 3 | 配置 Dart 代码混淆和 debug-info 分离 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `android/app/build.gradle` |
| 新增 | `android/app/proguard-rules.pro` |
| 修改 | `ci/build_android.sh`（或对应的构建脚本） |

---

## P5 级任务（启动体验+商业变现）

### P5-1: 首次启动动画页

| 属性 | 内容 |
|------|------|
| **优先级** | P5 |
| **预计工作量** | 1-2 天 |
| **依赖关系** | 无（独立任务） |
| **验收标准** | 1. 首次启动展示精美动画（类似微信地球小人）<br>2. 后续启动直接跳过动画<br>3. 动画时长 2-3 秒，流畅无卡顿 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `SplashScreen` 组件（缩放+旋转+淡入动画） | 0.5 天 |
| 2 | 实现 `AppEntryPoint` 统一入口点 | 0.5 天 |
| 3 | 使用 `SharedPreferences` 记录首次启动标记 | 0.25 天 |
| 4 | 动画完成后的过渡效果 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/presentation/pages/splash_screen.dart` |
| 新增 | `lib/presentation/widgets/app_entry_point.dart` |
| 修改 | `lib/main.dart` |

---

### P5-2: 启动期并行初始化

| 属性 | 内容 |
|------|------|
| **优先级** | P5 |
| **预计工作量** | 1 天 |
| **依赖关系** | 依赖 P0-1（Drift 数据库）和 P5-1（启动页） |
| **验收标准** | 1. 启动页动画期间并行执行 auth/locale/theme 初始化<br>2. 预加载本地数据（会话列表、最近消息）<br>3. 初始化任务不阻塞主界面展示 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 改造 `appBootstrapProvider` 使用 `Future.wait` 并行执行 | 0.5 天 |
| 2 | 添加 `_preloadLocalData` 预加载逻辑 | 0.25 天 |
| 3 | 添加 `_initImageCache` 初始化 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 修改 | `lib/presentation/providers/app_bootstrap_provider.dart` |
| 新增 | `lib/infrastructure/utils/preload_service.dart` |

---

### P5-3: 广告预留入口

| 属性 | 内容 |
|------|------|
| **优先级** | P5 |
| **预计工作量** | 0.5-1 天 |
| **依赖关系** | 依赖 P5-1（启动页） |
| **验收标准** | 1. 启动页底部预留广告占位区域（50px 高度）<br>2. 提供 `AdManager` 抽象层，未来可灵活接入广告 SDK<br>3. 占位符默认不展示真实广告，仅保留接口 |

#### 子任务

| # | 子任务 | 工作量 |
|---|--------|--------|
| 1 | 实现 `_AdPlaceholder` 组件 | 0.25 天 |
| 2 | 实现 `AdManager` 抽象层 | 0.25 天 |
| 3 | 在 `SplashScreen` 底部集成广告位 | 0.25 天 |

#### 相关文件路径

| 操作 | 文件路径 |
|------|----------|
| 新增 | `lib/infrastructure/services/ad_manager.dart` |
| 新增 | `lib/presentation/widgets/ad_placeholder.dart` |
| 修改 | `lib/presentation/pages/splash_screen.dart` |

---

## 实施路线图

```
Phase 1 (P0) — 2-3 周
├── P0-1 引入Drift本地数据库      ████████████████████  4-5天
├── P0-2 图片三级缓存             ████████              1-2天  (与P0-1并行)
├── P0-3 SliverList+渲染隔离      ████████████          2-3天  (部分依赖P0-2)
└── P0-4 语音音频本地缓存         ████                  1天    (依赖P0-2)

Phase 2 (P1) — 1-2 周
├── P1-1 WebSocket批量节流        ████████              1-2天  (建议P0-1后)
├── P1-2 Isolate离屏计算          ████████████          2-3天
├── P1-3 Selector精确订阅         ████                  1天
└── P1-4 ChatPage生命周期优化     ████                  1天

Phase 3 (P2) — 1 周
├── P2-1 会话列表预览缓存         ████                  1天
├── P2-2 消息预加载               ██                    0.5天  (依赖P0-1)
├── P2-3 引用链预计算             ████                  1天
└── P2-4 Watermark/Emoji优化      ██                    0.5天

Phase 4 (P3) — 持续迭代
├── P3-1 消息去重幂等             ████                  1天    (建议P1-1后)
├── P3-2 骨架屏                   ████████              1-2天
├── P3-3 Dio连接池配置            ████                  1天
└── P3-4 文件分片上传             ████████████          2-3天  (依赖P3-3)

Phase 5 (P4) — 1 周
├── P4-1 ChatPage build拆分       ████████              1-2天  (依赖P1-3)
├── P4-2 ChatComposer Emoji缓存   ██                    0.5天
├── P4-3 ConversationTile重构     ████                  1天    (依赖P2-1)
├── P4-4 VoiceMessageBubble简化   ██                    0.5天
├── P4-5 Watermark CustomPaint    ██                    0.5天
├── P4-6 GlobalKey缓存管理        ██                    0.5天
└── P4-7 构建配置优化             ██                    0.5天

Phase 6 (P5) — 3-4 天
├── P5-1 首次启动动画页           ████████              1-2天
├── P5-2 启动期并行初始化         ████                  1天    (依赖P0-1+P5-1)
└── P5-3 广告预留入口             ███                   0.5-1天(依赖P5-1)
```

---

## 验收场景汇总

| 场景 | 验收标准 | 测试方法 | 涉及任务 |
|------|----------|----------|----------|
| 冷启动进入聊天页 | 首帧 < 50ms | Flutter DevTools Timeline | P0-1 |
| 消息列表快速滑动 | 持续 60fps，无跳帧 | Performance Overlay | P0-3 |
| 群聊10人同时发言 | rebuild频率 < 5次/秒 | Widget Inspector | P1-1 |
| 图片消息二次加载 | 即时渲染，无闪烁 | 网络面板监控 | P0-2 |
| 内存占用（500条消息） | < 80MB | Flutter DevTools Memory | P0-1, P4-6 |
| 切换聊天页返回 | 状态保持，无重新加载 | 手动测试 | P0-1 |
| 语音消息播放 | < 100ms开始播放 | 手动测试 | P0-4 |
| 键盘弹出响应 | < 16ms | Performance Overlay | P1-4 |

---

## 风险评估

| 风险项 | 影响 | 缓解措施 |
|--------|------|----------|
| Drift数据库Schema设计 | 字段遗漏导致后续修改 | 先完整设计，充分Review |
| Isolate序列化开销 | 小数据量场景反而变慢 | 设置阈值（消息>20条才用Isolate） |
| 图片缓存占用磁盘 | 低端机存储空间不足 | 设置缓存上限（200张/100MB），定期清理 |
| SliverList改造 | 现有逻辑需要大改 | 渐进式替换，先在新页面验证 |
| Provider autoDispose移除 | 内存占用增加 | 配合状态缓存池（最多20个） |
| 消息预加载过度 | 占用过多内存 | 限制预加载数量（最近50条） |
