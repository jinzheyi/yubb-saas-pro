# IM 即时通讯 - 收藏功能开发任务清单 v2.0

## 任务概述

**任务目标**：实现企业级 IM 收藏功能，支持消息收藏、分类管理、搜索检索、跨端同步

**优先级**：高

**预计工期**：15 人天（3 周）

**技术选型**：
- 存储方案：MySQL（元数据）+ OSS（文件）
- 搜索方案：简单 LIKE 搜索（一期）+ 全文索引（二期可选）

**核心策略**：充分利用现有消息框架，新增收藏服务模块

---

## 现有可复用资源

### 前端可复用组件
1. **收藏页面**
   - 文件：`pages/profile/favorites.uvue`
   - 功能：收藏列表展示、分类筛选
   - 复用方式：已有 UI 框架，需集成真实 API
   - 状态：✅ 已存在（需完善）

2. **消息长按菜单**
   - 位置：`pages/message/chat.uvue`
   - 功能：消息操作菜单
   - 复用方式：添加"收藏"选项
   - 状态：⚠️ 需扩展

3. **上传工具**
   - 文件：`utils/upload.uts`
   - 功能：文件上传（图片、视频、文件）
   - 复用方式：直接调用 `uploadFile`、`uploadFileAndReturnId` 等方法
   - 状态：✅ 已存在

### 后端可复用服务
1. **表情收藏服务**
   - 文件：`ImStickerService.java`
   - 功能：表情收藏逻辑
   - 复用方式：参考其设计模式
   - 状态：✅ 可参考

2. **消息服务**
   - 文件：`ImMessageService.java`
   - 功能：消息查询、权限验证
   - 复用方式：直接调用
   - 状态：✅ 已存在

### 后端可复用接口
1. **消息查询接口**
   - 文件：`AppImMessageController.java`
   - 接口：`/im/message/detail`
   - 状态：✅ 已存在

2. **文件上传服务**
   - 文件：`FileServiceImpl.java`
   - 接口：`/infra/file/upload`, `/infra/file/upload-and-return-id`
   - 状态：✅ 已存在

3. **群文件服务**
   - 文件：`ImGroupFileServiceImpl.java`
   - 接口：`/system/im/group/file/upload`
   - 状态：✅ 已存在

---

## 开发任务分解

### 阶段一：数据库设计与基础框架（2 人天）

#### 任务 1.1：数据库表设计
- **负责人**：后端开发
- **完成时间**：Day 1 上午
- **任务详情**：
  1. 设计 `im_favorites` 表结构
  2. 设计索引（包含全文索引）
  3. 编写数据库迁移脚本
- **SQL 脚本**：
```sql
-- 收藏表
CREATE TABLE im_favorites (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL COMMENT '用户 ID',
  message_id BIGINT COMMENT '原消息 ID',
  chat_id VARCHAR(64) COMMENT '来源会话 ID',
  chat_name VARCHAR(255) COMMENT '来源会话名称',
  type VARCHAR(32) NOT NULL COMMENT '收藏类型',
  content TEXT COMMENT '收藏内容',
  title VARCHAR(500) COMMENT '标题',
  description TEXT COMMENT '描述',
  thumbnail VARCHAR(500) COMMENT '缩略图',
  file_name VARCHAR(255) COMMENT '文件名',
  file_size BIGINT COMMENT '文件大小',
  file_type VARCHAR(100) COMMENT '文件 MIME 类型',
  extra JSON COMMENT '扩展信息',
  tags JSON COMMENT '标签列表',
  view_count INT DEFAULT 0 COMMENT '查看次数',
  share_count INT DEFAULT 0 COMMENT '分享次数',
  is_deleted TINYINT DEFAULT 0 COMMENT '是否删除',
  deleted_at TIMESTAMP NULL COMMENT '删除时间',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_type (type),
  INDEX idx_created_at (created_at),
  INDEX idx_chat_id (chat_id),
  FULLTEXT INDEX idx_content_fulltext (content, title, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM 收藏表';

-- 收藏标签表（可选，支持多标签）
CREATE TABLE im_favorite_tags (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  tag_name VARCHAR(50) NOT NULL,
  tag_color VARCHAR(20) COMMENT '标签颜色',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_user_tag (user_id, tag_name),
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏标签表';
```
- **交付物**：
  - 数据库表结构
  - 迁移脚本
  - 数据字典文档

#### 任务 1.2：实体类与 Mapper
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 创建 `ImFavoriteDO.java` 实体类
  2. 创建 `ImFavoriteMapper.java` 接口
  3. 创建 `ImFavoriteMapper.xml` SQL 映射文件
  4. 创建 `ImFavoriteTagDO.java` 标签实体
