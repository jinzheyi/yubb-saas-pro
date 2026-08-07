# Pi Agent Harness 二次开发指南

> 基于 https://github.com/earendil-works/pi 的深度分析与实践指南

## 一、项目概述

### 1.1 什么是 Pi Agent Harness

Pi 是一个**极简主义的 AI 编码智能体框架**,核心理念是:

> **"Adapt Pi to your workflows, not the other way around"**  
> (让 Pi 适配你的工作流,而不是让你适配 Pi)

**关键数据**:
- GitHub: https://github.com/earendil-works/pi
- Star: 55.6k | Fork: 6.6k
- 协议: MIT
- 核心贡献者: mitsuhiko (Flask 作者)
- 版本: v0.75.5 (2026-05-27)

### 1.2 核心架构

Pi 采用 Monorepo 结构,包含 4 个核心包:

```
packages/
├── coding-agent/     # 交互式编码智能体 CLI (核心产品)
├── agent/           # 智能体运行时 (工具调用、状态管理)
├── ai/              # 统一 LLM API (支持 15+ 提供商)
└── tui/             # 终端 UI 库 (差分渲染)
```

### 1.3 设计哲学

Pi 刻意保持核心极简,提供**原语(Primitives)**而不是**功能(Features)**:

| 不内置的功能 | 替代方案 | 为什么 |
|------------|---------|--------|
| MCP 集成 | Skills (CLI 工具 + README) | MCP 太重,Skills 更轻量 |
| 子智能体 | tmux 启动多个 Pi,或自己写扩展 | 保持核心简单 |
| 权限弹窗 | 跑在容器里,或自己写确认流程 | 安全策略应该由用户定义 |
| 计划模式 | 写文件,或用扩展 | 计划是工作流,不是核心 |
| 待办事项 | 用 TODO.md 或扩展 | 同上 |
| 后台 bash | 用 tmux | 完全可观测,可直接交互 |

**核心思想**: 功能是用户根据自己的工作流构建的。

---

## 二、安装与基础使用

### 2.1 安装方式

**方式 1: npm 全局安装 (推荐)**

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

**方式 2: 安装脚本**

```bash
# Linux / macOS
curl -fsSL https://pi.dev/install.sh | sh

# Windows PowerShell
powershell -c "irm https://pi.dev/install.ps1 | iex"
```

**方式 3: 其他包管理器**

```bash
pnpm add -g --ignore-scripts @earendil-works/pi-coding-agent
bun add -g --ignore-scripts @earendil-works/pi-coding-agent
```

### 2.2 认证配置

**方式 1: API Key (推荐开发使用)**

```bash
# 设置环境变量
export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY=sk-...
export DEEPSEEK_API_KEY=sk-...

# 启动 Pi
pi
```

**方式 2: OAuth 订阅**

```bash
pi
# 在交互界面输入 /login
# 选择提供商 (Anthropic Claude Pro/Max, OpenAI ChatGPT Plus/Pro, GitHub Copilot)
```

### 2.3 基础使用

```bash
# 在项目目录启动
cd your-project
pi

# 继续上次会话
pi -c

# 浏览历史会话
pi -r

# 临时模式 (不保存会话)
pi --no-session

# 指定会话
pi --session <path|id>
```

### 2.4 交互界面

启动后界面从上到下:

1. **启动头部**: 显示快捷键、加载的 AGENTS.md、技能、扩展
2. **消息区**: 用户消息、助手响应、工具调用结果
3. **编辑器**: 输入区域,边框颜色表示思考级别
4. **页脚**: 工作目录、会话名、Token 使用、成本、上下文使用、当前模型

**常用快捷键**:

| 快捷键 | 功能 |
|-------|------|
| Ctrl+C | 清空编辑器 |
| Ctrl+C 两次 | 退出 |
| Escape | 取消/中止 |
| Escape 两次 | 打开 /tree |
| Ctrl+L | 打开模型选择器 |
| Ctrl+P | 循环切换模型 |
| Shift+Tab | 循环思考级别 |
| Shift+Enter | 多行输入 |
| Ctrl+V | 粘贴图片 |
| @ | 模糊搜索项目文件 |
| !command | 运行 bash 命令并发送给 LLM |

**常用命令**:

| 命令 | 功能 |
|------|------|
| `/login`, `/logout` | OAuth 认证 |
| `/model` | 切换模型 |
| `/settings` | 设置 (思考级别、主题等) |
| `/resume` | 选择历史会话 |
| `/new` | 新建会话 |
| `/tree` | 导航会话树 |
| `/compact` | 手动压缩上下文 |
| `/export` | 导出会话为 HTML |
| `/share` | 上传到 GitHub Gist |
| `/reload` | 重新加载扩展、技能等 |

---

## 三、二次开发方式

Pi 提供 4 种二次开发方式,从简单到复杂:

### 3.1 Prompt Templates (提示模板)

**适用场景**: 复用常用提示词

**位置**:
- 全局: `~/.pi/agent/prompts/`
- 项目: `.pi/prompts/`

**示例**:

```markdown
<!-- ~/.pi/agent/prompts/review.md -->
Review this code for bugs, security issues, and performance problems.
Focus on: {{focus}}
```

**使用**:

```
/review  # 在 Pi 中输入,会展开为模板内容
```

### 3.2 Skills (技能)

**适用场景**: 封装可复用的能力包

