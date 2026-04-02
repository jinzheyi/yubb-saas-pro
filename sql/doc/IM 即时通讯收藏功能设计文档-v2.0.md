# IM 即时通讯 - 收藏功能设计补充文档 v2.0

## 一、功能概述

### 1.1 功能描述

在企业 IM 场景中，收藏功能是企业知识沉淀和个人信息管理的重要工具。用户可以：

- **消息收藏**：长按聊天消息（文字、图片、文件、语音、视频、链接）添加到收藏
- **分类管理**：按消息类型自动分类（全部、文字、图片、文件、链接、语音）
- **快速检索**：支持关键字搜索收藏内容
- **跨端同步**：收藏内容云端存储，多端实时同步
- **分享转发**：将收藏内容快速发送到聊天窗口
- **批量操作**：支持批量删除、批量移动
- **标签管理**：为收藏内容添加自定义标签，构建个人知识库

### 1.2 企业级应用场景

| 场景 | 典型用途 | 价值 |
|------|----------|------|
| **会议纪要** | 收藏重要决策、任务分工 | 形成项目日志，方便回顾 |
| **客户服务** | 收藏客户需求、反馈 | 转化为客户知识库 |
| **培训学习** | 收藏答疑、资料 | 构建学习资源库 |
| **项目管理** | 收藏需求文档、方案 | 项目资料集中管理 |
| **灵感记录** | 收藏创意、想法 | 个人知识积累 |

### 1.3 UI 交互流程

```
聊天页面 → 长按消息 → 弹出菜单 → 点击"收藏"
→ 显示"已收藏"提示
→ 可在"我的收藏"页面查看

我的收藏页面 → 分类筛选 → 点击内容
→ 查看/播放/下载
→ 可转发到聊天、可删除
```

---

## 二、技术方案

### 2.1 收藏数据结构

#### 数据库表设计
```sql
-- 收藏表 (im_favorites)
CREATE TABLE im_favorites (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL COMMENT '用户 ID',
  message_id BIGINT COMMENT '原消息 ID（可选）',
  chat_id VARCHAR(64) COMMENT '来源会话 ID',
  chat_name VARCHAR(255) COMMENT '来源会话名称',
  
  -- 内容信息
  type VARCHAR(32) NOT NULL COMMENT '收藏类型：text/image/video/file/link/voice',
  content TEXT COMMENT '收藏内容（文字/URL/文件路径）',
  title VARCHAR(500) COMMENT '标题（链接/文件使用）',
  description TEXT COMMENT '描述信息',
  thumbnail VARCHAR(500) COMMENT '缩略图 URL',
  
  -- 文件信息
  file_name VARCHAR(255) COMMENT '文件名',
  file_size BIGINT COMMENT '文件大小（字节）',
  file_type VARCHAR(100) COMMENT '文件 MIME 类型',
  
  -- 元数据
  extra JSON COMMENT '扩展信息（JSON 格式）',
  tags JSON COMMENT '标签列表',
  
  -- 统计信息
  view_count INT DEFAULT 0 COMMENT '查看次数',
  share_count INT DEFAULT 0 COMMENT '分享次数',
  
  -- 状态
  is_deleted TINYINT DEFAULT 0 COMMENT '是否删除',
  deleted_at TIMESTAMP NULL COMMENT '删除时间',
  
  -- 时间
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- 索引
  INDEX idx_user_id (user_id),
  INDEX idx_type (type),
  INDEX idx_created_at (created_at),
  INDEX idx_chat_id (chat_id),
  FULLTEXT INDEX idx_content (content) COMMENT '全文索引用于搜索'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM 收藏表';
```

#### 收藏数据类型枚举
```java
public enum FavoriteTypeEnum {
    TEXT("text", "文字"),
    IMAGE("image", "图片"),
    VIDEO("video", "视频"),
    FILE("file", "文件"),
    LINK("link", "链接"),
    VOICE("voice", "语音");
    
    private final String code;
    private final String desc;
}
```

