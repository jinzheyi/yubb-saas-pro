# IM Flutter 开工顺序与进度看板 v1.0

> 文档日期：2026-04-29  
> 文档定位：文档阅读顺序、开发开工顺序、进度状态标记规范、避免重复推进  

---

## 1. 目标

解决三个问题：

1. 文档太多时先看什么
2. 当前推进到哪一步
3. 新开会话时如何不重复劳动

---

## 2. 状态标记规范

所有里程碑、专题、页面、基础设施能力统一使用以下状态：

- `not_started`
- `analyzing`
- `documented`
- `ready_for_codegen`
- `coding`
- `verifying`
- `completed`
- `blocked`

---

## 3. 当前总进度

### 3.1 总纲层

| 项目 | 状态 |
|---|---|
| 主目录与阅读顺序 | `completed` |
| 核心协议与事件契约 | `completed` |
| 架构与工程规范 | `completed` |
| 目录树与文件清单 | `completed` |
| 后端协同约束 | `completed` |

### 3.2 核心业务层

| 项目 | 状态 |
|---|---|
| 会话列表体系设计 | `documented` |
| 会话列表详细设计 | `documented` |
| 聊天页体系设计 | `documented` |
| 聊天页平台能力接线图 | `ready_for_codegen` |
| 登录页详细设计 | `documented` |
| 国际化与语言设置设计 | `documented` |
| 主题模式设计 | `documented` |
| 通用业务工具与基础规则 | `documented` |
| 多端平台兼容落地设计 | `documented` |
| 功能覆盖与交互验收清单 | `documented` |
| 核心基础能力代码模板 | `ready_for_codegen` |
| 文件上传与发送链路设计 | `ready_for_codegen` |
| 文件预览体系设计 | `ready_for_codegen` |
| OpenHarmony/HarmonyOS 插件兼容矩阵 | `documented` |
| OpenHarmony/HarmonyOS 适配缺口清单 | `documented` |
| OpenHarmony 适配器骨架模板 | `ready_for_codegen` |
| OpenHarmony 平台门槛清单 | `ready_for_codegen` |
| HarmonyOS 平台门槛清单 | `documented` |
| 音视频通话体系设计 | `documented` |
| 地图与位置能力设计 | `documented` |
| 移动端离线推送设计 | `documented` |

### 3.3 可直接代码生成层

| 项目 | 状态 |
|---|---|
| 第一阶段代码骨架模板 | `documented` |
| 文件上传对象模板 | `ready_for_codegen` |
| 文件上传代码骨架模板 | `ready_for_codegen` |
| 文件预览控制器与策略设计 | `ready_for_codegen` |
| 文件预览代码模板 | `ready_for_codegen` |
| 文件预览测试清单 | `ready_for_codegen` |
| 通话控制器与状态设计 | `ready_for_codegen` |
| 通话事件命令状态表 | `ready_for_codegen` |
| 通话对象代码模板 | `ready_for_codegen` |
| 通话代码骨架模板 | `ready_for_codegen` |
| 通话测试清单 | `ready_for_codegen` |
| 聊天页事件命令状态表 | `ready_for_codegen` |
| 会话页事件命令状态表 | `ready_for_codegen` |

---

## 4. 推荐开工顺序

### Phase A 文档总纲冻结

1. 主目录
2. 主设计文档
3. 核心协议
4. 架构规范
5. 后端协同约束

### Phase B 代码基线

1. 目录树与文件清单
2. 依赖与 pubspec
3. 第一阶段文件级实施清单
4. 首批类骨架与文件职责
5. 第一阶段代码骨架模板

### Phase C 核心主链路

1. 登录
2. WebSocket
3. 会话列表
4. 聊天页
5. 已读与角标

### Phase D 复杂专题

1. 文件上传
2. 文件预览
3. 音视频通话
4. 地图与位置
5. 离线推送

---

## 5. 避免重复推进规则

1. 新增文档前先查主目录是否已有专题承接
2. 同一能力先补总纲，再补事件表，再补代码模板
3. 若已有 `ready_for_codegen` 文档，优先转代码，不再重复写设计
4. 同一专题不要并行创建多份“详细设计”

---

## 6. 当前最推荐的下一批任务

### 代码方向

- `auth/socket/conversation/chat` 首轮骨架开工
- `chat upload` 对象与 coordinator 骨架
- `dict/nav-state/avatar/time` core 基础能力骨架
- `openharmony` P0 adapter 实现与真机验证
- `file preview/upload` 主链路骨架落地
- `call` 模块首轮 Flutter 代码骨架落地
- `chat` 平台能力按接线图实现，禁止页面直连平台插件

### 下一批文档方向

- 原则上暂停继续扩张文档
- 仅在代码落地暴露真实缺口时补专项文档

---

## 7. 进度更新规则

每次推进后只做两件事：

1. 更新本文件里的状态表
2. 更新持久记忆里的“Documentation created / current focus”

这样新会话可以最低成本恢复上下文。