**位置**:
- 全局: `~/.pi/agent/skills/`
- 项目: `.pi/skills/` (需要项目信任)

**结构**:

```
my-skill/
├── SKILL.md          # 必需: frontmatter + 指令
├── scripts/          # 辅助脚本
│   └── process.sh
├── references/       # 详细文档
│   └── api-reference.md
└── assets/
    └── template.json
```

**SKILL.md 格式**:

````markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific.
---

# My Skill

## Setup

Run once before first use:
```bash
cd /path/to/skill && npm install
```

## Usage

```bash
./scripts/process.sh <input>
```
````

**使用**:

```
/skill:my-skill  # 手动调用
# 或让 Pi 根据任务自动加载
```

**工作原理**:
1. 启动时扫描技能,提取名称和描述
2. 系统提示包含可用技能的 XML 格式
3. 任务匹配时,Agent 使用 `read` 加载完整 SKILL.md
4. Agent 按照指令执行任务

### 3.3 Extensions (扩展)

**适用场景**: 需要深度定制 Pi 的行为

**位置**:
- 全局: `~/.pi/agent/extensions/`
- 项目: `.pi/extensions/` (需要项目信任)

**核心能力**:
- 注册自定义工具 (LLM 可调用)
- 事件拦截 (阻止或修改工具调用)
- 用户交互 (通过 `ctx.ui` 提示用户)
- 自定义 UI 组件
- 自定义命令
- 会话持久化
- 自定义渲染

**示例 1: 基础扩展**

```typescript
// ~/.pi/agent/extensions/my-extension.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  // 监听事件
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.notify("Extension loaded!", "info");
  });

  // 拦截危险命令
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command?.includes("rm -rf")) {
      const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
      if (!ok) return { block: true, reason: "Blocked by user" };
    }
  });

  // 注册自定义工具
  pi.registerTool({
    name: "greet",
    label: "Greet",
    description: "Greet someone by name",
    parameters: Type.Object({
      name: Type.String({ description: "Name to greet" }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return {
        content: [{ type: "text", text: `Hello, ${params.name}!` }],
        details: {},
      };
    },
  });

  // 注册命令
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify(`Hello ${args || "world"}!`, "info");
    },
  });
}
```

**测试**:

```bash
pi -e ./my-extension.ts
```

**示例 2: 权限门控扩展**

```typescript
// ~/.pi/agent/extensions/permission-gate.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const DANGEROUS_COMMANDS = ["rm -rf", "sudo", "DROP TABLE", "git push --force"];

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const command = event.input.command || "";
    const isDangerous = DANGEROUS_COMMANDS.some((cmd) => 
      command.toLowerCase().includes(cmd.toLowerCase())
    );

    if (isDangerous) {
      const ok = await ctx.ui.confirm(
        "Dangerous Command Detected",
        `Command: ${command}\n\nAllow execution?`
      );
      
      if (!ok) {
        return { 
          block: true, 
          reason: "User blocked dangerous command" 
        };
      }
    }
  });
}
```

**示例 3: Git 检查点扩展**

```typescript
// ~/.pi/agent/extensions/git-checkpoint.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("turn_start", async (event, ctx) => {
    // 每个 turn 开始前创建 Git 检查点
    const { execSync } = await import("child_process");
    
    try {
      execSync("git add -A", { stdio: "ignore" });
      execSync(`git stash push -m "pi-checkpoint-${Date.now()}"`, { 
        stdio: "ignore" 
      });
      ctx.ui.notify("Git checkpoint created", "info");
    } catch (error) {
      // 忽略错误 (可能没有 Git 仓库)
    }
  });

  pi.on("session_before_tree", async (event, ctx) => {
    // 导航到历史节点时恢复检查点
    const { execSync } = await import("child_process");
    
    try {
      execSync("git stash pop", { stdio: "ignore" });
      ctx.ui.notify("Git checkpoint restored", "info");
    } catch (error) {
      // 忽略错误
    }
  });
}
```

**示例 4: 自定义 UI 组件**

```typescript
// ~/.pi/agent/extensions/custom-dialog.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user_questions",
    label: "Ask Questions",
    description: "Ask user multiple questions in a structured dialog",
    parameters: Type.Object({
      questions: Type.Array(
        Type.Object({
          question: Type.String(),
          options: Type.Array(Type.String()),
        })
      ),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const answers: string[] = [];

      for (const q of params.questions) {
        const answer = await ctx.ui.select(q.question, q.options);
        answers.push(answer);
      }

      return {
        content: [
          { 
            type: "text", 
            text: `User answers:\n${answers.map((a, i) => `${i + 1}. ${a}`).join("\n")}` 
          },
        ],
        details: { answers },
      };
    },
  });
}
```

### 3.4 SDK (嵌入式使用)

**适用场景**: 将 Pi 嵌入到自己的应用中

**安装**:

```bash
npm install @earendil-works/pi-coding-agent
```

**示例 1: 最小化使用**

```typescript
import { 
  AuthStorage, 
  createAgentSession, 
  ModelRegistry, 
  SessionManager 
} from "@earendil-works/pi-coding-agent";

// 设置凭证存储和模型注册表
const authStorage = AuthStorage.create();
const modelRegistry = ModelRegistry.create(authStorage);

const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
  authStorage,
  modelRegistry,
});

// 订阅事件
session.subscribe((event) => {
  if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
    process.stdout.write(event.assistantMessageEvent.delta);
  }
});

// 发送提示
await session.prompt("What files are in the current directory?");
```