#### 前端数据结构
```typescript
interface FavoriteItem {
  id: number
  userId: number
  messageId?: number        // 原消息 ID
  chatId?: string          // 来源会话 ID
  chatName?: string        // 来源会话名称
  
  type: FavoriteType       // 收藏类型
  content: string          // 内容
  title?: string           // 标题
  description?: string     // 描述
  thumbnail?: string       // 缩略图
  
  // 文件信息
  fileName?: string
  fileSize?: number
  fileType?: string
  
  // 元数据
  extra?: Record<string, any>
  tags?: string[]
  
  // 统计
  viewCount: number
  shareCount: number
  
  // 时间
  createTime: number
  updateTime: number
}
```

### 2.2 存储策略

#### 混合存储架构
```
┌─────────────────────────────────────┐
│         收藏内容存储策略             │
├─────────────────────────────────────┤
│ 元数据（MySQL）                     │
│ - 收藏 ID、用户 ID、类型            │
│ - 来源信息、统计信息                │
│ - 创建时间、标签                    │
├─────────────────────────────────────┤
│ 内容存储（根据类型）                │
│ - 文字：直接存储在 content 字段      │
│ - 图片/视频：OSS 对象存储            │
│ - 文件：OSS 对象存储 + CDN 加速       │
│ - 语音：OSS 对象存储                │
│ - 链接：存储 URL，定期抓取快照      │
└─────────────────────────────────────┘
```

#### 存储优化策略
1. **文字内容**：
   - 直接存储在数据库 TEXT 字段
   - 支持全文检索
   - 限制单条最大 10KB

2. **图片/视频/文件/语音**：
   - **复用现有上传工具**：使用 `utils/upload.uts` 中的上传方法
   - **统一存储**：使用现有的 OSS 存储服务
   - **CDN 加速**：利用现有 CDN 配置
   - **文件 ID 模式**：支持 `uploadAndReturnId` 模式

4. **链接**：
   - 存储原始 URL
   - 定期抓取页面标题和描述
   - 生成网页快照（可选）
   - 检测链接失效

### 2.3 API 接口设计

#### 收藏管理接口
```typescript
// 添加收藏
POST /im/favorite/collect
Request:
{
  "messageId": 123456,          // 消息 ID（可选，从消息收藏时必填）
  "chatId": "chat_001",         // 来源会话 ID
  "type": "text",               // 收藏类型
  "content": "会议通知...",     // 收藏内容
  "title": "下午 3 点开会",       // 标题（可选）
  "extra": {}                   // 扩展信息
}
Response:
{
  "code": 200,
  "data": {
    "id": 789,
    "createTime": 1712044800000
  }
}

// 取消收藏
DELETE /im/favorite/{favoriteId}
Response: { "code": 200 }

// 批量取消收藏
POST /im/favorite/batch-delete
Request: { "favoriteIds": [1, 2, 3] }

// 获取收藏列表
GET /im/favorite/list
Query:
{
  "type": "all",        // 类型筛选：all/text/image/...
  "keyword": "会议",    // 关键字搜索
  "pageNo": 1,
  "pageSize": 20
}
Response:
{
  "code": 200,
  "data": {
    "list": [...],
    "total": 100
  }
}

// 更新收藏
PUT /im/favorite/{favoriteId}
Request:
{
  "title": "新的标题",
  "tags": ["工作", "重要"],
  "extra": {}
}

// 获取收藏详情
GET /im/favorite/{favoriteId}
Response: {
  "code": 200,
  "data": { /* FavoriteItem */ }
}
```

#### 搜索接口
```typescript
// 搜索收藏
GET /im/favorite/search
Query:
{
  "keyword": "项目方案",  // 搜索关键字
  "types": ["text", "file"],  // 类型筛选
  "tags": ["工作"],      // 标签筛选
  "dateRange": {        // 时间范围（可选）
    "start": 1712044800000,
    "end": 1712131200000
  },
  "pageNo": 1,
  "pageSize": 20
}

// 智能搜索（支持语义）
GET /im/favorite/smart-search
Query:
{
  "query": "上周的项目文档",  // 自然语言查询
  "userId": 1001
}
```

### 2.4 消息收藏流程

#### 从聊天消息收藏
```
用户长按消息
  ↓
弹出操作菜单（包含"收藏"选项）
  ↓
点击"收藏"
  ↓
前端调用 /im/favorite/collect
  ↓
后端处理：
  1. 验证消息权限
  2. 解析消息内容
  3. 提取元数据（类型、内容、附件等）
  4. 保存到 im_favorites 表
  5. 返回收藏 ID
  ↓
前端显示"已收藏"提示（1 秒）
  ↓
自动隐藏提示
```