- **代码示例**：
```java
@Data
@TableName("im_favorites")
@Schema(description = "IM 收藏记录")
public class ImFavoriteDO {
    
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    
    @TableField("user_id")
    private Long userId;
    
    @TableField("message_id")
    private Long messageId;
    
    @TableField("chat_id")
    private String chatId;
    
    @TableField("chat_name")
    private String chatName;
    
    @TableField("type")
    private String type;
    
    @TableField("content")
    private String content;
    
    @TableField("title")
    private String title;
    
    @TableField("extra")
    private String extra;
    
    @TableField("tags")
    private String tags;
    
    @TableField("view_count")
    private Integer viewCount;
    
    @TableField("share_count")
    private Integer shareCount;
    
    @TableField("is_deleted")
    private Boolean deleted;
    
    @TableField("deleted_at")
    private LocalDateTime deletedAt;
    
    @TableField("created_at")
    private LocalDateTime createdAt;
    
    @TableField("updated_at")
    private LocalDateTime updatedAt;
}

// Mapper 接口
public interface ImFavoriteMapper extends BaseMapper<ImFavoriteDO> {
    
    /**
     * 游标分页查询收藏列表
     */
    List<ImFavoriteDO> selectByCursor(
        @Param("userId") Long userId,
        @Param("type") String type,
        @Param("cursor") Long cursor,
        @Param("limit") int limit
    );
    
    /**
     * 全文搜索收藏
     */
    List<ImFavoriteDO> searchByKeyword(
        @Param("userId") Long userId,
        @Param("keyword") String keyword
    );
    
    /**
     * 统计用户收藏数量
     */
    Integer countByUserId(@Param("userId") Long userId);
}
```
- **交付物**：
  - 实体类
  - Mapper 接口和 XML
  - 单元测试

#### 任务 1.3：VO 对象定义
- **负责人**：后端开发
- **完成时间**：Day 1 下午
- **任务详情**：
  1. 创建请求 VO：`FavoriteCollectReqVO`, `FavoriteListReqVO` 等
  2. 创建响应 VO：`FavoriteItemVO`, `FavoriteListRespVO` 等
  3. 确保 VO 与 DO 的转换关系
- **代码示例**：
```java
@Schema(description = "收藏请求 VO")
@Data
public class FavoriteCollectReqVO {
    
    @ApiModelProperty(value = "消息 ID", example = "123456")
    private Long messageId;
    
    @ApiModelProperty(value = "会话 ID", required = true, example = "chat_001")
    private String chatId;
    
    @ApiModelProperty(value = "会话名称", example = "产品研发团队")
    private String chatName;
    
    @ApiModelProperty(value = "收藏类型", required = true, example = "text")
    private String type;
    
    @ApiModelProperty(value = "收藏内容", required = true)
    private String content;
    
    @ApiModelProperty(value = "标题", example = "会议通知")
    private String title;
    
    @ApiModelProperty(value = "扩展信息")
    private Map<String, Object> extra;
}

@Schema(description = "收藏列表项 VO")
@Data
public class FavoriteItemVO {
    
    @ApiModelProperty(value = "收藏 ID", example = "789")
    private Long id;
    
    @ApiModelProperty(value = "收藏类型", example = "text")
    private String type;
    
    @ApiModelProperty(value = "收藏内容")
    private String content;
    
    @ApiModelProperty(value = "标题", example = "会议通知")
    private String title;
    
    @ApiModelProperty(value = "缩略图 URL")
    private String thumbnail;
    
    @ApiModelProperty(value = "来源会话名称")
    private String chatName;
    
    @ApiModelProperty(value = "创建时间戳", example = "1712044800000")
    private Long createTime;
    
    @ApiModelProperty(value = "查看次数", example = "5")
    private Integer viewCount;
}
```
- **交付物**：
  - 请求 VO 类
  - 响应 VO 类

---

### 阶段二：后端收藏服务（3 人天）

#### 任务 2.1：收藏服务接口定义
- **负责人**：后端开发
- **完成时间**：Day 2 上午
- **任务详情**：
  1. 创建 `ImFavoriteService.java` 接口
  2. 定义收藏管理方法
  3. 定义搜索方法
  4. 定义统计方法
