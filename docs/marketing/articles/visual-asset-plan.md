# 平台技术文章配图与架构图采集清单

这份清单与 `docs/marketing/articles/` 下的五篇文章配套使用。目标不是堆叠产品界面，而是让每一张图都回答一个技术问题：系统如何分层、状态如何流动、部署如何验证、故障如何定位。

所有公开截图都应先完成脱敏：遮蔽用户名、邮箱、手机号、企业名称、消息正文、文件名、Token、Cookie、服务器 IP、内网域名、数据库连接串、证书私钥和媒体服务密钥。

## 1. 一张必须先做的总架构图

现有主视觉：`docs/marketing/assets/enterprise-collaboration-architecture.png`，适合作为无文字封面背景。建议再制作一张带中文标签的横版架构图，供 CSDN、掘金、知乎和 B 站使用。

```mermaid
flowchart TB
  subgraph Clients[客户端与管理入口]
    PM[平台管理端\nVue 3]
    TM[企业管理端\nVue 3]
    FC[Flutter 协作端\nAndroid / iOS / Web]
  end

  subgraph Core[业务控制面]
    API[Spring Boot API]
    AUTH[认证 / 租户上下文 / RBAC / 数据权限]
    BIZ[组织 / 成员 / 会话 / 群组 / 文件 / 呼叫状态]
  end

  subgraph Realtime[实时数据面]
    IM[Netty + Protobuf\n业务事件]
    RTC[LiveKit + WebRTC\n音视频媒体]
  end

  subgraph Infra[基础设施]
    MYSQL[(MySQL)]
    REDIS[(Redis)]
    NGINX[Nginx / TLS / WSS]
  end

  PM --> API
  TM --> API
  FC --> API
  API --> AUTH --> BIZ
  BIZ --> MYSQL
  BIZ --> REDIS
  FC <--> IM
  BIZ --> IM
  FC <--> RTC
  API --> RTC
  NGINX --> API
  NGINX --> IM
  NGINX --> RTC
```

**绘图规范**：控制面、实时事件、媒体数据面使用三种稳定颜色；箭头标注协议，例如 HTTPS、WSS、WebRTC；不要把业务模块全部塞进图中；保持 16:9 横向比例，同时导出一张 3:4 竖版裁切图供小红书使用。

## 2. 建议采集的真实截图

| 编号 | 画面内容 | 推荐文章 | 要表达的技术点 | 采集方式 |
| --- | --- | --- | --- | --- |
| V1 | 平台端、企业端、Flutter 三端拼图 | 全部 | 三类入口共享一套身份和租户边界 | 浏览器与真机截图后统一拼图 |
| V2 | 企业切换前后会话列表 | CSDN、知乎、小红书 | 租户切换同步刷新数据域 | 使用测试账号并模糊名称 |
| V3 | WebSocket 事件帧或日志 | CSDN、掘金、B 站 | 事件 ID、类型、重连与去重 | DevTools/日志中仅保留字段名 |
| V4 | `callId` 通话状态日志时间线 | CSDN、知乎、B 站 | 业务状态与媒体连接可分层定位 | 导出后重绘为时序图更清晰 |
| V5 | Docker 容器与 Nginx 路由 | CSDN、掘金、B 站 | 应用容器与宿主机基础设施边界 | 截图前隐藏 IP、容器环境变量 |
| V6 | 云安全组或端口验收表 | 知乎、小红书、B 站 | HTTPS/WSS 与 UDP/TURN 是不同检查项 | 使用示意表优先于真实云账号截图 |
| V7 | Flutter Web 首次加载性能瀑布图 | 掘金、知乎 | 入口资源缓存与本地 CanvasKit 策略 | 隐藏请求参数与用户数据 |
| V8 | SQL 增量、菜单权限交付清单 | CSDN、掘金 | 功能发布包含代码、SQL、权限和验收 | 用 Markdown/表格重新绘制即可 |

## 3. 架构图之外，最值得做的三张技术图

### 3.1 租户切换时序图

```mermaid
sequenceDiagram
  participant U as 用户
  participant C as 客户端
  participant A as 业务服务
  participant W as 实时通道
  U->>C: 选择目标企业
  C->>A: 校验成员关系并切换上下文
  A-->>C: 返回新的租户上下文
  C->>W: 关闭旧企业订阅
  C->>C: 切换缓存命名空间
  C->>A: 拉取新企业会话/联系人快照
  C->>W: 建立新企业实时订阅
```

