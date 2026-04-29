# IM Flutter 主目录与阅读顺序 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter IM 文档主入口、阅读顺序、关联关系、AI 开工入口  

---

## 1. 目标

本目录文档用于把当前 Flutter IM 文档体系收敛为一个可直接开工的入口。

适用对象：

- AI 编码模型
- 人工开发者
- 后续文档维护者

阅读原则：

1. 先读总纲
2. 再读协议
3. 再读架构与目录
4. 再读页面与模块专题
5. 最后读模板、清单、测试

---

## 2. 一级总纲文档

以下文档属于最高优先级。

1. `sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md`
2. `sql/flutter-doc/IM-Flutter多端重构设计任务文档-v1.0.md`
3. `sql/flutter-doc/IM-Flutter核心协议与事件契约-v1.0.md`
4. `sql/flutter-doc/IM-Flutter架构与工程规范-v1.0.md`
5. `sql/flutter-doc/IM-Flutter目录树与文件清单-v1.0.md`
6. `sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议-v1.0.md`
7. `sql/flutter-doc/IM-Flutter视觉与交互设计规范-v1.0.md`

这 7 份文档共同定义：

- 项目目标
- 冻结约束
- 协议总线
- 工程边界
- 代码目录
- 后端协同边界
- 统一视觉路线

---

## 3. 第二层核心设计文档

### 3.1 状态与数据

- `sql/flutter-doc/IM-Flutter核心状态机与时序设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter数据模型与存储设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter核心字段表-v1.0.md`

### 3.2 页面与路由

- `sql/flutter-doc/IM-Flutter页面实现蓝图-v1.0.md`
- `sql/flutter-doc/IM-Flutter页面与路由详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter索引总表-v1.0.md`

### 3.3 分层与命名

- `sql/flutter-doc/IM-Flutter类命名与文件组织规范-v1.0.md`
- `sql/flutter-doc/IM-FlutterUseCase与数据访问分层设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter通用业务工具与基础规则-v1.0.md`
- `sql/flutter-doc/IM-Flutter核心基础能力代码模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter视觉与交互设计规范-v1.0.md`

---

## 4. 第三层业务专题文档

### 4.1 聊天与会话

- `sql/flutter-doc/IM-Flutter聊天页详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter聊天页平台能力接线图-v1.0.md`
- `sql/flutter-doc/IM-Flutter会话列表详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter功能覆盖与交互验收清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter聊天页事件命令状态表-v1.0.md`
- `sql/flutter-doc/IM-Flutter会话页事件命令状态表-v1.0.md`
- `sql/flutter-doc/IM-Flutter会话角标Socket协同设计-v1.0.md`

### 4.2 群、通讯录、搜索

- `sql/flutter-doc/IM-Flutter群设置通讯录搜索详细设计-v1.0.md`

### 4.3 登录、主题、国际化

- `sql/flutter-doc/IM-Flutter登录页详细设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter国际化与语言设置设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter主题模式设计-v1.0.md`

### 4.4 文件预览

- `sql/flutter-doc/IM-Flutter文件上传与发送链路设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件上传对象模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件上传代码骨架模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览与多格式渲染设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览控制器与策略设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览页面交互设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览测试清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览对象模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter文件预览代码模板-v1.0.md`

### 4.5 音视频通话

- `sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter通话控制器与状态设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter通话事件命令状态表-v1.0.md`
- `sql/flutter-doc/IM-Flutter通话对象代码模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter通话代码骨架模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter通话测试清单-v1.0.md`

### 4.6 基础设施专题

- `sql/flutter-doc/IM-Flutter基础设施选型与抽象层治理-v1.0.md`
- `sql/flutter-doc/IM-Flutter多端平台兼容落地设计-v1.0.md`
- `sql/flutter-doc/IM-FlutterOpenHarmony-HarmonyOS插件兼容矩阵-v1.0.md`
- `sql/flutter-doc/IM-FlutterOpenHarmony-HarmonyOS适配缺口清单-v1.0.md`
- `sql/flutter-doc/IM-FlutterOpenHarmony适配器骨架模板-v1.0.md`
- `sql/flutter-doc/IM-FlutterOpenHarmony平台门槛清单-v1.0.md`
- `sql/flutter-doc/IM-FlutterHarmonyOS平台门槛清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter移动端离线推送设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter地图与位置能力设计-v1.0.md`
- `sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议-v1.0.md`
- `sql/flutter-doc/IM-Flutter后端协同实施优先级清单-v1.0.md`

---

## 5. 第四层开工文档

- `sql/flutter-doc/IM-Flutter依赖与Pubspec建议-v1.0.md`
- `sql/flutter-doc/IM-FlutterPubspec草案-v1.0.md`
- `sql/flutter-doc/IM-Flutter首批类骨架与文件职责-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段文件级实施清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段代码骨架模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter对象代码模板-v1.0.md`
- `sql/flutter-doc/IM-Flutter第一阶段测试清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter开发任务拆解清单-v1.0.md`
- `sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md`
- `sql/flutter-doc/IM-Flutter新会话续接说明与推荐指令-v1.0.md`

---

## 6. 辅助治理文档

以下文档主要用于治理、流程和协作，不是 AI 编码首轮必须通读的业务文档：

- `sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md`
- `sql/flutter-doc/IM-Flutter新会话续接说明与推荐指令-v1.0.md`
- `sql/flutter-doc/IM-Flutter后端协同实施优先级清单-v1.0.md`

