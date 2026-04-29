# IM Flutter 开发任务拆解清单 v1.0

> 文档日期：2026-04-29  
> 对应主文档：`sql/flutter-doc/IM-Flutter多端重构设计任务文档-v1.0.md`
> 页面蓝图：`sql/flutter-doc/IM-Flutter页面实现蓝图-v1.0.md`
> 关键详细设计：
> - `sql/flutter-doc/IM-Flutter聊天页详细设计-v1.0.md`
> - `sql/flutter-doc/IM-Flutter会话角标Socket协同设计-v1.0.md`
> - `sql/flutter-doc/IM-Flutter群设置通讯录搜索详细设计-v1.0.md`
> - `sql/flutter-doc/IM-Flutter类命名与文件组织规范-v1.0.md`
> - `sql/flutter-doc/IM-FlutterUseCase与数据访问分层设计-v1.0.md`
> - `sql/flutter-doc/IM-Flutter消息类型与组件映射规范-v1.0.md`
> - `sql/flutter-doc/IM-Flutter目录树与文件清单-v1.0.md`
> - `sql/flutter-doc/IM-Flutter核心字段表-v1.0.md`
> - `sql/flutter-doc/IM-Flutter第一阶段文件级实施清单-v1.0.md`
> - `sql/flutter-doc/IM-Flutter依赖与Pubspec建议-v1.0.md`
> - `sql/flutter-doc/IM-Flutter首批类骨架与文件职责-v1.0.md`
> - `sql/flutter-doc/IM-Flutter第一阶段测试清单-v1.0.md`
> - `sql/flutter-doc/IM-FlutterPubspec草案-v1.0.md`
> - `sql/flutter-doc/IM-Flutter索引总表-v1.0.md`
> - `sql/flutter-doc/IM-Flutter聊天页事件命令状态表-v1.0.md`
> - `sql/flutter-doc/IM-Flutter会话页事件命令状态表-v1.0.md`
> - `sql/flutter-doc/IM-Flutter第一阶段代码骨架模板-v1.0.md`
> - `sql/flutter-doc/IM-Flutter对象代码模板-v1.0.md`

---

## 1. 任务边界

本清单用于 Flutter 开工执行，不再讨论是否重构，只定义顺序、依赖和 DoD。

---

## 2. M0 设计冻结

- [ ] 冻结 Flutter 目录结构
- [ ] 冻结状态管理方案
- [ ] 冻结网络层方案
- [ ] 冻结 WebSocket 抽象层方案
- [ ] 冻结本地存储方案
- [ ] 冻结路由参数模型
- [ ] 冻结核心实体清单

DoD：

- 主设计文档不再改范围
- 后续开发只允许补充实现细节，不允许反复换架构

---

## 3. M1 工程基线

- [ ] 重构 `lib/` 目录为 app/core/features/shared 分层
- [ ] 搭建环境配置与 flavor 基线
- [ ] 搭建主题系统
- [ ] 搭建国际化系统
- [ ] 搭建日志系统
- [ ] 搭建错误上报与统一异常模型
- [ ] 搭建 `go_router`

DoD：

- 空工程具备可运行的应用骨架
- 三端以上可启动

---

## 4. M2 鉴权与基础设施

- [ ] 定义 `AuthToken`、`CurrentUser`、`DeviceInfo`
- [ ] 实现 token 持久化
- [ ] 实现 Dio 基础封装
- [ ] 实现 `Authorization` 注入
- [ ] 实现 `tenant-id` 注入
- [ ] 实现 `Accept-Language` 注入
- [ ] 实现 401 refresh 单飞
- [ ] 实现请求队列重放
- [ ] 实现登录/短信登录/登出/刷新 token API
- [ ] 实现 permission info 初始化

DoD：

- HTTP 鉴权链路完整
- refresh 后业务请求自动恢复

---

## 5. M3 WebSocket 骨架

- [ ] 定义 socket event model
- [ ] 实现 connect / disconnect
- [ ] 实现 auth / reauth
- [ ] 实现 heartbeat
- [ ] 实现 reconnect backoff
- [ ] 实现 close reason 处理
- [ ] 实现 event stream 分发
- [ ] 预留 PB/JSON 双 codec 适配边界

DoD：

- Socket 层不依赖具体页面
- refresh token 后能触发同连接 reauth

---

## 6. M4 会话域