- **接口定义**：
```java
public interface ImFavoriteService {
    
    /**
     * 收藏消息
     */
    FavoriteCollectRespVO collect(Long userId, FavoriteCollectReqVO reqVO);
    
    /**
     * 取消收藏
     */
    void uncollect(Long userId, Long favoriteId);
    
    /**
     * 批量取消收藏
     */
    void batchUncollect(Long userId, List<Long> favoriteIds);
    
    /**
     * 获取收藏列表
     */
    PageResult<FavoriteItemVO> getFavoriteList(Long userId, FavoriteListReqVO reqVO);
    
    /**
     * 获取收藏详情
     */
    FavoriteItemVO getFavoriteDetail(Long userId, Long favoriteId);
    
    /**
     * 更新收藏
     */
    void updateFavorite(Long userId, FavoriteUpdateReqVO reqVO);
    
    /**
     * 搜索收藏
     */
    PageResult<FavoriteItemVO> searchFavorites(Long userId, FavoriteSearchReqVO reqVO);
    
    /**
     * 统计收藏数量
     */
    FavoriteStatsVO getFavoriteStats(Long userId);
    
    /**
     * 容量检查
     */
    void checkQuota(Long userId, String type, long fileSize);
}
```
- **交付物**：
  - 服务接口
  - JavaDoc 文档

#### 任务 2.2：收藏服务实现
- **负责人**：后端开发
- **完成时间**：Day 2 下午 - Day 3
- **任务详情**：
  1. 实现收藏逻辑（包含权限验证）
  2. 实现取消收藏逻辑
  3. 实现收藏列表查询（游标分页）
  4. 实现搜索功能（全文检索）
  5. 实现容量检查
  6. 添加缓存支持
- **核心实现**：
```java
@Service
@Slf4j
@RequiredArgsConstructor
public class ImFavoriteServiceImpl implements ImFavoriteService {
    
    private final ImFavoriteMapper favoriteMapper;
    private final ImMessageService messageService;
    private final ImContactService imContactService;
    private final RedisTemplate<String, Object> redisTemplate;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public FavoriteCollectRespVO collect(Long userId, FavoriteCollectReqVO reqVO) {
        // 1. 容量检查
        checkQuota(userId, reqVO.getType(), 0);
        
        // 2. 验证消息权限（如果是从消息收藏）
        if (reqVO.getMessageId() != null) {
            validateMessagePermission(userId, reqVO.getMessageId());
        }
        
        // 3. 构建收藏记录
        ImFavoriteDO favorite = buildFavoriteDO(userId, reqVO);
        
        // 4. 保存到数据库
        favoriteMapper.insert(favorite);
        
        // 5. 清除缓存
        clearFavoriteListCache(userId, reqVO.getType());
        
        // 6. 推送 WebSocket 通知
        pushFavoriteUpdate(userId, FavoriteUpdateType.ADD, favorite.getId());
        
        // 7. 返回结果
        return FavoriteCollectRespVO.builder()
                .id(favorite.getId())
                .createTime(favorite.getCreatedAt().toInstant(ZoneOffset.UTC).toEpochMilli())
                .build();
    }
    
    @Override
    public PageResult<FavoriteItemVO> getFavoriteList(Long userId, FavoriteListReqVO reqVO) {
        // 1. 尝试从缓存获取
        String cacheKey = buildCacheKey(userId, reqVO.getType(), reqVO.getPageNo());
        PageResult<FavoriteItemVO> cached = getCachedList(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        // 2. 游标分页查询
        Long cursor = calculateCursor(reqVO.getPageNo(), reqVO.getPageSize());
        List<ImFavoriteDO> favorites = favoriteMapper.selectByCursor(
            userId, 
            reqVO.getType(), 
            cursor, 
            reqVO.getPageSize() + 1
        );
        
        // 3. 判断是否有更多
        boolean hasMore = favorites.size() > reqVO.getPageSize();
        if (hasMore) {
            favorites.remove(favorites.size() - 1);
        }
        
        // 4. 转换为 VO
        List<FavoriteItemVO> voList = favorites.stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());
        
        // 5. 缓存结果
        cacheResult(cacheKey, voList, hasMore);
        
        return PageResult.<FavoriteItemVO>builder()
                .list(voList)
                .hasMore(hasMore)
                .build();
    }
    
    /**
     * 验证消息权限
     */
    private void validateMessagePermission(Long userId, Long messageId) {
        ImChatMessageDO message = messageService.getMessageById(messageId);
        if (message == null) {
            throw exception(MESSAGE_NOT_FOUND);
        }
        
        // 群聊消息：用户必须在群内
        if (message.getGroupId() != null) {
            boolean isInGroup = imContactService.isInGroup(userId, message.getGroupId());
            if (!isInGroup) {
                throw exception(FORBIDDEN);
            }
        }
        
        // 私聊消息：用户必须是参与者
        if (message.getChatId() != null) {
            boolean isParticipant = message.getSenderId().equals(userId) || 
                                   message.getReceiverId().equals(userId);
            if (!isParticipant) {
                throw exception(FORBIDDEN);
            }
        }
    }
    
    /**
     * 容量检查
     */
    private void checkQuota(Long userId, String type, long fileSize) {
        // 检查收藏数量
        int count = favoriteMapper.countByUserId(userId);
        int limit = getUserQuotaLimit(userId);  // 根据用户等级获取限制
        if (limit > 0 && count >= limit) {
            throw exception(FAVORITE_COUNT_LIMIT_EXCEEDED);
        }
        
        // 检查总容量（针对文件类型）
        if ("file".equals(type) || "image".equals(type) || "video".equals(type)) {
            long totalSize = favoriteMapper.sumFileSizeByUserId(userId);
            long sizeLimit = getUserSizeLimit(userId);
            if (sizeLimit > 0 && totalSize + fileSize > sizeLimit) {
                throw exception(FAVORITE_SIZE_LIMIT_EXCEEDED);
            }
        }
    }
}
```
- **交付物**：
  - 服务实现类
  - 单元测试
  - 集成测试