编码时按需查阅即可。

## 7. AI 开工最小阅读集

如果由 AI 模型直接开始编码，最低限度先读以下文档：

1. `IM-Flutter主目录与阅读顺序-v1.0.md`
2. `IM-Flutter多端重构设计任务文档-v1.0.md`
3. `IM-Flutter核心协议与事件契约-v1.0.md`
4. `IM-Flutter架构与工程规范-v1.0.md`
5. `IM-Flutter目录树与文件清单-v1.0.md`
6. `IM-Flutter后端协同约束与接口整顿建议-v1.0.md`
7. `IM-Flutter数据模型与存储设计-v1.0.md`
8. `IM-Flutter页面与路由详细设计-v1.0.md`
9. `IM-Flutter通用业务工具与基础规则-v1.0.md`
10. `IM-Flutter多端平台兼容落地设计-v1.0.md`
11. `IM-Flutter功能覆盖与交互验收清单-v1.0.md`
12. `IM-FlutterOpenHarmony-HarmonyOS插件兼容矩阵-v1.0.md`

如果要开发聊天：

- 再读 `IM-Flutter聊天页详细设计-v1.0.md`
- 再读 `IM-Flutter聊天页平台能力接线图-v1.0.md`
- 再读 `IM-Flutter会话角标Socket协同设计-v1.0.md`
- 再读 `IM-Flutter功能覆盖与交互验收清单-v1.0.md`

如果要开发音视频：

- 再读 `IM-Flutter音视频通话企业级设计-v1.0.md`
- 再读 `IM-Flutter通话控制器与状态设计-v1.0.md`
- 再读 `IM-Flutter通话事件命令状态表-v1.0.md`
- 再读 `IM-Flutter通话对象代码模板-v1.0.md`
- 再读 `IM-Flutter通话代码骨架模板-v1.0.md`
- 再读 `IM-Flutter通话测试清单-v1.0.md`

如果要开发 OpenHarmony / HarmonyOS：

- 再读 `IM-Flutter多端平台兼容落地设计-v1.0.md`
- 再读 `IM-FlutterOpenHarmony-HarmonyOS插件兼容矩阵-v1.0.md`
- 再读 `IM-FlutterOpenHarmony-HarmonyOS适配缺口清单-v1.0.md`
- 再读 `IM-FlutterOpenHarmony适配器骨架模板-v1.0.md`
- 再读 `IM-FlutterOpenHarmony平台门槛清单-v1.0.md`
- 再读 `IM-FlutterHarmonyOS平台门槛清单-v1.0.md`

如果要开发文件预览：

- 再读文件预览专题全套文档

如果要开发上传与发送链路：

- 再读 `IM-Flutter文件上传与发送链路设计-v1.0.md`
- 再读 `IM-Flutter文件上传对象模板-v1.0.md`
- 再读 `IM-Flutter文件上传代码骨架模板-v1.0.md`
- 再读 `IM-Flutter聊天页详细设计-v1.0.md`
- 再读 `IM-Flutter后端协同约束与接口整顿建议-v1.0.md`

---

## 8. 文档间依赖关系

### 8.1 协议优先级

当多个文档出现交叉描述时，优先级如下：

1. `IM-Flutter核心协议与事件契约-v1.0.md`
2. `IM-Flutter多端重构设计任务文档-v1.0.md`
3. 具体专题设计文档
4. 模板、清单、草案文档

### 8.2 工程优先级

工程组织相关冲突以以下顺序为准：

1. `IM-Flutter架构与工程规范-v1.0.md`
2. `IM-Flutter目录树与文件清单-v1.0.md`
3. `IM-Flutter类命名与文件组织规范-v1.0.md`

---

## 9. 当前主方案冻结结论

### 9.1 IM 核心

- 核心对话、会话、状态机、WebSocket 自研

### 9.2 音视频

- `flutter_webrtc` + 自有业务信令 + 自建 Janus + 自建 coturn

### 9.3 文件预览

- 原生预览 + 服务端 open-strategy + 服务端转换优先

### 9.4 离线推送

- 主方案只实现一个统一推送适配主链路
- 其余通道先保留抽象和空实现

### 9.5 地图

- 主方案只实现一个地图供应商适配器
- 其余供应商保留空实现与替换边界

---

## 10. AI 开工就绪结论

当前文档体系已满足 AI 进入首轮 Flutter 开工的条件，但按风险分层建议如下：

### 10.1 可直接开工

- 登录与鉴权
- app/bootstrap/router/theme/l10n 基线
- WebSocket 连接、reauth、事件分发
- 会话列表
- 聊天页主链路
- 文件上传与发送链路
- 文件预览
- Android / iOS 首轮端能力适配

### 10.2 可开工但建议先补代码模板

- 音视频通话
- 地图与位置
- 离线推送 adapter
- OpenHarmony / HarmonyOS 插件兼容矩阵

### 10.3 非核心辅助文档

以下文档不属于 AI 首轮编码必读内容：

- `sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md`
- `sql/flutter-doc/IM-Flutter新会话续接说明与推荐指令-v1.0.md`
- `sql/flutter-doc/IM-Flutter后端协同实施优先级清单-v1.0.md`
- `sql/flutter-doc/环境.md`

## 11. 开工约束

1. 当前阶段以文档定义为准，不反向迁就旧工程结构。
2. 只实现主方案，不同时落多供应商。
3. 所有第三方能力都必须经过 `adapter / facade` 抽象层。
4. 允许备选方案空实现占位，但不可污染业务层接口。