#### 代码实现示例
```typescript
// 前端：聊天页面收藏消息
async function collectMessage(message: MessageItem) {
  try {
    const payload = {
      messageId: message.id,
      chatId: message.chatId,
      type: mapMessageTypeToFavorit e(message.type),
      content: extractMessageContent(message),
      title: message.title,
      extra: {
        senderId: message.senderId,
        senderName: message.senderName,
        messageTime: message.time
      }
    }
    
    const result = await request({
      url: '/im/favorite/collect',
      method: 'POST',
      data: payload
    })
    
    uni.showToast({
      title: '已收藏',
      icon: 'success',
      duration: 1000
    })
    
    // 添加到本地缓存（可选）
    addToLocalCache(result.data)
    
  } catch (error) {
    console.error('[CollectMessage] 收藏失败:', error)
    uni.showToast({
      title: '收藏失败',
      icon: 'none'
    })
  }
}

// 后端：收藏服务实现
@Service
public class ImFavoriteServiceImpl implements ImFavoriteService {
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public FavoriteCollectRespVO collect(Long userId, FavoriteCollectReqVO reqVO) {
        // 1. 验证消息权限
        if (reqVO.getMessageId() != null) {
            ImChatMessageDO message = messageMapper.selectById(reqVO.getMessageId());
            if (message == null) {
                throw exception(MESSAGE_NOT_FOUND);
            }
            // 验证用户是否有权收藏该消息
            validateMessagePermission(userId, message);
        }
        
        // 2. 构建收藏记录
        ImFavoriteDO favorite = new ImFavoriteDO();
        favorite.setUserId(userId);
        favorite.setMessageId(reqVO.getMessageId());
        favorite.setChatId(reqVO.getChatId());
        favorite.setChatName(reqVO.getChatName());
        favorite.setType(reqVO.getType());
        favorite.setContent(reqVO.getContent());
        favorite.setTitle(reqVO.getTitle());
        favorite.setExtra(JSON.toJSONString(reqVO.getExtra()));
        
        // 3. 保存到数据库
        favoriteMapper.insert(favorite);
        
        // 4. 返回结果
        return FavoriteCollectRespVO.builder()
                .id(favorite.getId())
                .createTime(favorite.getCreatedAt().getTime())
                .build();
    }
}
```

### 2.5 搜索功能实现

#### 全文检索方案
```sql
-- 方案 1：MySQL 全文索引（推荐，简单场景）
ALTER TABLE im_favorites 
ADD FULLTEXT INDEX idx_content_fulltext (content, title, description);

-- 搜索查询
SELECT * FROM im_favorites
WHERE user_id = 1001
  AND is_deleted = 0
  AND MATCH(content, title, description) AGAINST('项目方案' IN NATURAL LANGUAGE MODE)
ORDER BY created_at DESC;

-- 方案 2：Elasticsearch（复杂场景，可选）
-- 适用于海量数据、复杂搜索场景
```

#### 智能搜索（自然语言处理）
```java
@Service
public class FavoriteSearchService {
    
    /**
     * 解析自然语言查询
     * 例如："上周的项目文档" → 结构化查询条件
     */
    public SearchCondition parseQuery(String query) {
        SearchCondition condition = new SearchCondition();
        
        // 时间识别
        if (query.contains("上周")) {
            condition.setDateRange(getLastWeekRange());
        } else if (query.contains("上月")) {
            condition.setDateRange(getLastMonthRange());
        }
        
        // 类型识别
        if (query.contains("文档") || query.contains("文件")) {
            condition.getTypes().add("file");
        } else if (query.contains("图片") || query.contains("照片")) {
            condition.getTypes().add("image");
        }
        
        // 关键词提取（去除时间、类型词）
        String keyword = extractKeyword(query);
        condition.setKeyword(keyword);
        
        return condition;
    }
}
```

---

## 三、企业级特性设计

### 3.1 权限控制