#### 任务 2.3：容量配置管理
- **负责人**：后端开发
- **完成时间**：Day 3 下午
- **任务详情**：
  1. 创建容量配置类
  2. 支持按用户等级配置
  3. 支持动态调整
- **配置类**：
```java
@Configuration
@ConfigurationProperties(prefix = "favorite.quota")
public class FavoriteQuotaProperties {
    
    /**
     * 普通用户收藏数量限制
     */
    private int normalUserMaxCount = 1000;
    
    /**
     * 普通用户容量限制（字节）
     */
    private long normalUserMaxSize = 104857600; // 100MB
    
    /**
     * VIP 用户收藏数量限制
     */
    private int vipUserMaxCount = 10000;
    
    /**
     * VIP 用户容量限制
     */
    private long vipUserMaxSize = 1073741824; // 1GB
    
    /**
     * 企业版限制（-1 表示无限）
     */
    private int enterpriseMaxCount = -1;
    private long enterpriseMaxSize = -1;
    
    // Getters and Setters
}
```
- **交付物**：
  - 配置类
  - 配置文档

---

### 阶段三：REST API 开发（2 人天）

#### 任务 3.1：收藏管理 Controller
- **负责人**：后端开发
- **完成时间**：Day 4 上午
- **任务详情**：
  1. 创建 `AppImFavoriteController.java`
  2. 实现收藏管理 REST API
  3. 添加 Swagger 文档
- **Controller 示例**：
```java
@RestController
@RequestMapping("/im/favorite")
@Validated
public class AppImFavoriteController {
    
    @Resource
    private ImFavoriteService favoriteService;
    
    /**
     * 收藏消息
     */
    @PostMapping("/collect")
    @ApiOperation("收藏消息")
    public CommonResult<FavoriteCollectRespVO> collect(
            @LoginUserId Long userId,
            @RequestBody @Valid FavoriteCollectReqVO reqVO) {
        return success(favoriteService.collect(userId, reqVO));
    }
    
    /**
     * 取消收藏
     */
    @DeleteMapping("/{favoriteId}")
    @ApiOperation("取消收藏")
    public CommonResult<Boolean> uncollect(
            @LoginUserId Long userId,
            @PathVariable Long favoriteId) {
        favoriteService.uncollect(userId, favoriteId);
        return success(true);
    }
    
    /**
     * 批量取消收藏
     */
    @PostMapping("/batch-delete")
    @ApiOperation("批量取消收藏")
    public CommonResult<Boolean> batchUncollect(
            @LoginUserId Long userId,
            @RequestBody List<Long> favoriteIds) {
        favoriteService.batchUncollect(userId, favoriteIds);
        return success(true);
    }
    
    /**
     * 获取收藏列表
     */
    @GetMapping("/list")
    @ApiOperation("获取收藏列表")
    public CommonResult<PageResult<FavoriteItemVO>> getFavoriteList(
            @LoginUserId Long userId,
            @Valid FavoriteListReqVO reqVO) {
        return success(favoriteService.getFavoriteList(userId, reqVO));
    }
    
    /**
     * 获取收藏详情
     */
    @GetMapping("/{favoriteId}")
    @ApiOperation("获取收藏详情")
    public CommonResult<FavoriteItemVO> getFavoriteDetail(
            @LoginUserId Long userId,
            @PathVariable Long favoriteId) {
        return success(favoriteService.getFavoriteDetail(userId, favoriteId));
    }
    
    /**
     * 更新收藏
     */
    @PutMapping("/{favoriteId}")
    @ApiOperation("更新收藏")
    public CommonResult<Boolean> updateFavorite(
            @LoginUserId Long userId,
            @PathVariable Long favoriteId,
            @RequestBody @Valid FavoriteUpdateReqVO reqVO) {
        favoriteService.updateFavorite(userId, reqVO);
        return success(true);
    }
    
    /**
     * 搜索收藏
     */
    @GetMapping("/search")
    @ApiOperation("搜索收藏")
    public CommonResult<PageResult<FavoriteItemVO>> searchFavorites(
            @LoginUserId Long userId,
            @Valid FavoriteSearchReqVO reqVO) {
        return success(favoriteService.searchFavorites(userId, reqVO));
    }
    
    /**
     * 获取收藏统计
     */
    @GetMapping("/stats")
    @ApiOperation("获取收藏统计")
    public CommonResult<FavoriteStatsVO> getFavoriteStats(
            @LoginUserId Long userId) {
        return success(favoriteService.getFavoriteStats(userId));
    }
}
```
- **交付物**：
  - Controller 类
  - API 文档（Swagger）
  - 接口测试用例