**示例 2: 自定义模型和工具**

```typescript
import { createAgentSession, SessionManager } from "@earendil-works/pi-coding-agent";
import { getModel } from "@earendil-works/pi-ai";

const opus = getModel("anthropic", "claude-opus-4-5");

const { session } = await createAgentSession({
  model: opus,
  thinkingLevel: "medium",
  tools: ["read", "write", "bash"], // 限制可用工具
  sessionManager: SessionManager.inMemory(),
});

// 监听完整事件流
session.subscribe((event) => {
  switch (event.type) {
    case "tool_execution_start":
      console.log(`Tool: ${event.toolName}`);
      break;
    case "tool_execution_end":
      console.log(`Result: ${event.isError ? "error" : "success"}`);
      break;
    case "agent_end":
      console.log("Agent finished processing");
      break;
  }
});

await session.prompt("Analyze this codebase and suggest improvements");
```

**示例 3: 构建 Web UI**

```typescript
import express from "express";
import { createAgentSession, SessionManager } from "@earendil-works/pi-coding-agent";

const app = express();
app.use(express.json());

app.post("/api/chat", async (req, res) => {
  const { message } = req.body;

  const { session } = await createAgentSession({
    sessionManager: SessionManager.inMemory(),
  });

  let response = "";

  session.subscribe((event) => {
    if (event.type === "message_update" && event.assistantMessageEvent.type === "text_delta") {
      response += event.assistantMessageEvent.delta;
    }
  });

  await session.prompt(message);

  res.json({ response });
});

app.listen(3000, () => {
  console.log("Server running on http://localhost:3000");
});
```

**示例 4: 自动化管道**

```typescript
import { createAgentSession, SessionManager } from "@earendil-works/pi-coding-agent";

async function analyzeCodebase() {
  const { session } = await createAgentSession({
    sessionManager: SessionManager.inMemory(),
    model: getModel("anthropic", "claude-sonnet-4-5"),
  });

  // 收集分析结果
  const results: string[] = [];

  session.subscribe((event) => {
    if (event.type === "message_end") {
      results.push(event.message.content);
    }
  });

  // 多轮对话
  await session.prompt("Find all security vulnerabilities in this codebase");
  await session.prompt("Suggest fixes for each vulnerability");
  await session.prompt("Generate a report in Markdown format");

  return results;
}

analyzeCodebase().then(console.log);
```

---

## 四、事件系统详解

### 4.1 生命周期概览

```
pi starts
 │
 ├─► project_trust (项目信任决策)
 ├─► session_start { reason: "startup" }
 └─► resources_discover { reason: "startup" }
 │
 ▼
user sends prompt
 │
 ├─► input (可拦截、转换或处理)
 ├─► before_agent_start (可注入消息、修改系统提示)
 ├─► agent_start
 ├─► message_start / message_update / message_end
 │
 │ ┌─── turn (重复直到 LLM 不再调用工具) ───┐
 │ │                                         │
 │ ├─► turn_start                            │
 │ ├─► context (可修改消息)                   │
 │ ├─► before_provider_request (可检查或替换)  │
 │ ├─► after_provider_response (流消费前)      │
 │ │                                         │
 │ │ LLM 响应,可能调用工具:                    │
 │ │ ├─► tool_execution_start                │
 │ │ ├─► tool_call (可阻止)                   │
 │ │ ├─► tool_execution_update               │
 │ │ ├─► tool_result (可修改)                 │
 │ │ └─► tool_execution_end                  │
 │ │                                         │
 │ └─► turn_end                              │
 │                                           │
 └─► agent_end ──────────────────────────────┘
 │
 ▼
user sends another prompt
```

### 4.2 关键事件示例

**session_start**: 会话启动

```typescript
pi.on("session_start", async (event, ctx) => {
  // event.reason: "startup" | "reload" | "new" | "resume" | "fork"
  ctx.ui.notify(`Session started: ${event.reason}`, "info");
});
```

**tool_call**: 工具调用前拦截

```typescript
pi.on("tool_call", async (event, ctx) => {
  if (event.toolName === "bash") {
    const command = event.input.command;
    
    // 阻止危险命令
    if (command.includes("rm -rf")) {
      return { block: true, reason: "Dangerous command blocked" };
    }
    
    // 修改命令
    if (command.includes("sudo")) {
      return { 
        override: { 
          ...event.input, 
          command: command.replace("sudo", "") 
        } 
      };
    }
  }
});
```

**tool_result**: 工具结果后修改

```typescript
pi.on("tool_result", async (event, ctx) => {
  if (event.toolName === "read") {
    // 过滤敏感信息
    const content = event.result.content;
    const filtered = content.replace(/password|secret|key/gi, "[REDACTED]");
    
    return {
      override: {
        ...event.result,
        content: filtered,
      },
    };
  }
});
```

**context**: 修改上下文消息

```typescript
pi.on("context", async (event, ctx) => {
  // 注入额外上下文
  const messages = event.messages;
  messages.push({
    role: "user",
    content: "Remember: Always use TypeScript strict mode",
  });
  
  return { messages };
});
```

**before_agent_start**: Agent 启动前

```typescript
pi.on("before_agent_start", async (event, ctx) => {
  // 修改系统提示
  const systemPrompt = event.systemPrompt + "\n\nAlways respond in Chinese.";
  
  // 注入初始消息
  const messages = [
    {
      role: "user",
      content: "Current project context: ...",
    },
  ];
  
  return { systemPrompt, messages };
});
```