#### 消息收藏权限
```java
/**
 * 验证消息收藏权限
 */
private void validateMessagePermission(Long userId, ImChatMessageDO message) {
    // 1. 群聊消息：用户必须在群内
    if (message.getGroupId() != null) {
        boolean isInGroup = imContactService.isInGroup(userId, message.getGroupId());
        if (!isInGroup) {
            throw exception(FORBIDDEN);
        }
    }
    
    // 2. 私聊消息：用户必须是参与者
    if (message.getChatId() != null) {
        boolean isParticipant = imChatService.isChatParticipant(userId, message.getChatId());
        if (!isParticipant) {
            throw exception(FORBIDDEN);
        }
    }
    
    // 3. 系统消息：不允许收藏
    if (message.getSystemMessage()) {
        throw exception(SYSTEM_MESSAGE_NOT_ALLOWED);
    }
}
```

#### 收藏内容可见性
```
企业级规则：
- 收藏内容仅自己可见（默认）
```

### 3.2 容量管理

#### 个人收藏容量限制
```java
public class FavoriteQuotaConfig {
    // 普通用户
    public static final int NORMAL_USER_MAX_COUNT = 1000;      // 最多 1000 条
    public static final long NORMAL_USER_MAX_SIZE = 100MB;     // 总大小限制
    
    // VIP 用户
    public static final int VIP_USER_MAX_COUNT = 10000;        // 最多 1 万条
    public static final long VIP_USER_MAX_SIZE = 1GB;          // 总大小限制
    
    // 企业版
    public static final int ENTERPRISE_MAX_COUNT = -1;         // 无限
    public static final long ENTERPRISE_MAX_SIZE = -1;         // 无限
}
```

#### 容量检查
```java
@Override
public void checkQuotaBeforeCollect(Long userId, FavoriteType type, long fileSize) {
    // 1. 检查收藏数量
    int count = favoriteMapper.countByUserId(userId);
    int limit = getUserQuotaLimit(userId);
    if (limit > 0 && count >= limit) {
        throw exception(FAVORITE_COUNT_LIMIT_EXCEEDED);
    }
    
    // 2. 检查总容量
    long totalSize = favoriteMapper.sumFileSizeByUserId(userId);
    long sizeLimit = getUserSizeLimit(userId);
    if (sizeLimit > 0 && totalSize + fileSize > sizeLimit) {
        throw exception(FAVORITE_SIZE_LIMIT_EXCEEDED);
    }
}
```

### 3.3 数据同步

#### 跨端同步机制
```
┌─────────────────────────────────────┐
│         收藏同步架构                │
├─────────────────────────────────────┤
│ 1. 实时同步                         │
│    - WebSocket 推送收藏变更         │
│    - 多端即时更新                   │
├─────────────────────────────────────┤
│ 2. 增量同步                         │
│    - 记录最后同步时间戳             │
│    - 仅同步变更数据                 │
├─────────────────────────────────────┤
│ 3. 冲突处理                         │
│    - 时间戳最新优先                 │
│    - 支持手动合并                   │
└─────────────────────────────────────┘
```

#### WebSocket 推送
```java
/**
 * 推送收藏变更到客户端
 */
public void pushFavoriteUpdate(Long userId, FavoriteUpdateType type, Long favoriteId) {
    // 构建推送消息
    WebSocketMessage wsMessage = WebSocketMessage.builder()
            .type(WebSocketMessageType.FAVORITE_UPDATE)
            .data(FavoriteUpdateMessage.builder()
                .updateType(type)  // ADD/UPDATE/DELETE
                .favoriteId(favoriteId)
                .timestamp(System.currentTimeMillis())
                .build())
            .build();
    
    // 推送到用户的所有在线设备
    sessionManager.sendToUser(userId, wsMessage);
}
```

### 3.4 离职交接

#### 员工离职收藏处理
```java
@Service
public class FavoriteTransferService {
    
    /**
     * 离职员工收藏内容转移
     */
    @Transactional
    public void transferFavorites(Long fromUserId, Long toUserId, TransferConfig config) {
        // 1. 查询离职员工的所有收藏
        List<ImFavoriteDO> favorites = favoriteMapper.selectByUserId(fromUserId);
        
        // 2. 根据配置决定处理方式
        if (config.isDeleteAll()) {
            // 全部删除
            favoriteMapper.deleteByUserId(fromUserId);
        } else if (config.isTransferTo(toUserId)) {
            // 转移给指定员工
            for (ImFavoriteDO favorite : favorites) {
                favorite.setUserId(toUserId);
                favorite.setUpdateTime(LocalDateTime.now());
                favoriteMapper.updateById(favorite);
            }
        } else if (config.isExport()) {
            // 导出为文件
            exportFavoritesToFile(fromUserId, config.getExportPath());
            favoriteMapper.deleteByUserId(fromUserId);
        }
        
        // 3. 记录操作日志
        logTransferOperation(fromUserId, toUserId, config);
    }
}
```