#### 任务 3.2：异常处理
- **负责人**：后端开发
- **完成时间**：Day 4 下午
- **任务详情**：
  1. 定义收藏相关异常码
  2. 创建异常类
  3. 添加全局异常处理
- **异常码定义**：
```java
public interface ErrorCodeConstants {
    
    // 收藏相关异常码 300100-300199
    int FAVORITE_NOT_FOUND = 300100;
    int FAVORITE_COUNT_LIMIT_EXCEEDED = 300101;
    int FAVORITE_SIZE_LIMIT_EXCEEDED = 300102;
    int FAVORITE_PERMISSION_DENIED = 300103;
    int FAVORITE_DUPLICATE = 300104;
    int FAVORITE_CONTENT_INVALID = 300105;
    
}
```
- **交付物**：
  - 异常码定义
  - 异常处理类

---

（文档继续...）

---

### 阶段四：前端开发（5 人天）

#### 任务 4.1：聊天页面收藏入口
- **负责人**：前端开发
- **完成时间**：Day 5 上午
- **任务详情**：
  1. 在 `chat.uvue` 的消息长按菜单中添加"收藏"选项
  2. 实现收藏消息的调用逻辑
  3. 处理收藏成功/失败的 UI 反馈
- **代码示例**：
```vue
<!-- 消息长按菜单 -->
<view class="message-context-menu" v-if="showContextMenu">
  <view class="menu-item" @click="handleCopy">复制</view>
  <view class="menu-item" @click="handleForward">转发</view>
  <view class="menu-item" @click="handleCollect">收藏</view>
  <view class="menu-item" @click="handleRecall">撤回</view>
  <view class="menu-item" @click="handleDelete">删除</view>
</view>

<script setup lang="uts">
// 处理收藏
async function handleCollect() {
  const message = contextMenuMessage.value
  
  try {
    const payload = {
      messageId: message.id,
      chatId: message.chatId,
      chatName: message.chatName,
      type: mapMessageTypeToFavorit e(message.type),
      content: extractMessageContent(message),
      title: message.title,
      extra: {
        senderId: message.senderId,
        senderName: message.senderName,
        messageTime: message.time
      }
    }
    
    await request({
      url: '/im/favorite/collect',
      method: 'POST',
      data: payload
    })
    
    uni.showToast({
      title: '已收藏',
      icon: 'success',
      duration: 1000
    })
    
    hideContextMenu()
    
  } catch (error) {
    console.error('[CollectMessage] 收藏失败:', error)
    uni.showToast({
      title: '收藏失败',
      icon: 'none'
    })
  }
}

// 消息类型映射
function mapMessageTypeToFavorit e(messageType: string): string {
  const typeMap = {
    'text': 'text',
    'image': 'image',
    'video': 'video',
    'file': 'file',
    'voice': 'voice',
    'link': 'link'
  }
  return typeMap[messageType] || 'text'
}

// 提取消息内容
function extractMessageContent(message: MessageItem): string {
  switch (message.type) {
    case 'text':
      return message.content
    case 'image':
      return message.imageUrl
    case 'video':
      return message.videoUrl
    case 'file':
      return message.fileUrl
    case 'voice':
      return message.voiceUrl
    case 'link':
      return message.linkUrl
    default:
      return message.content || ''
  }
}
</script>
```
- **交付物**：
  - 消息长按菜单扩展
  - 收藏调用逻辑

#### 任务 4.2：收藏页面完善
- **负责人**：前端开发
- **完成时间**：Day 5 下午 - Day 6
- **任务详情**：
  1. 完善 `favorites.uvue` 页面（已有框架，需集成真实 API）
  2. 实现收藏列表加载（分页）
  3. 实现分类筛选
  4. 实现搜索功能
  5. 实现批量操作