### 4.3 ExtensionContext API

`ctx` 对象提供丰富的 API:

```typescript
// 用户交互
await ctx.ui.confirm("Title", "Question");  // 确认对话框
await ctx.ui.select("Title", ["Option 1", "Option 2"]);  // 选择
await ctx.ui.input("Title", "Default value");  // 输入
ctx.ui.notify("Message", "info");  // 通知
ctx.ui.setStatus("my-ext", "Processing...");  // 页脚状态
ctx.ui.setWidget("my-ext", ["Line 1", "Line 2"]);  // 编辑器上方组件

// 会话管理
ctx.sessionManager.getSessionFile();  // 获取会话文件路径
ctx.sessionManager.getSessionId();    // 获取会话 ID

// 模型控制
ctx.modelRegistry.find("provider", "model");  // 查找模型
ctx.model;  // 当前模型

// 状态控制
ctx.isIdle();  // 是否空闲
ctx.abort();   // 中止当前操作
ctx.hasPendingMessages();  // 是否有待处理消息

// 上下文管理
ctx.getContextUsage();  // 获取上下文使用情况
await ctx.compact();    // 压缩上下文
ctx.getSystemPrompt();  // 获取系统提示

// 会话操作
await ctx.newSession();  // 新建会话
await ctx.fork(entryId);  // 分叉会话
await ctx.navigateTree(targetId);  // 树导航
await ctx.switchSession(sessionPath);  // 切换会话
```

---

## 五、上下文工程

### 5.1 AGENTS.md (项目指令)

**位置**:
- 全局: `~/.pi/agent/AGENTS.md`
- 项目: 从当前目录向上遍历,所有 `AGENTS.md` 都会拼接

**用途**: 项目级指令、约定、常用命令

**示例**:

```markdown
# Project Instructions

## Tech Stack
- Backend: Spring Boot 2.7 + MyBatis-Plus
- Frontend: Vue 3 + Element Plus
- Database: MySQL 8.0

## Code Style
- Use TypeScript strict mode
- Follow Alibaba Java Development Guidelines
- Use Prettier for formatting

## Common Commands
- Build: `mvn clean package`
- Test: `mvn test`
- Frontend dev: `cd shengyu-ui && npm run dev`

## Architecture
- Multi-tenant SaaS system
- Module-based architecture
- See docs/ for detailed documentation
```

### 5.2 SYSTEM.md (系统提示)

**位置**:
- 全局: `~/.pi/agent/SYSTEM.md`
- 项目: `.pi/SYSTEM.md`

**用途**: 替换或追加默认系统提示

**替换模式**:

```markdown
<!-- .pi/SYSTEM.md -->
You are a senior Java developer specializing in Spring Boot and enterprise SaaS applications.
Always respond in Chinese.
Follow best practices for security, performance, and maintainability.
```

**追加模式**:

```markdown
<!-- .pi/APPEND_SYSTEM.md -->
Additional context:
- This is a multi-tenant system
- Always consider tenant isolation
- Use the existing code generation framework
```

### 5.3 Compaction (上下文压缩)

**手动压缩**:

```
/compact  # 使用默认策略
/compact Focus on code changes and ignore discussions  # 自定义指令
```

**自动压缩**: 默认启用,接近上下文限制时触发

**自定义压缩策略** (通过扩展):

```typescript
// ~/.pi/agent/extensions/custom-compaction.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_before_compact", async (event, ctx) => {
    // 自定义压缩逻辑
    const messages = event.messages;
    
    // 保留最近的 10 条消息
    const recent = messages.slice(-10);
    
    // 摘要旧消息
    const old = messages.slice(0, -10);
    const summary = await summarizeMessages(old);
    
    return {
      messages: [
        { role: "user", content: `Previous context: ${summary}` },
        { role: "assistant", content: "Understood. Continuing from where we left off." },
        ...recent,
      ],
    };
  });
}

async function summarizeMessages(messages: any[]): Promise<string> {
  // 实现摘要逻辑 (可以调用 LLM)
  return "Summary of previous conversation...";
}
```

---

## 六、会话管理

### 6.1 会话存储

会话以 JSONL 文件形式存储在 `~/.pi/agent/sessions/`,按工作目录组织。

**会话格式**:

```jsonl
{"id":"entry-1","parentId":null,"type":"user","content":"Hello"}
{"id":"entry-2","parentId":"entry-1","type":"assistant","content":"Hi there!"}
{"id":"entry-3","parentId":"entry-2","type":"user","content":"How are you?"}
```

每个条目有 `id` 和 `parentId`,支持树状分支。

### 6.2 会话操作

**命令行**:

```bash
pi -c  # 继续最近会话
pi -r  # 浏览历史会话
pi --session <path|id>  # 指定会话
pi --fork <path|id>  # 从指定会话分叉
```

**交互模式**:

```
/tree  # 导航会话树
/fork  # 从历史消息分叉新会话
/clone  # 克隆当前分支
```

### 6.3 树状分支

Pi 的会话是树结构,支持从任意历史节点分叉:

```
entry-1 (user)
  └─ entry-2 (assistant)
       ├─ entry-3a (user) → entry-4a (assistant)  [分支 A]
       └─ entry-3b (user) → entry-4b (assistant)  [分支 B]
```