---

## 四、UI/UX 设计

### 4.1 收藏页面布局

```
┌─────────────────────────────────┐
│ ←返回      我的收藏            │
├─────────────────────────────────┤
│ [全部] [文字] [图片] [文件]...  │  ← 分类标签
├─────────────────────────────────┤
│ 🔍 搜索收藏内容...              │  ← 搜索框
├─────────────────────────────────┤
│                                 │
│ ┌─────────────────────────┐    │
│ │ 会议通知                 │    │
│ │ 今天下午 3 点开会...       │    │  ← 文字收藏
│ │ 来自：产品研发团队 2 小时前  │    │
│ └─────────────────────────┘    │
│                                 │
│ ┌─────────────────────────┐    │
│ │ [图片预览]              │    │
│ │ 来自：张敏 5 小时前       │    │  ← 图片收藏
│ └─────────────────────────┘    │
│                                 │
│ ┌─────────────────────────┐    │
│ │ 📄 项目需求文档.docx     │    │
│ │ 1.2MB · 来自：王静      │    │  ← 文件收藏
│ │ 2 天前                   │    │
│ └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

### 4.2 长按操作菜单

```
┌─────────────────────────┐
│ 取消收藏                │
├─────────────────────────┤
│ 发送到...               │
├─────────────────────────┤
│ 添加标签                │
├─────────────────────────┤
│ 编辑                    │
├─────────────────────────┤
│ 分享                    │
├─────────────────────────┤
│ 详情                    │
└─────────────────────────┘
```

### 4.3 搜索页面

```
┌─────────────────────────────────┐
│ ←返回      搜索收藏      🎤     │
├─────────────────────────────────┤
│ [搜索历史]                      │
│ · 项目方案             ✕        │
│ · 会议纪要             ✕        │
│ · 需求文档             ✕        │
├─────────────────────────────────┤
│ [热门标签]                      │
│ #工作  #学习  #重要  #待处理    │
└─────────────────────────────────┘
```

---

## 五、性能优化

### 5.1 缓存策略

#### 多级缓存架构
```
┌─────────────────────────────────────┐
│         收藏缓存架构                │
├─────────────────────────────────────┤
│ L1：本地缓存（LRU）                 │
│ - 最近访问的 50 条收藏              │
│ - 内存缓存，毫秒级访问              │
├─────────────────────────────────────┤
│ L2：Redis 缓存                      │
│ - 用户收藏列表（分页）              │
│ - 收藏详情                          │
│ - 过期时间：30 分钟                 │
├─────────────────────────────────────┤
│ L3：数据库                          │
│ - 持久化存储                        │
│ - 全文索引                          │
└─────────────────────────────────────┘
```

#### Redis 缓存 Key 设计
```java
public class FavoriteCacheKey {
    // 用户收藏列表（分页）
    public static String USER_FAVORITE_LIST = "favorite:list:{userId}:{type}:{page}";
    
    // 收藏详情
    public static String FAVORITE_DETAIL = "favorite:detail:{favoriteId}";
    
    // 用户收藏统计
    public static String USER_FAVORITE_STATS = "favorite:stats:{userId}";
    
    // 搜索缓存
    public static String SEARCH_RESULT = "favorite:search:{userId}:{keyword}:{page}";
}
```

### 5.2 分页加载

#### 游标分页（推荐）
```java
/**
 * 游标分页查询
 */
public PageResult<FavoriteItemVO> getFavoriteList(Long userId, String type, String cursor, int limit) {
    // 游标分页，避免深度分页性能问题
    List<ImFavoriteDO> favorites = favoriteMapper.selectByCursor(
        userId, 
        type, 
        cursor,  // 上一页最后一条的 ID
        limit + 1  // 多查一条判断是否有更多
    );
    
    boolean hasMore = favorites.size() > limit;
    if (hasMore) {
        favorites.remove(favorites.size() - 1);  // 移除多查的一条
    }
    
    String nextCursor = hasMore ? String.valueOf(favorites.get(favorites.size() - 1).getId()) : null;
    
    return PageResult.<FavoriteItemVO>builder()
            .list(convertToVO(favorites))
            .nextCursor(nextCursor)
            .hasMore(hasMore)
            .build();
}
```

### 5.3 图片优化

#### 缩略图生成
```java
/**
 * 生成图片缩略图
 */