- **核心实现**：
```vue
<script setup lang="uts">
import { useI18n } from '../../hooks/useI18n.uts'
import { getFavoriteList, uncollectFavorite, batchUncollect } from '../../api/favorite.uts'

const { t } = useI18n()

const currentTab = ref('all')
const pageNo = ref(1)
const pageSize = ref(20)
const favoriteList = ref<any[]>([])
const hasMore = ref(true)
const loading = ref(false)

// 加载收藏列表
async function loadFavorites(reset = false) {
  if (loading.value) return
  if (reset) {
    pageNo.value = 1
    favoriteList.value = []
  }
  
  loading.value = true
  
  try {
    const result = await getFavoriteList({
      type: currentTab.value,
      pageNo: pageNo.value,
      pageSize: pageSize.value
    })
    
    if (reset) {
      favoriteList.value = result.list
    } else {
      favoriteList.value = [...favoriteList.value, ...result.list]
    }
    
    hasMore.value = result.hasMore
    pageNo.value++
    
  } catch (error) {
    console.error('[LoadFavorites] 加载失败:', error)
    uni.showToast({
      title: '加载失败',
      icon: 'none'
    })
  } finally {
    loading.value = false
  }
}

// 切换分类
function switchTab(type: string) {
  currentTab.value = type
  loadFavorites(true)
}

// 取消收藏
async function handleUncollect(item: any) {
  uni.showModal({
    title: '提示',
    content: '确定取消收藏吗？',
    success: async (res) => {
      if (res.confirm) {
        try {
          await uncollectFavorite(item.id)
          uni.showToast({
            title: '已取消收藏',
            icon: 'success'
          })
          loadFavorites(true)
        } catch (error) {
          uni.showToast({
            title: '操作失败',
            icon: 'none'
          })
        }
      }
    }
  })
}

// 批量删除
async function handleBatchDelete() {
  // 实现批量选择 UI 和逻辑
}

// 搜索收藏
async function searchFavorites(keyword: string) {
  uni.navigateTo({
    url: `/pages/profile/favorite-search?keyword=${keyword}`
  })
}

// 初始化
onMounted(() => {
  loadFavorites()
})
</script>
```
- **交付物**：
  - 收藏列表页面
  - 分类筛选功能
  - 搜索入口

#### 任务 4.3：收藏详情页面
- **负责人**：前端开发
- **完成时间**：Day 7 上午
- **任务详情**：
  1. 创建 `favorite-detail.uvue` 页面
  2. 根据类型展示不同内容（文字、图片、文件、视频等）
  3. 实现转发、编辑、删除等操作
- **页面结构**：
```vue
<template>
  <view class="page">
    <view class="status-bar"></view>
    <view class="header">
      <view class="header-left" @click="handleBack">
        <text class="iconfont">&#xeb04;</text>
        <text class="back-text">{{ t('common.back') }}</text>
      </view>
      <text class="header-title">收藏详情</text>
      <view class="header-right" @click="handleMore">
        <text class="iconfont">&#xe620;</text>
      </view>
    </view>
    
    <scroll-view class="content" scroll-y>
      <!-- 文字类型 -->
      <view v-if="favorite.type === 'text'" class="detail-text">
        <text class="text-content">{{ favorite.content }}</text>
      </view>
      
      <!-- 图片类型 -->
      <view v-else-if="favorite.type === 'image'" class="detail-image">
        <image class="image-full" :src="favorite.content" mode="widthFix" />
      </view>
      
      <!-- 视频类型 -->
      <view v-else-if="favorite.type === 'video'" class="detail-video">
        <video class="video-full" :src="favorite.content" controls />
      </view>
      
      <!-- 文件类型 -->
      <view v-else-if="favorite.type === 'file'" class="detail-file">
        <view class="file-icon-wrap">
          <text class="iconfont file-icon">&#xea96;</text>
        </view>
        <view class="file-info">
          <text class="file-name">{{ favorite.fileName }}</text>
          <text class="file-size">{{ formatFileSize(favorite.fileSize) }}</text>
        </view>
        <button class="download-btn" @click="handleDownload">下载</button>
      </view>
      
      <!-- 链接类型 -->
      <view v-else-if="favorite.type === 'link'" class="detail-link">
        <text class="link-title">{{ favorite.title }}</text>
        <text class="link-url">{{ favorite.content }}</text>
        <button class="open-btn" @click="handleOpenLink">打开链接</button>
      </view>
      
      <!-- 元信息 -->
      <view class="meta-info">
        <text class="meta-label">来自</text>
        <text class="meta-value">{{ favorite.chatName }}</text>
      </view>
      <view class="meta-info">
        <text class="meta-label">时间</text>
        <text class="meta-value">{{ formatTime(favorite.createTime) }}</text>
      </view>
    </scroll-view>
    
    <!-- 底部操作栏 -->
    <view class="action-bar">
      <button class="action-btn" @click="handleForward">转发</button>
      <button class="action-btn" @click="handleEdit">编辑</button>
      <button class="action-btn danger" @click="handleDelete">删除</button>
    </view>
  </view>
</template>
```
- **交付物**：
  - 收藏详情页面
  - 各类型内容展示
  - 操作功能

