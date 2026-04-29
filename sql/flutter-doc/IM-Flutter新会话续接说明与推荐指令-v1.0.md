# IM Flutter 新会话续接说明与推荐指令 v1.0

> 文档日期：2026-04-29  
> 文档定位：新开会话时如何衔接已有进度，并给出推荐继续指令模板  

---

## 1. 目标

避免新会话出现以下问题：

- 重新从 0 讲背景
- 重复调研同一批文档
- 已有设计被新的会话误覆盖

---

## 2. 新会话最小上下文

新会话开始时，建议至少给出这 4 个信息：

1. 主目录文档路径
2. 当前目标专题
3. 当前状态
4. 是否允许继续写文档 / 是否开始写代码

---

## 3. 推荐新会话指令

### 3.1 继续写文档

推荐直接发：

```text
请先阅读 sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md、
sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md、
sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议-v1.0.md，
再根据当前进度继续推进下一轮，不要重复已有设计，先汇报你判断的当前状态，再直接补文档。
```

### 3.2 开始写 Flutter 代码

```text
请先阅读 sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md、
sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md、
sql/flutter-doc/IM-Flutter第一阶段文件级实施清单-v1.0.md、
sql/flutter-doc/IM-Flutter第一阶段代码骨架模板-v1.0.md，
然后按当前 ready_for_codegen 的专题直接开始落代码，不要重新设计。
```

### 3.3 继续推进音视频专题

```text
请先阅读 sql/flutter-doc/IM-Flutter音视频通话企业级设计-v1.0.md、
sql/flutter-doc/IM-Flutter通话控制器与状态设计-v1.0.md、
sql/flutter-doc/IM-Flutter通话事件命令状态表-v1.0.md、
sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md，
确认当前音视频专题状态后继续下一轮推进，避免重复造文档。
```

### 3.4 继续推进后端协同

```text
请先阅读 sql/flutter-doc/IM-Flutter后端协同约束与接口整顿建议-v1.0.md、
sql/flutter-doc/IM-Flutter后端协同实施优先级清单-v1.0.md，
结合当前仓库后端代码继续推进下一轮，优先输出可执行的整顿项。
```

---

## 4. 推荐会话开场句

如果你想更稳一点，新会话第一句建议加一句：

```text
不要从 0 开始分析，先基于已有 flutter-doc 文档体系判断当前进度，再继续推进。
```

---

## 5. 我建议你后续最常用的指令

### 指令 A：继续文档推进

```text
请先阅读 sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md 和 sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md，基于当前进度继续推进下一轮，不要重复已有设计，直接进入最优的下一个专题。
```

### 指令 B：转代码骨架

```text
请先阅读 sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md、sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md、sql/flutter-doc/IM-Flutter第一阶段文件级实施清单-v1.0.md，然后从 ready_for_codegen 的专题开始直接落 Flutter 代码骨架。
```

### 指令 C：专项推进

```text
请先阅读主目录和进度看板，再只推进 [这里填专题名]，要求更新对应文档状态并避免重复输出。
```

---

## 6. 当前默认推荐指令

基于现在的进度，我建议你后续下一句最值得用的是：

```text
请先阅读 sql/flutter-doc/IM-Flutter主目录与阅读顺序-v1.0.md、
sql/flutter-doc/IM-Flutter开工顺序与进度看板-v1.0.md、
sql/flutter-doc/IM-FlutterOpenHarmony平台门槛清单-v1.0.md、
sql/flutter-doc/IM-Flutter聊天页平台能力接线图-v1.0.md、
sql/flutter-doc/IM-Flutter通话代码骨架模板-v1.0.md，
然后基于当前 ready_for_codegen 状态继续企业级推进下一轮，优先做系统性查漏补缺或直接开始第一批 Flutter 代码骨架落地，并在完成后更新进度状态。
```