- [ ] 定义 `Conversation`、`ConversationCursorState`
- [ ] 实现 conversation API datasource
- [ ] 实现 repository
- [ ] 实现 conversation list state
- [ ] 实现 cursor 增量同步
- [ ] 实现 pinned / noDisturb / delete / markRead
- [ ] 实现 badge 联动

DoD：

- 会话列表可独立跑通
- 仅靠 `chatId` 驱动

---

## 7. M5 聊天页骨架

- [ ] 定义 `ChatEntryArgs`
- [ ] 定义 `ChatViewportState`
- [ ] 实现 latest/anchor/restore 入口状态机
- [ ] 实现 `message/window`
- [ ] 实现 `message/history`
- [ ] 实现历史翻页
- [ ] 实现视口保存/恢复
- [ ] 实现 `pullMessages` 补偿

DoD：

- 搜索、会话列表、收藏详情都能进入聊天页
- 不再依赖固定 `pageNo=1` 方案

---

## 8. M6 消息域

- [ ] 定义 `Message` 与 `MessageExtra`
- [ ] 定义消息类型枚举
- [ ] 实现发送态/失败态/重发态
- [ ] 实现文本消息
- [ ] 实现图片消息
- [ ] 实现文件消息
- [ ] 实现语音消息
- [ ] 实现视频消息
- [ ] 实现位置消息
- [ ] 实现名片消息
- [ ] 实现表情/自定义表情
- [ ] 实现引用回复
- [ ] 实现消息转发
- [ ] 实现撤回与 `rev` 合并保护

DoD：

- 实时消息、REST 拉取、补偿拉取三条链路能合并成一个最终态

---

## 9. M7 已读与角标

- [ ] 实现 `mark-read-seq`
- [ ] 实现 `mark-read`
- [ ] 实现 `badge/get`
- [ ] 实现群已读摘要
- [ ] 实现群已读/未读详情
- [ ] 实现语音已播放状态同步
- [ ] 实现离开页面时 flush

DoD：

- 已读水位只升不降
- badge 与会话列表一致

---

## 10. M8 联系人与组织

- [ ] 联系人列表
- [ ] 联系人搜索
- [ ] 用户详情
- [ ] 星标联系人
- [ ] 部门树
- [ ] 部门成员分页
- [ ] 发起单聊
- [ ] 发起群聊

DoD：

- 联系人到会话创建链路可用

---

## 11. M9 群域

- [ ] 群详情
- [ ] 群成员列表
- [ ] 添加成员
- [ ] 移除成员
- [ ] 角色设置
- [ ] 成员禁言
- [ ] 全员禁言
- [ ] 群名片
- [ ] 转让群主
- [ ] 群公告
- [ ] 入群申请
- [ ] 邀请码加入
- [ ] 解散群
- [ ] 退群

DoD：

- 群设置全链路可用

---

## 12. M10 搜索、收藏、文件

- [ ] 热搜
- [ ] 全局搜索
- [ ] 聊天记录搜索
- [ ] 搜索结果锚点跳转
- [ ] 收藏列表
- [ ] 收藏详情
- [ ] 收藏再转发
- [ ] 群文件列表
- [ ] 会话媒体列表
- [ ] 文件打开策略

DoD：

- 搜索与收藏都能准确跳回聊天定位点

---

## 13. M11 多端专项

- [ ] Web 键盘与滚动适配
- [ ] Web 文件预览与下载
- [ ] Mobile 录音与媒体权限
- [ ] Desktop 窗口与布局适配
- [ ] 生命周期差异处理
- [ ] 可见性变化与 pending flush

DoD：

- Web、Mobile、Desktop 行为差异被收口在适配层

---

## 14. M12 回归清单

- [ ] 登录 -> refresh -> reauth
- [ ] 单聊创建与打开
- [ ] 群聊创建与打开
- [ ] latest/anchor/restore
- [ ] 文本/图片/文件/语音/视频/位置/名片
- [ ] 引用定位
- [ ] 撤回最终态
- [ ] 转发与合并转发
- [ ] 搜索跳转
- [ ] 收藏跳转
- [ ] badge 与未读同步
- [ ] 群已读详情
- [ ] 语音未听红点
- [ ] 弱网重连与补偿

DoD：

- 关键业务回归通过后才能进入 UI 打磨阶段

---

## 15. 强制约束

1. 所有 ID 一律 `String`
2. DTO 不得直达 Widget
3. 页面不得直连 raw API
4. Socket 层不得承载页面状态
5. 聊天页必须是状态机
6. 文件访问必须走服务端策略接口
7. 群消息查询必须基于 `chatId`