#### 任务 4.4：搜索页面
- **负责人**：前端开发
- **完成时间**：Day 7 下午
- **任务详情**：
  1. 创建 `favorite-search.uvue` 页面
  2. 实现搜索框和搜索历史
  3. 实现搜索结果展示
  4. 实现热门标签
- **交付物**：
  - 搜索页面
  - 搜索历史功能

#### 任务 4.5：API 封装
- **负责人**：前端开发
- **完成时间**：Day 8 上午
- **任务详情**：
  1. 创建 `api/favorite.uts`
  2. 封装所有收藏相关 API
  3. 添加错误处理
- **API 封装**：
```typescript
// api/favorite.uts
import { request } from '../utils/request.uts'

/**
 * 收藏消息
 */
export function collectMessage(data: CollectMessageReq): Promise<CollectMessageResp> {
  return request({
    url: '/im/favorite/collect',
    method: 'POST',
    data
  })
}

/**
 * 取消收藏
 */
export function uncollectFavorite(favoriteId: number): Promise<void> {
  return request({
    url: `/im/favorite/${favoriteId}`,
    method: 'DELETE'
  })
}

/**
 * 批量取消收藏
 */
export function batchUncollect(favoriteIds: number[]): Promise<void> {
  return request({
    url: '/im/favorite/batch-delete',
    method: 'POST',
    data: { favoriteIds }
  })
}

/**
 * 获取收藏列表
 */
export function getFavoriteList(params: FavoriteListReq): Promise<PageResult<FavoriteItemVO>> {
  return request({
    url: '/im/favorite/list',
    method: 'GET',
    params
  })
}

/**
 * 获取收藏详情
 */
export function getFavoriteDetail(favoriteId: number): Promise<FavoriteItemVO> {
  return request({
    url: `/im/favorite/${favoriteId}`,
    method: 'GET'
  })
}

/**
 * 更新收藏
 */
export function updateFavorite(favoriteId: number, data: UpdateFavoriteReq): Promise<void> {
  return request({
    url: `/im/favorite/${favoriteId}`,
    method: 'PUT',
    data
  })
}

/**
 * 搜索收藏
 */
export function searchFavorites(params: FavoriteSearchReq): Promise<PageResult<FavoriteItemVO>> {
  return request({
    url: '/im/favorite/search',
    method: 'GET',
    params
  })
}

/**
 * 获取收藏统计
 */
export function getFavoriteStats(): Promise<FavoriteStatsVO> {
  return request({
    url: '/im/favorite/stats',
    method: 'GET'
  })
}
```
- **交付物**：
  - API 封装文件
  - 类型定义

---

### 阶段五：缓存与优化（2 人天）

#### 任务 5.1：Redis 缓存实现
- **负责人**：后端开发
- **完成时间**：Day 8 下午 - Day 9 上午
- **任务详情**：
  1. 实现收藏列表 Redis 缓存
  2. 实现收藏详情缓存
  3. 实现缓存更新和失效
  4. 添加缓存监控
- **交付物**：
  - 缓存实现
  - 缓存策略文档

#### 任务 5.2：性能优化
- **负责人**：后端开发
- **完成时间**：Day 9 下午
- **任务详情**：
  1. 数据库查询优化（索引、SQL 优化）
  2. 分页性能优化（游标分页）
  3. 图片缩略图优化
  4. 文件 CDN 加速
- **交付物**：
  - 性能优化报告
  - 压测报告

---

### 阶段六：联调测试（3 人天）

#### 任务 6.1：功能测试
- **负责人**：测试工程师
- **完成时间**：Day 10 上午
- **测试用例**：
  1. [ ] 从聊天消息收藏（文字、图片、文件、视频、语音、链接）
  2. [ ] 查看收藏列表（全部分类）
  3. [ ] 分类筛选功能
  4. [ ] 搜索收藏功能
  5. [ ] 取消收藏（单个/批量）
  6. [ ] 收藏详情查看
  7. [ ] 收藏转发功能
  8. [ ] 收藏编辑功能
- **Bug 修复**：
  - 前端开发负责修复 UI 问题
  - 后端开发负责修复接口问题

#### 任务 6.2：权限测试
- **负责人**：测试工程师
- **完成时间**：Day 10 下午
- **测试用例**：
  1. [ ] 只能收藏自己有权限的消息
  2. [ ] 群聊消息：非群成员无法收藏
  3. [ ] 私聊消息：非参与者无法收藏
  4. [ ] 收藏内容仅自己可见
  5. [ ] 容量限制生效