使用 `/tree` 可以:
- 搜索历史消息
- 跳转到任意节点
- 在不同分支间切换
- 标记书签

---

## 七、与当前项目集成方案

### 7.1 为圣钰 SaaS Pro 创建专属技能

**场景**: 让 Pi 理解项目架构,快速生成代码

**步骤 1: 创建技能目录**

```bash
mkdir -p .pi/skills/shengyu-codegen
```

**步骤 2: 编写 SKILL.md**

```markdown
---
name: shengyu-codegen
description: Generate CRUD code for Shengyu SaaS Pro platform. Use when user requests new module, entity, or CRUD functionality. Generates Spring Boot backend + Vue 3 frontend code following project conventions.
---

# Shengyu Code Generation Skill

## Project Context

Shengyu SaaS Pro is an enterprise-level multi-tenant SaaS system:
- Backend: Spring Boot 2.7 + MyBatis-Plus + MySQL 8.0
- Frontend: Vue 3 + Element Plus + TypeScript
- Architecture: Module-based, multi-tenant isolation

## Code Generation Workflow

When user requests a new module (e.g., "创建项目管理模块"):

### Step 1: Analyze Requirements

Extract:
- Entity name (e.g., "Project")
- Fields (name, type, validation rules)
- Relationships (1:N, N:M)
- Required features (CRUD, search, export)

### Step 2: Generate Backend Code

Generate the following files in `shengyu-module-xxx/`:

```
src/main/java/com/shengyu/module/xxx/
├── controller/
│   └── ProjectController.java
├── service/
│   ├── ProjectService.java
│   └── impl/
│       └── ProjectServiceImpl.java
├── mapper/
│   └── ProjectMapper.java
├── domain/
│   ├── Project.java
│   ├── dto/
│   │   ├── ProjectCreateDTO.java
│   │   ├── ProjectUpdateDTO.java
│   │   └── ProjectQueryDTO.java
│   └── vo/
│       └── ProjectVO.java
└── convert/
    └── ProjectConvert.java

src/main/resources/
└── mapper/
    └── xxx/
        └── ProjectMapper.xml
```

**Code Templates**:

```java
// ProjectController.java
@RestController
@RequestMapping("/api/{tenantId}/project")
public class ProjectController {
    
    @Autowired
    private ProjectService projectService;
    
    @PostMapping
    public R<Long> create(@RequestBody @Valid ProjectCreateDTO dto) {
        return R.ok(projectService.create(dto));
    }
    
    @DeleteMapping("/{id}")
    public R<Boolean> delete(@PathVariable Long id) {
        return R.ok(projectService.delete(id));
    }
    
    @PutMapping("/{id}")
    public R<Boolean> update(@PathVariable Long id, @RequestBody @Valid ProjectUpdateDTO dto) {
        return R.ok(projectService.update(id, dto));
    }
    
    @GetMapping("/{id}")
    public R<ProjectVO> getById(@PathVariable Long id) {
        return R.ok(projectService.getById(id));
    }
    
    @GetMapping("/page")
    public R<PageResult<ProjectVO>> page(ProjectQueryDTO query, PageParam pageParam) {
        return R.ok(projectService.page(query, pageParam));
    }
}
```

### Step 3: Generate Frontend Code

Generate in `shengyu-ui/shengyu-ui-admin-vue3/src/views/xxx/`:

```
project/
├── index.vue           # List page
├── ProjectForm.vue     # Create/Edit form
└── ProjectDetail.vue   # Detail page
```

**Vue Template**:

```vue
<!-- index.vue -->
<template>
  <div class="app-container">
    <!-- Search bar -->
    <el-form :model="queryParams" ref="queryRef" :inline="true">
      <el-form-item label="项目名称" prop="name">
        <el-input v-model="queryParams.name" placeholder="请输入项目名称" clearable />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="handleQuery">
          <el-icon><search /></el-icon>搜索
        </el-button>
        <el-button @click="resetQuery">
          <el-icon><refresh /></el-icon>重置
        </el-button>
      </el-form-item>
    </el-form>

    <!-- Toolbar -->
    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" @click="handleAdd">
          <el-icon><plus /></el-icon>新增
        </el-button>
      </el-col>
    </el-row>

    <!-- Table -->
    <el-table v-loading="loading" :data="list">
      <el-table-column label="项目名称" prop="name" />
      <el-table-column label="操作" fixed="right" width="200">
        <template #default="scope">
          <el-button link type="primary" @click="handleEdit(scope.row)">编辑</el-button>
          <el-button link type="danger" @click="handleDelete(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- Pagination -->
    <pagination
      v-show="total > 0"
      :total="total"
      v-model:page="queryParams.pageNo"
      v-model:limit="queryParams.pageSize"
      @pagination="getList"
    />

    <!-- Form Dialog -->
    <ProjectForm ref="formRef" @success="getList" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue';
import { ProjectApi } from '@/api/xxx/project';

const loading = ref(false);
const list = ref([]);
const total = ref(0);
const queryParams = ref({
  pageNo: 1,
  pageSize: 10,
  name: undefined,
});

const getList = async () => {
  loading.value = true;
  try {
    const { data } = await ProjectApi.page(queryParams.value);
    list.value = data.list;
    total.value = data.total;
  } finally {
    loading.value = false;
  }
};

const handleQuery = () => {
  queryParams.value.pageNo = 1;
  getList();
};