public String generateThumbnail(String imageUrl, int width, int height) {
    // OSS 自动处理（推荐）
    // https://oss.example.com/image.jpg?x-oss-process=image/resize,w_200,h_200
    
    String thumbnailUrl = imageUrl + 
        "?x-oss-process=image/resize,w_" + width + ",h_" + height + 
        "/format,webp";  // 转换为 WebP 格式
    
    return thumbnailUrl;
}
```

---

## 六、数据统计与分析

### 6.1 收藏行为分析

```sql
-- 收藏类型分布
SELECT type, COUNT(*) as count 
FROM im_favorites 
WHERE user_id = 1001 AND is_deleted = 0
GROUP BY type;

-- 收藏时间趋势
SELECT DATE_FORMAT(created_at, '%Y-%m-%d') as date, COUNT(*) as count
FROM im_favorites
WHERE user_id = 1001 AND is_deleted = 0
GROUP BY date
ORDER BY date DESC
LIMIT 30;

-- 热门搜索词
SELECT keyword, COUNT(*) as search_count
FROM favorite_search_log
WHERE user_id = 1001
GROUP BY keyword
ORDER BY search_count DESC
LIMIT 20;
```

### 6.2 企业知识图谱

通过分析收藏数据，构建企业知识图谱：
- 热门收藏内容识别
- 知识传播路径分析
- 专家识别（被收藏最多的内容作者）
- 知识盲区发现

---

## 七、安全与合规

### 7.1 数据安全

1. **传输加密**：HTTPS + TLS 1.3
2. **存储加密**：AES-256 加密存储
3. **访问控制**：RBAC 权限模型
4. **审计日志**：记录所有收藏操作

### 7.2 隐私保护

1. **收藏内容仅自己可见**（默认）
2. **支持设置可见范围**（个人/团队）
3. **离职自动处理**（转移/删除/导出）
4. **GDPR 合规**：支持数据导出和删除

### 7.3 内容审核

```java
/**
 * 收藏内容审核
 */
public void auditFavoriteContent(ImFavoriteDO favorite) {
    // 1. 敏感词检测
    if (sensitiveWordFilter.contains(favorite.getContent())) {
        favorite.setStatus(FavoriteStatus.AUDIT_FAILED);
        favorite.setAuditReason("包含敏感词");
        return;
    }
    
    // 2. 图片鉴黄（可选）
    if ("image".equals(favorite.getType())) {
        ImageAuditResult result = imageAuditService.audit(favorite.getContent());
        if (!result.isPass()) {
            favorite.setStatus(FavoriteStatus.AUDIT_FAILED);
            favorite.setAuditReason(result.getReason());
            return;
        }
    }
    
    // 3. 审核通过
    favorite.setStatus(FavoriteStatus.NORMAL);
}
```

---

## 八、验收标准

### 8.1 功能验收

- [ ] 支持收藏文字、图片、文件、语音、视频、链接
- [ ] 支持分类筛选和搜索
- [ ] 支持批量删除
- [ ] 支持转发到聊天
- [ ] 支持添加标签
- [ ] 跨端同步正常
- [ ] 容量限制生效
- [ ] 权限控制正确

### 8.2 性能验收

- [ ] 收藏操作响应时间 < 300ms
- [ ] 列表加载时间 < 500ms
- [ ] 搜索响应时间 < 1s
- [ ] 并发收藏成功率 > 99%

### 8.3 兼容性验收

- [ ] App 端（Android/iOS）正常
- [ ] H5 端正常
- [ ] Web 端正常
- [ ] 多端同步正常

---

## 九、参考资料

- [微信收藏功能设计](https://developers.weixin.qq.com/doc/)
- [企业微信「群精华」功能](https://qiwei.huawan.com/news/3760.html)
- [钉钉收藏功能](https://www.dingtalk.com/)
- [环信 IM 消息收藏实现](https://www.easemob.com/news/26026)
- [Elasticsearch 全文检索](https://www.elastic.co/guide/index.html)

---

**文档版本**：v2.0  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