#### 任务 6.3：性能测试
- **负责人**：测试工程师
- **完成时间**：Day 11 上午
- **测试指标**：
  1. [ ] 收藏操作响应时间 < 300ms
  2. [ ] 列表加载时间 < 500ms
  3. [ ] 搜索响应时间 < 1s
  4. [ ] 并发收藏成功率 > 99%
  5. [ ] 缓存命中率 > 80%

#### 任务 6.4：兼容性测试
- **负责人**：测试工程师
- **完成时间**：Day 11 下午
- **测试平台**：
  1. [ ] App 端（Android 10+）
  2. [ ] App 端（iOS 14+）
  3. [ ] H5 端（Chrome）
  4. [ ] H5 端（Safari）
  5. [ ] Web 端

#### 任务 6.5：验收评审
- **负责人**：产品经理
- **完成时间**：Day 12 下午
- **验收标准**：
  1. [ ] 所有功能测试用例通过
  2. [ ] 性能指标达标
  3. [ ] 兼容性测试通过
  4. [ ] UI/UX 符合设计稿
  5. [ ] 无严重 Bug
- **交付物**：
  - 测试报告
  - 验收报告
  - 上线清单

---

## 里程碑计划

| 里程碑 | 时间 | 交付物 | 验收标准 |
|--------|------|--------|----------|
| M1：数据库设计完成 | Day 1 | 数据库表结构、实体类 | 表结构评审通过 |
| M2：后端服务完成 | Day 4 | 收藏服务、REST API | 接口测试通过 |
| M3：前端页面完成 | Day 8 | 收藏页面、详情页面 | UI 评审通过 |
| M4：缓存优化完成 | Day 9 | Redis 缓存、性能优化 | 压测达标 |
| M5：测试验收完成 | Day 12 | 测试报告、验收报告 | 所有测试用例通过 |

---

## 风险评估

### 风险 1：全文检索性能问题
- **概率**：中
- **影响**：中
- **应对措施**：
  1. 一期使用 MySQL 全文索引（简单场景）
  2. 二期预留 Elasticsearch 接口（复杂场景）
  3. 搜索缓存优化

### 风险 2：容量限制导致用户体验差
- **概率**：中
- **影响**：低
- **应对措施**：
  1. 合理的容量限制（普通用户 1000 条/100MB）
  2. 清晰的容量提示
  3. 提供 VIP 升级路径

### 风险 3：多端同步冲突
- **概率**：低
- **影响**：中
- **应对措施**：
  1. WebSocket 实时推送
  2. 时间戳冲突解决策略
  3. 支持手动刷新

### 风险 4：文件存储成本
- **概率**：中
- **影响**：中
- **应对措施**：
  1. 图片自动生成缩略图
  2. 文件 CDN 加速
  3. 定期清理无效文件

---

## 资源需求

### 人力资源
- 后端开发：1 人（7 人天）
- 前端开发：1 人（5 人天）
- 测试工程师：1 人（3 人天）
- 产品经理：0.5 人天（验收）

### 技术资源
- MySQL 数据库（支持全文索引）
- Redis 缓存服务
- OSS 对象存储
- CDN 加速服务

### 环境资源
- 开发环境：完整功能测试
- 测试环境：性能压测
- 生产环境：灰度发布

---

## 上线检查清单

### 上线前检查
- [ ] 代码审查通过
- [ ] 所有测试用例通过
- [ ] 性能指标达标
- [ ] 无严重 Bug
- [ ] 产品验收通过
- [ ] 容量限制配置完成
- [ ] 监控告警已配置
- [ ] 数据备份策略已配置

### 上线后验证
- [ ] 生产环境功能验证
- [ ] 监控数据正常
- [ ] 用户反馈收集
- [ ] 性能指标监控

---

## 二期规划

### 2.1 智能标签
- 自动为收藏内容打标签
- 基于 NLP 的内容分析
- 标签推荐系统

### 2.2 团队共享
- 支持设置收藏可见范围
- 团队知识库
- 收藏协作编辑

### 2.3 智能搜索
- 语义搜索
- 图片 OCR 识别
- 语音转文字搜索

### 2.4 知识图谱
- 收藏关联分析
- 热门内容识别
- 专家识别

---

## 参考资料

- [设计文档](./IM 即时通讯收藏功能设计文档-v2.0.md)
- [微信收藏功能设计](https://developers.weixin.qq.com/doc/)
- [企业微信「群精华」功能](https://qiwei.huawan.com/news/3760.html)
- [环信 IM 消息收藏实现](https://www.easemob.com/news/26026)
- [Elasticsearch 全文检索](https://www.elastic.co/guide/index.html)

---

**文档版本**：v2.0  
**创建日期**：2026-04-02  
**更新日期**：2026-04-02  
**适用项目**：shengyu-im-saas  
**责任人**：开发团队