const resetQuery = () => {
  queryRef.value?.resetFields();
  handleQuery();
};

const handleAdd = () => {
  formRef.value?.open();
};

const handleEdit = (row: any) => {
  formRef.value?.open(row.id);
};

const handleDelete = async (row: any) => {
  await ProjectApi.delete(row.id);
  await getList();
};

onMounted(() => {
  getList();
});
</script>
```

### Step 4: Generate Database DDL

```sql
CREATE TABLE `xxx_project` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `tenant_id` bigint NOT NULL COMMENT '租户ID',
  `name` varchar(100) NOT NULL COMMENT '项目名称',
  `description` varchar(500) DEFAULT NULL COMMENT '项目描述',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态',
  `creator` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updater` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` bit(1) NOT NULL DEFAULT b'0' COMMENT '是否删除',
  PRIMARY KEY (`id`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='项目表';
```

### Step 5: Register Menu and Permissions

```sql
-- Menu
INSERT INTO system_menu (name, permission, type, sort, parent_id, path, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted, tenant_id)
VALUES ('项目管理', '', 1, 1, 0, '/project', 'xxx/project/index', 'Project', 0, true, true, true, 'admin', NOW(), 'admin', NOW(), 0, 1);

-- Permissions
INSERT INTO system_menu (name, permission, type, sort, parent_id, path, component, component_name, status, visible, keep_alive, always_show, creator, create_time, updater, update_time, deleted, tenant_id)
VALUES 
('项目查询', 'xxx:project:query', 3, 1, @menuId, '', '', '', 0, true, true, true, 'admin', NOW(), 'admin', NOW(), 0, 1),
('项目新增', 'xxx:project:create', 3, 2, @menuId, '', '', '', 0, true, true, true, 'admin', NOW(), 'admin', NOW(), 0, 1),
('项目修改', 'xxx:project:update', 3, 3, @menuId, '', '', '', 0, true, true, true, 'admin', NOW(), 'admin', NOW(), 0, 1),
('项目删除', 'xxx:project:delete', 3, 4, @menuId, '', '', '', 0, true, true, true, 'admin', NOW(), 'admin', NOW(), 0, 1);
```

## Validation Rules

- All entity names must be PascalCase
- All field names must be camelCase
- Table names must be snake_case with module prefix
- Always include tenant_id for multi-tenant isolation
- Always include audit fields (creator, create_time, updater, update_time)
- Always include soft delete field (deleted)

## Output Format

Generate all files in a single response, organized by directory structure.
Include file paths as comments at the top of each file.
```

**步骤 3: 使用技能**

```
# 在 Pi 中输入
/skill:shengyu-codegen 创建一个项目管理模块,包含项目名称、描述、状态、负责人字段
```

### 7.2 创建项目专属扩展

**场景**: 自动加载项目上下文,注入项目特定的工具和命令

**步骤 1: 创建扩展**

```typescript
// .pi/extensions/shengyu-context.ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { execSync } from "child_process";

export default function (pi: ExtensionAPI) {
  // 会话启动时加载项目上下文
  pi.on("session_start", async (event, ctx) => {
    ctx.ui.notify("Shengyu SaaS Pro context loaded", "info");
  });

  // 注入项目特定的上下文
  pi.on("before_agent_start", async (event, ctx) => {
    const projectContext = `
## Project Context

You are working on Shengyu SaaS Pro, an enterprise-level multi-tenant SaaS system.

### Tech Stack
- Backend: Spring Boot 2.7 + MyBatis-Plus + MySQL 8.0
- Frontend: Vue 3 + Element Plus + TypeScript
- Database: MySQL 8.0 with multi-tenant isolation

### Architecture
- Module-based structure
- Multi-tenant with tenant_id isolation
- Code generation framework available
- FlowLong workflow engine integrated

### Key Directories
- shengyu-module-*: Business modules
- shengyu-framework: Core framework
- shengyu-ui: Frontend applications
- docs: Documentation

### Conventions
- Follow Alibaba Java Development Guidelines
- Use TypeScript strict mode
- Always consider tenant isolation
- Use existing code generation for CRUD

### Common Commands
- Backend build: mvn clean package
- Backend test: mvn test
- Frontend dev: cd shengyu-ui/shengyu-ui-admin-vue3 && npm run dev
`;

    const systemPrompt = event.systemPrompt + "\n\n" + projectContext;

    return { systemPrompt };
  });

  // 注册项目特定的工具
  pi.registerTool({
    name: "shengyu_build",
    label: "Build Shengyu",
    description: "Build Shengyu SaaS Pro backend or frontend",
    parameters: Type.Object({
      target: Type.Union([Type.Literal("backend"), Type.Literal("frontend")]),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      try {
        if (params.target === "backend") {
          onUpdate({ type: "text", text: "Building backend...\n" });
          const output = execSync("mvn clean package -DskipTests", {
            encoding: "utf-8",
            maxBuffer: 10 * 1024 * 1024,
          });
          return {
            content: [{ type: "text", text: output }],
            details: { success: true },
          };
        } else {
          onUpdate({ type: "text", text: "Building frontend...\n" });
          const output = execSync(
            "cd shengyu-ui/shengyu-ui-admin-vue3 && npm run build",
            {
              encoding: "utf-8",
              maxBuffer: 10 * 1024 * 1024,
            }
          );
          return {
            content: [{ type: "text", text: output }],
            details: { success: true },
          };
        }
      } catch (error: any) {
        return {
          content: [{ type: "text", text: `Build failed: ${error.message}` }],
          details: { success: false, error: error.message },
        };
      }
    },
  });

  pi.registerTool({
    name: "shengyu_test",
    label: "Test Shengyu",
    description: "Run tests for Shengyu SaaS Pro",
    parameters: Type.Object({
      module: Type.Optional(Type.String({ description: "Module name (optional)" })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      try {
        const command = params.module
          ? `mvn test -pl shengyu-module-${params.module}`
          : "mvn test";

        onUpdate({ type: "text", text: `Running tests: ${command}\n` });

        const output = execSync(command, {
          encoding: "utf-8",
          maxBuffer: 10 * 1024 * 1024,
        });

        return {
          content: [{ type: "text", text: output }],
          details: { success: true },
        };
      } catch (error: any) {
        return {
          content: [{ type: "text", text: `Tests failed: ${error.message}` }],
          details: { success: false, error: error.message },
        };
      }
    },
  });

  // 注册项目命令
  pi.registerCommand("shengyu-status", {
    description: "Show Shengyu project status",
    handler: async (args, ctx) => {
      const { execSync } = await import("child_process");

      try {
        const gitStatus = execSync("git status --short", { encoding: "utf-8" });
        const gitBranch = execSync("git branch --show-current", { encoding: "utf-8" });

        ctx.ui.notify(`Branch: ${gitBranch.trim()}`, "info");
        ctx.ui.notify(`Changes:\n${gitStatus}`, "info");
      } catch (error) {
        ctx.ui.notify("Not a git repository", "warning");
      }
    },
  });
}
```

**步骤 2: 使用扩展**

扩展会自动加载,提供:
- 项目上下文注入
- `/shengyu-build` 命令
- `shengyu_build` 工具 (LLM 可调用)
- `shengyu_test` 工具
- `/shengyu-status` 命令

### 7.3 构建自定义 Web UI

**场景**: 为圣钰 SaaS Pro 构建 AI 辅助开发界面

**步骤 1: 创建后端服务**

```java
// shengyu-server/src/main/java/com/shengyu/controller/AiAssistantController.java
@RestController
@RequestMapping("/api/ai-assistant")
public class AiAssistantController {
    
    @Autowired
    private PiAgentService piAgentService;
    
    @PostMapping("/chat")
    public R<AiChatResponse> chat(@RequestBody AiChatRequest request) {
        return R.ok(piAgentService.chat(request));
    }
    
    @PostMapping("/code-generate")
    public R<CodeGenerateResponse> generateCode(@RequestBody CodeGenerateRequest request) {
        return R.ok(piAgentService.generateCode(request));
    }
}
```

**步骤 2: 集成 Pi SDK**

```java
// shengyu-server/src/main/java/com/shengyu/service/PiAgentService.java
@Service
public class PiAgentService {
    
    public AiChatResponse chat(AiChatRequest request) {
        // 调用 Pi SDK (通过 Node.js 进程或 HTTP API)
        // 这里使用 RPC 模式与 Pi 通信
        PiRpcClient client = new PiRpcClient();
        return client.prompt(request.getMessage());
    }
    
    public CodeGenerateResponse generateCode(CodeGenerateRequest request) {
        // 使用 Pi 的代码生成技能
        PiRpcClient client = new PiRpcClient();
        return client.generateCode(request.getRequirements());
    }
}
```

**步骤 3: 前端界面**

```vue
<!-- shengyu-ui/shengyu-ui-admin-vue3/src/views/ai-assistant/index.vue -->
<template>
  <div class="app-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>AI 开发助手</span>
        </div>
      </template>

      <!-- Chat area -->
      <div class="chat-area" ref="chatArea">
        <div v-for="(msg, index) in messages" :key="index" :class="['message', msg.role]">
          <div class="content" v-html="msg.content"></div>
        </div>
      </div>

      <!-- Input area -->
      <div class="input-area">
        <el-input
          v-model="inputMessage"
          type="textarea"
          :rows="4"
          placeholder="描述你的需求,例如: 创建一个项目管理模块..."
          @keydown.enter.exact="sendMessage"
        />
        <el-button type="primary" @click="sendMessage" :loading="loading">
          发送
        </el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue';
import { AiAssistantApi } from '@/api/ai-assistant';

const messages = ref([
  { role: 'assistant', content: '你好!我是 AI 开发助手,请描述你的需求。' },
]);
const inputMessage = ref('');
const loading = ref(false);
const chatArea = ref<HTMLElement>();

const sendMessage = async () => {
  if (!inputMessage.value.trim() || loading.value) return;

  // Add user message
  messages.value.push({
    role: 'user',
    content: inputMessage.value,
  });

  const userMessage = inputMessage.value;
  inputMessage.value = '';
  loading.value = true;

  try {
    // Call AI assistant API
    const { data } = await AiAssistantApi.chat({ message: userMessage });

    // Add assistant response
    messages.value.push({
      role: 'assistant',
      content: data.response,
    });

    // Scroll to bottom
    await nextTick();
    chatArea.value?.scrollTo(0, chatArea.value.scrollHeight);
  } catch (error) {
    messages.value.push({
      role: 'assistant',
      content: '抱歉,发生了错误,请重试。',
    });
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
.chat-area {
  height: 500px;
  overflow-y: auto;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 20px;
  margin-bottom: 20px;
}

.message {
  margin-bottom: 20px;
  display: flex;
}

.message.user {
  justify-content: flex-end;
}

.message .content {
  max-width: 70%;
  padding: 12px 16px;
  border-radius: 8px;
}

.message.user .content {
  background: #409eff;
  color: white;
}

.message.assistant .content {
  background: #f4f4f5;
  color: #303133;
}

.input-area {
  display: flex;
  gap: 10px;
}

.input-area .el-input {
  flex: 1;
}
</style>
```

---

## 八、最佳实践

### 8.1 扩展开发

1. **单一职责**: 每个扩展只做一件事
2. **错误处理**: 始终捕获异常,避免扩展崩溃
3. **资源清理**: 在 `session_shutdown` 事件中清理资源
4. **性能考虑**: 避免在事件处理器中执行耗时操作
5. **安全性**: 谨慎处理用户输入,防止注入攻击

### 8.2 技能开发

1. **清晰的描述**: description 决定何时加载技能,要具体
2. **渐进式披露**: 只在需要时加载完整指令
3. **相对路径**: 使用相对路径引用脚本和资源
4. **测试**: 在不同场景下测试技能
5. **文档**: 提供详细的使用示例

### 8.3 上下文工程

1. **精简 AGENTS.md**: 只包含关键信息
2. **分层上下文**: 全局 → 项目 → 模块
3. **动态注入**: 根据任务类型注入不同上下文
4. **压缩策略**: 自定义压缩逻辑,保留关键信息
5. **缓存友好**: 避免频繁变更系统提示

### 8.4 会话管理

1. **有意义的命名**: 使用 `/name` 给会话命名
2. **定期分叉**: 重要决策前分叉会话
3. **导出备份**: 定期导出重要会话
4. **树导航**: 熟练使用 `/tree` 回溯历史
5. **压缩时机**: 在上下文变大前主动压缩

---

## 九、常见问题

### Q1: 扩展和技能有什么区别?

- **扩展 (Extension)**: TypeScript 模块,可以注册工具、命令、监听事件,深度定制 Pi 行为
- **技能 (Skill)**: Markdown 指令包,提供可复用的工作流,按需加载

**选择建议**:
- 需要代码逻辑 → 扩展
- 需要工作流指令 → 技能
- 需要用户交互 → 扩展
- 需要文档参考 → 技能

### Q2: 如何在没有网络的环境使用?

```bash
# 离线模式启动
pi --offline

# 使用本地模型 (Ollama)
# 1. 安装 Ollama: https://ollama.com
# 2. 拉取模型: ollama pull llama2
# 3. 配置 Pi 使用本地模型
```

### Q3: 如何调试扩展?

```typescript
// 在扩展中使用 console.log
pi.on("tool_call", async (event, ctx) => {
  console.log("Tool call:", event.toolName, event.input);
  // 查看 Pi 的输出
});

// 使用调试器
// 1. 设置环境变量
// NODE_OPTIONS="--inspect"

// 2. 启动 Pi
// pi

// 3. 使用 Chrome DevTools 连接
// chrome://inspect
```

### Q4: 如何限制 Token 使用?

```typescript
// 在扩展中监控 Token 使用
pi.on("turn_end", async (event, ctx) => {
  const usage = ctx.getContextUsage();
  
  if (usage.tokens > 100000) {
    ctx.ui.notify("High token usage, consider compacting", "warning");
  }
});

// 手动压缩
// /compact
```

### Q5: 如何与现有 CI/CD 集成?

```bash
# 在 CI 脚本中使用 Pi
pi -p "Review this PR and check for security issues" --mode json > review.json

# 解析结果
jq '.messages[] | select(.role == "assistant")' review.json
```

---

## 十、参考资源

### 官方文档

- 主站: https://pi.dev/
- 文档: https://pi.dev/docs/latest
- GitHub: https://github.com/earendil-works/pi
- 示例: https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples

### 社区资源

- Discord: https://discord.com/invite/nKXTsAcmbT
- Pi Packages: https://pi.dev/packages
- Skills 仓库: https://github.com/badlogic/pi-skills

### 相关项目

- OpenClaw (SDK 集成示例): https://github.com/openclaw/openclaw
- Agent Skills 标准: https://agentskills.io/

---

## 十一、总结

Pi Agent Harness 的核心价值在于:

1. **极简核心**: 不预设工作流,让用户自己构建
2. **高度可扩展**: 4 种扩展方式,从简单到复杂
3. **自我定制**: AI 可以修改自己的代码和配置
4. **树状历史**: 支持分支和回溯的会话管理
5. **包生态**: 扩展、技能、提示、主题可以打包分享

**对于圣钰 SaaS Pro 的价值**:

1. **快速代码生成**: 通过 Skills 封装项目特定的代码生成逻辑
2. **项目上下文**: 通过 Extensions 自动注入项目架构和约定
3. **自动化工作流**: 通过 SDK 集成到现有开发流程
4. **团队协作**: 通过 Packages 分享团队的最佳实践

**下一步行动**:

1. 安装 Pi 并熟悉基础使用
2. 为项目创建第一个 Skill (代码生成)
3. 创建项目专属 Extension (上下文注入)
4. 探索 SDK 集成方案
5. 建立团队的 Pi Packages 生态

---

*文档版本: v1.0*  
*创建时间: 2026-06-30*  
*基于 Pi v0.75.5*