### 3.2 通话状态与媒体链路图

```mermaid
sequenceDiagram
  participant A as 主叫
  participant S as 业务服务
  participant B as 被叫
  participant R as RTC 媒体服务
  A->>S: 创建呼叫
  S->>B: RINGING
  B->>S: ACCEPT
  S->>A: 入房凭据
  S->>B: 入房凭据
  A->>R: 发布音视频轨道
  B->>R: 订阅音视频轨道
  A->>S: END / 网络异常
  S->>A: ENDED
  S->>B: ENDED
```

### 3.3 发布验收流程图

```mermaid
flowchart LR
  Build[构建镜像与前端产物] --> Deploy[Compose 替换服务]
  Deploy --> Health[容器与 Nginx 健康检查]
  Health --> API[登录、切换企业、会话]
  API --> Realtime[WSS、重连、消息]
  Realtime --> Upload[图片/语音上传预览]
  Upload --> RTC[不同网络通话验收]
  RTC --> Done[记录版本与验收结果]
```

### 3.4 事务提交与实时事件图

适合 CSDN、掘金、B 站加长段。它强调“业务状态先成为事实，实时事件负责尽快通知，重连端可回拉修复”。

```mermaid
flowchart LR
  C[客户端命令\nclientRequestId] --> V[租户/权限/状态校验]
  V --> T[数据库事务]
  T --> R[(权威记录)]
  T --> E[eventId 可重试事件]
  E --> W[WebSocket]
  W --> D[客户端去重]
  R --> S[事件缺口时 API 快照回拉]
  S --> D
```

### 3.5 文件上传与消息引用图

适合 CSDN、掘金、小红书、B 站。绘图时把“文件内容”和“会话消息”明确画成两条不同路径，避免观众误解为附件通过实时通道传输。

```mermaid
flowchart LR
  U[客户端上传] --> N[Nginx\nTLS/大小限制]
  N --> F[文件服务\n元数据与授权]
  F --> ST[(文件存储)]
  F --> M[(fileId / tenantId / hash)]
  M --> C[创建消息引用]
  C --> W[实时推送消息元数据]
  W --> P[其他端授权预览]
```

### 3.6 Flutter 多端状态恢复图

适合掘金、知乎和 B 站。图中要显式区分“本地体验缓存”和“服务端权威状态”，避免把客户端缓存误画成权限事实来源。

```mermaid
flowchart TB
  Login[登录/切换企业] --> Scope[用户 + 租户作用域]
  Scope --> API[服务端权威快照]
  API --> State[Flutter 状态管理]
  Event[WebSocket 增量事件] --> Merge[去重/版本比较]
  Merge --> State
  State --> UI[会话、联系人、通话 UI]
  UI --> Cache[草稿/缩略图/页面位置]
  Reconnect[重连/版本缺口] --> API
```

## 4. 发布到不同平台的图片策略

| 平台 | 图片数量 | 最佳比例 | 推荐内容 |
| --- | --- | --- | --- |
| CSDN | 3 到 5 张 | 16:9 或横版长图 | 总架构、时序图、部署验收表、日志关联图 |
| 掘金 | 3 到 6 张 | 横版图、代码截图 | 控制面/数据面图、重连时序、目录树、缓存策略 |
| 知乎 | 4 到 6 张 | 干净的横版信息图 | 技术决策图、租户切换、通话排查矩阵、域名边界 |
| B 站 | 6 到 8 个镜头 | 16:9 | 真实页面、架构图、终端、日志、部署拓扑 |
| 小红书 | 12 到 16 张 | 3:4 竖图 | 每页一个技术结论，少文字、强层级 |

## 5. 公开配图的底线

- 不展示生产数据库、Redis、服务器终端的完整连接信息。
- 不展示真实用户身份、客户企业、聊天内容、文件和音视频画面。
- 不在架构图中标注任何密钥、Token、私网网段或防火墙细节。
- 对日志使用“字段结构 + 脱敏值”的表达，优先重绘而非直接贴完整日志。
- 通过截图证明工程能力，但不把部署细节写成可被滥用的攻击入口。
