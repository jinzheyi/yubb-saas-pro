# 对标 NocoBase "AI + 无代码" 平台架构设计文档

> 文档版本：v2.3（深度细化版）
> 创建时间：2026-07-09
> 最后更新：2026-07-20
> 关联文档：[NocoBase 技术调研报告](nocobase-technical-research.md)
> 状态：**持续优化中，待达到可直接动工程度**

---

## 一、设计目标

### 1.1 核心目标

**完全对标 NocoBase 的"AI + 无代码"模式**，实现：

```
用户自然语言描述 → AI 理解意图 → 生成 Schema JSON → 存储到数据库 → 前端运行时渲染 → 业务系统立即可用
```

**关键特征**：
- 没有"生成代码 → 编译 → 部署"流程
- 所有页面都是数据库中的 Schema JSON
- 前端运行时解析 Schema 动态渲染 UI
- AI 操作的是 JSON，不是代码

### 1.2 与旧方案的本质区别

| 维度 | 旧方案（v1.0） | 新方案（v2.0） |
|------|--------------|--------------|
| **本质** | 低代码（生成代码） | 无代码（运行时渲染） |
| **页面存储** | .vue 文件（编译产物） | Schema JSON（数据库记录） |
| **页面渲染** | Vue 编译器 | SchemaRenderer 运行时解析 |
| **数据模型** | Java Entity（编译产物） | Collection 元数据（数据库记录） |
| **API** | Controller 代码（编译产物） | DynamicController 运行时生成 |
| **AI 产物** | 代码文件 | JSON Schema |
| **部署** | 需要重新编译部署 | 即时生效，无需部署 |
| **Schema 引擎** | form-create（仅表单） | **Formily Vue（全页面）** |

### 1.3 关键发现：NocoBase 就是基于 Formily 的

通过源码调研发现，NocoBase 的核心渲染引擎就是 Formily：

```
NocoBase 源码证据：
├── NocoBaseField.tsx          → 封装 Formily 字段组件
├── NocoBaseReactiveField.tsx  → 基于 Formily 的响应式字段渲染
├── createNocoBaseField.ts     → Formily 字段工厂函数
├── SchemaComponent.tsx        → 基于 Formily RecursionField 的递归渲染
└── SchemaComponentProvider    → Formily Schema 上下文提供者
```

**结论**：选择 Formily Vue 作为 Schema 引擎，是复刻 NocoBase 的正确技术路径。

---

## 二、技术选型

### 2.1 核心技术栈

| 层次 | 技术选型 | 说明 |
|------|---------|------|
| **前端框架** | Vue 3.5 + TypeScript | 保持不变 |
| **UI 组件库** | Element Plus | 保持不变 |
| **Schema 引擎** | **@formily/vue + @formily/element-plus** | **替换 form-create** |
| **Schema 设计器** | **@formily/designable** | **替换 form-create Designer** |
| **后端框架** | Spring Boot | 保持不变 |
| **ORM** | MyBatis / JdbcTemplate | 动态 API 用 JdbcTemplate |
| **工作流** | FlowLong | 保持不变 |
| **AI 协议** | OpenAI Function Calling 兼容格式 | 新增 |

### 2.2 Formily Vue 核心能力（对标 NocoBase 的关键）

#### 2.2.1 Schema 结构

Formily 使用 JSON Schema 标准，扩展了以下关键属性：

```json
{
  "type": "object",
  "properties": {
    "fieldName": {
      "type": "string",
      "title": "字段标题",
      "x-component": "Input",           // 使用的组件
      "x-decorator": "FormItem",         // 装饰器（布局容器）
      "x-reactions": "...",              // 联动规则
      "x-validator": "...",             // 校验规则
      "x-component-props": {},           // 组件属性
      "x-decorator-props": {}            // 装饰器属性
    }
  }
}
```

#### 2.2.2 递归渲染机制

```
SchemaJSON → SchemaField（Formily 核心组件）→ 递归解析 → 组件注册表查找 → 渲染实际组件
```

- `SchemaField` 是 Formily 的核心渲染组件
- 它递归遍历 Schema 树，为每个节点查找注册的组件并渲染
- 支持任意深度的嵌套和布局

#### 2.2.3 组件注册

```typescript
import { createForm } from '@formily/vue'
import { createSchemaField } from '@formily/vue'

const { SchemaField } = createSchemaField({
  components: {
    Input,           // 输入框
    Select,          // 下拉选择
    Table,           // 表格（自定义）
    FormLayout,      // 布局容器
    FormItem,        // 表单项装饰器
    // ... 注册所有可用组件
  }
})
```

#### 2.2.4 为什么 Formily 能支撑"无代码"

| 能力 | Formily 支持 | 说明 |
|------|-------------|------|
| 表单渲染 | ✅ | 原生能力 |
| 表格渲染 | ✅ | 通过自定义 Table 组件 |
| 详情渲染 | ✅ | 通过自定义 Description 组件 |
| 页面布局 | ✅ | 通过 Space/Card/Grid 等布局组件 |
| 组件嵌套 | ✅ | Schema 递归渲染 |
| 字段联动 | ✅ | x-reactions 强大联动 |
| 动态组件 | ✅ | 运行时注册组件 |
| 自定义扩展 | ✅ | 可注册任意自定义组件 |

**结论**：Formily Vue 的能力完全满足"无代码"平台的需求，NocoBase 已经验证了这条路径。

---

## 三、整体架构设计

### 3.1 系统架构全景

```
┌─────────────────────────────────────────────────────────────────────┐
│                          用户交互层                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐│
│  │ 可视化设计器  │  │ AI 对话界面   │  │ AI Agent     │  │ 管理后台 ││
│  │ (Designable) │  │ (Chat UI)    │  │ (MCP/API)    │  │ (Admin)  ││
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └────┬─────┘│
│         └──────────────────┼──────────────────┼──────────────┘      │
│                            ↓                  ↓                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     Schema 操作层                               │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │   │
│  │  │Schema Storage│  │Schema Render │  │Schema Validator    │  │   │
│  │  │(数据库存储)   │  │(Formily 渲染) │  │(格式/业务校验)     │  │   │
│  │  └──────────────┘  └──────────────┘  └────────────────────┘  │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              ↓                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     AI 能力层                                   │   │
│  │  ┌───────────┐  ┌──────────────┐  ┌──────────────────────┐   │   │
│  │  │LLM Client │  │AI Employee   │  │Tools / Skills        │   │   │
│  │  │(多模型支持)│  │(AI 员工实体)  │  │(Function Calling)    │   │   │
│  │  └───────────┘  └──────────────┘  └──────────────────────┘   │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              ↓                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     元数据驱动层                                 │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │   │
│  │  │Collection    │  │Field         │  │Dynamic API         │  │   │
│  │  │(数据集合)     │  │(字段定义)     │  │(运行时 CRUD)       │  │   │
│  │  └──────────────┘  └──────────────┘  └────────────────────┘  │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              ↓                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     基础设施层                                   │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐ │   │
│  │  │RBAC    │ │Data-   │ │Tenant  │ │Dict    │ │Workflow    │ │   │
│  │  │权限     │ │Scope   │ │多租户   │ │字典     │ │FlowLong   │ │   │
│  │  └────────┘ └────────┘ └────────┘ └────────┘ └────────────┘ │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 核心数据流

```
┌─────────────────────────────────────────────────────────────────────┐
│  场景：用户说"创建一个客户管理系统"                                      │
│                                                                      │
│  1. 用户输入 → AI 对话界面                                            │
│     "创建一个客户管理系统，包含客户名称、电话、邮箱、跟进状态"              │
│                                                                      │
│  2. AI 理解意图 → 调用工具                                            │
│     LLM 分析 → tool_calls:                                          │
│       - create_collection(name="customer", fields=[...])             │
│       - create_page_schema(pageKey="customer-list", schema={...})    │
│       - create_page_schema(pageKey="customer-form", schema={...})    │
│       - add_menu(path="/customer", title="客户管理")                  │
│                                                                      │
│  3. 工具执行 → 数据库写入                                             │
│     → system_collection 表：插入 customer 集合元数据                   │
│     → system_field 表：插入 name/phone/email/status 字段              │
│     → system_page_schema 表：插入列表页和表单页 Schema                 │
│     → system_menu 表：插入菜单项                                      │
│     → 数据库：CREATE TABLE customer (...)                             │
│                                                                      │
│  4. 前端渲染 → 即时可用                                               │
│     → 用户点击"客户管理"菜单                                           │
│     → 路由 /dynamic/customer-list                                    │
│     → SchemaRenderer 加载 Schema JSON                                │
│     → Formily 递归渲染 → 用户看到完整的客户列表页面                     │
│                                                                      │
│  全程无代码生成、无编译、无部署！                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 四、前端架构设计

### 4.1 前端项目重构方案

```
shengyu-ui-admin-vue3/
├── src/
│   ├── core/                          # 【新建】无代码核心层
│   │   ├── schema/                    # Schema 引擎
│   │   │   ├── SchemaRenderer.vue     # 统一 Schema 渲染入口
│   │   │   ├── SchemaFieldProvider.ts # Formily SchemaField 配置
│   │   │   └── componentRegistry.ts   # 组件注册表
│   │   ├── components/                # 注册到 Formily 的组件库
│   │   │   ├── data-display/          # 数据展示组件
│   │   │   │   ├── TableField.vue     # 表格字段
│   │   │   │   ├── DetailField.vue    # 详情字段
│   │   │   │   ├── StatisticField.vue # 统计字段
│   │   │   │   └── ...
│   │   │   ├── data-entry/            # 数据录入组件
│   │   │   │   ├── (复用 Element Plus 组件)
│   │   │   │   └── ...
│   │   │   ├── layout/               # 布局组件
│   │   │   │   ├── PageLayout.vue     # 页面布局
│   │   │   │   ├── CardLayout.vue     # 卡片布局
│   │   │   │   ├── GridLayout.vue     # 网格布局
│   │   │   │   └── ...
│   │   │   ├── action/               # 操作组件
│   │   │   │   ├── ActionButton.vue   # 操作按钮
│   │   │   │   ├── ActionBar.vue      # 操作栏
│   │   │   │   └── ...
│   │   │   └── business/             # 业务组件
│   │   │       ├── CollectionSelect.vue  # 数据集合选择
│   │   │       ├── FieldSelect.vue       # 字段选择
│   │   │       ├── DictSelect.vue        # 字典选择
│   │   │       └── ...
│   │   ├── blocks/                    # 区块系统（对标 NocoBase Block）
│   │   │   ├── TableBlock.vue         # 表格区块
│   │   │   ├── FormBlock.vue          # 表单区块
│   │   │   ├── DetailBlock.vue        # 详情区块
│   │   │   ├── ChartBlock.vue         # 图表区块
│   │   │   └── ...
│   │   ├── collection/                # 数据集合前端支持
│   │   │   ├── CollectionManager.ts   # 集合管理器
│   │   │   ├── useCollection.ts       # 集合 Hook
│   │   │   └── useField.ts           # 字段 Hook
│   │   └── dynamic/                   # 动态路由/页面
│   │       ├── DynamicRouter.ts       # 动态路由管理
│   │       └── DynamicPage.vue        # 动态页面容器
│   │
│   ├── designer/                      # 【新建】可视化设计器
│   │   ├── SchemaDesigner.vue         # 设计器主界面
│   │   ├── panels/                    # 面板
│   │   │   ├── ComponentPanel.vue     # 组件面板
│   │   │   ├── PropertyPanel.vue      # 属性面板
│   │   │   ├── TreePanel.vue          # 大纲树面板
│   │   │   └── PreviewPanel.vue       # 预览面板
│   │   └── settings/                  # 组件配置定义
│   │       ├── tableSettings.ts       # 表格组件配置
│   │       ├── formSettings.ts        # 表单组件配置
│   │       └── ...
│   │
│   ├── ai/                            # 【新建】AI 交互层
│   │   ├── AiChat.vue                 # AI 对话组件
│   │   ├── AiChatService.ts           # AI 对话服务
│   │   ├── AiActionRenderer.vue       # AI 操作结果渲染
│   │   └── AiFloatingButton.vue       # AI 悬浮按钮（全局可用）
│   │
│   ├── router/
│   │   └── index.ts                   # 【改造】加入动态路由
│   │
│   └── ... (其他现有目录保持不变)
```

### 4.2 SchemaRenderer 核心设计

```vue
<!-- SchemaRenderer.vue - 统一 Schema 渲染入口 -->
<template>
  <FormProvider :form="form">
    <SchemaField :schema="schema" />
  </FormProvider>
</template>

<script setup lang="ts">
import { createForm } from '@formily/vue'
import { SchemaField } from './SchemaFieldProvider'
import { useSchemaLoader } from './hooks/useSchemaLoader'
import { useCollectionData } from './hooks/useCollectionData'

const props = defineProps<{
  pageKey: string  // 页面唯一标识，从路由参数获取
}>()

// 1. 从后端加载 Schema JSON
const { schema, loading } = useSchemaLoader(props.pageKey)

// 2. 创建 Formily Form 实例
const form = createForm({
  validateFirst: true,
})

// 3. 如果 Schema 绑定了数据集合，加载数据
const { data, refresh } = useCollectionData(schema, form)

// 4. Schema 中的 x-reactions 会自动处理联动
// 5. Formily 递归渲染 Schema 为 UI
</script>
```

### 4.3 组件注册表

```typescript
// componentRegistry.ts - 注册所有可用组件到 Formily
import { Input, Select, DatePicker, ... } from 'element-plus'
import { TableField } from './components/data-display/TableField.vue'
import { DetailField } from './components/data-display/DetailField.vue'
import { PageLayout } from './components/layout/PageLayout.vue'
import { ActionButton } from './components/action/ActionButton.vue'
// ...

export const componentRegistry = {
  // === 数据录入组件 ===
  Input,
  InputNumber,
  Select,
  MultiSelect,
  DatePicker,
  TimePicker,
  Switch,
  Checkbox,
  Radio,
  Upload,
  Editor,            // 富文本
  
  // === 数据展示组件 ===
  TableField,        // 表格（对标 NocoBase Table）
  DetailField,       // 详情展示
  StatisticField,    // 统计数值
  TagField,          // 标签
  ImageField,        // 图片
  
  // === 布局组件 ===
  PageLayout,        // 页面布局
  CardLayout,        // 卡片布局
  GridLayout,        // 网格布局
  Space,             // 间距
  Collapse,          // 折叠面板
  Tabs,              // 标签页
  
  // === 操作组件 ===
  ActionButton,      // 操作按钮
  ActionBar,         // 操作栏
  FilterAction,      // 筛选操作
  
  // === 业务组件 ===
  CollectionSelect,  // 数据集合选择
  FieldSelect,       // 字段选择
  DictSelect,        // 字典选择
  UserSelect,        // 用户选择
  DeptSelect,        // 部门选择
}
```

### 4.4 区块系统（对标 NocoBase Block）

区块是 NocoBase 页面的基本组成单元，每个区块绑定一个数据集合：

```vue
<!-- TableBlock.vue - 表格区块 -->
<template>
  <div class="nb-table-block">
    <!-- 搜索区域 -->
    <SchemaField v-if="schema.properties.search" :schema="schema.properties.search" />
    
    <!-- 操作栏 -->
    <ActionBar v-if="schema.properties.actions" :schema="schema.properties.actions" />
    
    <!-- 表格 -->
    <TableField
      :collection="collectionName"
      :columns="columns"
      :pagination="pagination"
      @row-click="handleRowClick"
    />
  </div>
</template>

<script setup lang="ts">
// 表格区块自动从绑定的 Collection 获取数据
// 自动根据字段元数据生成列配置
// 支持搜索、排序、分页、批量操作
</script>
```

### 4.5 动态路由

```typescript
// DynamicRouter.ts - 动态路由管理
export function setupDynamicRouter(router: Router) {
  // 注册动态页面路由模板
  router.addRoute({
    path: '/dynamic/:pageKey',
    name: 'DynamicPage',
    component: () => import('@/core/dynamic/DynamicPage.vue'),
    meta: { requiresAuth: true }
  })
}

// DynamicPage.vue - 动态页面容器
<template>
  <SchemaRenderer :page-key="pageKey" />
</template>

<script setup lang="ts">
import { useRoute } from 'vue-router'
const route = useRoute()
const pageKey = route.params.pageKey as string
</script>
```

### 4.6 菜单与路由的动态加载

```
后端 system_menu 表
    ↓
用户登录后，前端请求菜单 API
    ↓
后端返回菜单树（包含动态页面菜单）
    ↓
前端遍历菜单树：
    - 静态菜单 → 加载对应 .vue 组件
    - 动态菜单 → 指向 /dynamic/{pageKey}
    ↓
用户点击动态菜单 → SchemaRenderer 加载 Schema → 渲染页面
```

### 4.7 前端核心组件详细实现

#### 4.7.1 SchemaFieldProvider.ts — Formily SchemaField 初始化

```typescript
// src/core/schema/SchemaFieldProvider.ts
import { createSchemaField } from '@formily/vue'
import {
  FormItem,    // 表单项装饰器（来自 @formily/element-plus）
  FormLayout,  // 表单布局（来自 @formily/element-plus）
  Input,       // 输入框（来自 @formily/element-plus）
  Select,      // 下拉选择
  DatePicker,  // 日期选择
  TimePicker,  // 时间选择
  InputNumber, // 数字输入
  Switch,      // 开关
  Checkbox,    // 复选框
  Radio,       // 单选框
  Upload,      // 上传
  Space,       // 间距
  Card,        // 卡片
  Collapse,    // 折叠面板
  ArrayTable,  // 数组表格（Formily 内置）
  ArrayCards,  // 数组卡片（Formily 内置）
} from '@formily/element-plus'

// 自定义组件
import { TableBlock } from '../blocks/TableBlock'
import { FormBlock } from '../blocks/FormBlock'
import { DetailBlock } from '../blocks/DetailBlock'
import { FilterBlock } from '../blocks/FilterBlock'
import { PageLayout } from '../components/layout/PageLayout'
import { CardLayout } from '../components/layout/CardLayout'
import { GridLayout } from '../components/layout/GridLayout'
import { ActionBar } from '../components/action/ActionBar'
import { ActionButton } from '../components/action/ActionButton'
import { TableColumn } from '../components/data-display/TableColumn'
import { TagField } from '../components/data-display/TagField'
import { ImageField } from '../components/data-display/ImageField'
import { StatisticField } from '../components/data-display/StatisticField'
import { CollectionSelect } from '../components/business/CollectionSelect'
import { DictSelect } from '../components/business/DictSelect'
import { UserSelect } from '../components/business/UserSelect'
import { DeptSelect } from '../components/business/DeptSelect'

export const { SchemaField } = createSchemaField({
  components: {
    // === @formily/element-plus 内置组件 ===
    FormItem,
    FormLayout,
    Input,
    Select,
    DatePicker,
    TimePicker,
    InputNumber,
    Switch,
    Checkbox,
    Radio,
    Upload,
    Space,
    Card,
    Collapse,
    ArrayTable,
    ArrayCards,

    // === 区块组件（对标 NocoBase Block）===
    TableBlock,
    FormBlock,
    DetailBlock,
    FilterBlock,

    // === 布局组件 ===
    PageLayout,
    CardLayout,
    GridLayout,

    // === 操作组件 ===
    ActionBar,
    ActionButton,

    // === 数据展示组件 ===
    TableColumn,
    TagField,
    ImageField,
    StatisticField,

    // === 业务组件 ===
    CollectionSelect,
    DictSelect,
    UserSelect,
    DeptSelect,
  },
})
```

#### 4.7.2 useSchemaLoader.ts — Schema 加载 Hook

```typescript
// src/core/schema/hooks/useSchemaLoader.ts
import { ref, watchEffect } from 'vue'
import { getPageSchema } from '@/api/nocode/schema'

export interface SchemaLoadResult {
  schema: Ref<any>
  loading: Ref<boolean>
  error: Ref<string | null>
  reload: () => Promise<void>
}

/**
 * 从后端加载页面 Schema
 * 支持树形 Schema 的自动拼装（将子 Block 合并到根 Schema）
 */
export function useSchemaLoader(pageKey: Ref<string>): SchemaLoadResult {
  const schema = ref<any>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const loadSchema = async () => {
    if (!pageKey.value) return
    loading.value = true
    error.value = null
    try {
      // 后端返回的是拼装好的完整 Schema（包含所有子 Block）
      const res = await getPageSchema(pageKey.value)
      schema.value = res.data
    } catch (e: any) {
      error.value = e.message || '加载 Schema 失败'
    } finally {
      loading.value = false
    }
  }

  // 监听 pageKey 变化自动重新加载
  watchEffect(() => {
    loadSchema()
  })

  return { schema, loading, error, reload: loadSchema }
}
```

#### 4.7.3 useCollectionData.ts — 数据集合数据加载 Hook

```typescript
// src/core/schema/hooks/useCollectionData.ts
import { ref, onMounted } from 'vue'
import { Form } from '@formily/core'
import { dynamicApi } from '@/api/nocode/dynamic'

/**
 * 根据 Schema 中绑定的 collection 属性，自动从动态 API 加载数据
 * 支持列表（分页查询）和详情（单条查询）两种模式
 */
export function useCollectionData(
  schema: Ref<any>,
  form: Form
) {
  const data = ref<any[]>([])
  const total = ref(0)
  const loading = ref(false)

  // 从 Schema 中提取 collection 名称
  const getCollectionName = (s: any): string | null => {
    return s?.['x-component-props']?.collection || null
  }

  // 从 Schema 中提取分页参数
  const getPagination = (s: any) => {
    const p = s?.['x-component-props']?.pagination
    return { pageNo: 1, pageSize: p?.pageSize || 20 }
  }

  // 加载列表数据
  const loadData = async (filters?: Record<string, any>) => {
    const collectionName = getCollectionName(schema.value)
    if (!collectionName) return

    loading.value = true
    try {
      const pagination = getPagination(schema.value)
      const res = await dynamicApi.list(collectionName, {
        ...pagination,
        filters: filters || {},
      })
      data.value = res.data.records
      total.value = res.data.total

      // 将数据注入 Formily form
      form.setValues({ records: data.value, total: total.value })
    } finally {
      loading.value = false
    }
  }

  // 加载单条数据（详情页使用）
  const loadDetail = async (id: string | number) => {
    const collectionName = getCollectionName(schema.value)
    if (!collectionName) return

    loading.value = true
    try {
      const res = await dynamicApi.getById(collectionName, id)
      form.setValues(res.data)
      data.value = [res.data]
    } finally {
      loading.value = false
    }
  }

  return { data, total, loading, loadData, loadDetail }
}
```

#### 4.7.4 TableBlock.vue — 表格区块（核心组件）

```vue
<!-- src/core/blocks/TableBlock.vue -->
<template>
  <el-card class="nb-table-block" shadow="never">
    <!-- 搜索区域 -->
    <div v-if="hasFilter" class="nb-table-block__filter">
      <SchemaField v-if="filterSchema" :schema="filterSchema" />
    </div>

    <!-- 操作栏 -->
    <div class="nb-table-block__actions">
      <SchemaField v-if="actionSchema" :schema="actionSchema" />
    </div>

    <!-- 表格 -->
    <el-table
      :data="tableData"
      v-loading="loading"
      border
      stripe
      @selection-change="handleSelectionChange"
    >
      <!-- 根据 Schema 动态生成列 -->
      <el-table-column
        v-for="col in columns"
        :key="col.name"
        :prop="col.name"
        :label="col.title"
        :sortable="col.sortable"
        :width="col.width"
      >
        <template #default="{ row }">
          <component
            :is="col.component"
            :value="row[col.name]"
            :row="row"
            :field-config="col"
          />
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination
      v-if="pagination !== false"
      :current-page="pageNo"
      :page-size="pageSize"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @current-change="handlePageChange"
      @size-change="handleSizeChange"
    />
  </el-card>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, inject } from 'vue'
import { useFieldSchema } from '@formily/vue'
import { dynamicApi } from '@/api/nocode/dynamic'

const fieldSchema = useFieldSchema()

// 从 Schema 的 x-component-props 中读取配置
const collectionName = computed(() =>
  fieldSchema.value['x-component-props']?.collection
)
const pagination = computed(() =>
  fieldSchema.value['x-component-props']?.pagination ?? { pageSize: 20 }
)

// 解析列配置：从 Schema properties 中提取表格列
const columns = computed(() => {
  const props = fieldSchema.value.properties || {}
  return Object.entries(props)
    .filter(([_, v]: any) => v['x-component'] === 'TableColumn')
    .map(([name, v]: any) => ({
      name,
      title: v.title || name,
      sortable: v['x-component-props']?.sortable || false,
      width: v['x-component-props']?.width,
      component: resolveDisplayComponent(v),
    }))
})

// 解析搜索 Schema 和操作 Schema
const filterSchema = computed(() => fieldSchema.value.properties?.filter || null)
const actionSchema = computed(() => fieldSchema.value.properties?.actions || null)
const hasFilter = computed(() => !!filterSchema.value)

// 数据状态
const tableData = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const pageNo = ref(1)
const pageSize = ref(pagination.value?.pageSize || 20)

// 加载数据
const loadData = async (filters?: Record<string, any>) => {
  if (!collectionName.value) return
  loading.value = true
  try {
    const res = await dynamicApi.list(collectionName.value, {
      pageNo: pageNo.value,
      pageSize: pageSize.value,
      filters: filters || {},
    })
    tableData.value = res.data.records
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

// 分页事件
const handlePageChange = (page: number) => {
  pageNo.value = page
  loadData()
}
const handleSizeChange = (size: number) => {
  pageSize.value = size
  pageNo.value = 1
  loadData()
}
const handleSelectionChange = (rows: any[]) => {
  // 将选中行注入 form 供操作按钮使用
}

// 解析展示组件：根据字段类型决定用哪个组件展示
const resolveDisplayComponent = (fieldSchema: any) => {
  const type = fieldSchema.type
  const dictType = fieldSchema['x-component-props']?.dictType
  if (dictType) return 'DictTagCell'
  if (type === 'string') return 'TextCell'
  if (type === 'number') return 'NumberCell'
  if (type === 'boolean') return 'BooleanCell'
  if (type === 'datetime') return 'DateTimeCell'
  return 'TextCell'
}

onMounted(() => loadData())

// 暴露刷新方法供外部调用
defineExpose({ loadData })
</script>
```

#### 4.7.5 FormBlock.vue — 表单区块

```vue
<!-- src/core/blocks/FormBlock.vue -->
<template>
  <el-card class="nb-form-block" shadow="never">
    <FormProvider :form="form">
      <SchemaField :schema="formSchema" />
      <div class="nb-form-block__footer">
        <el-button @click="handleReset">重置</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ submitText }}
        </el-button>
      </div>
    </FormProvider>
  </el-card>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { createForm } from '@formily/core'
import { FormProvider } from '@formily/vue'
import { useFieldSchema } from '@formily/vue'
import { dynamicApi } from '@/api/nocode/dynamic'
import { ElMessage } from 'element-plus'

const fieldSchema = useFieldSchema()
const emit = defineEmits(['success'])

const collectionName = computed(() =>
  fieldSchema.value['x-component-props']?.collection
)
const mode = computed(() =>
  fieldSchema.value['x-component-props']?.mode || 'create' // create | edit
)
const recordId = computed(() =>
  fieldSchema.value['x-component-props']?.recordId
)
const submitText = computed(() => mode.value === 'edit' ? '保存' : '提交')

// 提取表单 Schema（去掉外层 FormBlock 包装）
const formSchema = computed(() => {
  const s = { ...fieldSchema.value }
  s['x-component'] = 'Form'
  s['x-decorator'] = 'FormLayout'
  return s
})

const form = createForm({
  validateFirst: true,
  initialValues: {},
})

const submitting = ref(false)

// 编辑模式：加载初始数据
if (mode.value === 'edit' && recordId.value) {
  dynamicApi.getById(collectionName.value, recordId.value).then(res => {
    form.setValues(res.data)
  })
}

const handleSubmit = async () => {
  try {
    await form.validate()
    submitting.value = true
    const values = form.values

    if (mode.value === 'edit') {
      await dynamicApi.update(collectionName.value, {
        id: recordId.value,
        ...values,
      })
      ElMessage.success('保存成功')
    } else {
      await dynamicApi.create(collectionName.value, values)
      ElMessage.success('创建成功')
    }
    emit('success')
  } catch (e: any) {
    if (e.message) ElMessage.error(e.message)
  } finally {
    submitting.value = false
  }
}

const handleReset = () => form.reset()
</script>
```

#### 4.7.6 FilterBlock.vue — 筛选区块

```vue
<!-- src/core/blocks/FilterBlock.vue -->
<template>
  <el-form :model="filterValues" inline class="nb-filter-block">
    <template v-for="(field, name) in filterFields" :key="name">
      <el-form-item :label="field.title">
        <component
          :is="resolveComponent(field)"
          v-model="filterValues[name]"
          v-bind="resolveProps(field)"
          :placeholder="field['x-component-props']?.placeholder || `请输入${field.title}`"
        />
      </el-form-item>
    </template>
    <el-form-item>
      <el-button type="primary" @click="handleSearch">查询</el-button>
      <el-button @click="handleReset">重置</el-button>
    </el-form-item>
  </el-form>
</template>

<script setup lang="ts">
import { reactive, computed } from 'vue'
import { useFieldSchema } from '@formily/vue'

const fieldSchema = useFieldSchema()
const emit = defineEmits(['search', 'reset'])

// 从 Schema properties 中提取筛选字段
const filterFields = computed(() => {
  const props = fieldSchema.value.properties || {}
  const result: Record<string, any> = {}
  for (const [name, field] of Object.entries(props)) {
    if ((field as any).type !== 'void') {
      result[name] = field
    }
  }
  return result
})

const filterValues = reactive<Record<string, any>>({})

const resolveComponent = (field: any) => {
  const comp = field['x-component'] || 'Input'
  // 映射到 Element Plus 组件
  const map: Record<string, string> = {
    'Input': 'el-input',
    'Select': 'el-select',
    'DatePicker': 'el-date-picker',
    'InputNumber': 'el-input-number',
  }
  return map[comp] || 'el-input'
}

const resolveProps = (field: any) => {
  return field['x-component-props'] || {}
}

const handleSearch = () => emit('search', { ...filterValues })
const handleReset = () => {
  Object.keys(filterValues).forEach(k => delete filterValues[k])
  emit('reset')
}
</script>
```

#### 4.7.7 DynamicPage.vue — 动态页面容器（完整版）

```vue
<!-- src/core/dynamic/DynamicPage.vue -->
<template>
  <div class="nb-dynamic-page" v-loading="loading">
    <template v-if="error">
      <el-result icon="error" :title="error" sub-title="页面加载失败">
        <template #extra>
          <el-button type="primary" @click="reload">重新加载</el-button>
        </template>
      </el-result>
    </template>
    <template v-else-if="schema">
      <FormProvider :form="form">
        <SchemaField :schema="schema" />
      </FormProvider>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { createForm } from '@formily/core'
import { FormProvider } from '@formily/vue'
import { SchemaField } from '../schema/SchemaFieldProvider'
import { useSchemaLoader } from '../schema/hooks/useSchemaLoader'

const route = useRoute()
const pageKey = computed(() => route.params.pageKey as string)

// 使用 Schema 加载 Hook
const { schema, loading, error, reload } = useSchemaLoader(pageKey)

// 创建 Formily Form 实例
const form = createForm({
  validateFirst: true,
})

// pageKey 变化时重置 form
watch(pageKey, () => {
  form.reset()
})
</script>

<style scoped>
.nb-dynamic-page {
  padding: 16px;
  min-height: calc(100vh - 120px);
}
</style>
```

#### 4.7.8 DynamicRouter.ts — 动态路由管理（完整版）

```typescript
// src/core/dynamic/DynamicRouter.ts
import type { Router } from 'vue-router'

/**
 * 注册动态页面路由
 * 所有通过无代码平台创建的页面都使用这个统一路由
 */
export function setupDynamicRouter(router: Router) {
  router.addRoute('Layout', {
    path: 'dynamic/:pageKey',
    name: 'DynamicPage',
    component: () => import('./DynamicPage.vue'),
    meta: {
      requiresAuth: true,
      // 标记为动态页面，用于菜单高亮等逻辑
      isDynamic: true,
    },
  })
}

/**
 * 根据后端返回的菜单数据，动态添加路由
 * 用于支持菜单中配置的动态页面
 */
export function addDynamicMenuRoutes(
  router: Router,
  menus: MenuTreeItem[]
) {
  const flatMenus = flattenMenu(menus)
  for (const menu of flatMenus) {
    if (menu.pageType === 'dynamic' && menu.pageKey) {
      // 动态页面已经由 /dynamic/:pageKey 统一处理
      // 这里只需要确保菜单能正确跳转
      menu.path = `/dynamic/${menu.pageKey}`
    }
  }
}

function flattenMenu(menus: MenuTreeItem[]): MenuTreeItem[] {
  const result: MenuTreeItem[] = []
  for (const menu of menus) {
    result.push(menu)
    if (menu.children?.length) {
      result.push(...flattenMenu(menu.children))
    }
  }
  return result
}
```

#### 4.7.9 前端 API 接口定义

```typescript
// src/api/nocode/dynamic.ts — 动态数据 API
import request from '@/config/axios'

export const dynamicApi = {
  // 分页查询
  list: (collectionName: string, data: {
    pageNo: number
    pageSize: number
    filters?: Record<string, any>
    sort?: Record<string, 'asc' | 'desc'>
  }) => {
    return request.post({
      url: `/api/dynamic/${collectionName}/list`,
      data,
    })
  },

  // 单条查询
  getById: (collectionName: string, id: string | number) => {
    return request.get({
      url: `/api/dynamic/${collectionName}/get`,
      params: { id },
    })
  },

  // 创建
  create: (collectionName: string, data: Record<string, any>) => {
    return request.post({
      url: `/api/dynamic/${collectionName}/create`,
      data,
    })
  },

  // 更新
  update: (collectionName: string, data: Record<string, any>) => {
    return request.post({
      url: `/api/dynamic/${collectionName}/update`,
      data,
    })
  },

  // 删除
  delete: (collectionName: string, ids: (string | number)[]) => {
    return request.post({
      url: `/api/dynamic/${collectionName}/delete`,
      data: { ids },
    })
  },
}
```

```typescript
// src/api/nocode/schema.ts — Schema 管理 API
import request from '@/config/axios'

export const getPageSchema = (pageKey: string) => {
  return request.get({
    url: `/admin/nocode/schema/${pageKey}`,
  })
}

export const savePageSchema = (data: {
  name: string
  collectionName?: string
  schemaType: string
  parentUid?: string
  schemaJson: any
}) => {
  return request.post({
    url: '/admin/nocode/schema/create',
    data,
  })
}

export const updatePageSchema = (uid: string, schemaJson: any) => {
  return request.post({
    url: `/admin/nocode/schema/${uid}/update`,
    data: { schemaJson },
  })
}
```

```typescript
// src/api/nocode/collection.ts — Collection 管理 API
import request from '@/config/axios'

export const collectionApi = {
  list: () => request.get({ url: '/admin/nocode/collection/list' }),

  get: (name: string) => request.get({ url: `/admin/nocode/collection/${name}` }),

  create: (data: {
    name: string
    displayName: string
    description?: string
    fields: Array<{
      name: string
      displayName: string
      fieldType: string
      dbType?: string
      isNullable?: boolean
      isUnique?: boolean
      defaultValue?: string
      validators?: any
      uiSchema?: any
      options?: any
    }>
  }) => request.post({ url: '/admin/nocode/collection/create', data }),

  addField: (collectionName: string, field: any) =>
    request.post({ url: `/admin/nocode/collection/${collectionName}/field/add`, data: field }),

  updateField: (collectionName: string, fieldName: string, field: any) =>
    request.post({ url: `/admin/nocode/collection/${collectionName}/field/${fieldName}/update`, data: field }),

  deleteField: (collectionName: string, fieldName: string) =>
    request.post({ url: `/admin/nocode/collection/${collectionName}/field/${fieldName}/delete` }),

  delete: (name: string) =>
    request.post({ url: `/admin/nocode/collection/${name}/delete` }),
}
```

### 4.8 前端 AI 对话组件详细实现

#### 4.8.1 AI 对话侧边栏整体架构

```
┌─────────────────────────────────────────┐
│  AI 助手                          [收起] │  ← AiChatSidebar.vue
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 用户: 帮我创建一个客户管理系统     │  │  ← MessageList.vue
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ AI: 好的，我来帮您创建...         │  │
│  │    ✓ 已创建集合: crm_customer     │  │  ← ToolCallResult.vue
│  │    ✓ 已创建页面: 客户列表         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ AI: 正在生成中...                 │  │  ← StreamingMessage.vue
│  │ ▊                                 │  │
│  └───────────────────────────────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  [输入消息...]                    [发送] │  ← MessageInput.vue
└─────────────────────────────────────────┘
```

#### 4.8.2 AiChatSidebar.vue — 主容器组件

```typescript
// src/components/AiChat/AiChatSidebar.vue
<template>
  <div class="ai-chat-sidebar" :class="{ collapsed: isCollapsed }">
    <div class="header">
      <span class="title">AI 助手</span>
      <el-button :icon="isCollapsed ? 'Expand' : 'Fold'" @click="toggleCollapse" />
    </div>
    
    <div v-show="!isCollapsed" class="content">
      <MessageList :messages="messages" :streaming="isStreaming" />
      <MessageInput 
        v-model="inputMessage" 
        :disabled="isStreaming"
        @send="handleSend"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'
import MessageList from './MessageList.vue'
import MessageInput from './MessageInput.vue'
import { useAiChat } from './composables/useAiChat'

const isCollapsed = ref(false)
const inputMessage = ref('')

const {
  messages,
  isStreaming,
  sendMessage,
  stopStream,
} = useAiChat()

const toggleCollapse = () => {
  isCollapsed.value = !isCollapsed.value
}

const handleSend = async () => {
  if (!inputMessage.value.trim()) return
  
  try {
    await sendMessage(inputMessage.value)
    inputMessage.value = ''
  } catch (error) {
    ElMessage.error('发送失败: ' + (error as Error).message)
  }
}
</script>

<style scoped>
.ai-chat-sidebar {
  width: 400px;
  height: 100vh;
  display: flex;
  flex-direction: column;
  border-left: 1px solid #e4e7ed;
  background: #fff;
  transition: width 0.3s;
}

.ai-chat-sidebar.collapsed {
  width: 60px;
}

.header {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 16px;
  border-bottom: 1px solid #e4e7ed;
}

.content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
</style>
```

#### 4.8.3 useAiChat.ts — AI 对话核心 Hook

```typescript
// src/components/AiChat/composables/useAiChat.ts
import { ref, reactive } from 'vue'
import { fetchEventSource } from '@microsoft/fetch-event-source'
import { useUserStore } from '@/store/modules/user'

export interface ChatMessage {
  id: string
  role: 'user' | 'assistant' | 'system' | 'tool'
  content: string
  toolCalls?: ToolCall[]
  toolResults?: ToolResult[]
  timestamp: number
  streaming?: boolean
}

export interface ToolCall {
  id: string
  type: 'function'
  function: {
    name: string
    arguments: string
  }
}

export interface ToolResult {
  toolCallId: string
  name: string
  success: boolean
  message: string
  data?: any
}

export function useAiChat() {
  const messages = ref<ChatMessage[]>([])
  const isStreaming = ref(false)
  const currentAbortController = ref<AbortController | null>(null)
  
  const userStore = useUserStore()
  const sessionId = ref(generateSessionId())

  const sendMessage = async (content: string) => {
    // 1. 添加用户消息
    const userMessage: ChatMessage = {
      id: generateId(),
      role: 'user',
      content,
      timestamp: Date.now(),
    }
    messages.value.push(userMessage)

    // 2. 创建 AI 回复占位
    const assistantMessage: ChatMessage = {
      id: generateId(),
      role: 'assistant',
      content: '',
      timestamp: Date.now(),
      streaming: true,
    }
    messages.value.push(assistantMessage)

    // 3. 发起 SSE 流式请求
    isStreaming.value = true
    currentAbortController.value = new AbortController()

    try {
      await fetchEventSource('/admin/ai/chat/stream', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${userStore.token}`,
        },
        body: JSON.stringify({
          sessionId: sessionId.value,
          message: content,
          history: messages.value.slice(0, -1).map(m => ({
            role: m.role,
            content: m.content,
          })),
        }),
        signal: currentAbortController.value.signal,
        
        onopen: async (response) => {
          if (response.ok) {
            console.log('SSE 连接已建立')
          } else {
            throw new Error(`SSE 连接失败: ${response.status}`)
          }
        },
        
        onmessage: (event) => {
          if (event.event === 'message') {
            // 普通文本消息
            const data = JSON.parse(event.data)
            assistantMessage.content += data.content || ''
          } else if (event.event === 'tool_call') {
            // 工具调用
            const toolCall: ToolCall = JSON.parse(event.data)
            assistantMessage.toolCalls = assistantMessage.toolCalls || []
            assistantMessage.toolCalls.push(toolCall)
          } else if (event.event === 'tool_result') {
            // 工具执行结果
            const toolResult: ToolResult = JSON.parse(event.data)
            assistantMessage.toolResults = assistantMessage.toolResults || []
            assistantMessage.toolResults.push(toolResult)
          } else if (event.event === 'done') {
            // 流式结束
            assistantMessage.streaming = false
            isStreaming.value = false
          } else if (event.event === 'error') {
            // 错误
            const error = JSON.parse(event.data)
            assistantMessage.content += `\n\n[错误] ${error.message}`
            assistantMessage.streaming = false
            isStreaming.value = false
          }
        },
        
        onclose: () => {
          console.log('SSE 连接已关闭')
          assistantMessage.streaming = false
          isStreaming.value = false
        },
        
        onerror: (error) => {
          console.error('SSE 错误:', error)
          assistantMessage.content += `\n\n[错误] 连接中断`
          assistantMessage.streaming = false
          isStreaming.value = false
          throw error // 停止重试
        },
      })
    } catch (error) {
      if ((error as Error).name !== 'AbortError') {
        console.error('发送消息失败:', error)
        throw error
      }
    }
  }

  const stopStream = () => {
    if (currentAbortController.value) {
      currentAbortController.value.abort()
      currentAbortController.value = null
    }
    isStreaming.value = false
  }

  const clearMessages = () => {
    messages.value = []
    sessionId.value = generateSessionId()
  }

  return {
    messages,
    isStreaming,
    sendMessage,
    stopStream,
    clearMessages,
  }
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).substring(2)
}

function generateSessionId(): string {
  return 'session_' + generateId()
}
```

#### 4.8.4 MessageList.vue — 消息列表组件

```typescript
// src/components/AiChat/MessageList.vue
<template>
  <div class="message-list" ref="listRef">
    <div 
      v-for="message in messages" 
      :key="message.id" 
      class="message-item"
      :class="message.role"
    >
      <div class="avatar">
        <el-avatar v-if="message.role === 'user'" :size="32">
          <el-icon><User /></el-icon>
        </el-avatar>
        <el-avatar v-else :size="32" style="background: #409eff">
          AI
        </el-avatar>
      </div>
      
      <div class="content">
        <div class="text" v-html="renderContent(message.content)"></div>
        
        <!-- 工具调用结果展示 -->
        <div v-if="message.toolResults" class="tool-results">
          <div 
            v-for="result in message.toolResults" 
            :key="result.toolCallId"
            class="tool-result-item"
            :class="{ success: result.success, error: !result.success }"
          >
            <el-icon v-if="result.success" color="#67c23a"><CircleCheck /></el-icon>
            <el-icon v-else color="#f56c6c"><CircleClose /></el-icon>
            <span>{{ result.message }}</span>
          </div>
        </div>
        
        <!-- 流式加载指示器 -->
        <div v-if="message.streaming" class="streaming-indicator">
          <span class="cursor">▊</span>
        </div>
      </div>
    </div>
    
    <!-- 空状态 -->
    <div v-if="messages.length === 0" class="empty-state">
      <el-empty description="开始与 AI 对话，搭建您的业务系统" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import { User, CircleCheck, CircleClose } from '@element-plus/icons-vue'
import type { ChatMessage } from './composables/useAiChat'

const props = defineProps<{
  messages: ChatMessage[]
  streaming?: boolean
}>()

const listRef = ref<HTMLElement>()

// 自动滚动到底部
watch(
  () => props.messages,
  () => {
    nextTick(() => {
      if (listRef.value) {
        listRef.value.scrollTop = listRef.value.scrollHeight
      }
    })
  },
  { deep: true }
)

// 渲染内容（支持 Markdown）
const renderContent = (content: string) => {
  // 简单的 Markdown 渲染
  return content
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/`(.*?)`/g, '<code>$1</code>')
    .replace(/\n/g, '<br>')
}
</script>

<style scoped>
.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.message-item {
  display: flex;
  margin-bottom: 16px;
  gap: 12px;
}

.message-item.user {
  flex-direction: row-reverse;
}

.content {
  max-width: 80%;
  background: #f4f4f5;
  padding: 12px 16px;
  border-radius: 8px;
}

.message-item.user .content {
  background: #409eff;
  color: #fff;
}

.text {
  line-height: 1.6;
  word-break: break-word;
}

.tool-results {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid rgba(0, 0, 0, 0.1);
}

.tool-result-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 0;
  font-size: 13px;
}

.tool-result-item.success {
  color: #67c23a;
}

.tool-result-item.error {
  color: #f56c6c;
}

.streaming-indicator {
  display: inline-block;
  margin-left: 4px;
}

.cursor {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
}
</style>
```

#### 4.8.5 MessageInput.vue — 消息输入组件

```typescript
// src/components/AiChat/MessageInput.vue
<template>
  <div class="message-input">
    <el-input
      v-model="message"
      type="textarea"
      :rows="3"
      :disabled="disabled"
      placeholder="输入消息，按 Ctrl+Enter 发送..."
      @keydown.ctrl.enter="handleSend"
      @keydown.meta.enter="handleSend"
    />
    <div class="actions">
      <el-button 
        type="primary" 
        :disabled="disabled || !message.trim()"
        @click="handleSend"
      >
        发送
      </el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  modelValue: string
  disabled?: boolean
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'send'): void
}>()

const message = ref(props.modelValue)

const handleSend = () => {
  if (!message.value.trim() || props.disabled) return
  emit('send')
}

// 同步 modelValue
import { watch } from 'vue'
watch(() => props.modelValue, (val) => {
  message.value = val
})
watch(message, (val) => {
  emit('update:modelValue', val)
})
</script>

<style scoped>
.message-input {
  padding: 16px;
  border-top: 1px solid #e4e7ed;
}

.actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}
</style>
```

#### 4.8.6 前端 AI 对话 API 封装

```typescript
// src/api/nocode/ai.ts — AI 对话 API
import request from '@/config/axios'

export const aiApi = {
  // 同步对话（不推荐，主要用于测试）
  chatSync: (data: {
    sessionId: string
    message: string
    history?: Array<{ role: string; content: string }>
  }) => {
    return request.post({
      url: '/admin/ai/chat/sync',
      data,
    })
  },

  // 获取会话历史
  getHistory: (sessionId: string) => {
    return request.get({
      url: `/admin/ai/chat/history/${sessionId}`,
    })
  },

  // 清除会话
  clearSession: (sessionId: string) => {
    return request.post({
      url: `/admin/ai/chat/clear/${sessionId}`,
    })
  },

  // 获取可用工具列表
  getTools: () => {
    return request.get({
      url: '/admin/ai/tools',
    })
  },

  // 获取可用技能列表
  getSkills: () => {
    return request.get({
      url: '/admin/ai/skills',
    })
  },
}
```

---

### 4.9 视图系统设计（对标 NocoBase View System）

NocoBase 的核心设计之一是**同一集合可拥有多种视图**，用户通过 Tab 切换不同视图查看同一份数据。当前设计中页面与集合是 1:1 关系，缺少视图层抽象。

#### 4.9.1 视图概念模型

```
集合（Collection）
  ├── 视图1：表格视图（Table View）   ← 默认视图
  ├── 视图2：看板视图（Kanban View）  ← 按状态字段分组
  ├── 视图3：日历视图（Calendar View）← 按日期字段渲染
  ├── 视图4：甘特图视图（Gantt View）← 按开始/结束日期渲染
  └── 视图5：网格卡片视图（Grid Card）← 卡片网格布局
```

每个视图独立配置：
- **显示字段**：哪些字段在该视图中可见
- **筛选条件**：视图级别的默认筛选
- **排序规则**：视图级别的默认排序
- **分组规则**：看板按某字段分组
- **布局参数**：视图特有的布局配置

#### 4.9.2 数据库表设计

```sql
-- 视图元数据表
CREATE TABLE nocobase_view (
    id          bigint AUTO_INCREMENT PRIMARY KEY,
    uid         varchar(64)  NOT NULL UNIQUE COMMENT '视图唯一标识',
    title       varchar(128) NOT NULL COMMENT '视图标题',
    icon        varchar(64)  NULL COMMENT '视图图标',
    collection_name varchar(128) NOT NULL COMMENT '所属集合名',
    view_type   varchar(32)  NOT NULL COMMENT '视图类型：table/kanban/calendar/gantt/gridCard/list/map',
    is_default  tinyint(1)   NOT NULL DEFAULT 0 COMMENT '是否默认视图',
    sort        int          NOT NULL DEFAULT 0 COMMENT '排序序号',
    
    -- 视图配置（JSON）
    fields_config    json NULL COMMENT '显示字段配置：[{"name":"customer_name","width":200}]',
    filters_config   json NULL COMMENT '筛选条件配置',
    sort_config      json NULL COMMENT '排序配置：[{"field":"create_time","order":"desc"}]',
    group_config     json NULL COMMENT '分组配置（看板视图用）：{"field":"status"}',
    layout_config    json NULL COMMENT '布局特有配置（各视图类型不同）',
    
    -- 标准字段
    creator     varchar(64)  NULL,
    create_time datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater     varchar(64)  NULL,
    update_time datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted     bit(1)       NOT NULL DEFAULT b'0',
    tenant_id   bigint       NOT NULL DEFAULT 0
) COMMENT '视图元数据表';
```

#### 4.9.3 视图类型定义

```java
/**
 * 视图类型枚举
 */
public enum ViewType {
    TABLE("table", "表格视图", "TableBlock"),
    KANBAN("kanban", "看板视图", "KanbanBlock"),
    CALENDAR("calendar", "日历视图", "CalendarBlock"),
    GANTT("gantt", "甘特图视图", "GanttBlock"),
    GRID_CARD("gridCard", "网格卡片", "GridCardBlock"),
    LIST("list", "列表视图", "ListBlock"),
    MAP("map", "地图视图", "MapBlock"),
    FORM("form", "表单视图", "FormBlock"),
    DETAILS("details", "详情视图", "DetailsBlock");
    
    private final String code;
    private final String displayName;
    private final String blockComponent; // 对应前端组件名
}
```

#### 4.9.4 前端视图切换组件

```typescript
// src/components/nocode/ViewTabs.vue — 视图切换 Tab 组件
<template>
  <div class="view-tabs">
    <el-tabs v-model="activeViewUid" type="card" @tab-change="handleViewChange">
      <el-tab-pane
        v-for="view in views"
        :key="view.uid"
        :label="view.title"
        :name="view.uid"
      >
        <template #label>
          <span class="view-tab-label">
            <el-icon><component :is="view.icon" /></el-icon>
            {{ view.title }}
          </span>
        </template>
      </el-tab-pane>
      <!-- 新增视图按钮 -->
      <el-tab-pane v-if="canEdit">
        <template #label>
          <el-button size="small" text @click="showAddViewDialog">
            <el-icon><Plus /></el-icon>
          </el-button>
        </template>
      </el-tab-pane>
    </el-tabs>
    
    <!-- 当前视图内容区 -->
    <div class="view-content">
      <component
        :is="currentViewComponent"
        :collection-name="collectionName"
        :view-config="currentView"
        :key="activeViewUid"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useViewManager } from './composables/useViewManager'

const props = defineProps<{
  collectionName: string
}>()

const {
  views,
  activeViewUid,
  currentView,
  currentViewComponent,
  canEdit,
  handleViewChange,
  showAddViewDialog,
} = useViewManager(props.collectionName)
</script>
```

```typescript
// src/components/nocode/composables/useViewManager.ts
import { ref, computed, watch, onMounted } from 'vue'
import { viewApi } from '@/api/nocode/view'
import { markRaw, shallowRef } from 'vue'
import TableBlock from '../blocks/TableBlock.vue'
import KanbanBlock from '../blocks/KanbanBlock.vue'
import CalendarBlock from '../blocks/CalendarBlock.vue'
import GanttBlock from '../blocks/GanttBlock.vue'
import GridCardBlock from '../blocks/GridCardBlock.vue'
import ListBlock from '../blocks/ListBlock.vue'

// 视图类型 → 前端组件映射
const VIEW_COMPONENT_MAP: Record<string, any> = {
  table: markRaw(TableBlock),
  kanban: markRaw(KanbanBlock),
  calendar: markRaw(CalendarBlock),
  gantt: markRaw(GanttBlock),
  gridCard: markRaw(GridCardBlock),
  list: markRaw(ListBlock),
}

export function useViewManager(collectionName: string) {
  const views = ref<ViewMeta[]>([])
  const activeViewUid = ref<string>('')

  const currentView = computed(() =>
    views.value.find(v => v.uid === activeViewUid.value)
  )

  const currentViewComponent = computed(() => {
    const viewType = currentView.value?.viewType || 'table'
    return VIEW_COMPONENT_MAP[viewType] || VIEW_COMPONENT_MAP.table
  })

  // 加载视图列表
  const loadViews = async () => {
    const result = await viewApi.list(collectionName)
    views.value = result
    // 默认激活第一个视图或默认视图
    const defaultView = result.find(v => v.isDefault) || result[0]
    if (defaultView) {
      activeViewUid.value = defaultView.uid
    }
  }

  const handleViewChange = (uid: string) => {
    activeViewUid.value = uid
    // 持久化用户最后查看的视图
    localStorage.setItem(`view:${collectionName}`, uid)
  }

  onMounted(async () => {
    await loadViews()
    // 恢复用户上次查看的视图
    const lastView = localStorage.getItem(`view:${collectionName}`)
    if (lastView && views.value.some(v => v.uid === lastView)) {
      activeViewUid.value = lastView
    }
  })

  return {
    views,
    activeViewUid,
    currentView,
    currentViewComponent,
    canEdit: true, // TODO: 根据权限判断
    handleViewChange,
    showAddViewDialog: () => { /* 弹窗逻辑 */ },
    loadViews,
  }
}

interface ViewMeta {
  uid: string
  title: string
  icon?: string
  viewType: string
  isDefault: boolean
  sort: number
  fieldsConfig?: any[]
  filtersConfig?: any
  sortConfig?: any[]
  groupConfig?: any
  layoutConfig?: any
}
```

#### 4.9.5 页面与视图的关系

```
页面（Page / Schema）
  ├── 区块1：视图 Tabs 区块
  │     ├── 视图1：Table View → 数据来自 customers 集合
  │     ├── 视图2：Kanban View → 数据来自 customers 集合
  │     └── 视图3：Calendar View → 数据来自 customers 集合
  ├── 区块2：筛选区块 → 联动到视图 Tabs
  └── 区块3：统计卡片区块
```

页面 Schema 中的视图区块配置：

```json
{
  "type": "void",
  "x-component": "ViewTabsBlock",
  "x-component-props": {
    "collectionName": "customers",
    "defaultViewType": "table"
  },
  "properties": {
    "view_table_1": {
      "type": "void",
      "x-component": "ViewPane",
      "x-component-props": {
        "viewUid": "view_table_1",
        "viewType": "table"
      }
    },
    "view_kanban_1": {
      "type": "void",
      "x-component": "ViewPane",
      "x-component-props": {
        "viewUid": "view_kanban_1",
        "viewType": "kanban",
        "groupField": "status"
      }
    }
  }
}
```

#### 4.9.6 后端视图管理接口

```java
/**
 * 视图管理 Controller
 */
@Tag(name = "管理后台 - 无代码视图")
@RestController
@RequestMapping("/nocode/view")
@Validated
public class ViewController {

    @Resource
    private ViewService viewService;

    @PostMapping("create")
    @Operation(summary = "创建视图")
    @PreAuthorize("@ss.hasPermission('nocode:view:create')")
    public CommonResult<Long> createView(@Valid @RequestBody ViewSaveReqVO reqVO) {
        return success(viewService.createView(reqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新视图")
    @PreAuthorize("@ss.hasPermission('nocode:view:update')")
    public CommonResult<Boolean> updateView(@Valid @RequestBody ViewSaveReqVO reqVO) {
        viewService.updateView(reqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除视图")
    @Parameter(name = "id", description = "视图ID", required = true)
    @PreAuthorize("@ss.hasPermission('nocode:view:delete')")
    public CommonResult<Boolean> deleteView(@RequestParam("id") Long id) {
        viewService.deleteView(id);
        return success(true);
    }

    @GetMapping("/list")
    @Operation(summary = "获取集合的视图列表")
    @Parameter(name = "collectionName", description = "集合名", required = true)
    @PreAuthorize("@ss.hasPermission('nocode:view:query')")
    public CommonResult<List<ViewRespVO>> listViews(@RequestParam("collectionName") String collectionName) {
        return success(viewService.listViews(collectionName));
    }

    @PutMapping("sort")
    @Operation(summary = "视图排序")
    @PreAuthorize("@ss.hasPermission('nocode:view:update')")
    public CommonResult<Boolean> sortViews(@RequestBody List<Long> viewIds) {
        viewService.sortViews(viewIds);
        return success(true);
    }
}
```

```java
/**
 * 视图 SaveReqVO
 */
@Data
public class ViewSaveReqVO {
    private Long id;

    @Schema(description = "视图标题", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    private String title;

    @Schema(description = "视图图标")
    private String icon;

    @Schema(description = "所属集合名", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotBlank
    private String collectionName;

    @Schema(description = "视图类型", requiredMode = Schema.RequiredMode.REQUIRED,
            example = "table/kanban/calendar/gantt/gridCard/list/map")
    @NotBlank
    private String viewType;

    @Schema(description = "是否默认视图")
    private Boolean isDefault;

    @Schema(description = "显示字段配置")
    private List<ViewFieldConfig> fieldsConfig;

    @Schema(description = "筛选条件配置")
    private Object filtersConfig;

    @Schema(description = "排序配置")
    private List<ViewSortConfig> sortConfig;

    @Schema(description = "分组配置（看板视图用）")
    private ViewGroupConfig groupConfig;

    @Schema(description = "布局特有配置")
    private Object layoutConfig;
}

@Data
public class ViewFieldConfig {
    private String name;       // 字段名
    private Integer width;     // 列宽（表格视图）
    private Boolean visible;   // 是否可见
    private Integer sort;      // 排序
}

@Data
public class ViewSortConfig {
    private String field;
    private String order; // asc / desc
}

@Data
public class ViewGroupConfig {
    private String field; // 分组字段名
}
```

---

### 4.10 区块类型扩展（对标 NocoBase Block Types）

当前设计仅覆盖 TableBlock、FormBlock、FilterBlock、DetailsBlock 四种基础区块。NocoBase 支持 11+ 种数据区块，需扩展以支持更多业务场景。

#### 4.10.1 区块类型总览

| 区块类型 | 组件名 | 说明 | 适用场景 |
|---------|--------|------|---------|
| **Table** | TableBlock | 表格 | 数据列表、CRUD |
| **Form** | FormBlock | 表单 | 新增/编辑数据 |
| **Details** | DetailsBlock | 详情 | 查看单条数据 |
| **Filter** | FilterBlock | 筛选 | 过滤数据 |
| **Kanban** | KanbanBlock | 看板 | 项目管理、任务跟踪 |
| **Calendar** | CalendarBlock | 日历 | 日程、排班 |
| **Gantt** | GanttBlock | 甘特图 | 项目计划、时间线 |
| **Grid Card** | GridCardBlock | 网格卡片 | 产品目录、人员列表 |
| **List** | ListBlock | 列表 | 移动端列表、简单展示 |
| **Map** | MapBlock | 地图 | 地理位置数据 |
| **Charts** | ChartsBlock | 图表 | 数据可视化、仪表盘 |
| **Multi-step Form** | MultiStepFormBlock | 多步表单 | 向导式数据录入 |

#### 4.10.2 KanbanBlock 详细设计

看板区块按某字段（通常是状态/阶段）分组显示数据卡片。

```typescript
// src/components/nocode/blocks/KanbanBlock.vue
<template>
  <div class="kanban-block">
    <div class="kanban-header">
      <span class="kanban-title">{{ viewConfig?.title || '看板' }}</span>
      <el-button size="small" @click="handleAddCard">
        <el-icon><Plus /></el-icon> 新增
      </el-button>
    </div>

    <div class="kanban-board" v-loading="loading">
      <KanbanColumn
        v-for="column in columns"
        :key="column.value"
        :title="column.label"
        :color="column.color"
        :cards="column.cards"
        :group-field="groupField"
        :group-value="column.value"
        @card-click="handleCardClick"
        @card-drop="handleCardDrop"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'
import KanbanColumn from './kanban/KanbanColumn.vue'

const props = defineProps<{
  collectionName: string
  viewConfig?: any
}>()

const loading = ref(false)
const rawData = ref<any[]>([])

// 分组字段（从视图配置获取）
const groupField = computed(() =>
  props.viewConfig?.groupConfig?.field || 'status'
)

// 按分组字段聚合为列
const columns = computed(() => {
  const fieldMeta = getFieldMeta(props.collectionName, groupField.value)
  const choices = fieldMeta?.choices || []
  
  return choices.map((choice: any) => ({
    value: choice.value,
    label: choice.label,
    color: choice.color || '#999',
    cards: rawData.value.filter(item => item[groupField.value] === choice.value),
  }))
})

// 加载数据
const loadData = async () => {
  loading.value = true
  try {
    const result = await dynamicApi.list(props.collectionName, {
      pageNo: 1,
      pageSize: 1000,
      filters: props.viewConfig?.filtersConfig || {},
      sort: props.viewConfig?.sortConfig || {},
    })
    rawData.value = result.list
  } finally {
    loading.value = false
  }
}

// 拖拽卡片（更新分组字段值）
const handleCardDrop = async (cardId: any, newGroupValue: any) => {
  await dynamicApi.update(props.collectionName, {
    id: cardId,
    [groupField.value]: newGroupValue,
  })
  await loadData()
}

onMounted(loadData)
</script>
```

```typescript
// src/components/nocode/blocks/kanban/KanbanColumn.vue
<template>
  <div class="kanban-column">
    <div class="column-header" :style="{ borderLeftColor: color }">
      <span class="column-title">{{ title }}</span>
      <el-tag size="small" type="info">{{ cards.length }}</el-tag>
    </div>
    
    <div
      class="column-body"
      @dragover.prevent
      @drop="handleDrop"
    >
      <div
        v-for="card in cards"
        :key="card.id"
        class="kanban-card"
        draggable="true"
        @dragstart="handleDragStart(card)"
        @click="$emit('card-click', card)"
      >
        <slot name="card" :card="card">
          <div class="card-title">{{ card[titleField] }}</div>
          <div class="card-meta">
            <span v-for="field in displayFields" :key="field.name">
              {{ card[field.name] }}
            </span>
          </div>
        </slot>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  title: string
  color: string
  cards: any[]
  groupField: string
  groupValue: any
}>()

const emit = defineEmits(['card-click', 'card-drop'])

const draggingCard = ref<any>(null)

const handleDragStart = (card: any) => {
  draggingCard.value = card
}

const handleDrop = () => {
  if (draggingCard.value) {
    emit('card-drop', draggingCard.value.id, props.groupValue)
    draggingCard.value = null
  }
}
</script>
```

#### 4.10.3 CalendarBlock 详细设计

```typescript
// src/components/nocode/blocks/CalendarBlock.vue
<template>
  <div class="calendar-block">
    <div class="calendar-header">
      <el-button @click="prevMonth"><el-icon><ArrowLeft /></el-icon></el-button>
      <span class="current-month">{{ currentMonthLabel }}</span>
      <el-button @click="nextMonth"><el-icon><ArrowRight /></el-icon></el-button>
      <el-radio-group v-model="viewMode" size="small">
        <el-radio-button label="month">月</el-radio-button>
        <el-radio-button label="week">周</el-radio-button>
        <el-radio-button label="day">日</el-radio-button>
      </el-radio-group>
    </div>

    <el-calendar v-model="currentDate">
      <template #date-cell="{ data }">
        <div class="calendar-cell">
          <div
            v-for="event in getEventsForDate(data.day)"
            :key="event.id"
            class="calendar-event"
            :style="{ backgroundColor: event.color || '#409EFF' }"
            @click="handleEventClick(event)"
          >
            {{ event[titleField] }}
          </div>
        </div>
      </template>
    </el-calendar>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'
import dayjs from 'dayjs'

const props = defineProps<{
  collectionName: string
  viewConfig?: any
}>()

const currentDate = ref(dayjs())
const viewMode = ref('month')
const events = ref<any[]>([])

const startDateField = computed(() => props.viewConfig?.layoutConfig?.startDateField || 'start_time')
const endDateField = computed(() => props.viewConfig?.layoutConfig?.endDateField || 'end_time')
const titleField = computed(() => props.viewConfig?.layoutConfig?.titleField || 'title')

const currentMonthLabel = computed(() => currentDate.value.format('YYYY年MM月'))

// 获取某天的事件
const getEventsForDate = (day: string) => {
  const date = dayjs(day)
  return events.value.filter(event => {
    const start = dayjs(event[startDateField.value])
    const end = event[endDateField.value] ? dayjs(event[endDateField.value]) : start
    return date.isAfter(start.subtract(1, 'ms')) && date.isBefore(end.add(1, 'day'))
  })
}

const loadEvents = async () => {
  const start = currentDate.value.startOf('month').subtract(7, 'day').toISOString()
  const end = currentDate.value.endOf('month').add(7, 'day').toISOString()
  
  const result = await dynamicApi.list(props.collectionName, {
    pageNo: 1,
    pageSize: 1000,
    filters: {
      [`${startDateField.value}.$lte`]: end,
      [`${endDateField.value || startDateField.value}.$gte`]: start,
    },
  })
  events.value = result.list
}

const prevMonth = () => { currentDate.value = currentDate.value.subtract(1, 'month'); loadEvents() }
const nextMonth = () => { currentDate.value = currentDate.value.add(1, 'month'); loadEvents() }

onMounted(loadEvents)
</script>
```

#### 4.10.4 GanttBlock 详细设计

```typescript
// src/components/nocode/blocks/GanttBlock.vue
<template>
  <div class="gantt-block">
    <div class="gantt-toolbar">
      <el-radio-group v-model="scale" size="small">
        <el-radio-button label="day">日</el-radio-button>
        <el-radio-button label="week">周</el-radio-button>
        <el-radio-button label="month">月</el-radio-button>
      </el-radio-group>
    </div>
    
    <div class="gantt-container">
      <!-- 左侧：任务列表 -->
      <div class="gantt-tasks">
        <div class="gantt-header">任务名称</div>
        <div v-for="task in tasks" :key="task.id" class="gantt-task-row">
          {{ task[titleField] }}
        </div>
      </div>
      
      <!-- 右侧：甘特图时间线 -->
      <div class="gantt-timeline">
        <div class="gantt-header">
          <span v-for="col in timeColumns" :key="col.label">{{ col.label }}</span>
        </div>
        <div v-for="task in tasks" :key="task.id" class="gantt-timeline-row">
          <div
            class="gantt-bar"
            :style="getBarStyle(task)"
            @click="handleBarClick(task)"
          >
            {{ task[titleField] }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'
import dayjs from 'dayjs'

const props = defineProps<{
  collectionName: string
  viewConfig?: any
}>()

const scale = ref('week')
const tasks = ref<any[]>([])

const startDateField = computed(() => props.viewConfig?.layoutConfig?.startDateField || 'start_date')
const endDateField = computed(() => props.viewConfig?.layoutConfig?.endDateField || 'end_date')
const titleField = computed(() => props.viewConfig?.layoutConfig?.titleField || 'name')

// 时间轴列
const timeColumns = computed(() => {
  const columns: { label: string; date: string }[] = []
  const start = getTimelineStart()
  const count = getTimelineCount()
  
  for (let i = 0; i < count; i++) {
    const d = start.add(i, scale.value as any)
    columns.push({
      label: d.format(scale.value === 'month' ? 'YYYY-MM' : 'MM-DD'),
      date: d.toISOString(),
    })
  }
  return columns
})

// 计算任务条的位置和宽度
const getBarStyle = (task: any) => {
  const start = dayjs(task[startDateField.value])
  const end = dayjs(task[endDateField.value])
  const timelineStart = getTimelineStart()
  const totalDays = getTimelineCount()
  
  const leftPercent = start.diff(timelineStart, 'day') / totalDays * 100
  const widthPercent = end.diff(start, 'day') / totalDays * 100
  
  return {
    left: `${Math.max(0, leftPercent)}%`,
    width: `${Math.max(2, widthPercent)}%`,
  }
}

const getTimelineStart = () => dayjs().subtract(1, 'month')
const getTimelineCount = () => scale.value === 'month' ? 12 : scale.value === 'week' ? 12 : 30

const loadTasks = async () => {
  const result = await dynamicApi.list(props.collectionName, {
    pageNo: 1,
    pageSize: 1000,
    sort: { [startDateField.value]: 'asc' },
  })
  tasks.value = result.list
}

onMounted(loadTasks)
</script>
```

#### 4.10.5 GridCardBlock 详细设计

```typescript
// src/components/nocode/blocks/GridCardBlock.vue
<template>
  <div class="grid-card-block">
    <div class="grid-toolbar">
      <el-radio-group v-model="columns" size="small">
        <el-radio-button :label="2">2列</el-radio-button>
        <el-radio-button :label="3">3列</el-radio-button>
        <el-radio-button :label="4">4列</el-radio-button>
      </el-radio-group>
    </div>
    
    <el-row :gutter="16">
      <el-col
        v-for="item in items"
        :key="item.id"
        :span="24 / columns"
      >
        <el-card class="grid-card" shadow="hover" @click="handleCardClick(item)">
          <!-- 封面图 -->
          <div v-if="coverField && item[coverField]" class="card-cover">
            <el-image :src="item[coverField]" fit="cover" />
          </div>
          <!-- 标题 -->
          <div class="card-title">{{ item[titleField] }}</div>
          <!-- 描述字段 -->
          <div class="card-fields">
            <div v-for="field in displayFields" :key="field.name" class="card-field">
              <span class="field-label">{{ field.displayName }}：</span>
              <span class="field-value">{{ item[field.name] }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 分页 -->
    <el-pagination
      v-model:current-page="pageNo"
      :page-size="pageSize"
      :total="total"
      layout="total, prev, pager, next"
      @current-change="loadData"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'

const props = defineProps<{
  collectionName: string
  viewConfig?: any
}>()

const columns = ref(3)
const items = ref<any[]>([])
const pageNo = ref(1)
const pageSize = ref(24)
const total = ref(0)

const titleField = computed(() => props.viewConfig?.layoutConfig?.titleField || 'name')
const coverField = computed(() => props.viewConfig?.layoutConfig?.coverField || '')
const displayFields = computed(() => props.viewConfig?.layoutConfig?.displayFields || [])

const loadData = async () => {
  const result = await dynamicApi.list(props.collectionName, {
    pageNo: pageNo.value,
    pageSize: pageSize.value,
    filters: props.viewConfig?.filtersConfig || {},
  })
  items.value = result.list
  total.value = result.total
}

onMounted(loadData)
</script>
```

#### 4.10.6 ListBlock 详细设计

```typescript
// src/components/nocode/blocks/ListBlock.vue — 简洁列表视图（适合移动端）
<template>
  <div class="list-block">
    <div
      v-for="item in items"
      :key="item.id"
      class="list-item"
      @click="handleItemClick(item)"
    >
      <div class="list-item-main">
        <span class="list-item-title">{{ item[titleField] }}</span>
        <span v-if="subtitleField" class="list-item-subtitle">
          {{ item[subtitleField] }}
        </span>
      </div>
      <div class="list-item-extra">
        <slot name="extra" :item="item" />
      </div>
    </div>
    
    <el-pagination
      v-model:current-page="pageNo"
      :page-size="pageSize"
      :total="total"
      layout="total, prev, pager, next"
      @current-change="loadData"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'

const props = defineProps<{
  collectionName: string
  viewConfig?: any
}>()

const items = ref<any[]>([])
const pageNo = ref(1)
const pageSize = ref(20)
const total = ref(0)

const titleField = computed(() => props.viewConfig?.layoutConfig?.titleField || 'name')
const subtitleField = computed(() => props.viewConfig?.layoutConfig?.subtitleField || '')

const loadData = async () => {
  const result = await dynamicApi.list(props.collectionName, {
    pageNo: pageNo.value,
    pageSize: pageSize.value,
    filters: props.viewConfig?.filtersConfig || {},
    sort: props.viewConfig?.sortConfig || {},
  })
  items.value = result.list
  total.value = result.total
}

onMounted(loadData)
</script>
```

#### 4.10.7 区块注册机制

```typescript
// src/components/nocode/blocks/index.ts — 区块注册表
import { markRaw } from 'vue'
import TableBlock from './TableBlock.vue'
import FormBlock from './FormBlock.vue'
import DetailsBlock from './DetailsBlock.vue'
import FilterBlock from './FilterBlock.vue'
import KanbanBlock from './KanbanBlock.vue'
import CalendarBlock from './CalendarBlock.vue'
import GanttBlock from './GanttBlock.vue'
import GridCardBlock from './GridCardBlock.vue'
import ListBlock from './ListBlock.vue'

// 区块注册表
const blockRegistry: Record<string, any> = {
  TableBlock: markRaw(TableBlock),
  FormBlock: markRaw(FormBlock),
  DetailsBlock: markRaw(DetailsBlock),
  FilterBlock: markRaw(FilterBlock),
  KanbanBlock: markRaw(KanbanBlock),
  CalendarBlock: markRaw(CalendarBlock),
  GanttBlock: markRaw(GanttBlock),
  GridCardBlock: markRaw(GridCardBlock),
  ListBlock: markRaw(ListBlock),
}

/**
 * 注册自定义区块
 */
export function registerBlock(name: string, component: any) {
  blockRegistry[name] = markRaw(component)
}

/**
 * 获取区块组件
 */
export function getBlockComponent(name: string) {
  return blockRegistry[name] || null
}

/**
 * 获取所有已注册区块
 */
export function getAllBlocks() {
  return { ...blockRegistry }
}
```

---

### 4.11 模板系统设计（对标 NocoBase Template System）

NocoBase 支持区块模板的保存和复用，可以将常用的区块配置保存为模板，在其他页面快速复用。

#### 4.11.1 模板类型

| 模板类型 | 说明 | 典型场景 |
|---------|------|---------|
| **区块模板** | 单个区块的模板 | 客户列表表格、订单表单 |
| **页面模板** | 整个页面的模板 | CRM 客户管理页、订单管理页 |
| **应用模板** | 完整应用的模板 | CRM 系统、项目管理系统 |

#### 4.11.2 模板使用方式

- **引用模式**：模板更新时，所有引用该模板的区块同步更新
- **复制模式**：创建独立的副本，与模板解耦

#### 4.11.3 数据库表设计

```sql
-- 模板表
CREATE TABLE nocobase_template (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    uid VARCHAR(64) NOT NULL UNIQUE COMMENT '模板唯一标识',
    name VARCHAR(100) NOT NULL COMMENT '模板名称',
    description VARCHAR(500) COMMENT '模板描述',
    template_type VARCHAR(32) NOT NULL COMMENT '模板类型：block/page/app',
    category VARCHAR(50) COMMENT '模板分类',
    icon VARCHAR(64) COMMENT '模板图标',
    schema_json JSON NOT NULL COMMENT '模板 Schema（JSON格式）',
    is_system TINYINT(1) DEFAULT 0 COMMENT '是否系统模板：0-否，1-是',
    is_public TINYINT(1) DEFAULT 0 COMMENT '是否公开：0-否，1-是',
    usage_count INT DEFAULT 0 COMMENT '使用次数',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_type (template_type),
    INDEX idx_category (category),
    INDEX idx_tenant (tenant_id)
) COMMENT='模板表';

-- 模板引用关系表
CREATE TABLE nocobase_template_reference (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    template_id BIGINT NOT NULL COMMENT '模板ID',
    reference_type VARCHAR(32) NOT NULL COMMENT '引用类型：block/page',
    reference_uid VARCHAR(64) NOT NULL COMMENT '被引用的区块/页面 UID',
    use_mode VARCHAR(16) NOT NULL COMMENT '使用模式：reference/copy',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_template (template_id),
    INDEX idx_reference (reference_type, reference_uid),
    INDEX idx_tenant (tenant_id)
) COMMENT='模板引用关系表';
```

#### 4.11.4 前端模板管理组件

```typescript
// src/components/nocode/TemplateManager.vue
<template>
  <el-dialog v-model="visible" title="模板管理" width="900px">
    <el-tabs v-model="activeTab">
      <!-- 我的模板 -->
      <el-tab-pane label="我的模板" name="my">
        <div class="template-toolbar">
          <el-button type="primary" @click="showCreateDialog">
            <el-icon><Plus /></el-icon> 创建模板
          </el-button>
          <el-input 
            v-model="searchKeyword" 
            placeholder="搜索模板" 
            style="width: 200px"
          />
        </div>
        
        <el-row :gutter="16" class="template-list">
          <el-col :span="6" v-for="template in myTemplates" :key="template.id">
            <el-card class="template-card" shadow="hover">
              <div class="template-icon">
                <el-icon :size="32"><component :is="template.icon" /></el-icon>
              </div>
              <div class="template-name">{{ template.name }}</div>
              <div class="template-desc">{{ template.description }}</div>
              <div class="template-actions">
                <el-button size="small" @click="useTemplate(template, 'reference')">
                  引用
                </el-button>
                <el-button size="small" @click="useTemplate(template, 'copy')">
                  复制
                </el-button>
                <el-button size="small" type="danger" @click="deleteTemplate(template)">
                  删除
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>
      
      <!-- 系统模板 -->
      <el-tab-pane label="系统模板" name="system">
        <el-row :gutter="16" class="template-list">
          <el-col :span="6" v-for="template in systemTemplates" :key="template.id">
            <el-card class="template-card" shadow="hover">
              <div class="template-icon">
                <el-icon :size="32"><component :is="template.icon" /></el-icon>
              </div>
              <div class="template-name">{{ template.name }}</div>
              <div class="template-desc">{{ template.description }}</div>
              <div class="template-actions">
                <el-button size="small" @click="useTemplate(template, 'reference')">
                  引用
                </el-button>
                <el-button size="small" @click="useTemplate(template, 'copy')">
                  复制
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>
    </el-tabs>
  </el-dialog>
  
  <!-- 创建模板对话框 -->
  <el-dialog v-model="createDialogVisible" title="创建模板" width="500px">
    <el-form :model="createForm" label-width="100px">
      <el-form-item label="模板名称" required>
        <el-input v-model="createForm.name" placeholder="请输入模板名称" />
      </el-form-item>
      <el-form-item label="模板描述">
        <el-input 
          v-model="createForm.description" 
          type="textarea" 
          placeholder="请输入模板描述"
        />
      </el-form-item>
      <el-form-item label="模板分类">
        <el-select v-model="createForm.category" placeholder="请选择分类">
          <el-option label="CRM" value="crm" />
          <el-option label="项目管理" value="project" />
          <el-option label="OA" value="oa" />
          <el-option label="其他" value="other" />
        </el-select>
      </el-form-item>
      <el-form-item label="是否公开">
        <el-switch v-model="createForm.isPublic" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="createDialogVisible = false">取消</el-button>
      <el-button type="primary" @click="createTemplate">创建</el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { templateApi } from '@/api/nocode/template'

const props = defineProps<{
  currentSchema?: any
}>()

const emit = defineEmits(['use-template'])

const visible = ref(false)
const activeTab = ref('my')
const searchKeyword = ref('')
const myTemplates = ref<any[]>([])
const systemTemplates = ref<any[]>([])

const createDialogVisible = ref(false)
const createForm = ref({
  name: '',
  description: '',
  category: '',
  isPublic: false,
})

// 加载模板列表
const loadTemplates = async () => {
  const result = await templateApi.list({
    keyword: searchKeyword.value,
  })
  myTemplates.value = result.filter(t => !t.isSystem)
  systemTemplates.value = result.filter(t => t.isSystem)
}

// 显示创建对话框
const showCreateDialog = () => {
  createForm.value = {
    name: '',
    description: '',
    category: '',
    isPublic: false,
  }
  createDialogVisible.value = true
}

// 创建模板
const createTemplate = async () => {
  if (!props.currentSchema) {
    ElMessage.warning('请先选择要保存为模板的区块')
    return
  }
  
  await templateApi.create({
    ...createForm.value,
    templateType: 'block',
    schemaJson: props.currentSchema,
  })
  
  ElMessage.success('模板创建成功')
  createDialogVisible.value = false
  await loadTemplates()
}

// 使用模板
const useTemplate = (template: any, mode: 'reference' | 'copy') => {
  emit('use-template', {
    template,
    mode,
  })
  visible.value = false
}

// 删除模板
const deleteTemplate = async (template: any) => {
  await ElMessageBox.confirm('确定要删除该模板吗？', '提示', {
    type: 'warning',
  })
  
  await templateApi.delete(template.id)
  ElMessage.success('模板删除成功')
  await loadTemplates()
}

onMounted(loadTemplates)
</script>
```

#### 4.11.5 模板引用同步机制

```typescript
// src/utils/templateSync.ts
import { templateApi } from '@/api/nocode/template'

/**
 * 检查模板是否有更新
 */
export async function checkTemplateUpdates(referenceUid: string): Promise<{
  hasUpdate: boolean
  templateVersion?: number
  currentVersion?: number
}> {
  const reference = await templateApi.getReference(referenceUid)
  if (!reference || reference.useMode !== 'reference') {
    return { hasUpdate: false }
  }
  
  const template = await templateApi.get(reference.templateId)
  const templateVersion = template.version || 1
  const currentVersion = reference.templateVersion || 1
  
  return {
    hasUpdate: templateVersion > currentVersion,
    templateVersion,
    currentVersion,
  }
}

/**
 * 同步模板更新
 */
export async function syncTemplateUpdate(referenceUid: string): Promise<void> {
  const reference = await templateApi.getReference(referenceUid)
  if (!reference || reference.useMode !== 'reference') {
    return
  }
  
  const template = await templateApi.get(reference.templateId)
  
  // 更新区块 Schema
  await updateBlockSchema(referenceUid, template.schemaJson)
  
  // 更新引用版本
  await templateApi.updateReferenceVersion(reference.id, template.version)
}

/**
 * 批量同步所有引用
 */
export async function syncAllTemplateUpdates(): Promise<{
  total: number
  updated: number
}> {
  const references = await templateApi.listReferences({
    useMode: 'reference',
  })
  
  let updated = 0
  for (const ref of references) {
    const check = await checkTemplateUpdates(ref.referenceUid)
    if (check.hasUpdate) {
      await syncTemplateUpdate(ref.referenceUid)
      updated++
    }
  }
  
  return {
    total: references.length,
    updated,
  }
}
```

#### 4.11.6 模板版本管理

对标 NocoBase 的模板版本控制机制，支持模板的多版本管理和版本回滚。

##### 4.11.6.1 数据库表设计

```sql
-- 模板版本表
CREATE TABLE nocobase_template_version (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    template_id BIGINT NOT NULL COMMENT '模板ID',
    version_no INT NOT NULL COMMENT '版本号',
    version_name VARCHAR(100) COMMENT '版本名称',
    schema_json JSON NOT NULL COMMENT '该版本的 Schema',
    change_summary TEXT COMMENT '变更说明',
    change_type VARCHAR(32) COMMENT '变更类型：major/minor/patch',
    is_current TINYINT(1) DEFAULT 0 COMMENT '是否当前版本：0-否，1-是',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    UNIQUE INDEX uk_template_version (template_id, version_no),
    INDEX idx_template_current (template_id, is_current),
    INDEX idx_tenant (tenant_id)
) COMMENT='模板版本表';
```

##### 4.11.6.2 版本管理服务

```java
/**
 * 模板版本管理服务
 */
@Service
public class TemplateVersionService {
    
    @Resource
    private TemplateVersionMapper versionMapper;
    
    @Resource
    private TemplateMapper templateMapper;
    
    /**
     * 创建新版本
     */
    @Transactional(rollbackFor = Exception.class)
    public Long createVersion(Long templateId, String schemaJson, String changeSummary) {
        // 1. 获取当前最大版本号
        Integer maxVersion = versionMapper.selectMaxVersionByTemplateId(templateId);
        int newVersionNo = (maxVersion == null ? 0 : maxVersion) + 1;
        
        // 2. 取消旧版本的 current 标记
        versionMapper.clearCurrentFlag(templateId);
        
        // 3. 创建新版本
        TemplateVersionDO version = new TemplateVersionDO();
        version.setTemplateId(templateId);
        version.setVersionNo(newVersionNo);
        version.setSchemaJson(schemaJson);
        version.setChangeSummary(changeSummary);
        version.setIsCurrent(true);
        version.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        versionMapper.insert(version);
        
        // 4. 更新模板表的 schema_json 为最新版本
        TemplateDO template = templateMapper.selectById(templateId);
        if (template != null) {
            template.setSchemaJson(schemaJson);
            templateMapper.updateById(template);
        }
        
        return version.getId();
    }
    
    /**
     * 回滚到指定版本
     */
    @Transactional(rollbackFor = Exception.class)
    public void rollbackToVersion(Long templateId, Integer versionNo) {
        TemplateVersionDO targetVersion = versionMapper.selectByTemplateAndVersion(
            templateId, versionNo);
        
        if (targetVersion == null) {
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_VERSION_NOT_FOUND);
        }
        
        // 1. 取消当前版本的 current 标记
        versionMapper.clearCurrentFlag(templateId);
        
        // 2. 标记目标版本为当前版本
        targetVersion.setIsCurrent(true);
        versionMapper.updateById(targetVersion);
        
        // 3. 更新模板表的 schema_json
        TemplateDO template = templateMapper.selectById(templateId);
        if (template != null) {
            template.setSchemaJson(targetVersion.getSchemaJson());
            templateMapper.updateById(template);
        }
        
        // 4. 同步更新所有引用该模板的区块/页面
        syncTemplateReferences(templateId, targetVersion.getSchemaJson());
    }
    
    /**
     * 获取版本历史
     */
    public List<TemplateVersionDO> getVersionHistory(Long templateId) {
        return versionMapper.selectByTemplateId(templateId);
    }
    
    /**
     * 比较两个版本差异
     */
    public VersionDiff compareVersions(Long templateId, Integer versionNo1, Integer versionNo2) {
        TemplateVersionDO v1 = versionMapper.selectByTemplateAndVersion(templateId, versionNo1);
        TemplateVersionDO v2 = versionMapper.selectByTemplateAndVersion(templateId, versionNo2);
        
        if (v1 == null || v2 == null) {
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_VERSION_NOT_FOUND);
        }
        
        // 使用 JSON Diff 算法比较差异
        JsonDiff diff = JsonDiff.compare(v1.getSchemaJson(), v2.getSchemaJson());
        
        VersionDiff result = new VersionDiff();
        result.setAddedFields(diff.getAddedPaths());
        result.setRemovedFields(diff.getRemovedPaths());
        result.setModifiedFields(diff.getModifiedPaths());
        
        return result;
    }
    
    private void syncTemplateReferences(Long templateId, String newSchemaJson) {
        // 查找所有引用该模板的区块/页面，并更新其 Schema
        List<TemplateReferenceDO> references = templateReferenceMapper.selectByTemplateId(templateId);
        for (TemplateReferenceDO ref : references) {
            if ("reference".equals(ref.getUseMode())) {
                // 更新引用模式的区块/页面 Schema
                pageSchemaService.updateBlockSchema(ref.getReferenceUid(), newSchemaJson);
            }
        }
    }
}
```

#### 4.11.7 模板导入导出

##### 4.11.7.1 导出服务

```java
/**
 * 模板导出服务
 */
@Service
public class TemplateExportService {
    
    @Resource
    private TemplateMapper templateMapper;
    
    @Resource
    private TemplateVersionMapper versionMapper;
    
    /**
     * 导出模板为 JSON 文件
     */
    public byte[] exportTemplate(Long templateId) {
        TemplateDO template = templateMapper.selectById(templateId);
        if (template == null) {
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_NOT_FOUND);
        }
        
        // 获取版本历史
        List<TemplateVersionDO> versions = versionMapper.selectByTemplateId(templateId);
        
        // 构建导出对象
        TemplateExportDTO exportDTO = new TemplateExportDTO();
        exportDTO.setUid(template.getUid());
        exportDTO.setName(template.getName());
        exportDTO.setDescription(template.getDescription());
        exportDTO.setTemplateType(template.getTemplateType());
        exportDTO.setCategory(template.getCategory());
        exportDTO.setIcon(template.getIcon());
        exportDTO.setCurrentSchema(template.getSchemaJson());
        exportDTO.setVersions(versions.stream().map(v -> {
            TemplateVersionExportDTO vDTO = new TemplateVersionExportDTO();
            vDTO.setVersionNo(v.getVersionNo());
            vDTO.setVersionName(v.getVersionName());
            vDTO.setSchemaJson(v.getSchemaJson());
            vDTO.setChangeSummary(v.getChangeSummary());
            return vDTO;
        }).collect(Collectors.toList()));
        exportDTO.setExportTime(LocalDateTime.now());
        exportDTO.setExportVersion("1.0");
        
        return JSONUtil.toJsonStr(exportDTO).getBytes(StandardCharsets.UTF_8);
    }
    
    /**
     * 批量导出模板
     */
    public byte[] exportTemplates(List<Long> templateIds) {
        List<TemplateExportDTO> exports = templateIds.stream()
            .map(this::exportTemplateToDTO)
            .collect(Collectors.toList());
        
        // 打包为 ZIP
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (ZipOutputStream zos = new ZipOutputStream(baos)) {
            for (int i = 0; i < exports.size(); i++) {
                TemplateExportDTO dto = exports.get(i);
                ZipEntry entry = new ZipEntry(dto.getName() + ".json");
                zos.putNextEntry(entry);
                zos.write(JSONUtil.toJsonStr(dto).getBytes(StandardCharsets.UTF_8));
                zos.closeEntry();
            }
        } catch (IOException e) {
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_EXPORT_FAILED);
        }
        
        return baos.toByteArray();
    }
}
```

##### 4.11.7.2 导入服务

```java
/**
 * 模板导入服务
 */
@Service
public class TemplateImportService {
    
    @Resource
    private TemplateMapper templateMapper;
    
    @Resource
    private TemplateVersionService versionService;
    
    /**
     * 导入模板
     */
    @Transactional(rollbackFor = Exception.class)
    public Long importTemplate(byte[] data) {
        String json = new String(data, StandardCharsets.UTF_8);
        TemplateExportDTO importDTO = JSONUtil.toBean(json, TemplateExportDTO.class);
        
        // 检查 UID 是否已存在
        TemplateDO existingTemplate = templateMapper.selectByUid(importDTO.getUid());
        
        if (existingTemplate != null) {
            // 模板已存在，询问是否覆盖或创建新版本
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_ALREADY_EXISTS, 
                "模板 UID 已存在: " + importDTO.getUid());
        }
        
        // 创建新模板
        TemplateDO template = new TemplateDO();
        template.setUid(importDTO.getUid());
        template.setName(importDTO.getName());
        template.setDescription(importDTO.getDescription());
        template.setTemplateType(importDTO.getTemplateType());
        template.setCategory(importDTO.getCategory());
        template.setIcon(importDTO.getIcon());
        template.setSchemaJson(importDTO.getCurrentSchema());
        template.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        templateMapper.insert(template);
        
        // 导入版本历史
        if (importDTO.getVersions() != null) {
            for (TemplateVersionExportDTO vDTO : importDTO.getVersions()) {
                versionService.createVersion(
                    template.getId(), 
                    vDTO.getSchemaJson(), 
                    vDTO.getChangeSummary()
                );
            }
        }
        
        return template.getId();
    }
    
    /**
     * 从 ZIP 文件批量导入
     */
    @Transactional(rollbackFor = Exception.class)
    public List<Long> importTemplatesFromZip(byte[] zipData) {
        List<Long> importedIds = new ArrayList<>();
        
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(zipData))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (entry.getName().endsWith(".json")) {
                    byte[] data = zis.readAllBytes();
                    Long id = importTemplate(data);
                    importedIds.add(id);
                }
                zis.closeEntry();
            }
        } catch (IOException e) {
            throw new ServiceException(ErrorCodeConstants.TEMPLATE_IMPORT_FAILED);
        }
        
        return importedIds;
    }
}
```

#### 4.11.8 模板市场

对标 NocoBase 的模板市场，提供模板的分享、搜索和安装功能。

##### 4.11.8.1 数据库表扩展

```sql
-- 模板市场表（系统级）
CREATE TABLE nocobase_template_market (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    template_id BIGINT NOT NULL COMMENT '模板ID',
    market_name VARCHAR(200) NOT NULL COMMENT '市场展示名称',
    market_description TEXT COMMENT '市场展示描述',
    preview_image VARCHAR(500) COMMENT '预览图 URL',
    demo_url VARCHAR(500) COMMENT '演示地址',
    price DECIMAL(10,2) DEFAULT 0 COMMENT '价格（0 表示免费）',
    download_count INT DEFAULT 0 COMMENT '下载次数',
    rating DECIMAL(2,1) DEFAULT 0 COMMENT '评分（0-5）',
    rating_count INT DEFAULT 0 COMMENT '评分人数',
    tags VARCHAR(500) COMMENT '标签（逗号分隔）',
    is_featured TINYINT(1) DEFAULT 0 COMMENT '是否推荐：0-否，1-是',
    status VARCHAR(32) DEFAULT 'pending' COMMENT '状态：pending/approved/rejected',
    publisher_id BIGINT NOT NULL COMMENT '发布者ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_status (status),
    INDEX idx_featured (is_featured),
    INDEX idx_download_count (download_count),
    INDEX idx_rating (rating)
) COMMENT='模板市场表';

-- 模板评价表
CREATE TABLE nocobase_template_review (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    market_id BIGINT NOT NULL COMMENT '市场模板ID',
    user_id BIGINT NOT NULL COMMENT '评价用户ID',
    rating INT NOT NULL COMMENT '评分（1-5）',
    comment TEXT COMMENT '评价内容',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    UNIQUE INDEX uk_market_user (market_id, user_id),
    INDEX idx_market (market_id)
) COMMENT='模板评价表';
```

##### 4.11.8.2 模板市场前端组件

```typescript
// src/components/nocode/TemplateMarket.vue
<template>
  <div class="template-market">
    <!-- 搜索和筛选 -->
    <div class="market-header">
      <el-input 
        v-model="searchKeyword" 
        placeholder="搜索模板..." 
        prefix-icon="Search"
        clearable
        @input="handleSearch"
      />
      <div class="filter-tags">
        <el-check-tag 
          v-for="tag in availableTags" 
          :key="tag"
          :checked="selectedTags.includes(tag)"
          @change="toggleTag(tag)"
        >
          {{ tag }}
        </el-check-tag>
      </div>
      <el-select v-model="sortBy" placeholder="排序方式">
        <el-option label="最热" value="download_count" />
        <el-option label="最新" value="create_time" />
        <el-option label="评分最高" value="rating" />
      </el-select>
    </div>
    
    <!-- 推荐轮播 -->
    <el-carousel v-if="featuredTemplates.length > 0" height="300px">
      <el-carousel-item v-for="tpl in featuredTemplates" :key="tpl.id">
        <div class="featured-card" @click="viewTemplateDetail(tpl)">
          <img :src="tpl.previewImage" class="preview-img" />
          <div class="featured-info">
            <h3>{{ tpl.marketName }}</h3>
            <p>{{ tpl.marketDescription }}</p>
            <div class="featured-meta">
              <el-rate v-model="tpl.rating" disabled />
              <span>{{ tpl.downloadCount }} 次下载</span>
              <el-tag v-if="tpl.price === 0" type="success">免费</el-tag>
              <el-tag v-else>¥{{ tpl.price }}</el-tag>
            </div>
          </div>
        </div>
      </el-carousel-item>
    </el-carousel>
    
    <!-- 模板网格 -->
    <el-row :gutter="16" class="template-grid">
      <el-col :span="6" v-for="tpl in filteredTemplates" :key="tpl.id">
        <el-card class="market-template-card" shadow="hover">
          <img :src="tpl.previewImage" class="card-preview" />
          <div class="card-body">
            <h4>{{ tpl.marketName }}</h4>
            <p class="card-desc">{{ tpl.marketDescription }}</p>
            <div class="card-meta">
              <el-rate v-model="tpl.rating" disabled show-score text-color="#ff9900" />
              <span class="download-count">
                <el-icon><Download /></el-icon> {{ tpl.downloadCount }}
              </span>
            </div>
            <div class="card-tags">
              <el-tag v-for="tag in tpl.tags?.split(',')" :key="tag" size="small">
                {{ tag }}
              </el-tag>
            </div>
            <div class="card-actions">
              <el-button size="small" @click="previewTemplate(tpl)">预览</el-button>
              <el-button size="small" type="primary" @click="installTemplate(tpl)">
                {{ tpl.price === 0 ? '免费安装' : `¥${tpl.price}` }}
              </el-button>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    
    <!-- 模板详情弹窗 -->
    <el-dialog v-model="detailVisible" title="模板详情" width="800px">
      <div v-if="currentTemplate" class="template-detail">
        <el-carousel height="400px">
          <el-carousel-item>
            <img :src="currentTemplate.previewImage" class="detail-preview" />
          </el-carousel-item>
        </el-carousel>
        <h2>{{ currentTemplate.marketName }}</h2>
        <p>{{ currentTemplate.marketDescription }}</p>
        <div class="detail-meta">
          <el-rate v-model="currentTemplate.rating" />
          <span>{{ currentTemplate.ratingCount }} 人评价</span>
          <span>{{ currentTemplate.downloadCount }} 次下载</span>
        </div>
        
        <!-- 评价列表 -->
        <div class="review-section">
          <h3>用户评价</h3>
          <div v-for="review in reviews" :key="review.id" class="review-item">
            <el-rate v-model="review.rating" disabled />
            <p>{{ review.comment }}</p>
            <span class="review-time">{{ review.createTime }}</span>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
        <el-button type="primary" @click="installTemplate(currentTemplate)">安装模板</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { templateMarketApi } from '@/api/nocode/templateMarket'

const searchKeyword = ref('')
const selectedTags = ref<string[]>([])
const sortBy = ref('download_count')
const availableTags = ref(['CRM', '项目管理', 'OA', '数据分析', '电商', '教育'])
const featuredTemplates = ref<any[]>([])
const filteredTemplates = ref<any[]>([])
const detailVisible = ref(false)
const currentTemplate = ref<any>(null)
const reviews = ref<any[]>([])

const handleSearch = async () => {
  filteredTemplates.value = await templateMarketApi.search({
    keyword: searchKeyword.value,
    tags: selectedTags.value,
    sortBy: sortBy.value,
  })
}

const toggleTag = (tag: string) => {
  const idx = selectedTags.value.indexOf(tag)
  if (idx >= 0) {
    selectedTags.value.splice(idx, 1)
  } else {
    selectedTags.value.push(tag)
  }
  handleSearch()
}

const previewTemplate = (tpl: any) => {
  if (tpl.demoUrl) {
    window.open(tpl.demoUrl, '_blank')
  }
}

const installTemplate = async (tpl: any) => {
  await templateMarketApi.install(tpl.id)
  ElMessage.success('模板安装成功')
}

const viewTemplateDetail = async (tpl: any) => {
  currentTemplate.value = tpl
  reviews.value = await templateMarketApi.getReviews(tpl.id)
  detailVisible.value = true
}

onMounted(async () => {
  featuredTemplates.value = await templateMarketApi.getFeatured()
  await handleSearch()
})
</script>
```

#### 4.11.9 AI 生成模板

对标 NocoBase 的 AI 能力，支持通过对话描述需求自动生成模板。

##### 4.11.9.1 AI 模板生成工具

```java
/**
 * AI 工具：生成模板
 */
@Component
public class GenerateTemplateTool implements ToolCallback {
    
    @Resource
    private TemplateMapper templateMapper;
    
    @Resource
    private CollectionService collectionService;
    
    @Resource
    private PageSchemaService pageSchemaService;
    
    @Override
    public String getName() {
        return "generate_template";
    }
    
    @Override
    public String getDescription() {
        return "根据需求描述自动生成区块/页面模板。支持生成表格、表单、详情等区块模板";
    }
    
    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String requirement = args.getStr("requirement");
        String templateType = args.getStr("templateType", "block");
        String blockType = args.getStr("blockType", "table"); // table/form/detail
        
        // 1. 分析需求，提取 Collection 和字段信息
        List<CollectionDO> collections = collectionService.listAll();
        String collectionContext = buildCollectionContext(collections);
        
        // 2. 调用 LLM 生成 Schema
        String prompt = buildTemplateGenerationPrompt(requirement, blockType, collectionContext);
        String schemaJson = llmClient.generateSchema(prompt);
        
        // 3. 验证生成的 Schema
        SchemaValidationResult validationResult = schemaValidator.validate(schemaJson);
        if (!validationResult.isValid()) {
            return JSONUtil.toJsonStr(Map.of(
                "success", false,
                "message", "生成的 Schema 验证失败: " + validationResult.getErrors()
            ));
        }
        
        // 4. 创建模板
        TemplateDO template = new TemplateDO();
        template.setUid(UUID.randomUUID().toString());
        template.setName(generateTemplateName(requirement));
        template.setDescription("AI 生成: " + requirement);
        template.setTemplateType(templateType);
        template.setSchemaJson(schemaJson);
        template.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        templateMapper.insert(template);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true,
            "templateId", template.getId(),
            "templateName", template.getName(),
            "message", "模板生成成功"
        ));
    }
    
    private String buildTemplateGenerationPrompt(String requirement, String blockType, 
                                                  String collectionContext) {
        return String.format("""
            你是一个无代码平台的 Schema 生成专家。请根据以下需求生成 Formily Vue Schema JSON。
            
            需求描述：%s
            区块类型：%s
            
            可用的 Collection 和字段：
            %s
            
            要求：
            1. 生成符合 Formily Vue 规范的 Schema JSON
            2. 字段类型要匹配 Collection 中定义的字段类型
            3. 包含合理的布局和样式配置
            4. 如果是表格区块，包含排序、筛选、分页配置
            5. 如果是表单区块，包含验证规则和提交配置
            
            请直接输出 JSON，不要包含其他说明文字。
            """, requirement, blockType, collectionContext);
    }
    
    private String buildCollectionContext(List<CollectionDO> collections) {
        StringBuilder sb = new StringBuilder();
        for (CollectionDO coll : collections) {
            sb.append(String.format("Collection: %s (%s)\n", coll.getName(), coll.getDisplayName()));
            List<FieldDO> fields = fieldMapper.selectByCollectionName(coll.getName());
            for (FieldDO field : fields) {
                sb.append(String.format("  - %s (%s): %s\n", 
                    field.getName(), field.getFieldType(), field.getDisplayName()));
            }
        }
        return sb.toString();
    }
    
    private String generateTemplateName(String requirement) {
        // 从需求中提取关键词作为模板名称
        if (requirement.length() > 20) {
            return requirement.substring(0, 20) + "...";
        }
        return requirement;
    }
}
```

##### 4.11.9.2 AI 对话示例

```
用户: 帮我生成一个客户列表的表格模板，需要显示客户名称、联系人、电话、状态，支持搜索和筛选

AI: 好的，我来为您生成客户列表的表格模板。

[调用 generate_template 工具]
{
  "requirement": "客户列表的表格模板，需要显示客户名称、联系人、电话、状态，支持搜索和筛选",
  "templateType": "block",
  "blockType": "table"
}

AI: 已成功生成客户列表表格模板！

模板包含以下功能：
- 表格展示：客户名称、联系人、电话、状态
- 搜索功能：支持按客户名称模糊搜索
- 筛选功能：支持按状态筛选
- 分页功能：每页 20 条记录
- 排序功能：支持按创建时间排序

您可以：
1. 在模板管理中查看该模板
2. 将模板应用到页面中
3. 根据需要进一步调整配置
```

---

### 4.12 子表格编辑模式（对标 NocoBase SubTable Edit Modes）

NocoBase 支持两种子表格编辑模式：行内编辑和弹窗编辑，适用于不同的业务场景。

#### 4.12.1 编辑模式对比

| 编辑模式 | 说明 | 适用场景 | 优点 | 缺点 |
|---------|------|---------|------|------|
| **行内编辑** | 直接在表格行内编辑 | 简单字段、快速录入 | 操作便捷、直观 | 字段过多时拥挤 |
| **弹窗编辑** | 通过弹窗编辑 | 复杂字段、关联数据 | 空间充足、支持复杂交互 | 操作步骤多 |

#### 4.12.2 行内编辑模式

```typescript
// src/components/nocode/blocks/SubTableInlineEdit.vue
<template>
  <div class="sub-table-inline-edit">
    <el-table :data="tableData" border>
      <!-- 普通字段：直接编辑 -->
      <el-table-column 
        v-for="field in editableFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 150"
      >
        <template #default="{ row }">
          <component 
            :is="getFieldComponent(field)"
            v-model="row[field.name]"
            :placeholder="field.placeholder"
            :disabled="isFieldDisabled(field, row)"
            @change="handleFieldChange(row, field)"
            class="inline-edit-component"
          />
        </template>
      </el-table-column>
      
      <!-- 关联字段：弹窗选择 -->
      <el-table-column 
        v-for="field in relationFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 200"
      >
        <template #default="{ row }">
          <div class="relation-field-wrapper">
            <span class="relation-value">{{ getRelationDisplayValue(row, field) }}</span>
            <el-button size="small" text @click="openRelationPicker(row, field)">
              <el-icon><Edit /></el-icon>
            </el-button>
          </div>
        </template>
      </el-table-column>
      
      <!-- 操作列 -->
      <el-table-column label="操作" width="120" fixed="right">
        <template #default="{ row, $index }">
          <el-button size="small" type="danger" text @click="removeRow($index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <el-button class="mt-4" @click="addRow">
      <el-icon><Plus /></el-icon> 添加行
    </el-button>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps<{
  fields: any[]
  modelValue: any[]
}>()

const emit = defineEmits(['update:modelValue', 'change'])

const tableData = ref(props.modelValue || [])

// 可编辑的普通字段
const editableFields = computed(() => {
  return props.fields.filter(f => 
    !f.fieldType.startsWith('belongsTo') &&
    !f.fieldType.startsWith('hasMany') &&
    !f.fieldType.startsWith('belongsToMany') &&
    !['id', 'create_time', 'update_time', 'creator', 'updater'].includes(f.name)
  )
})

// 关联字段
const relationFields = computed(() => {
  return props.fields.filter(f => 
    f.fieldType.startsWith('belongsTo') ||
    f.fieldType.startsWith('belongsToMany')
  )
})

// 获取字段编辑组件
const getFieldComponent = (field: any) => {
  const componentMap: Record<string, string> = {
    string: 'el-input',
    text: 'el-input',
    integer: 'el-input-number',
    decimal: 'el-input-number',
    boolean: 'el-switch',
    datetime: 'el-date-picker',
    select: 'el-select',
  }
  return componentMap[field.fieldType] || 'el-input'
}

// 字段是否禁用
const isFieldDisabled = (field: any, row: any) => {
  // 根据业务逻辑判断
  return false
}

// 字段值变更
const handleFieldChange = (row: any, field: any) => {
  emit('update:modelValue', tableData.value)
  emit('change', { row, field, value: row[field.name] })
}

// 获取关联字段显示值
const getRelationDisplayValue = (row: any, field: any) => {
  const relationData = row[field.name]
  if (!relationData) return ''
  
  // 根据关联字段的配置获取显示字段
  const displayField = field.uiSchema?.['x-component-props']?.displayField || 'name'
  return relationData[displayField] || relationData.id
}

// 打开关联选择器
const openRelationPicker = (row: any, field: any) => {
  // 打开弹窗选择关联数据
  // TODO: 实现关联选择器弹窗
}

// 添加行
const addRow = () => {
  const newRow: any = {}
  // 初始化默认值
  for (const field of props.fields) {
    if (field.defaultValue !== undefined) {
      newRow[field.name] = field.defaultValue
    }
  }
  tableData.value.push(newRow)
  emit('update:modelValue', tableData.value)
}

// 删除行
const removeRow = (index: number) => {
  tableData.value.splice(index, 1)
  emit('update:modelValue', tableData.value)
}
</script>

<style scoped>
.inline-edit-component {
  width: 100%;
}

.relation-field-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
}

.relation-value {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
```

#### 4.12.3 弹窗编辑模式

```typescript
// src/components/nocode/blocks/SubTableDialogEdit.vue
<template>
  <div class="sub-table-dialog-edit">
    <el-table :data="tableData" border>
      <!-- 只读展示所有字段 -->
      <el-table-column 
        v-for="field in displayFields" 
        :key="field.name"
        :label="field.displayName"
        :prop="field.name"
        :width="field.width || 150"
      >
        <template #default="{ row }">
          {{ formatFieldValue(row[field.name], field) }}
        </template>
      </el-table-column>
      
      <!-- 操作列 -->
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="{ row, $index }">
          <el-button size="small" type="primary" text @click="editRow(row, $index)">
            编辑
          </el-button>
          <el-button size="small" type="danger" text @click="removeRow($index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <el-button class="mt-4" @click="addRow">
      <el-icon><Plus /></el-icon> 添加
    </el-button>
    
    <!-- 编辑弹窗 -->
    <el-dialog 
      v-model="editDialogVisible" 
      :title="isEditing ? '编辑' : '新增'" 
      width="600px"
    >
      <el-form :model="editForm" label-width="120px">
        <el-form-item 
          v-for="field in editableFields" 
          :key="field.name"
          :label="field.displayName"
          :required="field.required"
        >
          <component 
            :is="getFieldComponent(field)"
            v-model="editForm[field.name]"
            :placeholder="field.placeholder"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveEdit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps<{
  fields: any[]
  modelValue: any[]
}>()

const emit = defineEmits(['update:modelValue', 'change'])

const tableData = ref(props.modelValue || [])
const editDialogVisible = ref(false)
const isEditing = ref(false)
const editingIndex = ref(-1)
const editForm = ref<any>({})

// 展示字段
const displayFields = computed(() => {
  return props.fields.filter(f => 
    !['id', 'create_time', 'update_time', 'creator', 'updater', 'deleted'].includes(f.name)
  )
})

// 可编辑字段
const editableFields = computed(() => {
  return props.fields.filter(f => 
    !['id', 'create_time', 'update_time', 'creator', 'updater'].includes(f.name)
  )
})

// 获取字段编辑组件
const getFieldComponent = (field: any) => {
  const componentMap: Record<string, string> = {
    string: 'el-input',
    text: 'el-input',
    integer: 'el-input-number',
    decimal: 'el-input-number',
    boolean: 'el-switch',
    datetime: 'el-date-picker',
    select: 'el-select',
  }
  return componentMap[field.fieldType] || 'el-input'
}

// 格式化字段值
const formatFieldValue = (value: any, field: any) => {
  if (value === null || value === undefined) return ''
  
  switch (field.fieldType) {
    case 'boolean':
      return value ? '是' : '否'
    case 'datetime':
      return new Date(value).toLocaleString()
    case 'select':
      // 返回选项标签
      return value
    default:
      return value
  }
}

// 添加行
const addRow = () => {
  isEditing.value = false
  editingIndex.value = -1
  editForm.value = {}
  
  // 初始化默认值
  for (const field of props.fields) {
    if (field.defaultValue !== undefined) {
      editForm.value[field.name] = field.defaultValue
    }
  }
  
  editDialogVisible.value = true
}

// 编辑行
const editRow = (row: any, index: number) => {
  isEditing.value = true
  editingIndex.value = index
  editForm.value = { ...row }
  editDialogVisible.value = true
}

// 保存编辑
const saveEdit = () => {
  // 校验必填字段
  for (const field of editableFields.value) {
    if (field.required && (editForm.value[field.name] === undefined || editForm.value[field.name] === null || editForm.value[field.name] === '')) {
      ElMessage.warning(`请填写${field.displayName}`)
      return
    }
  }
  
  if (isEditing.value) {
    // 更新
    tableData.value[editingIndex.value] = { ...editForm.value }
  } else {
    // 新增
    tableData.value.push({ ...editForm.value })
  }
  
  emit('update:modelValue', tableData.value)
  editDialogVisible.value = false
}

// 删除行
const removeRow = (index: number) => {
  tableData.value.splice(index, 1)
  emit('update:modelValue', tableData.value)
}
</script>
```

#### 4.12.4 编辑模式切换与批量操作

```typescript
// src/components/nocode/blocks/SubTableBlock.vue
<template>
  <div class="sub-table-block">
    <div class="sub-table-header">
      <span class="sub-table-title">{{ field.displayName }}</span>
      <div class="header-actions">
        <el-radio-group v-model="editMode" size="small">
          <el-radio-button label="inline">行内编辑</el-radio-button>
          <el-radio-button label="dialog">弹窗编辑</el-radio-button>
        </el-radio-group>
        <el-button size="small" @click="showBatchActions = !showBatchActions">
          <el-icon><Operation /></el-icon> 批量操作
        </el-button>
      </div>
    </div>
    
    <!-- 批量操作栏 -->
    <div v-if="showBatchActions" class="batch-actions-bar">
      <el-button size="small" @click="selectAll">全选</el-button>
      <el-button size="small" @click="batchDelete" :disabled="selectedRows.length === 0">
        批量删除 ({{ selectedRows.length }})
      </el-button>
      <el-button size="small" @click="batchExport" :disabled="selectedRows.length === 0">
        批量导出
      </el-button>
      <el-button size="small" @click="batchAssign" :disabled="selectedRows.length === 0">
        批量赋值
      </el-button>
      <el-button size="small" @click="openAiAssistant">
        <el-icon><ChatDotRound /></el-icon> AI 助手
      </el-button>
    </div>
    
    <component 
      :is="editMode === 'inline' ? SubTableInlineEdit : SubTableDialogEdit"
      :fields="subFields"
      v-model="tableData"
      v-model:selectedRows="selectedRows"
      :validationRules="validationRules"
      :calculationRules="calculationRules"
      :enableDragSort="field.enableDragSort"
      @change="handleDataChange"
      @validation-error="handleValidationError"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import SubTableInlineEdit from './SubTableInlineEdit.vue'
import SubTableDialogEdit from './SubTableDialogEdit.vue'

const props = defineProps<{
  field: any
  modelValue: any[]
}>()

const emit = defineEmits(['update:modelValue', 'change', 'validation-error'])

const editMode = ref<'inline' | 'dialog'>('inline')
const tableData = ref(props.modelValue || [])
const selectedRows = ref<number[]>([])
const showBatchActions = ref(false)

// 子表字段
const subFields = computed(() => {
  return props.field.subFields || []
})

// 校验规则（从字段配置中提取）
const validationRules = computed(() => {
  const rules: Record<string, any[]> = {}
  subFields.value.forEach(field => {
    rules[field.name] = []
    if (field.required) {
      rules[field.name].push({ required: true, message: `${field.displayName}不能为空` })
    }
    if (field.validationRules) {
      rules[field.name].push(...field.validationRules)
    }
  })
  return rules
})

// 计算规则（行内计算公式）
const calculationRules = computed(() => {
  return props.field.calculationRules || []
})

const handleDataChange = (data: any[]) => {
  emit('update:modelValue', data)
  emit('change', data)
}

const handleValidationError = (error: any) => {
  ElMessage.error(error.message)
  emit('validation-error', error)
}

// 全选
const selectAll = () => {
  if (selectedRows.value.length === tableData.value.length) {
    selectedRows.value = []
  } else {
    selectedRows.value = tableData.value.map((_, index) => index)
  }
}

// 批量删除
const batchDelete = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要删除选中的 ${selectedRows.value.length} 行数据吗？`,
      '批量删除确认',
      { type: 'warning' }
    )
    
    const newData = tableData.value.filter((_, index) => !selectedRows.value.includes(index))
    tableData.value = newData
    selectedRows.value = []
    emit('update:modelValue', newData)
    ElMessage.success('批量删除成功')
  } catch {
    // 用户取消
  }
}

// 批量导出
const batchExport = () => {
  const exportData = tableData.value.filter((_, index) => selectedRows.value.includes(index))
  // TODO: 调用导出服务
  ElMessage.success(`已导出 ${exportData.length} 行数据`)
}

// 批量赋值
const batchAssign = () => {
  // TODO: 打开批量赋值弹窗，选择字段和值
  ElMessage.info('批量赋值功能开发中')
}

// 打开 AI 助手
const openAiAssistant = () => {
  // TODO: 打开 AI 对话助手，支持自然语言操作子表格
  ElMessage.info('AI 助手功能开发中')
}
</script>

<style scoped>
.sub-table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.sub-table-title {
  font-weight: bold;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.batch-actions-bar {
  display: flex;
  gap: 8px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 4px;
  margin-bottom: 16px;
}
</style>
```

#### 4.12.5 拖拽排序与行内计算

```typescript
// src/components/nocode/blocks/SubTableInlineEdit.vue (增强版)
<template>
  <div class="sub-table-inline-edit">
    <el-table :data="tableData" border>
      <!-- 拖拽手柄列 -->
      <el-table-column width="50" v-if="enableDragSort">
        <template #default>
          <el-icon class="drag-handle"><Rank /></el-icon>
        </template>
      </el-table-column>
      
      <!-- 选择框列 -->
      <el-table-column width="50" v-if="enableBatchSelect">
        <template #default="{ $index }">
          <el-checkbox 
            v-model="selectedRows" 
            :label="$index"
            @change="handleSelectionChange"
          />
        </template>
      </el-table-column>
      
      <!-- 普通字段：直接编辑 -->
      <el-table-column 
        v-for="field in editableFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 150"
      >
        <template #default="{ row, $index }">
          <div class="cell-wrapper">
            <component 
              :is="getFieldComponent(field)"
              v-model="row[field.name]"
              :placeholder="field.placeholder"
              :disabled="isFieldDisabled(field, row)"
              @change="handleFieldChange(row, field, $index)"
              @blur="validateCell(row, field, $index)"
              class="inline-edit-component"
              :class="{ 'validation-error': cellErrors[$index]?.[field.name] }"
            />
            <div v-if="cellErrors[$index]?.[field.name]" class="cell-error">
              {{ cellErrors[$index][field.name] }}
            </div>
          </div>
        </template>
      </el-table-column>
      
      <!-- 计算字段：只读展示 -->
      <el-table-column 
        v-for="field in calculatedFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 150"
      >
        <template #default="{ row }">
          <span class="calculated-value">{{ calculateFieldValue(row, field) }}</span>
        </template>
      </el-table-column>
      
      <!-- 关联字段：弹窗选择 -->
      <el-table-column 
        v-for="field in relationFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 200"
      >
        <template #default="{ row }">
          <div class="relation-field-wrapper">
            <span class="relation-value">{{ getRelationDisplayValue(row, field) }}</span>
            <el-button size="small" text @click="openRelationPicker(row, field)">
              <el-icon><Edit /></el-icon>
            </el-button>
          </div>
        </template>
      </el-table-column>
      
      <!-- 操作列 -->
      <el-table-column label="操作" width="120" fixed="right">
        <template #default="{ row, $index }">
          <el-button size="small" type="danger" text @click="removeRow($index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <el-button class="mt-4" @click="addRow">
      <el-icon><Plus /></el-icon> 添加行
    </el-button>
    
    <!-- 拖拽排序初始化 -->
    <div v-if="enableDragSort" ref="sortableContainer" class="sortable-container"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import Sortable from 'sortablejs'

const props = defineProps<{
  fields: any[]
  modelValue: any[]
  selectedRows?: number[]
  validationRules?: Record<string, any[]>
  calculationRules?: any[]
  enableDragSort?: boolean
}>()

const emit = defineEmits(['update:modelValue', 'change', 'validation-error', 'update:selectedRows'])

const tableData = ref(props.modelValue || [])
const cellErrors = ref<Record<number, Record<string, string>>>({})
const sortableContainer = ref<HTMLElement | null>(null)
let sortableInstance: Sortable | null = null

// 启用拖拽排序
const enableDragSort = computed(() => props.enableDragSort || false)
// 启用批量选择
const enableBatchSelect = computed(() => props.selectedRows !== undefined)

// 可编辑的普通字段
const editableFields = computed(() => {
  return props.fields.filter(f => 
    !f.fieldType.startsWith('belongsTo') &&
    !f.fieldType.startsWith('hasMany') &&
    !f.fieldType.startsWith('belongsToMany') &&
    !['id', 'create_time', 'update_time', 'creator', 'updater'].includes(f.name) &&
    !f.isCalculated
  )
})

// 计算字段
const calculatedFields = computed(() => {
  return props.fields.filter(f => f.isCalculated)
})

// 关联字段
const relationFields = computed(() => {
  return props.fields.filter(f => 
    f.fieldType.startsWith('belongsTo') ||
    f.fieldType.startsWith('belongsToMany')
  )
})

// 初始化拖拽排序
onMounted(() => {
  if (enableDragSort.value && sortableContainer.value) {
    initSortable()
  }
})

// 监听拖拽开关
watch(enableDragSort, (enabled) => {
  if (enabled && sortableContainer.value) {
    initSortable()
  } else if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }
})

const initSortable = () => {
  const tableBody = sortableContainer.value?.closest('.el-table')?.querySelector('.el-table__body-wrapper tbody')
  if (!tableBody) return
  
  sortableInstance = Sortable.create(tableBody as HTMLElement, {
    handle: '.drag-handle',
    animation: 150,
    onEnd: (evt) => {
      const { oldIndex, newIndex } = evt
      if (oldIndex === newIndex) return
      
      // 更新数据顺序
      const item = tableData.value[oldIndex!]
      tableData.value.splice(oldIndex!, 1)
      tableData.value.splice(newIndex!, 0, item)
      
      emit('update:modelValue', tableData.value)
      emit('change', tableData.value)
    }
  })
}

// 获取字段编辑组件
const getFieldComponent = (field: any) => {
  const componentMap: Record<string, string> = {
    string: 'el-input',
    text: 'el-input',
    integer: 'el-input-number',
    decimal: 'el-input-number',
    boolean: 'el-switch',
    datetime: 'el-date-picker',
    select: 'el-select',
  }
  return componentMap[field.fieldType] || 'el-input'
}

// 字段是否禁用
const isFieldDisabled = (field: any, row: any) => {
  // 根据业务逻辑判断
  return false
}

// 字段值变更
const handleFieldChange = (row: any, field: any, index: number) => {
  // 清除该字段的错误
  if (cellErrors.value[index]?.[field.name]) {
    delete cellErrors.value[index][field.name]
  }
  
  // 触发计算字段更新
  updateCalculatedFields(row, index)
  
  emit('update:modelValue', tableData.value)
  emit('change', { row, field, value: row[field.name], index })
}

// 单元格校验
const validateCell = (row: any, field: any, index: number) => {
  if (!props.validationRules?.[field.name]) return
  
  const rules = props.validationRules[field.name]
  const errors: string[] = []
  
  for (const rule of rules) {
    if (rule.required && (row[field.name] === undefined || row[field.name] === null || row[field.name] === '')) {
      errors.push(rule.message || `${field.displayName}不能为空`)
    }
    if (rule.pattern && !rule.pattern.test(row[field.name])) {
      errors.push(rule.message || `${field.displayName}格式不正确`)
    }
    if (rule.min !== undefined && row[field.name] < rule.min) {
      errors.push(rule.message || `${field.displayName}不能小于${rule.min}`)
    }
    if (rule.max !== undefined && row[field.name] > rule.max) {
      errors.push(rule.message || `${field.displayName}不能大于${rule.max}`)
    }
  }
  
  if (errors.length > 0) {
    if (!cellErrors.value[index]) {
      cellErrors.value[index] = {}
    }
    cellErrors.value[index][field.name] = errors.join('; ')
    emit('validation-error', { row, field, index, errors })
  }
}

// 计算字段值
const calculateFieldValue = (row: any, field: any) => {
  const calcRule = props.calculationRules?.find(r => r.targetField === field.name)
  if (!calcRule) return row[field.name]
  
  try {
    // 简单的表达式计算（实际应使用更安全的表达式引擎）
    const expression = calcRule.expression
    // 替换字段名为实际值
    let evalExpr = expression.replace(/\{(\w+)\}/g, (match: string, fieldName: string) => {
      return row[fieldName] ?? 0
    })
    // 注意：实际生产环境应使用安全的表达式解析器（如 expr-eval）
    return eval(evalExpr)
  } catch (e) {
    return row[field.name]
  }
}

// 更新计算字段
const updateCalculatedFields = (row: any, index: number) => {
  calculatedFields.value.forEach(field => {
    row[field.name] = calculateFieldValue(row, field)
  })
}

// 选择变更
const handleSelectionChange = () => {
  emit('update:selectedRows', props.selectedRows)
}

// 获取关联字段显示值
const getRelationDisplayValue = (row: any, field: any) => {
  const relationData = row[field.name]
  if (!relationData) return ''
  
  const displayField = field.uiSchema?.['x-component-props']?.displayField || 'name'
  return relationData[displayField] || relationData.id
}

// 打开关联选择器
const openRelationPicker = (row: any, field: any) => {
  // TODO: 实现关联选择器弹窗
}

// 添加行
const addRow = () => {
  const newRow: any = {}
  // 初始化默认值
  for (const field of props.fields) {
    if (field.defaultValue !== undefined) {
      newRow[field.name] = field.defaultValue
    }
  }
  tableData.value.push(newRow)
  emit('update:modelValue', tableData.value)
}

// 删除行
const removeRow = (index: number) => {
  tableData.value.splice(index, 1)
  emit('update:modelValue', tableData.value)
}
</script>

<style scoped>
.inline-edit-component {
  width: 100%;
}

.cell-wrapper {
  position: relative;
}

.cell-error {
  position: absolute;
  bottom: -18px;
  left: 0;
  font-size: 12px;
  color: #f56c6c;
  white-space: nowrap;
}

.validation-error {
  border-color: #f56c6c !important;
}

.calculated-value {
  color: #909399;
  font-style: italic;
}

.drag-handle {
  cursor: move;
  font-size: 18px;
  color: #909399;
}

.drag-handle:hover {
  color: #409eff;
}

.relation-field-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
}

.relation-value {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
```

#### 4.12.6 数据校验规则引擎

```java
/**
 * 子表格数据校验引擎
 */
@Component
public class SubTableValidationEngine {

    /**
     * 校验子表格数据
     */
    public ValidationResult validate(List<Map<String, Object>> tableData, List<FieldMeta> fields) {
        ValidationResult result = new ValidationResult();
        
        for (int i = 0; i < tableData.size(); i++) {
            Map<String, Object> row = tableData.get(i);
            RowValidationResult rowResult = validateRow(row, fields, i);
            if (!rowResult.isValid()) {
                result.addRowError(i, rowResult);
            }
        }
        
        // 执行跨行校验（如：唯一性约束）
        validateCrossRowConstraints(tableData, fields, result);
        
        return result;
    }
    
    /**
     * 校验单行数据
     */
    private RowValidationResult validateRow(Map<String, Object> row, List<FieldMeta> fields, int rowIndex) {
        RowValidationResult rowResult = new RowValidationResult(rowIndex);
        
        for (FieldMeta field : fields) {
            Object value = row.get(field.getName());
            
            // 必填校验
            if (field.isRequired() && isEmpty(value)) {
                rowResult.addFieldError(field.getName(), field.getDisplayName() + "不能为空");
                continue;
            }
            
            // 类型校验
            if (value != null && !isEmpty(value)) {
                if (!validateType(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "类型不正确");
                    continue;
                }
                
                // 范围校验
                if (!validateRange(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "超出范围");
                    continue;
                }
                
                // 格式校验
                if (!validateFormat(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "格式不正确");
                }
            }
        }
        
        return rowResult;
    }
    
    /**
     * 跨行约束校验
     */
    private void validateCrossRowConstraints(List<Map<String, Object>> tableData, List<FieldMeta> fields, ValidationResult result) {
        for (FieldMeta field : fields) {
            if (field.isUniqueInSubTable()) {
                Set<Object> seen = new HashSet<>();
                for (int i = 0; i < tableData.size(); i++) {
                    Object value = tableData.get(i).get(field.getName());
                    if (value != null && !isEmpty(value)) {
                        if (!seen.add(value)) {
                            result.addRowError(i, new RowValidationResult(i)
                                .addFieldError(field.getName(), field.getDisplayName() + "必须唯一"));
                        }
                    }
                }
            }
        }
    }
    
    private boolean isEmpty(Object value) {
        if (value == null) return true;
        if (value instanceof String) return ((String) value).trim().isEmpty();
        return false;
    }
    
    private boolean validateType(Object value, FieldMeta field) {
        switch (field.getFieldType()) {
            case "integer":
                return value instanceof Integer || value instanceof Long;
            case "decimal":
                return value instanceof Number;
            case "boolean":
                return value instanceof Boolean;
            case "datetime":
                return value instanceof Date || value instanceof String;
            default:
                return true;
        }
    }
    
    private boolean validateRange(Object value, FieldMeta field) {
        if (field.getMinValue() != null && value instanceof Number) {
            if (((Number) value).doubleValue() < field.getMinValue().doubleValue()) {
                return false;
            }
        }
        if (field.getMaxValue() != null && value instanceof Number) {
            if (((Number) value).doubleValue() > field.getMaxValue().doubleValue()) {
                return false;
            }
        }
        return true;
    }
    
    private boolean validateFormat(Object value, FieldMeta field) {
        if (field.getPattern() != null && value instanceof String) {
            return Pattern.matches(field.getPattern(), (String) value);
        }
        return true;
    }
}

/**
 * 校验结果
 */
@Data
public class ValidationResult {
    private Map<Integer, RowValidationResult> rowErrors = new LinkedHashMap<>();
    
    public void addRowError(int rowIndex, RowValidationResult rowResult) {
        rowErrors.put(rowIndex, rowResult);
    }
    
    public boolean isValid() {
        return rowErrors.isEmpty();
    }
    
    public List<String> getAllErrors() {
        List<String> errors = new ArrayList<>();
        rowErrors.forEach((rowIndex, rowResult) -> {
            rowResult.getFieldErrors().forEach((field, message) -> {
                errors.add(String.format("第 %d 行：%s", rowIndex + 1, message));
            });
        });
        return errors;
    }
}

@Data
public class RowValidationResult {
    private int rowIndex;
    private Map<String, String> fieldErrors = new LinkedHashMap<>();
    
    public RowValidationResult(int rowIndex) {
        this.rowIndex = rowIndex;
    }
    
    public RowValidationResult addFieldError(String fieldName, String message) {
        fieldErrors.put(fieldName, message);
        return this;
    }
    
    public boolean isValid() {
        return fieldErrors.isEmpty();
    }
}
```

#### 4.12.7 行内计算引擎

```java
/**
 * 子表格行内计算引擎
 */
@Component
public class SubTableCalculationEngine {

    private final ExpressionParser expressionParser;
    
    public SubTableCalculationEngine() {
        this.expressionParser = new ExpressionParser();
    }
    
    /**
     * 计算单行的所有计算字段
     */
    public Map<String, Object> calculateRow(Map<String, Object> rowData, List<CalculationRule> rules) {
        Map<String, Object> calculatedValues = new HashMap<>();
        
        for (CalculationRule rule : rules) {
            try {
                Object result = evaluateExpression(rule.getExpression(), rowData);
                calculatedValues.put(rule.getTargetField(), result);
            } catch (Exception e) {
                log.warn("计算字段失败: field={}, error={}", rule.getTargetField(), e.getMessage());
                calculatedValues.put(rule.getTargetField(), null);
            }
        }
        
        return calculatedValues;
    }
    
    /**
     * 批量计算多行
     */
    public List<Map<String, Object>> calculateRows(List<Map<String, Object>> tableData, List<CalculationRule> rules) {
        return tableData.stream()
            .map(row -> {
                Map<String, Object> calculated = calculateRow(row, rules);
                Map<String, Object> newRow = new HashMap<>(row);
                newRow.putAll(calculated);
                return newRow;
            })
            .collect(Collectors.toList());
    }
    
    /**
     * 执行表达式计算
     */
    private Object evaluateExpression(String expression, Map<String, Object> context) {
        // 使用安全的表达式解析器（如 expr-eval 或 Aviator）
        // 示例：{price} * {quantity} * (1 - {discount})
        
        // 替换变量
        String processedExpression = expression;
        for (Map.Entry<String, Object> entry : context.entrySet()) {
            String placeholder = "\\{" + entry.getKey() + "\\}";
            Object value = entry.getValue();
            String valueStr = value != null ? value.toString() : "0";
            processedExpression = processedExpression.replaceAll(placeholder, valueStr);
        }
        
        // 使用 Aviator 执行表达式
        return AviatorEvaluator.eval(processedExpression);
    }
}

/**
 * 计算规则
 */
@Data
public class CalculationRule {
    private String targetField;      // 目标字段名
    private String expression;       // 计算表达式，如 {price} * {quantity}
    private List<String> dependencies; // 依赖的字段列表
    private String description;      // 规则描述
}
```

#### 4.12.8 AI 辅助配置子表格

```java
/**
 * AI 辅助配置子表格工具
 */
@Component
public class ConfigureSubTableTool implements ToolCallback {

    @Resource
    private FieldMapper fieldMapper;
    
    @Resource
    private SubTableValidationEngine validationEngine;
    
    @Resource
    private SubTableCalculationEngine calculationEngine;

    @Override
    public String getName() {
        return "configure_sub_table";
    }

    @Override
    public String getDescription() {
        return "AI 辅助配置子表格字段、校验规则和计算规则";
    }

    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String collectionName = args.getStr("collectionName");
        String subFieldName = args.getStr("subFieldName");
        String action = args.getStr("action"); // addFields / setValidation / setCalculation
        
        switch (action) {
            case "addFields":
                return addSubFields(collectionName, subFieldName, args.getJSONArray("fields"));
            case "setValidation":
                return setValidationRules(collectionName, subFieldName, args.getJSONArray("rules"));
            case "setCalculation":
                return setCalculationRules(collectionName, subFieldName, args.getJSONArray("rules"));
            default:
                return JSONUtil.toJsonStr(Map.of("success", false, "message", "不支持的操作类型"));
        }
    }
    
    private String addSubFields(String collectionName, String subFieldName, JSONArray fieldsJson) {
        // 解析字段配置并批量添加
        List<FieldDO> fields = new ArrayList<>();
        for (int i = 0; i < fieldsJson.size(); i++) {
            JSONObject fieldJson = fieldsJson.getJSONObject(i);
            FieldDO field = new FieldDO();
            field.setCollectionName(collectionName);
            field.setParentFieldName(subFieldName);
            field.setName(fieldJson.getStr("name"));
            field.setDisplayName(fieldJson.getStr("displayName"));
            field.setFieldType(fieldJson.getStr("fieldType"));
            field.setIsRequired(fieldJson.getBool("required", false));
            field.setDefaultValue(fieldJson.getStr("defaultValue"));
            fields.add(field);
        }
        
        // 批量插入
        fieldMapper.batchInsert(fields);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true, 
            "message", "成功添加 " + fields.size() + " 个子字段"
        ));
    }
    
    private String setValidationRules(String collectionName, String subFieldName, JSONArray rulesJson) {
        // 更新字段的校验规则配置
        FieldDO parentField = fieldMapper.selectByCollectionAndName(collectionName, subFieldName);
        if (parentField == null) {
            return JSONUtil.toJsonStr(Map.of("success", false, "message", "子表格字段不存在"));
        }
        
        // 将校验规则存储到字段的 uiSchema 中
        JSONObject uiSchema = JSONUtil.parseObj(parentField.getUiSchema());
        uiSchema.set("validationRules", rulesJson);
        parentField.setUiSchema(uiSchema.toString());
        fieldMapper.updateById(parentField);
        
        return JSONUtil.toJsonStr(Map.of("success", true, "message", "校验规则设置成功"));
    }
    
    private String setCalculationRules(String collectionName, String subFieldName, JSONArray rulesJson) {
        // 更新字段的计算规则配置
        FieldDO parentField = fieldMapper.selectByCollectionAndName(collectionName, subFieldName);
        if (parentField == null) {
            return JSONUtil.toJsonStr(Map.of("success", false, "message", "子表格字段不存在"));
        }
        
        // 将计算规则存储到字段的 uiSchema 中
        JSONObject uiSchema = JSONUtil.parseObj(parentField.getUiSchema());
        uiSchema.set("calculationRules", rulesJson);
        parentField.setUiSchema(uiSchema.toString());
        fieldMapper.updateById(parentField);
        
        return JSONUtil.toJsonStr(Map.of("success", true, "message", "计算规则设置成功"));
    }
}
```

**AI 配置示例：**

```
用户：帮我配置订单明细子表格，需要包含商品名称、单价、数量、折扣和总价字段，总价自动计算为 单价*数量*(1-折扣)

AI：好的，我来为您配置订单明细子表格：

1. 添加子字段：
   - 商品名称（字符串，必填）
   - 单价（数字，必填，最小值 0）
   - 数量（整数，必填，最小值 1）
   - 折扣（数字，0-1 之间）
   - 总价（数字，自动计算）

2. 设置计算规则：
   - 总价 = {单价} * {数量} * (1 - {折扣})

3. 设置校验规则：
   - 商品名称：必填
   - 单价：必填，最小值 0
   - 数量：必填，最小值 1
   - 折扣：范围 0-1

配置完成！您可以开始使用子表格录入订单明细了。
```

#### 4.12.5 拖拽排序功能

```typescript
// src/components/nocode/blocks/SubTableInlineEdit.vue (增强版)
<template>
  <div class="sub-table-inline-edit">
    <el-table :data="tableData" border>
      <!-- 拖拽手柄列 -->
      <el-table-column width="50" v-if="enableDragSort">
        <template #default>
          <el-icon class="drag-handle"><Rank /></el-icon>
        </template>
      </el-table-column>
      
      <!-- 选择框列 -->
      <el-table-column width="50" v-if="enableBatchSelect">
        <template #default="{ $index }">
          <el-checkbox 
            v-model="selectedRows" 
            :label="$index"
            @change="handleSelectionChange"
          />
        </template>
      </el-table-column>
      
      <!-- 普通字段：直接编辑 -->
      <el-table-column 
        v-for="field in editableFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 150"
      >
        <template #default="{ row, $index }">
          <div class="cell-wrapper">
            <component 
              :is="getFieldComponent(field)"
              v-model="row[field.name]"
              :placeholder="field.placeholder"
              :disabled="isFieldDisabled(field, row)"
              @change="handleFieldChange(row, field, $index)"
              @blur="validateCell(row, field, $index)"
              class="inline-edit-component"
              :class="{ 'validation-error': cellErrors[$index]?.[field.name] }"
            />
            <div v-if="cellErrors[$index]?.[field.name]" class="cell-error">
              {{ cellErrors[$index][field.name] }}
            </div>
          </div>
        </template>
      </el-table-column>
      
      <!-- 计算字段：只读展示 -->
      <el-table-column 
        v-for="field in calculatedFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 150"
      >
        <template #default="{ row }">
          <span class="calculated-value">{{ calculateFieldValue(row, field) }}</span>
        </template>
      </el-table-column>
      
      <!-- 关联字段：弹窗选择 -->
      <el-table-column 
        v-for="field in relationFields" 
        :key="field.name"
        :label="field.displayName"
        :width="field.width || 200"
      >
        <template #default="{ row }">
          <div class="relation-field-wrapper">
            <span class="relation-value">{{ getRelationDisplayValue(row, field) }}</span>
            <el-button size="small" text @click="openRelationPicker(row, field)">
              <el-icon><Edit /></el-icon>
            </el-button>
          </div>
        </template>
      </el-table-column>
      
      <!-- 操作列 -->
      <el-table-column label="操作" width="120" fixed="right">
        <template #default="{ row, $index }">
          <el-button size="small" type="danger" text @click="removeRow($index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <el-button class="mt-4" @click="addRow">
      <el-icon><Plus /></el-icon> 添加行
    </el-button>
    
    <!-- 拖拽排序初始化 -->
    <div v-if="enableDragSort" ref="sortableContainer" class="sortable-container"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import Sortable from 'sortablejs'

const props = defineProps<{
  fields: any[]
  modelValue: any[]
  selectedRows?: number[]
  validationRules?: Record<string, any[]>
  calculationRules?: any[]
}>()

const emit = defineEmits(['update:modelValue', 'change', 'validation-error', 'update:selectedRows'])

const tableData = ref(props.modelValue || [])
const cellErrors = ref<Record<number, Record<string, string>>>({})
const sortableContainer = ref<HTMLElement | null>(null)
let sortableInstance: Sortable | null = null

// 启用拖拽排序
const enableDragSort = computed(() => props.fields.some(f => f.enableSort))
// 启用批量选择
const enableBatchSelect = computed(() => props.selectedRows !== undefined)

// 可编辑的普通字段
const editableFields = computed(() => {
  return props.fields.filter(f => 
    !f.fieldType.startsWith('belongsTo') &&
    !f.fieldType.startsWith('hasMany') &&
    !f.fieldType.startsWith('belongsToMany') &&
    !['id', 'create_time', 'update_time', 'creator', 'updater'].includes(f.name) &&
    !f.isCalculated
  )
})

// 计算字段
const calculatedFields = computed(() => {
  return props.fields.filter(f => f.isCalculated)
})

// 关联字段
const relationFields = computed(() => {
  return props.fields.filter(f => 
    f.fieldType.startsWith('belongsTo') ||
    f.fieldType.startsWith('belongsToMany')
  )
})

// 初始化拖拽排序
onMounted(() => {
  if (enableDragSort.value && sortableContainer.value) {
    initSortable()
  }
})

// 监听拖拽开关
watch(enableDragSort, (enabled) => {
  if (enabled && sortableContainer.value) {
    initSortable()
  } else if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }
})

const initSortable = () => {
  const tableBody = sortableContainer.value?.closest('.el-table')?.querySelector('.el-table__body-wrapper tbody')
  if (!tableBody) return
  
  sortableInstance = Sortable.create(tableBody as HTMLElement, {
    handle: '.drag-handle',
    animation: 150,
    onEnd: (evt) => {
      const { oldIndex, newIndex } = evt
      if (oldIndex === newIndex) return
      
      // 更新数据顺序
      const item = tableData.value[oldIndex!]
      tableData.value.splice(oldIndex!, 1)
      tableData.value.splice(newIndex!, 0, item)
      
      emit('update:modelValue', tableData.value)
      emit('change', tableData.value)
    }
  })
}

// 获取字段编辑组件
const getFieldComponent = (field: any) => {
  const componentMap: Record<string, string> = {
    string: 'el-input',
    text: 'el-input',
    integer: 'el-input-number',
    decimal: 'el-input-number',
    boolean: 'el-switch',
    datetime: 'el-date-picker',
    select: 'el-select',
  }
  return componentMap[field.fieldType] || 'el-input'
}

// 字段是否禁用
const isFieldDisabled = (field: any, row: any) => {
  // 根据业务逻辑判断
  return false
}

// 字段值变更
const handleFieldChange = (row: any, field: any, index: number) => {
  // 清除该字段的错误
  if (cellErrors.value[index]?.[field.name]) {
    delete cellErrors.value[index][field.name]
  }
  
  // 触发计算字段更新
  updateCalculatedFields(row, index)
  
  emit('update:modelValue', tableData.value)
  emit('change', { row, field, value: row[field.name], index })
}

// 单元格校验
const validateCell = (row: any, field: any, index: number) => {
  if (!props.validationRules?.[field.name]) return
  
  const rules = props.validationRules[field.name]
  const errors: string[] = []
  
  for (const rule of rules) {
    if (rule.required && (row[field.name] === undefined || row[field.name] === null || row[field.name] === '')) {
      errors.push(rule.message || `${field.displayName}不能为空`)
    }
    if (rule.pattern && !rule.pattern.test(row[field.name])) {
      errors.push(rule.message || `${field.displayName}格式不正确`)
    }
    if (rule.min !== undefined && row[field.name] < rule.min) {
      errors.push(rule.message || `${field.displayName}不能小于${rule.min}`)
    }
    if (rule.max !== undefined && row[field.name] > rule.max) {
      errors.push(rule.message || `${field.displayName}不能大于${rule.max}`)
    }
  }
  
  if (errors.length > 0) {
    if (!cellErrors.value[index]) {
      cellErrors.value[index] = {}
    }
    cellErrors.value[index][field.name] = errors.join('; ')
    emit('validation-error', { row, field, index, errors })
  }
}

// 计算字段值
const calculateFieldValue = (row: any, field: any) => {
  const calcRule = props.calculationRules?.find(r => r.targetField === field.name)
  if (!calcRule) return row[field.name]
  
  try {
    // 简单的表达式计算（实际应使用更安全的表达式引擎）
    const expression = calcRule.expression
    // 替换字段名为实际值
    let evalExpr = expression.replace(/\{(\w+)\}/g, (match: string, fieldName: string) => {
      return row[fieldName] ?? 0
    })
    // 注意：实际生产环境应使用安全的表达式解析器（如 expr-eval）
    return eval(evalExpr)
  } catch (e) {
    return row[field.name]
  }
}

// 更新计算字段
const updateCalculatedFields = (row: any, index: number) => {
  calculatedFields.value.forEach(field => {
    row[field.name] = calculateFieldValue(row, field)
  })
}

// 选择变更
const handleSelectionChange = () => {
  emit('update:selectedRows', props.selectedRows)
}

// 获取关联字段显示值
const getRelationDisplayValue = (row: any, field: any) => {
  const relationData = row[field.name]
  if (!relationData) return ''
  
  const displayField = field.uiSchema?.['x-component-props']?.displayField || 'name'
  return relationData[displayField] || relationData.id
}

// 打开关联选择器
const openRelationPicker = (row: any, field: any) => {
  // TODO: 实现关联选择器弹窗
}

// 添加行
const addRow = () => {
  const newRow: any = {}
  // 初始化默认值
  for (const field of props.fields) {
    if (field.defaultValue !== undefined) {
      newRow[field.name] = field.defaultValue
    }
  }
  tableData.value.push(newRow)
  emit('update:modelValue', tableData.value)
}

// 删除行
const removeRow = (index: number) => {
  tableData.value.splice(index, 1)
  emit('update:modelValue', tableData.value)
}
</script>

<style scoped>
.inline-edit-component {
  width: 100%;
}

.cell-wrapper {
  position: relative;
}

.cell-error {
  position: absolute;
  bottom: -18px;
  left: 0;
  font-size: 12px;
  color: #f56c6c;
  white-space: nowrap;
}

.validation-error {
  border-color: #f56c6c !important;
}

.calculated-value {
  color: #909399;
  font-style: italic;
}

.drag-handle {
  cursor: move;
  font-size: 18px;
  color: #909399;
}

.drag-handle:hover {
  color: #409eff;
}

.relation-field-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
}

.relation-value {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
```

#### 4.12.6 数据校验规则引擎

```java
/**
 * 子表格数据校验引擎
 */
@Component
public class SubTableValidationEngine {

    /**
     * 校验子表格数据
     */
    public ValidationResult validate(List<Map<String, Object>> tableData, List<FieldMeta> fields) {
        ValidationResult result = new ValidationResult();
        
        for (int i = 0; i < tableData.size(); i++) {
            Map<String, Object> row = tableData.get(i);
            RowValidationResult rowResult = validateRow(row, fields, i);
            if (!rowResult.isValid()) {
                result.addRowError(i, rowResult);
            }
        }
        
        // 执行跨行校验（如：唯一性约束）
        validateCrossRowConstraints(tableData, fields, result);
        
        return result;
    }
    
    /**
     * 校验单行数据
     */
    private RowValidationResult validateRow(Map<String, Object> row, List<FieldMeta> fields, int rowIndex) {
        RowValidationResult rowResult = new RowValidationResult(rowIndex);
        
        for (FieldMeta field : fields) {
            Object value = row.get(field.getName());
            
            // 必填校验
            if (field.isRequired() && isEmpty(value)) {
                rowResult.addFieldError(field.getName(), field.getDisplayName() + "不能为空");
                continue;
            }
            
            // 类型校验
            if (value != null && !isEmpty(value)) {
                if (!validateType(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "类型不正确");
                    continue;
                }
                
                // 范围校验
                if (!validateRange(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "超出范围");
                    continue;
                }
                
                // 格式校验
                if (!validateFormat(value, field)) {
                    rowResult.addFieldError(field.getName(), field.getDisplayName() + "格式不正确");
                }
            }
        }
        
        return rowResult;
    }
    
    /**
     * 跨行约束校验
     */
    private void validateCrossRowConstraints(List<Map<String, Object>> tableData, List<FieldMeta> fields, ValidationResult result) {
        for (FieldMeta field : fields) {
            if (field.isUniqueInSubTable()) {
                Set<Object> seen = new HashSet<>();
                for (int i = 0; i < tableData.size(); i++) {
                    Object value = tableData.get(i).get(field.getName());
                    if (value != null && !isEmpty(value)) {
                        if (!seen.add(value)) {
                            result.addRowError(i, new RowValidationResult(i)
                                .addFieldError(field.getName(), field.getDisplayName() + "必须唯一"));
                        }
                    }
                }
            }
        }
    }
    
    private boolean isEmpty(Object value) {
        if (value == null) return true;
        if (value instanceof String) return ((String) value).trim().isEmpty();
        return false;
    }
    
    private boolean validateType(Object value, FieldMeta field) {
        switch (field.getFieldType()) {
            case "integer":
                return value instanceof Integer || value instanceof Long;
            case "decimal":
                return value instanceof Number;
            case "boolean":
                return value instanceof Boolean;
            case "datetime":
                return value instanceof Date || value instanceof String;
            default:
                return true;
        }
    }
    
    private boolean validateRange(Object value, FieldMeta field) {
        if (field.getMinValue() != null && value instanceof Number) {
            if (((Number) value).doubleValue() < field.getMinValue().doubleValue()) {
                return false;
            }
        }
        if (field.getMaxValue() != null && value instanceof Number) {
            if (((Number) value).doubleValue() > field.getMaxValue().doubleValue()) {
                return false;
            }
        }
        return true;
    }
    
    private boolean validateFormat(Object value, FieldMeta field) {
        if (field.getPattern() != null && value instanceof String) {
            return Pattern.matches(field.getPattern(), (String) value);
        }
        return true;
    }
}

/**
 * 校验结果
 */
@Data
public class ValidationResult {
    private Map<Integer, RowValidationResult> rowErrors = new LinkedHashMap<>();
    
    public void addRowError(int rowIndex, RowValidationResult rowResult) {
        rowErrors.put(rowIndex, rowResult);
    }
    
    public boolean isValid() {
        return rowErrors.isEmpty();
    }
    
    public List<String> getAllErrors() {
        List<String> errors = new ArrayList<>();
        rowErrors.forEach((rowIndex, rowResult) -> {
            rowResult.getFieldErrors().forEach((field, message) -> {
                errors.add(String.format("第 %d 行：%s", rowIndex + 1, message));
            });
        });
        return errors;
    }
}

@Data
public class RowValidationResult {
    private int rowIndex;
    private Map<String, String> fieldErrors = new LinkedHashMap<>();
    
    public RowValidationResult(int rowIndex) {
        this.rowIndex = rowIndex;
    }
    
    public RowValidationResult addFieldError(String fieldName, String message) {
        fieldErrors.put(fieldName, message);
        return this;
    }
    
    public boolean isValid() {
        return fieldErrors.isEmpty();
    }
}
```

#### 4.12.7 行内计算引擎

```java
/**
 * 子表格行内计算引擎
 */
@Component
public class SubTableCalculationEngine {

    private final ExpressionParser expressionParser;
    
    public SubTableCalculationEngine() {
        this.expressionParser = new ExpressionParser();
    }
    
    /**
     * 计算单行的所有计算字段
     */
    public Map<String, Object> calculateRow(Map<String, Object> rowData, List<CalculationRule> rules) {
        Map<String, Object> calculatedValues = new HashMap<>();
        
        for (CalculationRule rule : rules) {
            try {
                Object result = evaluateExpression(rule.getExpression(), rowData);
                calculatedValues.put(rule.getTargetField(), result);
            } catch (Exception e) {
                log.warn("计算字段失败: field={}, error={}", rule.getTargetField(), e.getMessage());
                calculatedValues.put(rule.getTargetField(), null);
            }
        }
        
        return calculatedValues;
    }
    
    /**
     * 批量计算多行
     */
    public List<Map<String, Object>> calculateRows(List<Map<String, Object>> tableData, List<CalculationRule> rules) {
        return tableData.stream()
            .map(row -> {
                Map<String, Object> calculated = calculateRow(row, rules);
                Map<String, Object> newRow = new HashMap<>(row);
                newRow.putAll(calculated);
                return newRow;
            })
            .collect(Collectors.toList());
    }
    
    /**
     * 执行表达式计算
     */
    private Object evaluateExpression(String expression, Map<String, Object> context) {
        // 使用安全的表达式解析器（如 expr-eval 或 Aviator）
        // 示例：{price} * {quantity} * (1 - {discount})
        
        // 替换变量
        String processedExpression = expression;
        for (Map.Entry<String, Object> entry : context.entrySet()) {
            String placeholder = "\\{" + entry.getKey() + "\\}";
            Object value = entry.getValue();
            String valueStr = value != null ? value.toString() : "0";
            processedExpression = processedExpression.replaceAll(placeholder, valueStr);
        }
        
        // 使用 Aviator 执行表达式
        return AviatorEvaluator.eval(processedExpression);
    }
}

/**
 * 计算规则
 */
@Data
public class CalculationRule {
    private String targetField;      // 目标字段名
    private String expression;       // 计算表达式，如 {price} * {quantity}
    private List<String> dependencies; // 依赖的字段列表
    private String description;      // 规则描述
}
```

#### 4.12.8 AI 辅助配置子表格

```java
/**
 * AI 辅助配置子表格工具
 */
@Component
public class ConfigureSubTableTool implements ToolCallback {

    @Resource
    private FieldMapper fieldMapper;
    
    @Resource
    private SubTableValidationEngine validationEngine;
    
    @Resource
    private SubTableCalculationEngine calculationEngine;

    @Override
    public String getName() {
        return "configure_sub_table";
    }

    @Override
    public String getDescription() {
        return "AI 辅助配置子表格字段、校验规则和计算规则";
    }

    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String collectionName = args.getStr("collectionName");
        String subFieldName = args.getStr("subFieldName");
        String action = args.getStr("action"); // addFields / setValidation / setCalculation
        
        switch (action) {
            case "addFields":
                return addSubFields(collectionName, subFieldName, args.getJSONArray("fields"));
            case "setValidation":
                return setValidationRules(collectionName, subFieldName, args.getJSONArray("rules"));
            case "setCalculation":
                return setCalculationRules(collectionName, subFieldName, args.getJSONArray("rules"));
            default:
                return JSONUtil.toJsonStr(Map.of("success", false, "message", "不支持的操作类型"));
        }
    }
    
    private String addSubFields(String collectionName, String subFieldName, JSONArray fieldsJson) {
        // 解析字段配置并批量添加
        List<FieldDO> fields = new ArrayList<>();
        for (int i = 0; i < fieldsJson.size(); i++) {
            JSONObject fieldJson = fieldsJson.getJSONObject(i);
            FieldDO field = new FieldDO();
            field.setCollectionName(collectionName);
            field.setParentFieldName(subFieldName);
            field.setName(fieldJson.getStr("name"));
            field.setDisplayName(fieldJson.getStr("displayName"));
            field.setFieldType(fieldJson.getStr("fieldType"));
            field.setIsRequired(fieldJson.getBool("required", false));
            field.setDefaultValue(fieldJson.getStr("defaultValue"));
            fields.add(field);
        }
        
        // 批量插入
        fieldMapper.batchInsert(fields);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true, 
            "message", "成功添加 " + fields.size() + " 个子字段"
        ));
    }
    
    private String setValidationRules(String collectionName, String subFieldName, JSONArray rulesJson) {
        // 更新字段的校验规则配置
        FieldDO parentField = fieldMapper.selectByCollectionAndName(collectionName, subFieldName);
        if (parentField == null) {
            return JSONUtil.toJsonStr(Map.of("success", false, "message", "子表格字段不存在"));
        }
        
        // 将校验规则存储到字段的 uiSchema 中
        JSONObject uiSchema = JSONUtil.parseObj(parentField.getUiSchema());
        uiSchema.set("validationRules", rulesJson);
        parentField.setUiSchema(uiSchema.toString());
        fieldMapper.updateById(parentField);
        
        return JSONUtil.toJsonStr(Map.of("success", true, "message", "校验规则设置成功"));
    }
    
    private String setCalculationRules(String collectionName, String subFieldName, JSONArray rulesJson) {
        // 更新字段的计算规则配置
        FieldDO parentField = fieldMapper.selectByCollectionAndName(collectionName, subFieldName);
        if (parentField == null) {
            return JSONUtil.toJsonStr(Map.of("success", false, "message", "子表格字段不存在"));
        }
        
        // 将计算规则存储到字段的 uiSchema 中
        JSONObject uiSchema = JSONUtil.parseObj(parentField.getUiSchema());
        uiSchema.set("calculationRules", rulesJson);
        parentField.setUiSchema(uiSchema.toString());
        fieldMapper.updateById(parentField);
        
        return JSONUtil.toJsonStr(Map.of("success", true, "message", "计算规则设置成功"));
    }
}
```

**AI 配置示例：**

```
用户：帮我配置订单明细子表格，需要包含商品名称、单价、数量、折扣和总价字段，总价自动计算为 单价*数量*(1-折扣)

AI：好的，我来为您配置订单明细子表格：

1. 添加子字段：
   - 商品名称（字符串，必填）
   - 单价（数字，必填，最小值 0）
   - 数量（整数，必填，最小值 1）
   - 折扣（数字，0-1 之间）
   - 总价（数字，自动计算）

2. 设置计算规则：
   - 总价 = {单价} * {数量} * (1 - {折扣})

3. 设置校验规则：
   - 商品名称：必填
   - 单价：必填，最小值 0
   - 数量：必填，最小值 1
   - 折扣：范围 0-1

配置完成！您可以开始使用子表格录入订单明细了。
```

---

## 五、后端架构设计

### 5.1 新增模块规划

```
shengyu-module-no-code/                 # 【新建】无代码核心模块
├── shengyu-module-no-code-api/         # API 定义
│   └── src/main/java/.../nocode/
│       ├── api/                        # 对外接口
│       └── enums/                      # 枚举常量
│
└── shengyu-module-no-code-biz/         # 业务实现
    └── src/main/java/.../nocode/
        ├── collection/                 # 数据集合管理
        │   ├── controller/
        │   │   └── CollectionController.java
        │   ├── service/
        │   │   ├── CollectionService.java
        │   │   └── CollectionServiceImpl.java
        │   ├── dal/
        │   │   ├── dataobject/
        │   │   │   ├── CollectionDO.java
        │   │   │   └── FieldDO.java
        │   │   └── mysql/
        │   │       ├── CollectionMapper.java
        │   │       └── FieldMapper.java
        │   └── cache/
        │       └── CollectionMetaCache.java
        │
        ├── schema/                     # Schema 管理
        │   ├── controller/
        │   │   └── PageSchemaController.java
        │   ├── service/
        │   │   ├── PageSchemaService.java
        │   │   └── PageSchemaServiceImpl.java
        │   ├── dal/
        │   │   ├── dataobject/
        │   │   │   └── PageSchemaDO.java
        │   │   └── mysql/
        │   │       └── PageSchemaMapper.java
        │   └── validator/
        │       └── SchemaValidator.java
        │
        ├── dynamic/                    # 动态 API
        │   ├── controller/
        │   │   └── DynamicDataController.java
        │   ├── service/
        │   │   ├── DynamicDataService.java
        │   │   └── DynamicDataServiceImpl.java
        │   └── sql/
        │       ├── SqlBuilder.java
        │       └── QueryParser.java
        │
        └── sync/                       # 元数据同步
            ├── service/
            │   ├── DdlSyncService.java
            │   └── DdlSyncServiceImpl.java
            └── generator/
                └── DdlGenerator.java
```

```
shengyu-module-ai/                      # 【新建】AI 模块
└── shengyu-module-ai-biz/
    └── src/main/java/.../ai/
        ├── chat/                       # AI 对话
        │   ├── controller/
        │   │   └── AiChatController.java
        │   └── service/
        │       ├── AiChatService.java
        │       └── AiChatServiceImpl.java
        │
        ├── llm/                        # LLM 客户端
        │   ├── LlmClient.java          # 接口
        │   ├── OpenAiCompatibleClient.java  # OpenAI 兼容实现
        │   └── LlmConfig.java
        │
        ├── employee/                   # AI 员工
        │   ├── controller/
        │   │   └── AiEmployeeController.java
        │   ├── service/
        │   │   ├── AiEmployeeService.java
        │   │   └── AiEmployeeServiceImpl.java
        │   └── dal/
        │       ├── dataobject/
        │       │   └── AiEmployeeDO.java
        │       └── mysql/
        │           └── AiEmployeeMapper.java
        │
        ├── tool/                       # AI 工具
        │   ├── ToolManager.java        # 工具管理器
        │   ├── ToolDefinition.java     # 工具定义
        │   ├── ToolExecutor.java       # 工具执行器
        │   └── tools/                  # 内置工具
        │       ├── CreateCollectionTool.java
        │       ├── AddFieldTool.java
        │       ├── CreatePageSchemaTool.java
        │       ├── UpdatePageSchemaTool.java
        │       ├── AddMenuTool.java
        │       ├── QueryDataTool.java
        │       └── CreateWorkflowTool.java
        │
        └── skill/                      # AI 技能
            ├── SkillManager.java
            ├── SkillDefinition.java
            └── skills/                 # 内置技能
                ├── DataModelingSkill.java
                ├── PageBuildingSkill.java
                └── WorkflowSkill.java
```

### 5.2 数据库表设计

#### 5.2.1 数据集合元数据

```sql
-- 数据集合（对标 NocoBase Collection）
CREATE TABLE nocobase_collection (
    id              bigint       NOT NULL AUTO_INCREMENT,
    name            varchar(128) NOT NULL COMMENT '集合名（物理表名）',
    display_name    varchar(256) NOT NULL COMMENT '显示名称',
    description     text         NULL     COMMENT '描述',
    -- 对标 NocoBase Collection options
    typing          varchar(32)  NOT NULL DEFAULT 'business' COMMENT '集合类型：system/business/external',
    genealogy       varchar(32)  NULL     COMMENT '继承关系',
    -- 功能开关
    auto_fill_created_at  tinyint NOT NULL DEFAULT 1 COMMENT '自动填充创建时间',
    auto_fill_created_by  tinyint NOT NULL DEFAULT 1 COMMENT '自动填充创建者',
    auto_fill_updated_at  tinyint NOT NULL DEFAULT 1 COMMENT '自动填充更新时间',
    auto_fill_updated_by  tinyint NOT NULL DEFAULT 1 COMMENT '自动填充更新者',
    auto_fill_deleted_at  tinyint NOT NULL DEFAULT 0 COMMENT '自动填充删除时间（软删除）',
    -- 可插入/可移除
    insertable      tinyint      NOT NULL DEFAULT 1,
    removable       tinyint      NOT NULL DEFAULT 1,
    -- 额外配置
    options         json         NULL     COMMENT '集合扩展配置',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_name_tenant (name, tenant_id)
) COMMENT '数据集合元数据（对标 NocoBase Collection）';

-- 数据字段（对标 NocoBase Field）
CREATE TABLE nocobase_field (
    id              bigint       NOT NULL AUTO_INCREMENT,
    collection_id   bigint       NOT NULL COMMENT '所属集合ID',
    name            varchar(128) NOT NULL COMMENT '字段名（物理列名）',
    display_name    varchar(256) NOT NULL COMMENT '显示名称',
    description     text         NULL     COMMENT '描述',
    -- 对标 NocoBase Field 属性
    field_type      varchar(64)  NOT NULL COMMENT '字段类型：string/number/boolean/datetime/belongsTo/hasMany...',
    db_type         varchar(64)  NULL     COMMENT '数据库类型：varchar/text/bigint/datetime/decimal...',
    -- 字段配置
    is_primary_key  tinyint      NOT NULL DEFAULT 0,
    is_nullable     tinyint      NOT NULL DEFAULT 1,
    is_unique       tinyint      NOT NULL DEFAULT 0,
    default_value   varchar(512) NULL     COMMENT '默认值',
    -- 校验规则
    validators      json         NULL     COMMENT '校验规则（Formily 格式）',
    -- UI 配置（对标 NocoBase uiSchema）
    ui_schema       json         NULL     COMMENT 'UI Schema（Formily 格式，控制组件渲染）',
    -- 关联配置（关联字段专用）
    relation_config json         NULL     COMMENT '关联配置：target collection, foreign key 等',
    -- 排序
    sort            int          NOT NULL DEFAULT 0,
    -- 额外配置
    options         json         NULL     COMMENT '字段扩展配置',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_collection_field (collection_id, name, tenant_id),
    KEY idx_collection_id (collection_id)
) COMMENT '数据字段元数据（对标 NocoBase Field）';
```

#### 5.2.2 页面 Schema 存储

```sql
-- 页面 Schema（对标 NocoBase ui-schema-storage）
CREATE TABLE nocobase_page_schema (
    id              bigint       NOT NULL AUTO_INCREMENT,
    uid             varchar(36)  NOT NULL COMMENT 'Schema 唯一标识（UUID）',
    name            varchar(256) NOT NULL COMMENT 'Schema 名称',
    -- 对标 NocoBase Schema 结构
    schema_type     varchar(32)  NOT NULL COMMENT '类型：page/block/void',
    parent_uid      varchar(36)  NULL     COMMENT '父 Schema UID（树形结构）',
    -- Schema 内容（Formily JSON Schema 格式）
    schema_json     json         NOT NULL COMMENT 'Schema JSON（Formily 格式）',
    -- 关联
    collection_name varchar(128) NULL     COMMENT '绑定的数据集合名',
    -- 排序
    sort            int          NOT NULL DEFAULT 0,
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_uid (uid, tenant_id),
    KEY idx_parent_uid (parent_uid),
    KEY idx_collection_name (collection_name)
) COMMENT '页面 Schema 存储（对标 NocoBase ui-schema-storage）';
```

#### 5.2.3 Schema 版本管理（对标 NocoBase Version Control）

```sql
-- Schema 版本（对标 NocoBase Version Control）
CREATE TABLE nocobase_schema_version (
    id              bigint       NOT NULL AUTO_INCREMENT,
    version_no      varchar(64)  NOT NULL COMMENT '版本号（自动生成，如 v1.0.0）',
    -- 版本类型
    version_type    varchar(32)  NOT NULL DEFAULT 'manual' COMMENT '版本类型：manual（手动）/ai_auto（AI自动）/system（系统）',
    -- 版本描述
    description     varchar(2000) NULL    COMMENT '版本描述（最多2000字符）',
    -- 快照内容（JSON格式，包含完整的Schema状态）
    snapshot_data   json         NOT NULL COMMENT '快照数据：包含所有Collection、Field、PageSchema的完整状态',
    -- 变更摘要
    change_summary  json         NULL     COMMENT '变更摘要：与上一版本的差异（新增/修改/删除的集合、字段、页面）',
    -- 文件信息
    file_size       bigint       NULL     COMMENT '快照文件大小（字节）',
    -- 来源信息
    source_type     varchar(32)  NULL     COMMENT '来源类型：ai_chat/manual/system',
    source_id       varchar(64)  NULL     COMMENT '来源ID（如AI会话ID）',
    -- 状态
    status          tinyint      NOT NULL DEFAULT 1 COMMENT '状态：0-已删除 1-正常 2-恢复中',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_version_no (version_no, tenant_id),
    KEY idx_tenant_create (tenant_id, create_time DESC)
) COMMENT 'Schema 版本管理（对标 NocoBase Version Control）';

-- Schema 版本关联的集合（记录版本包含哪些集合）
CREATE TABLE nocobase_schema_version_collection (
    id              bigint       NOT NULL AUTO_INCREMENT,
    version_id      bigint       NOT NULL COMMENT '版本ID',
    collection_name varchar(128) NOT NULL COMMENT '集合名称',
    -- 该集合在版本中的状态
    action_type     varchar(16)  NOT NULL COMMENT '操作类型：created/modified/deleted/unchanged',
    -- 集合快照（可选，用于精细回滚）
    collection_snapshot json     NULL     COMMENT '集合快照：包含字段定义等完整信息',
    PRIMARY KEY (id),
    KEY idx_version_id (version_id),
    KEY idx_collection_name (collection_name)
) COMMENT '版本关联的集合';

-- Schema 变更日志（细粒度变更记录）
CREATE TABLE nocobase_schema_change_log (
    id              bigint       NOT NULL AUTO_INCREMENT,
    version_id      bigint       NULL     COMMENT '关联版本ID（可选）',
    -- 变更对象
    object_type     varchar(32)  NOT NULL COMMENT '对象类型：collection/field/page_schema',
    object_id       bigint       NULL     COMMENT '对象ID',
    object_name     varchar(256) NOT NULL COMMENT '对象名称',
    -- 变更类型
    change_type     varchar(16)  NOT NULL COMMENT '变更类型：create/update/delete',
    -- 变更内容
    before_data     json         NULL     COMMENT '变更前数据',
    after_data      json         NULL     COMMENT '变更后数据',
    -- 变更描述
    change_desc     varchar(512) NULL     COMMENT '变更描述',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_version_id (version_id),
    KEY idx_object (object_type, object_id),
    KEY idx_tenant_create (tenant_id, create_time DESC)
) COMMENT 'Schema 变更日志';
```

**版本管理核心服务**：

```java
/**
 * Schema 版本管理服务
 * 对标 NocoBase Version Control 插件
 */
@Service
public class SchemaVersionServiceImpl implements SchemaVersionService {
    
    @Autowired
    private SchemaVersionMapper versionMapper;
    
    @Autowired
    private SchemaVersionCollectionMapper versionCollectionMapper;
    
    @Autowired
    private SchemaChangeLogMapper changeLogMapper;
    
    @Autowired
    private CollectionMapper collectionMapper;
    
    @Autowired
    private FieldMapper fieldMapper;
    
    @Autowired
    private PageSchemaMapper pageSchemaMapper;
    
    @Autowired
    private TransactionTemplate transactionTemplate;
    
    /**
     * 创建版本（手动创建）
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public SchemaVersionDO createVersion(CreateVersionReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        String userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 生成版本号
        String versionNo = generateVersionNo(tenantId);
        
        // 2. 构建快照数据
        SnapshotData snapshot = buildSnapshot(tenantId);
        
        // 3. 计算变更摘要（与上一版本对比）
        ChangeSummary summary = calculateChangeSummary(tenantId, snapshot);
        
        // 4. 创建版本记录
        SchemaVersionDO version = new SchemaVersionDO();
        version.setVersionNo(versionNo);
        version.setVersionType("manual");
        version.setDescription(req.getDescription());
        version.setSnapshotData(JSON.toJSONString(snapshot));
        version.setChangeSummary(JSON.toJSONString(summary));
        version.setFileSize(calculateSize(snapshot));
        version.setSourceType("manual");
        version.setStatus(1);
        version.setCreator(userId);
        version.setTenantId(tenantId);
        versionMapper.insert(version);
        
        // 5. 记录版本关联的集合
        saveVersionCollections(version.getId(), snapshot);
        
        // 6. 清理旧版本（根据保留策略）
        cleanOldVersions(tenantId);
        
        return version;
    }
    
    /**
     * AI 自动创建版本
     * 在 AI 完成阶段性成果后自动调用
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public SchemaVersionDO createAiAutoVersion(String sessionId, String description) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 生成版本号
        String versionNo = generateVersionNo(tenantId);
        
        // 2. 构建快照数据
        SnapshotData snapshot = buildSnapshot(tenantId);
        
        // 3. 计算变更摘要
        ChangeSummary summary = calculateChangeSummary(tenantId, snapshot);
        
        // 4. 创建版本记录
        SchemaVersionDO version = new SchemaVersionDO();
        version.setVersionNo(versionNo);
        version.setVersionType("ai_auto");
        version.setDescription(description);
        version.setSnapshotData(JSON.toJSONString(snapshot));
        version.setChangeSummary(JSON.toJSONString(summary));
        version.setFileSize(calculateSize(snapshot));
        version.setSourceType("ai_chat");
        version.setSourceId(sessionId);
        version.setStatus(1);
        version.setCreator("AI");
        version.setTenantId(tenantId);
        versionMapper.insert(version);
        
        // 5. 记录版本关联的集合
        saveVersionCollections(version.getId(), snapshot);
        
        // 6. 清理旧版本
        cleanOldVersions(tenantId);
        
        return version;
    }
    
    /**
     * 恢复到指定版本
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void restoreVersion(Long versionId) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 获取版本信息
        SchemaVersionDO version = versionMapper.selectByIdAndTenant(versionId, tenantId);
        if (version == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "版本不存在");
        }
        
        // 2. 标记版本为恢复中
        version.setStatus(2);
        versionMapper.updateById(version);
        
        try {
            // 3. 解析快照数据
            SnapshotData snapshot = JSON.parseObject(version.getSnapshotData(), SnapshotData.class);
            
            // 4. 在事务中执行恢复
            transactionTemplate.execute(status -> {
                // 4.1 恢复集合和字段
                restoreCollectionsAndFields(tenantId, snapshot);
                
                // 4.2 恢复页面Schema
                restorePageSchemas(tenantId, snapshot);
                
                // 4.3 同步DDL（物理表结构）
                syncDdlAfterRestore(tenantId, snapshot);
                
                return null;
            });
            
            // 5. 恢复成功，更新状态
            version.setStatus(1);
            versionMapper.updateById(version);
            
            // 6. 记录恢复日志
            logRestoreOperation(versionId, "success");
            
        } catch (Exception e) {
            // 7. 恢复失败，标记状态
            version.setStatus(1);
            versionMapper.updateById(version);
            logRestoreOperation(versionId, "failed: " + e.getMessage());
            throw new BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "恢复失败: " + e.getMessage());
        }
    }
    
    /**
     * 构建快照数据
     */
    private SnapshotData buildSnapshot(Long tenantId) {
        SnapshotData snapshot = new SnapshotData();
        
        // 1. 获取所有集合
        List<CollectionDO> collections = collectionMapper.selectByTenantId(tenantId);
        snapshot.setCollections(collections);
        
        // 2. 获取所有字段
        List<FieldDO> fields = fieldMapper.selectByTenantId(tenantId);
        snapshot.setFields(fields);
        
        // 3. 获取所有页面Schema
        List<PageSchemaDO> pageSchemas = pageSchemaMapper.selectByTenantId(tenantId);
        snapshot.setPageSchemas(pageSchemas);
        
        return snapshot;
    }
    
    /**
     * 计算变更摘要
     */
    private ChangeSummary calculateChangeSummary(Long tenantId, SnapshotData currentSnapshot) {
        ChangeSummary summary = new ChangeSummary();
        
        // 获取上一版本
        SchemaVersionDO lastVersion = versionMapper.selectLatestByTenantId(tenantId);
        if (lastVersion == null) {
            // 首次创建版本
            summary.setTotalCollections(currentSnapshot.getCollections().size());
            summary.setTotalFields(currentSnapshot.getFields().size());
            summary.setTotalPageSchemas(currentSnapshot.getPageSchemas().size());
            summary.setNewCollections(currentSnapshot.getCollections().size());
            return summary;
        }
        
        // 解析上一版本快照
        SnapshotData lastSnapshot = JSON.parseObject(lastVersion.getSnapshotData(), SnapshotData.class);
        
        // 对比集合变化
        Set<String> lastCollectionNames = lastSnapshot.getCollections().stream()
            .map(CollectionDO::getName)
            .collect(Collectors.toSet());
        Set<String> currentCollectionNames = currentSnapshot.getCollections().stream()
            .map(CollectionDO::getName)
            .collect(Collectors.toSet());
        
        summary.setNewCollections(currentCollectionNames.stream()
            .filter(name -> !lastCollectionNames.contains(name))
            .collect(Collectors.toList()));
        summary.setDeletedCollections(lastCollectionNames.stream()
            .filter(name -> !currentCollectionNames.contains(name))
            .collect(Collectors.toList()));
        
        // 对比字段变化（类似逻辑）
        // ...
        
        // 对比页面Schema变化（类似逻辑）
        // ...
        
        return summary;
    }
    
    /**
     * 恢复集合和字段
     */
    private void restoreCollectionsAndFields(Long tenantId, SnapshotData snapshot) {
        // 1. 删除当前所有集合和字段（软删除）
        collectionMapper.deleteByTenantId(tenantId);
        fieldMapper.deleteByTenantId(tenantId);
        
        // 2. 恢复快照中的集合和字段
        for (CollectionDO collection : snapshot.getCollections()) {
            collection.setId(null); // 清除ID，让数据库重新生成
            collectionMapper.insert(collection);
        }
        
        for (FieldDO field : snapshot.getFields()) {
            field.setId(null);
            fieldMapper.insert(field);
        }
    }
    
    /**
     * 恢复页面Schema
     */
    private void restorePageSchemas(Long tenantId, SnapshotData snapshot) {
        // 1. 删除当前所有页面Schema（软删除）
        pageSchemaMapper.deleteByTenantId(tenantId);
        
        // 2. 恢复快照中的页面Schema
        for (PageSchemaDO pageSchema : snapshot.getPageSchemas()) {
            pageSchema.setId(null);
            pageSchemaMapper.insert(pageSchema);
        }
    }
    
    /**
     * 恢复后同步DDL
     */
    private void syncDdlAfterRestore(Long tenantId, SnapshotData snapshot) {
        // 获取当前物理表列表
        Set<String> currentTables = ddlSyncService.listTables(tenantId);
        
        // 获取快照中的表列表
        Set<String> snapshotTables = snapshot.getCollections().stream()
            .map(CollectionDO::getName)
            .collect(Collectors.toSet());
        
        // 删除多余的表
        for (String table : currentTables) {
            if (!snapshotTables.contains(table)) {
                ddlSyncService.dropTable(table);
            }
        }
        
        // 创建缺失的表
        for (String table : snapshotTables) {
            if (!currentTables.contains(table)) {
                CollectionDO collection = snapshot.getCollections().stream()
                    .filter(c -> c.getName().equals(table))
                    .findFirst()
                    .orElse(null);
                if (collection != null) {
                    ddlSyncService.createTable(collection);
                }
            }
        }
        
        // 同步字段（对比并调整）
        for (CollectionDO collection : snapshot.getCollections()) {
            ddlSyncService.syncFields(collection);
        }
    }
    
    /**
     * 生成版本号
     */
    private String generateVersionNo(Long tenantId) {
        SchemaVersionDO latest = versionMapper.selectLatestByTenantId(tenantId);
        if (latest == null) {
            return "v1.0.0";
        }
        
        // 解析版本号并递增
        String lastVersionNo = latest.getVersionNo();
        // 简单实现：v1.0.0 -> v1.0.1
        Pattern pattern = Pattern.compile("v(\\d+)\\.(\\d+)\\.(\\d+)");
        Matcher matcher = pattern.matcher(lastVersionNo);
        if (matcher.matches()) {
            int major = Integer.parseInt(matcher.group(1));
            int minor = Integer.parseInt(matcher.group(2));
            int patch = Integer.parseInt(matcher.group(3));
            return String.format("v%d.%d.%d", major, minor, patch + 1);
        }
        
        return "v" + System.currentTimeMillis();
    }
    
    /**
     * 清理旧版本（保留策略）
     */
    private void cleanOldVersions(Long tenantId) {
        int keepCount = 50; // 默认保留50个版本
        
        List<SchemaVersionDO> versions = versionMapper.selectByTenantId(tenantId);
        if (versions.size() > keepCount) {
            // 删除超出数量的旧版本
            List<Long> deleteIds = versions.subList(keepCount, versions.size()).stream()
                .map(SchemaVersionDO::getId)
                .collect(Collectors.toList());
            versionMapper.deleteByIds(deleteIds);
        }
    }
    
    /**
     * 记录恢复操作日志
     */
    private void logRestoreOperation(Long versionId, String result) {
        SchemaChangeLog log = new SchemaChangeLog();
        log.setObjectType("version");
        log.setObjectId(versionId);
        log.setObjectName("restore");
        log.setChangeType("restore");
        log.setChangeDesc("恢复版本: " + result);
        log.setCreator(SecurityFrameworkUtils.getLoginUserId());
        log.setTenantId(SecurityFrameworkUtils.getTenantId());
        changeLogMapper.insert(log);
    }
}

/**
 * 快照数据结构
 */
@Data
public class SnapshotData {
    private List<CollectionDO> collections;
    private List<FieldDO> fields;
    private List<PageSchemaDO> pageSchemas;
}

/**
 * 变更摘要
 */
@Data
public class ChangeSummary {
    private Integer totalCollections;
    private Integer totalFields;
    private Integer totalPageSchemas;
    private List<String> newCollections;
    private List<String> deletedCollections;
    private List<String> modifiedCollections;
    private List<String> newFields;
    private List<String> deletedFields;
    private List<String> newPageSchemas;
    private List<String> deletedPageSchemas;
}
```

**AI 自动保存版本工具**：

```java
/**
 * AI 创建版本工具
 * 让 AI 在完成阶段性成果后自动保存版本
 */
@Component
public class CreateVersionTool implements AiTool {
    
    @Autowired
    private SchemaVersionService schemaVersionService;
    
    @Override
    public String getName() { return "create_version"; }
    
    @Override
    public String getDescription() {
        return "创建当前应用的版本快照。用于保存搭建进度，支持后续回滚。" +
               "建议在完成一组数据表、一个页面或一条工作流后调用。";
    }
    
    @Override
    public JsonSchema getParametersSchema() {
        return JsonSchema.builder()
            .type("object")
            .properties(Map.of(
                "description", JsonSchema.builder()
                    .type("string")
                    .description("版本描述，记录本次变更的内容，如'创建客户管理模块'")
                    .build()
            ))
            .required(List.of("description"))
            .build();
    }
    
    @Override
    public ToolResult execute(Map<String, Object> params, ToolContext context) {
        String description = (String) params.get("description");
        
        try {
            SchemaVersionDO version = schemaVersionService.createAiAutoVersion(
                context.getSessionId(),
                description
            );
            
            return ToolResult.success(
                "已创建版本: " + version.getVersionNo() + 
                "，描述: " + description
            );
        } catch (Exception e) {
            return ToolResult.error("创建版本失败: " + e.getMessage());
        }
    }
}
```

#### 5.2.4 AI 员工

```sql
-- AI 员工（对标 NocoBase AI Employee）
CREATE TABLE nocobase_ai_employee (
    id              bigint       NOT NULL AUTO_INCREMENT,
    name            varchar(128) NOT NULL COMMENT '员工名称',
    avatar          varchar(512) NULL     COMMENT '头像',
    description     text         NULL     COMMENT '描述',
    -- 角色权限
    role_id         bigint       NOT NULL COMMENT '关联角色ID（控制数据权限）',
    -- LLM 配置
    llm_provider    varchar(64)  NOT NULL COMMENT 'LLM 提供商：openai/tongyi/wenxin',
    llm_model       varchar(128) NOT NULL COMMENT '模型名称',
    llm_config      json         NOT NULL COMMENT '模型参数（temperature, max_tokens 等）',
    -- 能力配置
    system_prompt   text         NULL     COMMENT '系统提示词',
    skills          json         NULL     COMMENT '技能列表',
    tools           json         NULL     COMMENT '可用工具列表',
    knowledge_ids   json         NULL     COMMENT '知识库ID列表',
    -- 输出配置
    structured_output json       NULL     COMMENT '结构化输出 Schema',
    -- 状态
    status          tinyint      NOT NULL DEFAULT 1 COMMENT '0-禁用 1-启用',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
) COMMENT 'AI 员工配置（对标 NocoBase AI Employee）';

-- AI 对话记录
CREATE TABLE nocobase_ai_chat_message (
    id              bigint       NOT NULL AUTO_INCREMENT,
    employee_id     bigint       NULL     COMMENT 'AI 员工ID（可为空表示通用对话）',
    session_id      varchar(64)  NOT NULL COMMENT '会话ID',
    role            varchar(16)  NOT NULL COMMENT '角色：user/assistant/system/tool',
    content         text         NOT NULL COMMENT '消息内容',
    tool_calls      json         NULL     COMMENT '工具调用记录',
    tool_results    json         NULL     COMMENT '工具执行结果',
    tokens_used     int          NULL     COMMENT '消耗 token 数',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_session_id (session_id),
    KEY idx_employee_id (employee_id)
) COMMENT 'AI 对话记录';
```

### 5.3 动态 API 设计

```java
/**
 * 动态数据 API - 对标 NocoBase 的 Collection Repository API
 * 
 * 路由规则：
 *   POST /api/dynamic/{collectionName}/list    → 分页查询
 *   POST /api/dynamic/{collectionName}/get     → 单条查询
 *   POST /api/dynamic/{collectionName}/create  → 创建
 *   POST /api/dynamic/{collectionName}/update  → 更新
 *   POST /api/dynamic/{collectionName}/delete  → 删除
 * 
 * 查询参数（对标 NocoBase）：
 *   - filter: 过滤条件，支持 $eq/$ne/$in/$like 等操作符
 *   - fields: 返回字段白名单
 *   - appends: 关联展开字段，如 ["customer", "roles"]
 *   - sort: 排序字段，如 ["-createTime"] 表示倒序
 *   - page/pageSize: 分页参数
 */
@RestController
@RequestMapping("/api/dynamic/{collectionName}")
public class DynamicDataController {

    @Autowired
    private DynamicDataService dynamicDataService;

    @PostMapping("/list")
    public PageResult<Map<String, Object>> list(
            @PathVariable String collectionName,
            @RequestBody DynamicQueryReq req) {
        return dynamicDataService.query(collectionName, req);
    }

    @PostMapping("/get")
    public Map<String, Object> get(
            @PathVariable String collectionName,
            @RequestParam Long id,
            @RequestParam(required = false) List<String> appends) {
        return dynamicDataService.getById(collectionName, id, appends);
    }

    @PostMapping("/create")
    public Long create(
            @PathVariable String collectionName,
            @RequestBody Map<String, Object> data) {
        return dynamicDataService.insert(collectionName, data);
    }

    @PostMapping("/update")
    public void update(
            @PathVariable String collectionName,
            @RequestBody Map<String, Object> data) {
        dynamicDataService.update(collectionName, data);
    }

    @PostMapping("/delete")
    public void delete(
            @PathVariable String collectionName,
            @RequestBody Map<String, Object> data) {
        dynamicDataService.delete(collectionName, data);
    }
}
```

#### 5.3.1 关联字段处理设计（对标 NocoBase Association Fields）

**关联类型定义**（完全对标 NocoBase）：

| 关联类型 | 说明 | 外键存储位置 | 参数 |
|---------|------|-------------|------|
| **belongsTo** | 多对一 | 当前表 | target, foreignKey, sourceKey |
| **hasMany** | 一对多 | 对方表 | target, foreignKey, sourceKey |
| **hasOne** | 一对一 | 对方表 | target, foreignKey, sourceKey |
| **belongsToMany** | 多对多 | 中间表 | target, through, foreignKey, otherKey |

**元数据定义**（nocobase_field 表扩展）：

```java
/**
 * 关联字段元数据
 * 对标 NocoBase 的 Association Field 定义
 */
@Data
public class AssociationFieldMeta {
    /**
     * 关联类型：belongsTo / hasMany / hasOne / belongsToMany
     */
    private String associationType;
    
    /**
     * 目标集合名称
     */
    private String target;
    
    /**
     * 外键字段名（当前表或对方表）
     */
    private String foreignKey;
    
    /**
     * 源键（当前表的主键或唯一键，默认 id）
     */
    private String sourceKey = "id";
    
    /**
     * 中间表名（仅 belongsToMany）
     */
    private String through;
    
    /**
     * 中间表中的外键（仅 belongsToMany）
     */
    private String otherKey;
    
    /**
     * 级联删除配置
     */
    private String onDelete; // SET_NULL / CASCADE / RESTRICT
    
    /**
     * 级联更新配置
     */
    private String onUpdate; // CASCADE / RESTRICT
}
```

**关联字段创建示例**（AI 工具调用）：

```java
/**
 * 创建关联字段工具
 */
@Component
public class AddAssociationFieldTool implements AiTool {
    
    @Override
    public String getName() { return "add_association_field"; }
    
    @Override
    public String getDescription() {
        return "创建关联字段。支持 belongsTo/hasMany/hasOne/belongsToMany 四种关联类型。";
    }
    
    @Override
    public ToolResult execute(Map<String, Object> params, ToolContext ctx) {
        String collectionName = (String) params.get("collectionName");
        String fieldName = (String) params.get("fieldName");
        String associationType = (String) params.get("associationType");
        String target = (String) params.get("target");
        
        // 1. 构建关联元数据
        AssociationFieldMeta meta = new AssociationFieldMeta();
        meta.setAssociationType(associationType);
        meta.setTarget(target);
        
        // 2. 根据关联类型设置不同参数
        switch (associationType) {
            case "belongsTo":
                // 当前表存储外键
                String foreignKey = (String) params.getOrDefault("foreignKey", fieldName + "Id");
                meta.setForeignKey(foreignKey);
                // 创建外键字段
                fieldService.createForeignKeyField(collectionName, foreignKey);
                break;
                
            case "hasMany":
            case "hasOne":
                // 对方表存储外键
                String fk = (String) params.getOrDefault("foreignKey", 
                    collectionName.substring(collectionName.lastIndexOf("_") + 1) + "Id");
                meta.setForeignKey(fk);
                // 在目标表创建外键字段
                fieldService.createForeignKeyField(target, fk);
                break;
                
            case "belongsToMany":
                // 需要中间表
                String through = (String) params.get("through");
                if (through == null) {
                    // 自动生成中间表名
                    through = collectionName + "_" + target + "_rel";
                }
                meta.setThrough(through);
                meta.setForeignKey((String) params.getOrDefault("foreignKey", 
                    collectionName.substring(collectionName.lastIndexOf("_") + 1) + "Id"));
                meta.setOtherKey((String) params.getOrDefault("otherKey",
                    target.substring(target.lastIndexOf("_") + 1) + "Id"));
                // 创建中间表
                ddlSyncService.createThroughTable(through, meta.getForeignKey(), meta.getOtherKey());
                break;
        }
        
        // 3. 保存关联字段元数据
        fieldService.createAssociationField(collectionName, fieldName, meta);
        
        return ToolResult.success("已创建关联字段: " + fieldName + " (" + associationType + ")");
    }
}
```

**动态 SQL 关联查询实现**：

```java
/**
 * 关联查询处理器
 * 对标 NocoBase 的 appends 参数
 */
@Component
public class AssociationQueryHandler {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    /**
     * 展开关联数据
     * @param records 主查询结果
     * @param collectionName 集合名
     * @param appends 需要展开的关联字段列表
     */
    public void expandAssociations(
            List<Map<String, Object>> records,
            String collectionName,
            List<String> appends) {
        
        if (appends == null || appends.isEmpty()) {
            return;
        }
        
        CollectionMeta meta = metaCache.get(collectionName);
        
        for (String appendField : appends) {
            FieldMeta field = meta.getField(appendField);
            if (field == null || !field.isAssociation()) {
                continue;
            }
            
            AssociationFieldMeta assocMeta = field.getAssociationMeta();
            
            switch (assocMeta.getAssociationType()) {
                case "belongsTo":
                case "hasOne":
                    expandSingleRecord(records, field, assocMeta);
                    break;
                case "hasMany":
                    expandMultipleRecords(records, field, assocMeta);
                    break;
                case "belongsToMany":
                    expandMultipleRecords(records, field, assocMeta);
                    break;
            }
        }
    }
    
    /**
     * 展开单条关联记录（belongsTo / hasOne）
     */
    private void expandSingleRecord(
            List<Map<String, Object>> records,
            FieldMeta field,
            AssociationFieldMeta assocMeta) {
        
        String targetTable = assocMeta.getTarget();
        String foreignKey = assocMeta.getForeignKey();
        String sourceKey = assocMeta.getSourceKey();
        
        // 收集所有外键值
        Set<Object> foreignKeyValues = new HashSet<>();
        for (Map<String, Object> record : records) {
            Object fkValue = record.get(foreignKey);
            if (fkValue != null) {
                foreignKeyValues.add(fkValue);
            }
        }
        
        if (foreignKeyValues.isEmpty()) {
            return;
        }
        
        // 批量查询关联记录（避免 N+1 问题）
        String placeholders = foreignKeyValues.stream()
            .map(v -> "?")
            .collect(Collectors.joining(","));
        
        String sql = String.format(
            "SELECT * FROM `%s` WHERE `%s` IN (%s) AND deleted = 0",
            targetTable, sourceKey, placeholders
        );
        
        List<Map<String, Object>> relatedRecords = jdbcTemplate.queryForList(
            sql, foreignKeyValues.toArray()
        );
        
        // 构建映射
        Map<Object, Map<String, Object>> recordMap = relatedRecords.stream()
            .collect(Collectors.toMap(
                r -> r.get(sourceKey),
                r -> r,
                (a, b) -> a
            ));
        
        // 填充到主记录
        String fieldName = field.getName();
        for (Map<String, Object> record : records) {
            Object fkValue = record.get(foreignKey);
            if (fkValue != null) {
                record.put(fieldName, recordMap.get(fkValue));
            }
        }
    }
    
    /**
     * 展开多条关联记录（hasMany / belongsToMany）
     */
    private void expandMultipleRecords(
            List<Map<String, Object>> records,
            FieldMeta field,
            AssociationFieldMeta assocMeta) {
        
        String targetTable = assocMeta.getTarget();
        String foreignKey = assocMeta.getForeignKey();
        String sourceKey = assocMeta.getSourceKey();
        
        // 收集所有主键值
        Set<Object> sourceKeyValues = records.stream()
            .map(r -> r.get(sourceKey))
            .filter(Objects::nonNull)
            .collect(Collectors.toSet());
        
        if (sourceKeyValues.isEmpty()) {
            return;
        }
        
        List<Map<String, Object>> relatedRecords;
        
        if ("belongsToMany".equals(assocMeta.getAssociationType())) {
            // 多对多：通过中间表查询
            relatedRecords = queryBelongsToMany(
                sourceKeyValues, targetTable, 
                assocMeta.getThrough(), foreignKey, assocMeta.getOtherKey()
            );
        } else {
            // 一对多：直接查询
            String placeholders = sourceKeyValues.stream()
                .map(v -> "?")
                .collect(Collectors.joining(","));
            
            String sql = String.format(
                "SELECT * FROM `%s` WHERE `%s` IN (%s) AND deleted = 0",
                targetTable, foreignKey, placeholders
            );
            
            relatedRecords = jdbcTemplate.queryForList(sql, sourceKeyValues.toArray());
        }
        
        // 按外键分组
        Map<Object, List<Map<String, Object>>> groupedRecords = relatedRecords.stream()
            .collect(Collectors.groupingBy(r -> r.get(foreignKey)));
        
        // 填充到主记录
        String fieldName = field.getName();
        for (Map<String, Object> record : records) {
            Object skValue = record.get(sourceKey);
            if (skValue != null) {
                record.put(fieldName, groupedRecords.getOrDefault(skValue, Collections.emptyList()));
            }
        }
    }
    
    /**
     * 多对多关联查询
     */
    private List<Map<String, Object>> queryBelongsToMany(
            Set<Object> sourceKeyValues,
            String targetTable,
            String throughTable,
            String foreignKey,
            String otherKey) {
        
        String placeholders = sourceKeyValues.stream()
            .map(v -> "?")
            .collect(Collectors.joining(","));
        
        // 使用 JOIN 查询
        String sql = String.format(
            "SELECT t.*, th.`%s` as _fk " +
            "FROM `%s` t " +
            "INNER JOIN `%s` th ON t.id = th.`%s` " +
            "WHERE th.`%s` IN (%s) AND t.deleted = 0",
            foreignKey, targetTable, throughTable, otherKey, foreignKey, placeholders
        );
        
        return jdbcTemplate.queryForList(sql, sourceKeyValues.toArray());
    }
}
```

**关联数据的创建与更新**：

```java
/**
 * 关联数据操作处理器
 */
@Component
public class AssociationDataHandler {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private TransactionTemplate transactionTemplate;
    
    /**
     * 创建记录时处理关联数据
     * 支持嵌套创建（如创建订单时同时创建订单项）
     */
    public Long createWithAssociations(
            String collectionName,
            Map<String, Object> data,
            CollectionMeta meta) {
        
        return transactionTemplate.execute(status -> {
            // 1. 分离普通字段和关联字段
            Map<String, Object> normalData = new HashMap<>();
            Map<String, Object> associationData = new HashMap<>();
            
            for (Map.Entry<String, Object> entry : data.entrySet()) {
                String fieldName = entry.getKey();
                FieldMeta field = meta.getField(fieldName);
                
                if (field != null && field.isAssociation()) {
                    associationData.put(fieldName, entry.getValue());
                } else {
                    normalData.put(fieldName, entry.getValue());
                }
            }
            
            // 2. 创建主记录
            Long id = insertRecord(collectionName, normalData, meta);
            
            // 3. 处理关联数据
            for (Map.Entry<String, Object> entry : associationData.entrySet()) {
                String fieldName = entry.getKey();
                Object value = entry.getValue();
                FieldMeta field = meta.getField(fieldName);
                AssociationFieldMeta assocMeta = field.getAssociationMeta();
                
                handleAssociationCreate(id, value, assocMeta, meta);
            }
            
            return id;
        });
    }
    
    /**
     * 处理关联数据创建
     */
    private void handleAssociationCreate(
            Long sourceId,
            Object value,
            AssociationFieldMeta assocMeta,
            CollectionMeta sourceMeta) {
        
        switch (assocMeta.getAssociationType()) {
            case "belongsTo":
                // belongsTo: 创建关联记录，更新外键
                if (value instanceof Map) {
                    Long targetId = insertRecord(
                        assocMeta.getTarget(), 
                        (Map<String, Object>) value,
                        metaCache.get(assocMeta.getTarget())
                    );
                    // 更新主记录的外键
                    jdbcTemplate.update(
                        "UPDATE `" + sourceMeta.getTableName() + 
                        "` SET `" + assocMeta.getForeignKey() + "` = ? WHERE id = ?",
                        targetId, sourceId
                    );
                }
                break;
                
            case "hasMany":
                // hasMany: 批量创建子记录
                if (value instanceof List) {
                    CollectionMeta targetMeta = metaCache.get(assocMeta.getTarget());
                    for (Object item : (List<?>) value) {
                        if (item instanceof Map) {
                            Map<String, Object> itemData = new HashMap<>((Map<String, Object>) item);
                            itemData.put(assocMeta.getForeignKey(), sourceId);
                            insertRecord(assocMeta.getTarget(), itemData, targetMeta);
                        }
                    }
                }
                break;
                
            case "belongsToMany":
                // belongsToMany: 创建中间表记录
                if (value instanceof List) {
                    String throughTable = assocMeta.getThrough();
                    for (Object item : (List<?>) value) {
                        Long targetId;
                        if (item instanceof Map) {
                            // 创建新的关联记录
                            targetId = insertRecord(
                                assocMeta.getTarget(),
                                (Map<String, Object>) item,
                                metaCache.get(assocMeta.getTarget())
                            );
                        } else {
                            // 关联已存在的记录
                            targetId = ((Number) item).longValue();
                        }
                        // 创建中间表记录
                        jdbcTemplate.update(
                            "INSERT INTO `" + throughTable + "` (`" + 
                            assocMeta.getForeignKey() + "`, `" + assocMeta.getOtherKey() + 
                            "`) VALUES (?, ?)",
                            sourceId, targetId
                        );
                    }
                }
                break;
        }
    }
}
```

```java
/**
 * 动态数据服务实现
 * 核心：根据 Collection 元数据动态构建 SQL
 */
@Service
public class DynamicDataServiceImpl implements DynamicDataService {

    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private CollectionMetaCache metaCache;

    @Override
    public PageResult<Map<String, Object>> query(String collectionName, DynamicQueryReq req) {
        // 1. 获取 Collection 元数据（带缓存）
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 2. 构建 SQL
        SqlBuilder sqlBuilder = new SqlBuilder(meta);
        sqlBuilder.select(req.getFields())
                  .where(req.getFilters())
                  .orderBy(req.getSort())
                  .limit(req.getPageSize())
                  .offset(req.getPageNo());
        
        // 3. 权限过滤（数据权限）
        applyDataPermission(sqlBuilder, meta);
        
        // 4. 执行查询
        String sql = sqlBuilder.build();
        List<Map<String, Object>> records = jdbcTemplate.queryForList(sql, sqlBuilder.getParams());
        
        // 5. 查询总数
        long total = sqlBuilder.count();
        
        return new PageResult<>(records, total);
    }
}
```

### 5.4 后端核心实现详细设计

#### 5.4.1 SqlBuilder — 安全增强的 SQL 构建器

```java
/**
 * 安全的 SQL 构建器
 * 核心原则：
 * 1. 所有值参数使用 ? 占位符，防止 SQL 注入
 * 2. 所有结构标识符（表名、字段名）使用白名单校验
 * 3. 排序方向只允许 ASC/DESC 枚举
 */
public class SqlBuilder {
    private final CollectionMeta meta;
    private final StringBuilder sql = new StringBuilder();
    private final List<Object> params = new ArrayList<>();
    private String selectClause;
    private String whereClause;
    private String orderByClause;
    private Integer limit;
    private Integer offset;
    
    public SqlBuilder(CollectionMeta meta) {
        this.meta = meta;
    }
    
    /**
     * SELECT 子句
     * @param fields 字段列表，为空则 SELECT *
     */
    public SqlBuilder select(List<String> fields) {
        if (fields == null || fields.isEmpty()) {
            selectClause = "*";
        } else {
            // 白名单校验：只允许 Collection 中定义的字段
            List<String> validFields = fields.stream()
                .filter(this::isValidField)
                .collect(Collectors.toList());
            
            if (validFields.isEmpty()) {
                selectClause = "*";
            } else {
                selectClause = validFields.stream()
                    .map(this::quoteIdentifier)
                    .collect(Collectors.joining(", "));
            }
        }
        return this;
    }
    
    /**
     * WHERE 子句
     * @param filters 过滤条件 Map<fieldName, value>
     */
    public SqlBuilder where(Map<String, Object> filters) {
        if (filters == null || filters.isEmpty()) {
            whereClause = "";
            return this;
        }
        
        List<String> conditions = new ArrayList<>();
        for (Map.Entry<String, Object> entry : filters.entrySet()) {
            String fieldName = entry.getKey();
            Object value = entry.getValue();
            
            // 白名单校验字段名
            if (!isValidField(fieldName)) {
                continue; // 跳过无效字段
            }
            
            // 支持多种操作符
            if (value instanceof Map) {
                Map<String, Object> opMap = (Map<String, Object>) value;
                for (Map.Entry<String, Object> op : opMap.entrySet()) {
                    String operator = op.getKey();
                    Object opValue = op.getValue();
                    conditions.add(buildCondition(fieldName, operator, opValue));
                }
            } else {
                // 默认等值查询
                conditions.add(quoteIdentifier(fieldName) + " = ?");
                params.add(value);
            }
        }
        
        whereClause = conditions.isEmpty() ? "" : " WHERE " + String.join(" AND ", conditions);
        return this;
    }
    
    /**
     * ORDER BY 子句
     * @param sort Map<fieldName, direction> direction: "asc" | "desc"
     */
    public SqlBuilder orderBy(Map<String, String> sort) {
        if (sort == null || sort.isEmpty()) {
            orderByClause = "";
            return this;
        }
        
        List<String> orderClauses = new ArrayList<>();
        for (Map.Entry<String, String> entry : sort.entrySet()) {
            String fieldName = entry.getKey();
            String direction = entry.getValue().toUpperCase();
            
            // 白名单校验字段名
            if (!isValidField(fieldName)) {
                continue;
            }
            
            // 只允许 ASC/DESC
            if (!"ASC".equals(direction) && !"DESC".equals(direction)) {
                direction = "ASC";
            }
            
            orderClauses.add(quoteIdentifier(fieldName) + " " + direction);
        }
        
        orderByClause = orderClauses.isEmpty() ? "" : " ORDER BY " + String.join(", ", orderClauses);
        return this;
    }
    
    /**
     * 分页
     */
    public SqlBuilder page(int pageNo, int pageSize) {
        if (pageNo < 1) pageNo = 1;
        if (pageSize < 1 || pageSize > 1000) pageSize = 20; // 限制最大 1000
        
        this.limit = pageSize;
        this.offset = (pageNo - 1) * pageSize;
        return this;
    }
    
    /**
     * 构建最终 SQL
     */
    public String build() {
        sql.setLength(0); // 清空
        sql.append("SELECT ").append(selectClause)
           .append(" FROM ").append(quoteIdentifier(meta.getTableName()))
           .append(whereClause)
           .append(orderByClause);
        
        if (limit != null && offset != null) {
            sql.append(" LIMIT ? OFFSET ?");
            params.add(limit);
            params.add(offset);
        }
        
        return sql.toString();
    }
    
    /**
     * 构建 COUNT SQL
     */
    public String buildCount() {
        return "SELECT COUNT(*) FROM " + quoteIdentifier(meta.getTableName()) + whereClause;
    }
    
    /**
     * 获取参数数组
     */
    public Object[] getParams() {
        return params.toArray();
    }
    
    // ========== 私有方法 ==========
    
    /**
     * 白名单校验：字段是否合法
     */
    private boolean isValidField(String fieldName) {
        return meta.getFieldNames().contains(fieldName);
    }
    
    /**
     * 引用标识符（防止 SQL 注入）
     * MySQL 使用反引号 `fieldName`
     */
    private String quoteIdentifier(String identifier) {
        // 移除可能的危险字符
        String safe = identifier.replaceAll("[^a-zA-Z0-9_]", "");
        return "`" + safe + "`";
    }
    
    /**
     * 构建条件表达式
     */
    private String buildCondition(String fieldName, String operator, Object value) {
        String quotedField = quoteIdentifier(fieldName);
        
        switch (operator.toLowerCase()) {
            case "eq":
                params.add(value);
                return quotedField + " = ?";
            case "ne":
                params.add(value);
                return quotedField + " != ?";
            case "gt":
                params.add(value);
                return quotedField + " > ?";
            case "gte":
                params.add(value);
                return quotedField + " >= ?";
            case "lt":
                params.add(value);
                return quotedField + " < ?";
            case "lte":
                params.add(value);
                return quotedField + " <= ?";
            case "like":
                params.add("%" + value + "%");
                return quotedField + " LIKE ?";
            case "in":
                if (value instanceof List) {
                    List<?> list = (List<?>) value;
                    String placeholders = list.stream()
                        .map(v -> "?")
                        .collect(Collectors.joining(", "));
                    params.addAll(list);
                    return quotedField + " IN (" + placeholders + ")";
                }
                return "1=0"; // 无效条件
            default:
                return "1=0"; // 不支持的操作符
        }
    }
}
```

#### 5.4.2 CollectionMetaCache — 元数据缓存

```java
/**
 * Collection 元数据缓存
 * 缓存策略：本地缓存 + Redis 缓存（多实例部署时）
 */
@Component
public class CollectionMetaCache {
    
    @Autowired
    private CollectionMapper collectionMapper;
    
    @Autowired
    private FieldMapper fieldMapper;
    
    // 本地缓存：Caffeine
    private final Cache<String, CollectionMeta> localCache = Caffeine.newBuilder()
        .maximumSize(1000)
        .expireAfterWrite(Duration.ofMinutes(10))
        .build();
    
    /**
     * 获取 Collection 元数据
     */
    public CollectionMeta get(String collectionName) {
        // 1. 从本地缓存获取
        CollectionMeta meta = localCache.getIfPresent(collectionName);
        if (meta != null) {
            return meta;
        }
        
        // 2. 从数据库加载
        meta = loadFromDatabase(collectionName);
        if (meta != null) {
            localCache.put(collectionName, meta);
        }
        
        return meta;
    }
    
    /**
     * 刷新缓存
     */
    public void refresh(String collectionName) {
        localCache.invalidate(collectionName);
        get(collectionName); // 重新加载
    }
    
    /**
     * 从数据库加载元数据
     */
    private CollectionMeta loadFromDatabase(String collectionName) {
        // 1. 加载 Collection
        CollectionDO collection = collectionMapper.selectByName(collectionName);
        if (collection == null) {
            return null;
        }
        
        // 2. 加载 Fields
        List<FieldDO> fields = fieldMapper.selectByCollectionId(collection.getId());
        
        // 3. 构建 CollectionMeta
        CollectionMeta meta = new CollectionMeta();
        meta.setName(collection.getName());
        meta.setTableName(collection.getName()); // 表名 = 集合名
        meta.setFields(fields.stream()
            .map(this::convertToFieldMeta)
            .collect(Collectors.toList()));
        
        return meta;
    }
    
    private FieldMeta convertToFieldMeta(FieldDO field) {
        FieldMeta meta = new FieldMeta();
        meta.setName(field.getName());
        meta.setFieldType(field.getFieldType());
        meta.setDbType(field.getDbType());
        meta.setNullable(field.getIsNullable() == 1);
        meta.setUnique(field.getIsUnique() == 1);
        meta.setDefaultValue(field.getDefaultValue());
        return meta;
    }
}

/**
 * Collection 元数据
 */
@Data
public class CollectionMeta {
    private String name;
    private String tableName;
    private List<FieldMeta> fields;
    
    /**
     * 获取所有字段名（用于白名单校验）
     */
    public Set<String> getFieldNames() {
        return fields.stream()
            .map(FieldMeta::getName)
            .collect(Collectors.toSet());
    }
}

@Data
public class FieldMeta {
    private String name;
    private String fieldType;
    private String dbType;
    private boolean nullable;
    private boolean unique;
    private String defaultValue;
}
```

#### 5.4.3 DdlSyncService — DDL 同步服务

```java
/**
 * DDL 同步服务
 * 将 Collection 元数据同步到物理数据库表
 */
@Service
public class DdlSyncServiceImpl implements DdlSyncService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    /**
     * 同步 Collection 到物理表
     * 如果表不存在则创建，如果已存在则对比差异并更新
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void syncCollection(String collectionName) {
        CollectionMeta meta = metaCache.get(collectionName);
        if (meta == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found: " + collectionName);
        }
        
        // 1. 检查表是否存在
        boolean tableExists = checkTableExists(collectionName);
        
        if (!tableExists) {
            // 2. 创建新表
            createTable(meta);
        } else {
            // 3. 对比差异并更新
            syncTableStructure(meta);
        }
        
        // 4. 刷新缓存
        metaCache.refresh(collectionName);
    }
    
    /**
     * 检查表是否存在
     */
    private boolean checkTableExists(String tableName) {
        String sql = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?";
        Integer count = jdbcTemplate.queryForObject(sql, Integer.class, tableName);
        return count != null && count > 0;
    }
    
    /**
     * 创建新表
     */
    private void createTable(CollectionMeta meta) {
        StringBuilder ddl = new StringBuilder();
        ddl.append("CREATE TABLE `").append(meta.getTableName()).append("` (\n");
        
        // 1. 主键
        ddl.append("  `id` BIGINT NOT NULL AUTO_INCREMENT,\n");
        
        // 2. 业务字段
        for (FieldMeta field : meta.getFields()) {
            ddl.append("  `").append(field.getName()).append("` ")
               .append(field.getDbType());
            
            if (!field.isNullable()) {
                ddl.append(" NOT NULL");
            }
            
            if (field.getDefaultValue() != null) {
                ddl.append(" DEFAULT ").append(field.getDefaultValue());
            }
            
            if (field.isUnique()) {
                ddl.append(" UNIQUE");
            }
            
            ddl.append(" COMMENT '").append(field.getName()).append("',\n");
        }
        
        // 3. 系统字段
        ddl.append("  `creator` VARCHAR(64) NULL COMMENT '创建者',\n");
        ddl.append("  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',\n");
        ddl.append("  `updater` VARCHAR(64) NULL COMMENT '更新者',\n");
        ddl.append("  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',\n");
        ddl.append("  `deleted` BIT(1) NOT NULL DEFAULT 0 COMMENT '删除标记',\n");
        ddl.append("  `tenant_id` BIGINT NOT NULL DEFAULT 0 COMMENT '租户ID',\n");
        
        // 4. 主键和索引
        ddl.append("  PRIMARY KEY (`id`),\n");
        ddl.append("  KEY `idx_tenant_id` (`tenant_id`)\n");
        
        ddl.append(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='").append(meta.getName()).append("'");
        
        // 执行 DDL
        jdbcTemplate.execute(ddl.toString());
    }
    
    /**
     * 同步表结构（对比差异并更新）
     */
    private void syncTableStructure(CollectionMeta meta) {
        // 1. 获取当前表结构
        List<String> existingColumns = getExistingColumns(meta.getTableName());
        
        // 2. 对比差异
        for (FieldMeta field : meta.getFields()) {
            if (!existingColumns.contains(field.getName())) {
                // 新增字段
                addColumn(meta.getTableName(), field);
            }
            // TODO: 对比字段类型、是否可空等，必要时 ALTER COLUMN
        }
    }
    
    /**
     * 获取已存在的列
     */
    private List<String> getExistingColumns(String tableName) {
        String sql = "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?";
        return jdbcTemplate.queryForList(sql, String.class, tableName);
    }
    
    /**
     * 新增列
     */
    private void addColumn(String tableName, FieldMeta field) {
        StringBuilder ddl = new StringBuilder();
        ddl.append("ALTER TABLE `").append(tableName).append("` ADD COLUMN `")
           .append(field.getName()).append("` ")
           .append(field.getDbType());
        
        if (!field.isNullable()) {
            ddl.append(" NOT NULL");
        }
        
        if (field.getDefaultValue() != null) {
            ddl.append(" DEFAULT ").append(field.getDefaultValue());
        }
        
        jdbcTemplate.execute(ddl.toString());
    }
}
```

#### 5.4.4 权限控制实现

```java
/**
 * 动态 API 权限控制
 * 对标 NocoBase 的 ACL 机制
 */
@Component
public class DynamicApiPermissionChecker {
    
    @Autowired
    private CollectionPermissionMapper permissionMapper;
    
    @Autowired
    private SecurityFrameworkUtils securityUtils;
    
    /**
     * 检查权限
     * @param collectionName Collection 名称
     * @param action 操作类型：view/create/update/delete
     */
    public void checkPermission(String collectionName, String action) {
        Long userId = securityUtils.getLoginUserId();
        Long tenantId = securityUtils.getTenantId();
        
        // 1. 获取用户角色
        List<Long> roleIds = getUserRoleIds(userId);
        
        // 2. 查询 Collection 权限
        List<CollectionPermissionDO> permissions = permissionMapper.selectByRoleIdsAndCollection(
            roleIds, collectionName, tenantId
        );
        
        // 3. 检查是否有对应操作权限
        boolean hasPermission = permissions.stream()
            .anyMatch(p -> checkActionPermission(p, action));
        
        if (!hasPermission) {
            throw new AccessDeniedException("无权限执行此操作");
        }
    }
    
    /**
     * 获取数据范围过滤条件
     * 对标 NocoBase 的 Data Scope
     */
    public Map<String, Object> getDataScopeFilter(String collectionName, String action) {
        Long userId = securityUtils.getLoginUserId();
        Long deptId = securityUtils.getDeptId();
        
        // 1. 获取用户角色
        List<Long> roleIds = getUserRoleIds(userId);
        
        // 2. 查询数据范围配置
        List<CollectionPermissionDO> permissions = permissionMapper.selectByRoleIdsAndCollection(
            roleIds, collectionName, securityUtils.getTenantId()
        );
        
        // 3. 合并数据范围（取最宽松的）
        Map<String, Object> filter = new HashMap<>();
        for (CollectionPermissionDO perm : permissions) {
            if (perm.getDataScope() != null) {
                Map<String, Object> scopeFilter = parseDataScope(perm.getDataScope(), userId, deptId);
                // 合并过滤条件（OR 逻辑）
                filter.putAll(scopeFilter);
            }
        }
        
        return filter;
    }
    
    /**
     * 解析数据范围表达式
     * 支持：
     * - "creator = #{userId}" → 只看自己创建的
     * - "dept_id = #{deptId}" → 只看本部门的
     * - "all" → 所有数据
     */
    private Map<String, Object> parseDataScope(String dataScope, Long userId, Long deptId) {
        Map<String, Object> filter = new HashMap<>();
        
        if ("all".equals(dataScope)) {
            return filter; // 不过滤
        }
        
        // 替换变量
        String parsed = dataScope
            .replace("#{userId}", userId.toString())
            .replace("#{deptId}", deptId.toString());
        
        // 解析表达式（简单实现，实际可用表达式引擎）
        // 示例："creator = 123" → Map<"creator", 123>
        String[] parts = parsed.split("=");
        if (parts.length == 2) {
            String fieldName = parts[0].trim();
            Object value = parseValue(parts[1].trim());
            filter.put(fieldName, value);
        }
        
        return filter;
    }
    
    private Object parseValue(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            return value;
        }
    }
    
    private boolean checkActionPermission(CollectionPermissionDO perm, String action) {
        switch (action) {
            case "view": return perm.getCanView() == 1;
            case "create": return perm.getCanCreate() == 1;
            case "update": return perm.getCanUpdate() == 1;
            case "delete": return perm.getCanDelete() == 1;
            default: return false;
        }
    }
    
    private List<Long> getUserRoleIds(Long userId) {
        // 从缓存或数据库获取用户角色
        return securityUtils.getUserRoleIds(userId);
    }
}
```

#### 5.4.5 DynamicDataServiceImpl — 完整实现

```java
/**
 * 动态数据服务完整实现
 */
@Service
public class DynamicDataServiceImpl implements DynamicDataService {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @Autowired
    private NamedParameterJdbcTemplate namedParameterJdbcTemplate;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    @Autowired
    private DynamicApiPermissionChecker permissionChecker;
    
    @Override
    public PageResult<Map<String, Object>> query(String collectionName, DynamicQueryReq req) {
        // 1. 权限检查
        permissionChecker.checkPermission(collectionName, "view");
        
        // 2. 获取元数据
        CollectionMeta meta = metaCache.get(collectionName);
        if (meta == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found");
        }
        
        // 3. 构建 SQL
        SqlBuilder sqlBuilder = new SqlBuilder(meta);
        
        // 合并用户过滤条件和数据范围过滤
        Map<String, Object> allFilters = new HashMap<>();
        allFilters.putAll(permissionChecker.getDataScopeFilter(collectionName, "view"));
        if (req.getFilters() != null) {
            allFilters.putAll(req.getFilters());
        }
        
        sqlBuilder.select(req.getFields())
                  .where(allFilters)
                  .orderBy(req.getSort())
                  .page(req.getPageNo(), req.getPageSize());
        
        // 4. 执行查询
        String sql = sqlBuilder.build();
        List<Map<String, Object>> records = jdbcTemplate.queryForList(sql, sqlBuilder.getParams());
        
        // 5. 查询总数
        String countSql = sqlBuilder.buildCount();
        Long total = jdbcTemplate.queryForObject(countSql, Long.class, sqlBuilder.getParams());
        
        return new PageResult<>(records, total != null ? total : 0);
    }
    
    @Override
    public Map<String, Object> getById(String collectionName, Long id) {
        // 1. 权限检查
        permissionChecker.checkPermission(collectionName, "view");
        
        // 2. 获取元数据
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 3. 构建 SQL
        String sql = "SELECT * FROM `" + meta.getTableName() + "` WHERE id = ? AND deleted = 0";
        
        // 4. 执行查询
        List<Map<String, Object>> results = jdbcTemplate.queryForList(sql, id);
        if (results.isEmpty()) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Record not found");
        }
        
        return results.get(0);
    }
    
    @Override
    public Long insert(String collectionName, Map<String, Object> data) {
        // 1. 权限检查
        permissionChecker.checkPermission(collectionName, "create");
        
        // 2. 获取元数据
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 3. 白名单校验字段
        Map<String, Object> validData = new HashMap<>();
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            if (meta.getFieldNames().contains(entry.getKey())) {
                validData.put(entry.getKey(), entry.getValue());
            }
        }
        
        // 4. 添加系统字段
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        validData.put("creator", userId);
        validData.put("updater", userId);
        validData.put("tenant_id", tenantId);
        
        // 5. 构建 INSERT SQL
        StringBuilder sql = new StringBuilder();
        sql.append("INSERT INTO `").append(meta.getTableName()).append("` (");
        
        List<String> columns = new ArrayList<>(validData.keySet());
        sql.append(columns.stream()
            .map(c -> "`" + c + "`")
            .collect(Collectors.joining(", ")));
        
        sql.append(") VALUES (");
        sql.append(columns.stream()
            .map(c -> "?")
            .collect(Collectors.joining(", ")));
        sql.append(")");
        
        // 6. 执行插入
        KeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(connection -> {
            PreparedStatement ps = connection.prepareStatement(sql.toString(), Statement.RETURN_GENERATED_KEYS);
            int i = 1;
            for (String col : columns) {
                ps.setObject(i++, validData.get(col));
            }
            return ps;
        }, keyHolder);
        
        return keyHolder.getKey().longValue();
    }
    
    @Override
    public void update(String collectionName, Map<String, Object> data) {
        // 1. 权限检查
        permissionChecker.checkPermission(collectionName, "update");
        
        // 2. 获取元数据
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 3. 获取 ID
        Object idObj = data.get("id");
        if (idObj == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "id is required");
        }
        Long id = Long.parseLong(idObj.toString());
        
        // 4. 白名单校验字段
        Map<String, Object> validData = new HashMap<>();
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            String key = entry.getKey();
            if (!"id".equals(key) && meta.getFieldNames().contains(key)) {
                validData.put(key, entry.getValue());
            }
        }
        
        if (validData.isEmpty()) {
            return; // 没有需要更新的字段
        }
        
        // 5. 添加系统字段
        validData.put("updater", SecurityFrameworkUtils.getLoginUserId());
        
        // 6. 构建 UPDATE SQL
        StringBuilder sql = new StringBuilder();
        sql.append("UPDATE `").append(meta.getTableName()).append("` SET ");
        
        List<String> setClauses = validData.keySet().stream()
            .map(col -> "`" + col + "` = ?")
            .collect(Collectors.toList());
        sql.append(String.join(", ", setClauses));
        
        sql.append(" WHERE id = ? AND deleted = 0");
        
        // 7. 执行更新
        List<Object> params = new ArrayList<>(validData.values());
        params.add(id);
        jdbcTemplate.update(sql.toString(), params.toArray());
    }
    
    @Override
    public void delete(String collectionName, Map<String, Object> data) {
        // 1. 权限检查
        permissionChecker.checkPermission(collectionName, "delete");
        
        // 2. 获取元数据
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 3. 获取 IDs
        Object idsObj = data.get("ids");
        if (!(idsObj instanceof List)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "ids is required");
        }
        List<?> ids = (List<?>) idsObj;
        
        if (ids.isEmpty()) {
            return;
        }
        
        // 4. 软删除（更新 deleted 字段）
        String placeholders = ids.stream()
            .map(id -> "?")
            .collect(Collectors.joining(", "));
        
        String sql = "UPDATE `" + meta.getTableName() + "` SET deleted = 1, updater = ? WHERE id IN (" + placeholders + ") AND deleted = 0";
        
        List<Object> params = new ArrayList<>();
        params.add(SecurityFrameworkUtils.getLoginUserId());
        params.addAll(ids);
        
        jdbcTemplate.update(sql, params.toArray());
    }
}
```

### 5.5 AI 工具设计（Function Calling）

```java
/**
 * AI 工具定义 - 每个工具对应一个系统操作
 * 对标 NocoBase 的 Tools Manager
 */

// 工具定义接口
public interface AiTool {
    String getName();
    String getDescription();
    JsonSchema getParametersSchema();
    ToolResult execute(Map<String, Object> parameters, ToolContext context);
}

// 创建数据集合工具
@Component
public class CreateCollectionTool implements AiTool {
    
    @Override
    public String getName() { return "create_collection"; }
    
    @Override
    public String getDescription() {
        return "创建一个新的数据集合（数据库表）。需要提供集合名、显示名称和字段列表。";
    }
    
    @Override
    public ToolResult execute(Map<String, Object> params, ToolContext ctx) {
        String name = (String) params.get("name");
        String displayName = (String) params.get("displayName");
        List<Map<String, Object>> fields = (List) params.get("fields");
        
        // 1. 创建 Collection 元数据
        CollectionDO collection = collectionService.create(name, displayName, ctx.getTenantId());
        
        // 2. 创建 Field 元数据
        for (Map<String, Object> fieldDef : fields) {
            fieldService.create(collection.getId(), fieldDef);
        }
        
        // 3. 同步物理表（DDL）
        ddlSyncService.syncCollection(collection);
        
        return ToolResult.success("已创建数据集合: " + name);
    }
}

// 创建页面 Schema 工具
@Component
public class CreatePageSchemaTool implements AiTool {
    
    @Override
    public String getName() { return "create_page_schema"; }
    
    @Override
    public String getDescription() {
        return "创建一个页面 Schema。Schema 使用 Formily JSON Schema 格式。";
    }
    
    @Override
    public ToolResult execute(Map<String, Object> params, ToolContext ctx) {
        String name = (String) params.get("name");
        String collectionName = (String) params.get("collectionName");
        String pageType = (String) params.get("pageType"); // table/form/detail
        Map<String, Object> schemaJson = (Map) params.get("schema");
        
        // 1. 验证 Schema 格式
        schemaValidator.validate(schemaJson);
        
        // 2. 保存 Schema
        PageSchemaDO schema = pageSchemaService.create(name, collectionName, pageType, schemaJson);
        
        // 3. 自动创建菜单
        menuService.createDynamicMenu(schema);
        
        return ToolResult.success("已创建页面: " + name + "，菜单已添加");
    }
}
```

### 5.6 AI Skills 设计

```java
/**
 * AI 技能 - 告诉 AI 如何正确使用系统的知识包
 * 对标 NocoBase 的 Skills Manager
 */

// 技能定义
public class SkillDefinition {
    private String name;
    private String description;
    private String content;  // Prompt 内容
    private List<String> relatedTools;  // 关联的工具
}

// 数据建模技能 - 嵌入到 System Prompt 中
// skills/data-modeling.md
```

### 5.8 数据建模规范（AI Skill 知识包）

数据建模规范作为 AI Skill 的知识包，嵌入到 System Prompt 中，指导 AI 正确创建数据集合和字段。

#### 5.8.1 命名规范

- **集合名（表名）**：小写下划线，前缀为模块名，如 `crm_customer`、`crm_contact`
- **字段名（列名）**：小写下划线，如 `customer_name`、`phone_number`

#### 5.8.2 必须包含的基础字段

系统会自动添加以下字段，AI 不需要手动定义：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | bigint | 主键，自增 |
| creator | varchar(64) | 创建人 |
| create_time | datetime | 创建时间 |
| updater | varchar(64) | 更新人 |
| update_time | datetime | 更新时间 |
| deleted | bit | 软删除标记 |
| tenant_id | bigint | 租户 ID |

#### 5.8.3 字段类型映射

| 业务类型 | field_type | db_type | UI 组件 |
|---------|-----------|---------|--------|
| 短文本 | string | varchar(255) | Input |
| 长文本 | text | text | Input.TextArea |
| 整数 | integer | bigint | InputNumber |
| 小数 | decimal | decimal(24,6) | InputNumber |
| 日期 | datetime | datetime | DatePicker |
| 布尔 | boolean | tinyint | Switch |
| 枚举 | enum | tinyint | Select |
| 关联(多对一) | belongsTo | bigint | AssociationField |
| 关联(一对多) | hasMany | - | TableField(子表格) |

#### 5.8.4 关联关系

- **belongsTo**：当前表存储外键字段，如 `customer_id`
- **hasMany**：对方表存储外键字段
- **belongsToMany**：需要中间表

#### 5.8.5 可用工具

- `create_collection`: 创建数据集合
- `add_field`: 添加字段
- `update_field`: 修改字段
- `delete_field`: 删除字段

---

### 5.9 集合类型扩展设计（对标 NocoBase Collection Types）

NocoBase 支持 5 种集合类型，每种类型有独特的行为和能力。当前设计仅覆盖 General（通用）类型，需扩展以完全对标。

#### 5.9.1 集合类型总览

| 类型 | 说明 | 典型场景 | 特殊能力 |
|------|------|---------|---------|
| **general** | 通用业务数据 | 客户、订单、工单 | 标准 CRUD |
| **tree** | 树形层级数据 | 部门、分类、组织架构 | parent/children 自关联、递归查询 |
| **calendar** | 日历事件数据 | 日程、会议、排班 | 开始/结束时间配置、日历视图 |
| **file** | 文件附件管理 | 文档、图片、视频 | 文件上传/下载、预览、存储策略 |
| **expression** | 计算/表达式字段 | 统计、汇总、派生值 | 基于其他字段动态计算，不存储物理列 |

#### 5.9.2 数据库表扩展

在 `nocobase_collection` 表增加类型相关配置字段：

```sql
ALTER TABLE nocobase_collection ADD COLUMN collection_type varchar(32) NOT NULL DEFAULT 'general'
    COMMENT '集合类型：general/tree/calendar/file/expression';

-- Tree 集合配置
ALTER TABLE nocobase_collection ADD COLUMN tree_config json NULL
    COMMENT 'Tree 集合配置：parentKey, childrenKey, level 等';

-- Calendar 集合配置
ALTER TABLE nocobase_collection ADD COLUMN calendar_config json NULL
    COMMENT 'Calendar 集合配置：startDateField, endDateField, colorField 等';

-- File 集合配置
ALTER TABLE nocobase_collection ADD COLUMN file_config json NULL
    COMMENT 'File 集合配置：storageStrategy, allowedTypes, maxSize 等';

-- Expression 集合配置
ALTER TABLE nocobase_collection ADD COLUMN expression_config json NULL
    COMMENT 'Expression 集合配置：sourceCollection, expression 等';
```

#### 5.9.3 Tree 集合详细设计

Tree 集合通过自关联实现层级结构，系统自动添加 `parent_id` 和 `level` 字段。

```java
/**
 * Tree 集合配置
 */
@Data
public class TreeCollectionConfig {
    /** 父节点字段名，默认 parent_id */
    private String parentKey = "parent_id";
    /** 子节点集合字段名，默认 children */
    private String childrenKey = "children";
    /** 层级字段名，默认 level */
    private String levelKey = "level";
    /** 最大层级深度，0 表示不限制 */
    private Integer maxDepth = 0;
}

/**
 * Tree 集合服务扩展
 */
@Service
public class TreeCollectionService {

    /**
     * 获取树形数据（递归）
     */
    public List<Map<String, Object>> getTree(String collectionName, TreeQueryReq req) {
        CollectionMeta meta = metaCache.get(collectionName);
        TreeCollectionConfig config = parseTreeConfig(meta);

        // 递归查询子节点
        return queryTreeRecursive(meta, config, req.getParentId(), req.getDepth());
    }

    /**
     * 获取节点路径（从根到当前节点）
     */
    public List<Map<String, Object>> getPath(String collectionName, Long nodeId) {
        CollectionMeta meta = metaCache.get(collectionName);
        TreeCollectionConfig config = parseTreeConfig(meta);

        List<Map<String, Object>> path = new ArrayList<>();
        Long currentId = nodeId;
        while (currentId != null) {
            Map<String, Object> node = dynamicDataService.getById(collectionName, currentId, null);
            path.add(0, node); // 倒序插入，根在前
            currentId = (Long) node.get(config.getParentKey());
        }
        return path;
    }

    /**
     * 移动节点（拖拽排序）
     */
    @Transactional(rollbackFor = Exception.class)
    public void moveNode(String collectionName, Long nodeId, Long newParentId, Integer sort) {
        CollectionMeta meta = metaCache.get(collectionName);
        TreeCollectionConfig config = parseTreeConfig(meta);

        // 1. 更新 parent_id
        Map<String, Object> updateData = new HashMap<>();
        updateData.put("id", nodeId);
        updateData.put(config.getParentKey(), newParentId);
        updateData.put("sort", sort);
        dynamicDataService.update(collectionName, updateData);

        // 2. 递归更新子节点 level
        updateChildrenLevel(collectionName, config, nodeId, getLevel(nodeId));
    }

    private void updateChildrenLevel(String collectionName, TreeCollectionConfig config,
                                      Long parentId, int parentLevel) {
        List<Map<String, Object>> children = queryByParent(collectionName, parentId);
        for (Map<String, Object> child : children) {
            Long childId = ((Number) child.get("id")).longValue();
            int childLevel = parentLevel + 1;
            Map<String, Object> updateData = new HashMap<>();
            updateData.put("id", childId);
            updateData.put(config.getLevelKey(), childLevel);
            dynamicDataService.update(collectionName, updateData);
            updateChildrenLevel(collectionName, config, childId, childLevel);
        }
    }
}
```

**Tree 集合自动字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| parent_id | bigint | 父节点 ID，NULL 表示根节点 |
| level | int | 层级深度，0 表示根 |
| sort | int | 同级排序序号 |

#### 5.9.4 Calendar 集合详细设计

Calendar 集合配置开始/结束时间字段，支持日历视图渲染。

```java
/**
 * Calendar 集合配置
 */
@Data
public class CalendarCollectionConfig {
    /** 开始时间字段名 */
    @NotBlank
    private String startDateField;
    /** 结束时间字段名（可选，无则为单日事件） */
    private String endDateField;
    /** 标题字段名（日历卡片显示） */
    private String titleField;
    /** 颜色字段名（可选，用于事件着色） */
    private String colorField;
}

/**
 * Calendar 集合查询服务
 */
@Service
public class CalendarCollectionService {

    /**
     * 按时间范围查询事件（日历视图核心查询）
     */
    public List<Map<String, Object>> getEvents(String collectionName, CalendarQueryReq req) {
        CollectionMeta meta = metaCache.get(collectionName);
        CalendarCollectionConfig config = parseCalendarConfig(meta);

        // 构建时间范围过滤：事件的结束时间 >= 查询开始 AND 事件的开始时间 <= 查询结束
        Map<String, Object> filters = new HashMap<>();
        filters.put(config.getStartDateField() + ".$lte", req.getEndDate());
        if (config.getEndDateField() != null) {
            filters.put(config.getEndDateField() + ".$gte", req.getStartDate());
        } else {
            filters.put(config.getStartDateField() + ".$gte", req.getStartDate());
            filters.put(config.getStartDateField() + ".$lte", req.getEndDate());
        }

        return dynamicDataService.query(collectionName,
            new DynamicQueryReq().setFilters(filters).setPageSize(1000));
    }
}
```

#### 5.9.5 File 集合详细设计

File 集合管理文件附件，支持多种存储策略。

```java
/**
 * File 集合配置
 */
@Data
public class FileCollectionConfig {
    /** 存储策略：local / s3 / oss */
    private String storageType = "local";
    /** 允许的文件类型，如 ["image/*", ".pdf", ".doc"] */
    private List<String> allowedTypes = List.of("*");
    /** 最大文件大小（MB） */
    private Integer maxSizeMb = 50;
    /** 是否支持多文件上传 */
    private Boolean multiple = true;
    /** 缩略图配置 */
    private ThumbnailConfig thumbnail;
}

@Data
public class ThumbnailConfig {
    /** 是否生成缩略图 */
    private Boolean enabled = false;
    /** 缩略图宽度 */
    private Integer width = 200;
    /** 缩略图高度 */
    private Integer height = 200;
}

/**
 * File 集合自动字段
 */
// | 字段 | 类型 | 说明 |
// |------|------|------|
// | file_name | varchar(255) | 原始文件名 |
// | file_size | bigint | 文件大小（字节） |
// | file_type | varchar(128) | MIME 类型 |
// | storage_path | varchar(512) | 存储路径 |
// | url | varchar(1024) | 访问 URL |
// | thumbnail_url | varchar(1024) | 缩略图 URL |
```

#### 5.9.6 Expression 集合详细设计

Expression 集合基于其他集合的数据进行计算，不存储物理列。

```java
/**
 * Expression 集合配置
 */
@Data
public class ExpressionCollectionConfig {
    /** 源集合名 */
    @NotBlank
    private String sourceCollection;
    /** 表达式定义（JSON 格式） */
    @NotBlank
    private String expression;
    /** 依赖字段列表 */
    private List<String> dependencies;
}

/**
 * 表达式计算引擎
 */
@Component
public class ExpressionEvaluator {

    /**
     * 计算表达式字段值
     * 支持聚合：sum / avg / count / max / min
     * 支持公式：field1 + field2 * 0.1
     */
    public Object evaluate(String expression, Map<String, Object> context) {
        // 使用 Spring EL 或 Aviator 表达式引擎
        ExpressionParser parser = new SpelExpressionParser();
        StandardEvaluationContext evalCtx = new StandardEvaluationContext();
        context.forEach(evalCtx::setVariable);
        return parser.parseExpression(expression).getValue(evalCtx);
    }
}
```

**表达式示例**：

| 场景 | 表达式 | 说明 |
|------|--------|------|
| 求和 | `sum(orders.amount)` | 订单总额 |
| 计数 | `count(orders.id)` | 订单数量 |
| 公式 | `price * quantity * (1 - discount)` | 折后金额 |
| 条件 | `status == 'completed' ? amount : 0` | 已完成金额 |

#### 5.9.7 AI 工具扩展

为支持不同集合类型，AI 工具需扩展：

```java
/**
 * 创建集合工具 — 支持集合类型参数
 */
@Component
public class CreateCollectionTool implements AiTool {

    @Override
    public JsonSchema getParametersSchema() {
        return JsonSchema.object()
            .property("name", JsonSchema.string().description("集合名"))
            .property("displayName", JsonSchema.string().description("显示名称"))
            .property("collectionType", JsonSchema.string()
                .description("集合类型：general/tree/calendar/file/expression")
                .enumValues("general", "tree", "calendar", "file", "expression"))
            .property("fields", JsonSchema.array().description("字段列表"))
            .property("typeConfig", JsonSchema.object()
                .description("类型特有配置，如 treeConfig/calendarConfig 等"))
            .required("name", "displayName")
            .build();
    }
}
```

---

### 5.10 字段类型完整映射表（对标 NocoBase Field Types）

当前字段类型映射仅覆盖基础类型，需扩展以完全对标 NocoBase 的字段体系。

#### 5.10.1 完整字段类型映射

##### 文本类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 短文本 | string | varchar(255) | Input | 默认 |
| 长文本 | text | text | Input.TextArea | 支持 tiny/medium/long |
| Markdown | markdown | text | Markdown | Markdown 编辑器 |
| 富文本 | richText | text | RichText | 富文本编辑器 |
| 手机号 | phone | varchar(32) | PhoneInput | 带格式校验 |
| 邮箱 | email | varchar(255) | EmailInput | 带格式校验 |
| URL | url | varchar(1024) | UrlInput | 带格式校验 |

##### 数字类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 整数 | integer | int | InputNumber | — |
| 大整数 | bigInt | bigint | InputNumber | 大数值 |
| 浮点数 | float | float | InputNumber | 精度较低 |
| 双精度 | double | double | InputNumber | 高精度 |
| 定点数 | decimal | decimal(p,s) | InputNumber | 金额等精确计算 |
| 百分比 | percent | decimal(5,2) | PercentInput | 百分比显示 |
| 评分 | rate | tinyint | Rate | 星级评分 |

##### 日期时间类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 日期时间 | datetime | datetime(3) | DatePicker | 带毫秒 |
| 仅日期 | dateOnly | date | DatePicker | 无时间部分 |
| 仅时间 | time | time | TimePicker | 无日期部分 |
| Unix 时间戳 | unixTimestamp | bigint | DatePicker | 秒/毫秒精度 |

##### 布尔类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 布尔 | boolean | tinyint(1) | Switch | — |
| 复选框 | checkbox | tinyint(1) | Checkbox | 勾选框 |

##### 选择类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 单选 | select | varchar(64) | Select | 下拉单选 |
| 多选 | multiselect | json | Select(multiple) | 下拉多选，JSON 数组存储 |
| 单选按钮 | radio | varchar(64) | RadioGroup | 单选按钮组 |
| 复选框组 | checkboxGroup | json | CheckboxGroup | 复选框组，JSON 数组存储 |

##### 结构化数据类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| JSON | json | json | JsonEditor | JSON 数据 |
| JSONB | jsonb | jsonb | JsonEditor | PostgreSQL 二进制 JSON |
| 数组 | array | json | ArrayInput | 数组存储 |

##### ID 生成类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 自增 ID | autoIncrement | bigint | — | 默认主键 |
| UUID | uuid | varchar(36) | Input(readonly) | UUID v4 |
| NanoID | nanoid | varchar(64) | Input(readonly) | 短唯一 ID |
| 雪花 ID | snowflakeId | bigint | Input(readonly) | 分布式 ID |
| 自定义 UID | uid | varchar(64) | Input(readonly) | 带前缀的短 ID |

##### 特殊类型

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 密码 | password | varchar(255) | PasswordInput | 加密存储 |
| 颜色 | color | varchar(32) | ColorPicker | 颜色选择器 |
| 图标 | icon | varchar(64) | IconPicker | 图标选择器 |
| 代码 | code | text | CodeEditor | 代码编辑器 |

##### 关联类型（完整）

| 业务类型 | field_type | db_type | UI 组件 | 说明 |
|---------|-----------|---------|--------|------|
| 多对一 | belongsTo | bigint | AssociationField(Dropdown) | 下拉选择关联 |
| 一对多 | hasMany | — | SubTable / SubForm | 子表格/子表单 |
| 一对一 | hasOne | — | SubForm | 子表单 |
| 多对多 | belongsToMany | — | AssociationField(Picker) | 弹窗选择关联 |
| 文件 | attachment | — | Upload / FileManager | 文件上传 |

#### 5.10.2 数据库字段扩展

```sql
-- 扩展 nocobase_field 表以支持完整字段类型
ALTER TABLE nocobase_field MODIFY COLUMN field_type varchar(64) NOT NULL
    COMMENT '字段类型：string/text/integer/bigInt/float/double/decimal/boolean/datetime/dateOnly/time/unixTimestamp/select/multiselect/json/jsonb/array/uuid/nanoid/snowflakeId/password/color/belongsTo/hasMany/hasOne/belongsToMany/attachment/expression 等';

-- 增加选项配置（用于 select/multiselect/radio/checkboxGroup）
ALTER TABLE nocobase_field ADD COLUMN choices json NULL
    COMMENT '选项列表，用于选择类型：[{"value":"v1","label":"选项1","color":"#ff0000"}]';

-- 增加 ID 生成配置
ALTER TABLE nocobase_field ADD COLUMN id_generator varchar(32) NULL
    COMMENT 'ID 生成策略：autoIncrement/uuid/nanoid/snowflakeId/uid';

-- 增加表达式配置（用于 expression 类型）
ALTER TABLE nocobase_field ADD COLUMN expression varchar(1024) NULL
    COMMENT '表达式，用于 expression 类型字段';
```

#### 5.10.3 字段类型注册机制

```java
/**
 * 字段类型注册器 — 支持扩展新字段类型
 */
@Component
public class FieldTypeRegistry {

    private final Map<String, FieldTypeDefinition> registry = new ConcurrentHashMap<>();

    @PostConstruct
    public void init() {
        // 注册所有内置字段类型
        register(FieldTypeDefinition.builder()
            .fieldType("string").dbType("varchar(255)")
            .uiComponent("Input").category("text")
            .build());
        register(FieldTypeDefinition.builder()
            .fieldType("text").dbType("text")
            .uiComponent("Input.TextArea").category("text")
            .build());
        register(FieldTypeDefinition.builder()
            .fieldType("json").dbType("json")
            .uiComponent("JsonEditor").category("structured")
            .build());
        register(FieldTypeDefinition.builder()
            .fieldType("uuid").dbType("varchar(36)")
            .uiComponent("Input").category("id")
            .autoGenerate(true).build());
        // ... 注册所有类型
    }

    public void register(FieldTypeDefinition definition) {
        registry.put(definition.getFieldType(), definition);
    }

    public FieldTypeDefinition get(String fieldType) {
        return registry.get(fieldType);
    }

    public List<FieldTypeDefinition> listByCategory(String category) {
        return registry.values().stream()
            .filter(f -> f.getCategory().equals(category))
            .collect(Collectors.toList());
    }
}

@Data
@Builder
public class FieldTypeDefinition {
    private String fieldType;
    private String dbType;
    private String uiComponent;
    private String category; // text/number/datetime/boolean/choice/structured/id/special/association
    private boolean autoGenerate;
    private Map<String, Object> defaultOptions;
}
```

---

### 5.11 操作（Action）系统设计（对标 NocoBase Action System）

NocoBase 的操作系统非常丰富，支持多种数据操作类型。当前设计仅覆盖基础 CRUD 操作，需扩展以完全对标。

#### 5.11.1 操作类型总览

| 操作类型 | 说明 | 当前状态 | 优先级 |
|---------|------|---------|--------|
| **Create** | 新增记录 | ✅ 已实现 | — |
| **Update** | 更新记录 | ✅ 已实现 | — |
| **Delete** | 删除记录 | ✅ 已实现 | — |
| **View** | 查看记录 | ✅ 已实现 | — |
| **Duplicate** | 复制记录 | ❌ 缺失 | 高 |
| **Bulk Edit** | 批量编辑 | ❌ 缺失 | 高 |
| **Export** | 导出数据 | ❌ 缺失 | 中 |
| **Import** | 导入数据 | ❌ 缺失 | 中 |
| **Batch Delete** | 批量删除 | ❌ 缺失 | 高 |
| **Custom Action** | 自定义操作 | ❌ 缺失 | 中 |
| **Submit** | 提交（工作流） | ❌ 缺失 | 中 |
| **Save** | 保存草稿 | ❌ 缺失 | 低 |

#### 5.11.2 Duplicate（复制记录）设计

```java
/**
 * 复制记录服务
 */
@Service
public class DuplicateService {

    @Resource
    private DynamicDataService dynamicDataService;

    @Resource
    private CollectionMetaCache metaCache;

    /**
     * 复制记录
     * @param collectionName 集合名
     * @param sourceId 源记录 ID
     * @param options 复制选项
     */
    @Transactional(rollbackFor = Exception.class)
    public Long duplicate(String collectionName, Long sourceId, DuplicateOptions options) {
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 1. 查询源记录
        Map<String, Object> sourceData = dynamicDataService.getById(collectionName, sourceId, null);
        if (sourceData == null) {
            throw new ServiceException(ErrorCodeConstants.DATA_NOT_EXISTS);
        }

        // 2. 构建新记录数据
        Map<String, Object> newData = new HashMap<>(sourceData);
        
        // 3. 清除系统字段
        newData.remove("id");
        newData.remove("create_time");
        newData.remove("update_time");
        newData.remove("creator");
        newData.remove("updater");
        
        // 4. 根据选项处理关联数据
        if (options.isIncludeRelations()) {
            // 复制关联数据（递归复制子表）
            copyRelations(collectionName, sourceId, newData, meta, options);
        } else {
            // 清除关联字段
            clearRelationFields(newData, meta);
        }

        // 5. 修改标题字段（添加"副本"后缀）
        if (options.isAppendCopySuffix()) {
            String titleField = meta.getTitleField();
            if (titleField != null && newData.containsKey(titleField)) {
                newData.put(titleField, newData.get(titleField) + " (副本)");
            }
        }

        // 6. 创建新记录
        return dynamicDataService.create(collectionName, newData);
    }

    /**
     * 复制关联数据
     */
    private void copyRelations(String collectionName, Long sourceId, 
                                Map<String, Object> newData,
                                CollectionMeta meta, 
                                DuplicateOptions options) {
        // 遍历所有 hasMany 关联
        for (FieldMeta field : meta.getFields()) {
            if ("hasMany".equals(field.getFieldType())) {
                String targetCollection = field.getTargetCollection();
                String foreignKey = field.getForeignKey();
                
                // 查询源记录的关联数据
                List<Map<String, Object>> relatedData = dynamicDataService.query(
                    targetCollection,
                    new DynamicQueryReq().setFilters(Map.of(foreignKey, sourceId))
                );
                
                // 存储关联数据的 ID 映射（旧 ID → 新 ID）
                Map<Long, Long> idMapping = new HashMap<>();
                
                // 复制关联数据
                for (Map<String, Object> related : relatedData) {
                    Long oldId = ((Number) related.get("id")).longValue();
                    related.remove("id");
                    related.put(foreignKey, null); // 稍后更新
                    
                    Long newRelatedId = dynamicDataService.create(targetCollection, related);
                    idMapping.put(oldId, newRelatedId);
                }
                
                // 存储新记录的 ID，稍后更新外键
                newData.put("_relation_" + field.getName(), idMapping);
            }
        }
    }

    /**
     * 清除关联字段
     */
    private void clearRelationFields(Map<String, Object> data, CollectionMeta meta) {
        for (FieldMeta field : meta.getFields()) {
            if (field.getFieldType().startsWith("belongsTo") || 
                field.getFieldType().startsWith("hasOne") ||
                field.getFieldType().startsWith("belongsToMany")) {
                data.put(field.getName(), null);
            }
        }
    }
}

@Data
public class DuplicateOptions {
    /** 是否包含关联数据 */
    private boolean includeRelations = false;
    /** 是否在标题后添加"(副本)"后缀 */
    private boolean appendCopySuffix = true;
    /** 要排除的字段列表 */
    private List<String> excludeFields = List.of();
}
```

**前端 Duplicate 操作**：

```typescript
// 表格行操作 - 复制按钮
const handleDuplicate = async (record: any) => {
  try {
    const newId = await dynamicApi.duplicate(collectionName.value, record.id, {
      includeRelations: false,
      appendCopySuffix: true,
    })
    ElMessage.success('复制成功')
    await loadData() // 刷新列表
  } catch (error) {
    ElMessage.error('复制失败')
  }
}
```

#### 5.11.3 Bulk Edit（批量编辑）设计

```java
/**
 * 批量编辑服务
 */
@Service
public class BulkEditService {

    @Resource
    private DynamicDataService dynamicDataService;

    /**
     * 批量编辑
     * @param collectionName 集合名
     * @param ids 记录 ID 列表
     * @param updates 更新字段映射
     */
    @Transactional(rollbackFor = Exception.class)
    public int bulkEdit(String collectionName, List<Long> ids, Map<String, Object> updates) {
        if (ids == null || ids.isEmpty()) {
            return 0;
        }
        
        int count = 0;
        for (Long id : ids) {
            Map<String, Object> updateData = new HashMap<>(updates);
            updateData.put("id", id);
            dynamicDataService.update(collectionName, updateData);
            count++;
        }
        return count;
    }

    /**
     * 批量编辑（带条件）
     */
    @Transactional(rollbackFor = Exception.class)
    public int bulkEditByFilter(String collectionName, Map<String, Object> filters, 
                                 Map<String, Object> updates) {
        // 1. 查询符合条件的记录
        List<Map<String, Object>> records = dynamicDataService.query(
            collectionName,
            new DynamicQueryReq().setFilters(filters)
        );
        
        // 2. 批量更新
        int count = 0;
        for (Map<String, Object> record : records) {
            Long id = ((Number) record.get("id")).longValue();
            Map<String, Object> updateData = new HashMap<>(updates);
            updateData.put("id", id);
            dynamicDataService.update(collectionName, updateData);
            count++;
        }
        return count;
    }
}
```

**前端批量编辑弹窗**：

```typescript
// src/components/nocode/BulkEditDialog.vue
<template>
  <el-dialog v-model="visible" title="批量编辑" width="600px">
    <el-form :model="formData" label-width="120px">
      <el-form-item 
        v-for="field in editableFields" 
        :key="field.name"
        :label="field.displayName"
      >
        <!-- 字段编辑组件 -->
        <component 
          :is="getFieldComponent(field)" 
          v-model="formData[field.name]"
          :placeholder="`批量设置 ${field.displayName}`"
        />
        <!-- 是否应用该字段 -->
        <el-checkbox v-model="applyFields[field.name]" class="ml-2">
          应用
        </el-checkbox>
      </el-form-item>
    </el-form>
    
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" @click="handleConfirm">
        确认编辑 {{ selectedIds.length }} 条记录
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { dynamicApi } from '@/api/nocode/dynamic'

const props = defineProps<{
  collectionName: string
  selectedIds: (string | number)[]
  fields: any[]
}>()

const emit = defineEmits(['success', 'update:visible'])

const visible = computed({
  get: () => props.visible,
  set: (val) => emit('update:visible', val),
})

const formData = ref<Record<string, any>>({})
const applyFields = ref<Record<string, boolean>>({})

// 可编辑的字段（排除系统字段、关联字段等）
const editableFields = computed(() => {
  return props.fields.filter(f => 
    !['id', 'create_time', 'update_time', 'creator', 'updater', 'deleted', 'tenant_id'].includes(f.name) &&
    !f.fieldType.startsWith('belongsTo') &&
    !f.fieldType.startsWith('hasMany')
  )
})

const handleConfirm = async () => {
  // 只提交勾选的字段
  const updates: Record<string, any> = {}
  for (const [key, value] of Object.entries(formData.value)) {
    if (applyFields.value[key] && value !== undefined && value !== null) {
      updates[key] = value
    }
  }
  
  if (Object.keys(updates).length === 0) {
    ElMessage.warning('请至少选择一个要编辑的字段')
    return
  }
  
  try {
    await dynamicApi.bulkEdit(props.collectionName, props.selectedIds, updates)
    ElMessage.success(`成功编辑 ${props.selectedIds.length} 条记录`)
    visible.value = false
    emit('success')
  } catch (error) {
    ElMessage.error('批量编辑失败')
  }
}
</script>
```

#### 5.11.4 Export/Import（导入导出）设计

```java
/**
 * 数据导出服务
 */
@Service
public class ExportService {

    @Resource
    private DynamicDataService dynamicDataService;

    @Resource
    private CollectionMetaCache metaCache;

    /**
     * 导出数据为 Excel
     */
    public void exportToExcel(String collectionName, ExportOptions options, 
                               HttpServletResponse response) throws IOException {
        CollectionMeta meta = metaCache.get(collectionName);
        
        // 1. 查询数据
        List<Map<String, Object>> data = dynamicDataService.query(
            collectionName,
            new DynamicQueryReq()
                .setFilters(options.getFilters())
                .setSort(options.getSort())
                .setPageSize(options.getMaxRows() != null ? options.getMaxRows() : 10000)
        );
        
        // 2. 确定导出的字段
        List<FieldMeta> exportFields = getExportFields(meta, options.getFields());
        
        // 3. 生成 Excel
        try (ExcelWriter writer = EasyExcel.write(response.getOutputStream())
                .head(buildExcelHead(exportFields))
                .build()) {
            
            WriteSheet sheet = EasyExcel.writerSheet("数据").build();
            
            // 转换数据为 Excel 行
            List<List<Object>> excelData = data.stream()
                .map(row -> buildExcelRow(row, exportFields))
                .collect(Collectors.toList());
            
            writer.write(excelData, sheet);
        }
        
        // 4. 设置响应头
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", 
            "attachment;filename=" + URLEncoder.encode(meta.getDisplayName() + ".xlsx", "UTF-8"));
    }

    /**
     * 构建 Excel 表头
     */
    private List<List<String>> buildExcelHead(List<FieldMeta> fields) {
        return fields.stream()
            .map(f -> List.of(f.getDisplayName()))
            .collect(Collectors.toList());
    }

    /**
     * 构建 Excel 行
     */
    private List<Object> buildExcelRow(Map<String, Object> row, List<FieldMeta> fields) {
        return fields.stream()
            .map(f -> formatFieldValue(row.get(f.getName()), f))
            .collect(Collectors.toList());
    }

    /**
     * 格式化字段值（用于 Excel 显示）
     */
    private Object formatFieldValue(Object value, FieldMeta field) {
        if (value == null) return "";
        
        // 根据字段类型格式化
        switch (field.getFieldType()) {
            case "datetime":
                return LocalDateTime.parse(value.toString())
                    .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            case "dateOnly":
                return LocalDate.parse(value.toString())
                    .format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            case "boolean":
                return Boolean.parseBoolean(value.toString()) ? "是" : "否";
            case "select":
                // 返回选项标签而非值
                return getChoiceLabel(field, value.toString());
            default:
                return value.toString();
        }
    }
}

@Data
public class ExportOptions {
    /** 筛选条件 */
    private Map<String, Object> filters;
    /** 排序规则 */
    private Map<String, String> sort;
    /** 要导出的字段列表（为空则导出全部） */
    private List<String> fields;
    /** 最大导出行数 */
    private Integer maxRows;
}
```

**数据导入服务**：

```java
/**
 * 数据导入服务
 */
@Service
public class ImportService {

    @Resource
    private DynamicDataService dynamicDataService;

    @Resource
    private CollectionMetaCache metaCache;

    /**
     * 从 Excel 导入数据
     */
    @Transactional(rollbackFor = Exception.class)
    public ImportResult importFromExcel(String collectionName, MultipartFile file, 
                                         ImportOptions options) throws IOException {
        CollectionMeta meta = metaCache.get(collectionName);
        
        ImportResult result = new ImportResult();
        
        try (ExcelReader reader = EasyExcel.read(file.getInputStream()).build()) {
            // 读取所有数据
            ReadSheet sheet = EasyExcel.readSheet(0)
                .headRowNumber(1) // 第一行为表头
                .registerReadListener(new AnalysisEventListener<Map<Integer, String>>() {
                    @Override
                    public void invoke(Map<Integer, String> rowData, AnalysisContext context) {
                        try {
                            // 转换 Excel 行为数据 Map
                            Map<String, Object> data = convertExcelRow(rowData, meta, options);
                            
                            // 数据校验
                            ValidationResult validation = validateData(data, meta);
                            if (!validation.isValid()) {
                                result.addError(context.readRowHolder().getRowIndex(), 
                                    validation.getErrors());
                                return;
                            }
                            
                            // 创建记录
                            if (options.isUpsert() && data.containsKey("id")) {
                                // 更新或创建
                                Long id = ((Number) data.get("id")).longValue();
                                Map<String, Object> existing = dynamicDataService.getById(
                                    collectionName, id, null);
                                if (existing != null) {
                                    dynamicDataService.update(collectionName, data);
                                    result.incrementUpdated();
                                } else {
                                    dynamicDataService.create(collectionName, data);
                                    result.incrementCreated();
                                }
                            } else {
                                // 仅创建
                                data.remove("id"); // 清除 ID，让系统自动生成
                                dynamicDataService.create(collectionName, data);
                                result.incrementCreated();
                            }
                        } catch (Exception e) {
                            result.addError(context.readRowHolder().getRowIndex(), 
                                List.of(e.getMessage()));
                        }
                    }
                    
                    @Override
                    public void doAfterAllAnalysed(AnalysisContext context) {
                        // 完成
                    }
                })
                .build();
            
            reader.read(sheet);
        }
        
        return result;
    }

    /**
     * 转换 Excel 行为数据 Map
     */
    private Map<String, Object> convertExcelRow(Map<Integer, String> rowData, 
                                                  CollectionMeta meta,
                                                  ImportOptions options) {
        Map<String, Object> data = new HashMap<>();
        List<FieldMeta> fields = meta.getFields();
        
        for (int i = 0; i < fields.size() && i < rowData.size(); i++) {
            FieldMeta field = fields.get(i);
            String cellValue = rowData.get(i);
            
            if (cellValue != null && !cellValue.trim().isEmpty()) {
                Object convertedValue = convertCellValue(cellValue, field);
                data.put(field.getName(), convertedValue);
            }
        }
        
        return data;
    }

    /**
     * 转换单元格值
     */
    private Object convertCellValue(String cellValue, FieldMeta field) {
        switch (field.getFieldType()) {
            case "integer":
            case "bigInt":
                return Long.parseLong(cellValue);
            case "float":
            case "double":
            case "decimal":
                return new BigDecimal(cellValue);
            case "boolean":
                return "是".equals(cellValue) || "true".equalsIgnoreCase(cellValue) || "1".equals(cellValue);
            case "datetime":
                return LocalDateTime.parse(cellValue, DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
            case "dateOnly":
                return LocalDate.parse(cellValue, DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            case "select":
                // 将标签转换为值
                return getChoiceValue(field, cellValue);
            default:
                return cellValue;
        }
    }
}

@Data
public class ImportResult {
    private int created = 0;
    private int updated = 0;
    private List<ImportError> errors = new ArrayList<>();
    
    public void incrementCreated() { created++; }
    public void incrementUpdated() { updated++; }
    public void addError(int row, List<String> messages) {
        errors.add(new ImportError(row, messages));
    }
}

@Data
@AllArgsConstructor
public class ImportError {
    private int row;
    private List<String> messages;
}

@Data
public class ImportOptions {
    /** 是否更新已存在的记录（根据 ID 匹配） */
    private boolean upsert = false;
    /** 字段映射（Excel 列 → 集合字段） */
    private Map<String, String> fieldMapping;
}
```

#### 5.11.5 Custom Action（自定义操作）设计

```java
/**
 * 自定义操作执行器
 */
@Service
public class CustomActionExecutor {

    @Resource
    private DynamicDataService dynamicDataService;

    @Resource
    private WorkflowBindingService workflowBindingService;

    /**
     * 执行自定义操作
     * @param collectionName 集合名
     * @param actionId 操作 ID
     * @param recordId 记录 ID（可选，单条记录操作）
     * @param params 操作参数
     */
    @Transactional(rollbackFor = Exception.class)
    public Object executeCustomAction(String collectionName, String actionId, 
                                       Long recordId, Map<String, Object> params) {
        // 1. 查询操作定义
        CustomActionMeta action = getActionMeta(collectionName, actionId);
        if (action == null) {
            throw new ServiceException(ErrorCodeConstants.ACTION_NOT_EXISTS);
        }
        
        // 2. 根据操作类型执行
        switch (action.getActionType()) {
            case "UPDATE_RECORD":
                return executeUpdateRecord(collectionName, recordId, action, params);
            case "DELETE_RECORD":
                return executeDeleteRecord(collectionName, recordId);
            case "TRIGGER_WORKFLOW":
                return executeTriggerWorkflow(collectionName, recordId, action, params);
            case "HTTP_REQUEST":
                return executeHttpRequest(action, params);
            case "CUSTOM_SCRIPT":
                return executeCustomScript(collectionName, recordId, action, params);
            default:
                throw new ServiceException(ErrorCodeConstants.UNSUPPORTED_ACTION_TYPE);
        }
    }

    /**
     * 执行更新记录操作
     */
    private Object executeUpdateRecord(String collectionName, Long recordId,
                                        CustomActionMeta action, Map<String, Object> params) {
        Map<String, Object> updateData = new HashMap<>();
        updateData.put("id", recordId);
        
        // 从参数或操作配置中获取更新字段
        for (ActionFieldMapping mapping : action.getFieldMappings()) {
            Object value = params.get(mapping.getParamName());
            if (value != null) {
                updateData.put(mapping.getFieldName(), value);
            } else if (mapping.getDefaultValue() != null) {
                updateData.put(mapping.getFieldName(), mapping.getDefaultValue());
            }
        }
        
        dynamicDataService.update(collectionName, updateData);
        return Map.of("success", true, "message", "操作成功");
    }

    /**
     * 执行触发工作流操作
     */
    private Object executeTriggerWorkflow(String collectionName, Long recordId,
                                           CustomActionMeta action, Map<String, Object> params) {
        String workflowKey = action.getWorkflowKey();
        
        // 查询记录数据
        Map<String, Object> record = dynamicDataService.getById(collectionName, recordId, null);
        
        // 触发工作流
        workflowBindingService.triggerWorkflow(
            collectionName,
            "custom_action:" + action.getActionId(),
            record
        );
        
        return Map.of("success", true, "message", "工作流已触发");
    }
}

@Data
public class CustomActionMeta {
    private String actionId;
    private String actionName;
    private String actionType; // UPDATE_RECORD / DELETE_RECORD / TRIGGER_WORKFLOW / HTTP_REQUEST / CUSTOM_SCRIPT
    private String collectionName;
    private String workflowKey; // 触发工作流时的工作流 KEY
    private String httpConfig; // HTTP 请求配置（JSON）
    private String script; // 自定义脚本
    private List<ActionFieldMapping> fieldMappings; // 字段映射
    private String confirmMessage; // 确认提示
    private String successMessage; // 成功提示
}

@Data
public class ActionFieldMapping {
    private String paramName; // 参数名
    private String fieldName; // 字段名
    private Object defaultValue; // 默认值
}
```

**前端自定义操作按钮**：

```typescript
// 表格行操作 - 自定义操作按钮
const handleCustomAction = async (actionId: string, record: any) => {
  const action = getActionMeta(actionId)
  
  // 显示确认弹窗
  if (action.confirmMessage) {
    const confirmed = await ElMessageBox.confirm(
      action.confirmMessage,
      '确认操作',
      { type: 'warning' }
    )
    if (!confirmed) return
  }
  
  try {
    const result = await dynamicApi.executeCustomAction(
      collectionName.value,
      actionId,
      record.id,
      {} // 操作参数
    )
    
    ElMessage.success(result.message || '操作成功')
    await loadData() // 刷新列表
  } catch (error) {
    ElMessage.error('操作失败')
  }
}
```

#### 5.11.6 操作权限控制

```java
/**
 * 操作权限检查
 */
@Component
public class ActionPermissionChecker {

    @Resource
    private CollectionPermissionService permissionService;

    /**
     * 检查操作权限
     * @param collectionName 集合名
     * @param actionType 操作类型
     * @param recordId 记录 ID（可选，用于数据权限检查）
     */
    public void checkActionPermission(String collectionName, String actionType, Long recordId) {
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 检查功能权限
        boolean hasPermission = permissionService.hasActionPermission(
            userId, tenantId, collectionName, actionType);
        if (!hasPermission) {
            throw new ServiceException(ErrorCodeConstants.NO_PERMISSION);
        }
        
        // 2. 检查数据权限（如果指定了记录 ID）
        if (recordId != null) {
            boolean hasDataPermission = permissionService.hasDataPermission(
                userId, tenantId, collectionName, recordId);
            if (!hasDataPermission) {
                throw new ServiceException(ErrorCodeConstants.NO_DATA_PERMISSION);
            }
        }
    }
}
```

---

### 5.14 字段赋值机制设计（对标 NocoBase Field Assignment）

NocoBase 2.0 引入统一的字段赋值机制，支持在表单提交、工作流节点、自定义操作等场景下对字段进行赋值。

#### 5.14.1 赋值类型

| 赋值类型 | 说明 | 典型场景 |
|---------|------|---------|
| **默认值** | 新建记录时的初始值 | 状态默认为"待处理" |
| **常量值** | 固定值赋值 | 类型固定为"普通" |
| **表达式** | 基于其他字段计算 | 总价 = 单价 × 数量 |
| **关联字段** | 从关联记录获取 | 客户名称从客户表获取 |
| **系统字段** | 系统自动填充 | 创建人、创建时间 |
| **用户输入** | 用户手动输入 | 表单字段 |

#### 5.14.2 数据库表设计

```sql
-- 字段赋值规则表
CREATE TABLE nocobase_field_assignment (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    collection_name VARCHAR(100) NOT NULL COMMENT '集合名称',
    field_name VARCHAR(100) NOT NULL COMMENT '字段名称',
    assignment_type VARCHAR(32) NOT NULL COMMENT '赋值类型：default/constant/expression/relation/system/user_input',
    assignment_config JSON NOT NULL COMMENT '赋值配置（JSON格式）',
    trigger_scene VARCHAR(32) NOT NULL COMMENT '触发场景：create/update/both',
    priority INT DEFAULT 0 COMMENT '优先级（数字越大优先级越高）',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_collection_field (collection_name, field_name),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='字段赋值规则表';
```

#### 5.14.3 赋值配置示例

```json
// 默认值赋值
{
  "assignment_type": "default",
  "assignment_config": {
    "value": "pending",
    "description": "状态默认为待处理"
  }
}

// 常量值赋值
{
  "assignment_type": "constant",
  "assignment_config": {
    "value": "normal",
    "description": "类型固定为普通"
  }
}

// 表达式赋值
{
  "assignment_type": "expression",
  "assignment_config": {
    "expression": "price * quantity",
    "dependencies": ["price", "quantity"],
    "description": "总价 = 单价 × 数量"
  }
}

// 关联字段赋值
{
  "assignment_type": "relation",
  "assignment_config": {
    "source_field": "customer_id",
    "target_collection": "customers",
    "target_field": "customer_name",
    "description": "从客户表获取客户名称"
  }
}

// 系统字段赋值
{
  "assignment_type": "system",
  "assignment_config": {
    "system_field": "creator",
    "value_source": "current_user_id",
    "description": "自动填充当前用户ID"
  }
}
```

#### 5.14.4 字段赋值引擎

```java
/**
 * 字段赋值引擎
 */
@Service
public class FieldAssignmentEngine {

    @Resource
    private FieldAssignmentMapper assignmentMapper;

    @Resource
    private DynamicDataService dynamicDataService;

    @Resource
    private ExpressionEvaluator expressionEvaluator;

    /**
     * 应用字段赋值规则
     * @param collectionName 集合名称
     * @param data 待处理数据
     * @param scene 触发场景：create/update
     */
    public void applyAssignments(String collectionName, Map<String, Object> data, String scene) {
        // 1. 查询该集合的所有赋值规则
        List<FieldAssignmentDO> assignments = assignmentMapper.selectByCollectionAndScene(
            collectionName, scene);
        
        // 2. 按优先级排序
        assignments.sort((a, b) -> b.getPriority() - a.getPriority());
        
        // 3. 逐条应用赋值规则
        for (FieldAssignmentDO assignment : assignments) {
            if (!assignment.getEnabled()) {
                continue;
            }
            
            String fieldName = assignment.getFieldName();
            String assignmentType = assignment.getAssignmentType();
            JSONObject config = JSONUtil.parseObj(assignment.getAssignmentConfig());
            
            // 如果字段已有值且不允许覆盖，跳过
            if (data.containsKey(fieldName) && data.get(fieldName) != null) {
                if (!config.getBool("allow_override", false)) {
                    continue;
                }
            }
            
            // 根据赋值类型处理
            Object value = null;
            switch (assignmentType) {
                case "default":
                case "constant":
                    value = config.get("value");
                    break;
                case "expression":
                    value = evaluateExpression(config.getStr("expression"), data);
                    break;
                case "relation":
                    value = resolveRelation(config, data);
                    break;
                case "system":
                    value = resolveSystemField(config.getStr("system_field"));
                    break;
                case "user_input":
                    // 用户输入字段不自动赋值，跳过
                    continue;
            }
            
            if (value != null) {
                data.put(fieldName, value);
            }
        }
    }

    /**
     * 计算表达式
     */
    private Object evaluateExpression(String expression, Map<String, Object> context) {
        try {
            return expressionEvaluator.evaluate(expression, context);
        } catch (Exception e) {
            log.warn("表达式计算失败: expression={}, error={}", expression, e.getMessage());
            return null;
        }
    }

    /**
     * 解析关联字段
     */
    private Object resolveRelation(JSONObject config, Map<String, Object> data) {
        String sourceField = config.getStr("source_field");
        String targetCollection = config.getStr("target_collection");
        String targetField = config.getStr("target_field");
        
        Object sourceValue = data.get(sourceField);
        if (sourceValue == null) {
            return null;
        }
        
        // 查询关联记录
        Map<String, Object> relatedRecord = dynamicDataService.getById(
            targetCollection, ((Number) sourceValue).longValue(), null);
        
        return relatedRecord != null ? relatedRecord.get(targetField) : null;
    }

    /**
     * 解析系统字段
     */
    private Object resolveSystemField(String systemField) {
        switch (systemField) {
            case "creator":
            case "updater":
                return SecurityFrameworkUtils.getLoginUserId();
            case "create_time":
            case "update_time":
                return LocalDateTime.now();
            case "tenant_id":
                return SecurityFrameworkUtils.getTenantId();
            default:
                return null;
        }
    }
}
```

#### 5.14.5 前端字段赋值配置界面

```typescript
// src/components/nocode/FieldAssignmentConfig.vue
<template>
  <el-dialog v-model="visible" title="字段赋值配置" width="800px">
    <el-table :data="assignments" border>
      <el-table-column prop="fieldName" label="字段" width="150" />
      <el-table-column prop="assignmentType" label="赋值类型" width="120">
        <template #default="{ row }">
          <el-select v-model="row.assignmentType" size="small">
            <el-option label="默认值" value="default" />
            <el-option label="常量" value="constant" />
            <el-option label="表达式" value="expression" />
            <el-option label="关联字段" value="relation" />
            <el-option label="系统字段" value="system" />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="赋值配置" min-width="300">
        <template #default="{ row }">
          <component 
            :is="getAssignmentComponent(row.assignmentType)" 
            v-model="row.assignmentConfig"
            :fields="availableFields"
          />
        </template>
      </el-table-column>
      <el-table-column prop="triggerScene" label="触发场景" width="120">
        <template #default="{ row }">
          <el-select v-model="row.triggerScene" size="small">
            <el-option label="创建时" value="create" />
            <el-option label="更新时" value="update" />
            <el-option label="创建和更新" value="both" />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="100">
        <template #default="{ $index }">
          <el-button size="small" type="danger" @click="removeAssignment($index)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <el-button class="mt-4" @click="addAssignment">添加赋值规则</el-button>
    
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" @click="saveAssignments">保存</el-button>
    </template>
  </el-dialog>
</template>
```

#### 5.14.6 AI 辅助字段赋值配置

NocoBase 2.0 支持 AI 辅助配置字段赋值规则,通过对话方式快速创建复杂的赋值逻辑。

##### 5.14.6.1 AI 赋值配置工具

```java
/**
 * AI 工具:配置字段赋值规则
 */
@Component
public class ConfigureFieldAssignmentTool implements ToolCallback {
    
    @Resource
    private FieldAssignmentMapper assignmentMapper;
    
    @Resource
    private CollectionService collectionService;
    
    @Override
    public String getName() {
        return "configure_field_assignment";
    }
    
    @Override
    public String getDescription() {
        return "为 Collection 的字段配置赋值规则,支持默认值、常量、表达式、关联字段、系统字段等多种赋值类型";
    }
    
    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String collectionName = args.getStr("collectionName");
        String fieldName = args.getStr("fieldName");
        String assignmentType = args.getStr("assignmentType");
        JSONObject assignmentConfig = args.getJSONObject("assignmentConfig");
        String triggerScene = args.getStr("triggerScene", "both");
        Integer priority = args.getInt("priority", 0);
        
        // 验证 Collection 和字段是否存在
        CollectionDO collection = collectionService.getByName(collectionName);
        if (collection == null) {
            return JSONUtil.toJsonStr(Map.of(
                "success", false,
                "message", "Collection 不存在: " + collectionName
            ));
        }
        
        // 创建赋值规则
        FieldAssignmentDO assignment = new FieldAssignmentDO();
        assignment.setCollectionName(collectionName);
        assignment.setFieldName(fieldName);
        assignment.setAssignmentType(assignmentType);
        assignment.setAssignmentConfig(assignmentConfig.toString());
        assignment.setTriggerScene(triggerScene);
        assignment.setPriority(priority);
        assignment.setEnabled(true);
        
        assignmentMapper.insert(assignment);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true,
            "assignmentId", assignment.getId(),
            "message", "字段赋值规则配置成功"
        ));
    }
}
```

##### 5.14.6.2 AI 对话示例

```
用户: 帮我为订单表的 total_amount 字段配置一个表达式赋值规则,计算 price * quantity

AI: 好的,我来为订单表的 total_amount 字段配置表达式赋值规则。

[调用 configure_field_assignment 工具]
{
  "collectionName": "orders",
  "fieldName": "total_amount",
  "assignmentType": "expression",
  "assignmentConfig": {
    "expression": "price * quantity",
    "dependencies": ["price", "quantity"],
    "description": "总价 = 单价 × 数量"
  },
  "triggerScene": "both",
  "priority": 10
}

AI: 已成功配置!当创建或更新订单时,total_amount 字段会自动计算为 price * quantity。
```

#### 5.14.7 赋值规则验证与调试

##### 5.14.7.1 赋值规则验证器

```java
/**
 * 字段赋值规则验证器
 */
@Service
public class FieldAssignmentValidator {
    
    @Resource
    private ExpressionEvaluator expressionEvaluator;
    
    @Resource
    private DynamicDataService dynamicDataService;
    
    /**
     * 验证赋值规则配置
     */
    public ValidationResult validateAssignment(FieldAssignmentDO assignment) {
        String assignmentType = assignment.getAssignmentType();
        JSONObject config = JSONUtil.parseObj(assignment.getAssignmentConfig());
        
        switch (assignmentType) {
            case "expression":
                return validateExpressionAssignment(config);
            case "relation":
                return validateRelationAssignment(config);
            case "default":
            case "constant":
                return validateConstantAssignment(config);
            case "system":
                return validateSystemAssignment(config);
            default:
                return ValidationResult.error("未知的赋值类型: " + assignmentType);
        }
    }
    
    /**
     * 验证表达式赋值
     */
    private ValidationResult validateExpressionAssignment(JSONObject config) {
        String expression = config.getStr("expression");
        if (StrUtil.isBlank(expression)) {
            return ValidationResult.error("表达式不能为空");
        }
        
        // 验证表达式语法
        try {
            expressionEvaluator.validate(expression);
        } catch (Exception e) {
            return ValidationResult.error("表达式语法错误: " + e.getMessage());
        }
        
        // 验证依赖字段
        List<String> dependencies = config.getBeanList("dependencies", String.class);
        if (dependencies != null && !dependencies.isEmpty()) {
            // 检查依赖字段是否存在(需要传入 collectionName)
            // 这里简化处理
        }
        
        return ValidationResult.success();
    }
    
    /**
     * 验证关联字段赋值
     */
    private ValidationResult validateRelationAssignment(JSONObject config) {
        String sourceField = config.getStr("source_field");
        String targetCollection = config.getStr("target_collection");
        String targetField = config.getStr("target_field");
        
        if (StrUtil.isBlank(sourceField)) {
            return ValidationResult.error("源字段不能为空");
        }
        if (StrUtil.isBlank(targetCollection)) {
            return ValidationResult.error("目标集合不能为空");
        }
        if (StrUtil.isBlank(targetField)) {
            return ValidationResult.error("目标字段不能为空");
        }
        
        // 验证目标集合和字段是否存在
        CollectionDO targetColl = dynamicDataService.getCollection(targetCollection);
        if (targetColl == null) {
            return ValidationResult.error("目标集合不存在: " + targetCollection);
        }
        
        return ValidationResult.success();
    }
    
    /**
     * 验证常量赋值
     */
    private ValidationResult validateConstantAssignment(JSONObject config) {
        if (!config.containsKey("value")) {
            return ValidationResult.error("常量值不能为空");
        }
        return ValidationResult.success();
    }
    
    /**
     * 验证系统字段赋值
     */
    private ValidationResult validateSystemAssignment(JSONObject config) {
        String systemField = config.getStr("system_field");
        if (StrUtil.isBlank(systemField)) {
            return ValidationResult.error("系统字段不能为空");
        }
        
        List<String> validFields = Arrays.asList("creator", "updater", "create_time", "update_time", "tenant_id");
        if (!validFields.contains(systemField)) {
            return ValidationResult.error("不支持的系统字段: " + systemField);
        }
        
        return ValidationResult.success();
    }
}

/**
 * 验证结果
 */
@Data
public class ValidationResult {
    private boolean success;
    private String errorMessage;
    
    public static ValidationResult success() {
        ValidationResult result = new ValidationResult();
        result.setSuccess(true);
        return result;
    }
    
    public static ValidationResult error(String errorMessage) {
        ValidationResult result = new ValidationResult();
        result.setSuccess(false);
        result.setErrorMessage(errorMessage);
        return result;
    }
}
```

##### 5.14.7.2 赋值调试日志

```java
/**
 * 字段赋值调试日志
 */
@Service
public class FieldAssignmentLogger {
    
    @Resource
    private FieldAssignmentLogMapper logMapper;
    
    /**
     * 记录赋值日志
     */
    public void logAssignment(String collectionName, Long recordId, String fieldName, 
                              String assignmentType, Object oldValue, Object newValue, 
                              String triggerScene) {
        FieldAssignmentLogDO log = new FieldAssignmentLogDO();
        log.setCollectionName(collectionName);
        log.setRecordId(recordId);
        log.setFieldName(fieldName);
        log.setAssignmentType(assignmentType);
        log.setOldValue(oldValue != null ? oldValue.toString() : null);
        log.setNewValue(newValue != null ? newValue.toString() : null);
        log.setTriggerScene(triggerScene);
        log.setExecuteTime(LocalDateTime.now());
        
        logMapper.insert(log);
    }
    
    /**
     * 查询赋值日志
     */
    public List<FieldAssignmentLogDO> getAssignmentLogs(String collectionName, Long recordId) {
        return logMapper.selectByCollectionAndRecord(collectionName, recordId);
    }
}
```

```sql
-- 字段赋值日志表
CREATE TABLE nocobase_field_assignment_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    collection_name VARCHAR(100) NOT NULL COMMENT '集合名称',
    record_id BIGINT NOT NULL COMMENT '记录ID',
    field_name VARCHAR(100) NOT NULL COMMENT '字段名称',
    assignment_type VARCHAR(32) NOT NULL COMMENT '赋值类型',
    old_value TEXT COMMENT '旧值',
    new_value TEXT COMMENT '新值',
    trigger_scene VARCHAR(32) NOT NULL COMMENT '触发场景',
    execute_time DATETIME NOT NULL COMMENT '执行时间',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    
    INDEX idx_collection_record (collection_name, record_id),
    INDEX idx_execute_time (execute_time),
    INDEX idx_tenant (tenant_id)
) COMMENT='字段赋值日志表';
```

#### 5.14.8 批量赋值优化

##### 5.14.8.1 批量赋值引擎

```java
/**
 * 批量字段赋值引擎
 */
@Service
public class BatchFieldAssignmentEngine {
    
    @Resource
    private FieldAssignmentMapper assignmentMapper;
    
    @Resource
    private DynamicDataService dynamicDataService;
    
    @Resource
    private ExpressionEvaluator expressionEvaluator;
    
    /**
     * 批量应用字段赋值
     * @param collectionName 集合名称
     * @param dataList 待处理数据列表
     * @param scene 触发场景
     */
    public void batchApplyAssignments(String collectionName, List<Map<String, Object>> dataList, String scene) {
        if (dataList == null || dataList.isEmpty()) {
            return;
        }
        
        // 1. 一次性查询所有赋值规则(避免 N+1 查询)
        List<FieldAssignmentDO> allAssignments = assignmentMapper.selectByCollectionAndScene(
            collectionName, scene);
        
        if (allAssignments.isEmpty()) {
            return;
        }
        
        // 2. 按字段分组赋值规则
        Map<String, List<FieldAssignmentDO>> assignmentsByField = allAssignments.stream()
            .collect(Collectors.groupingBy(FieldAssignmentDO::getFieldName));
        
        // 3. 预加载关联数据(批量查询,避免循环查询)
        Map<String, Map<Long, Map<String, Object>>> relationDataCache = preloadRelationData(
            allAssignments, dataList);
        
        // 4. 批量应用赋值
        for (Map<String, Object> data : dataList) {
            for (Map.Entry<String, List<FieldAssignmentDO>> entry : assignmentsByField.entrySet()) {
                String fieldName = entry.getKey();
                List<FieldAssignmentDO> assignments = entry.getValue();
                
                // 按优先级排序
                assignments.sort((a, b) -> b.getPriority() - a.getPriority());
                
                for (FieldAssignmentDO assignment : assignments) {
                    if (!assignment.getEnabled()) {
                        continue;
                    }
                    
                    JSONObject config = JSONUtil.parseObj(assignment.getAssignmentConfig());
                    
                    // 如果字段已有值且不允许覆盖,跳过
                    if (data.containsKey(fieldName) && data.get(fieldName) != null) {
                        if (!config.getBool("allow_override", false)) {
                            continue;
                        }
                    }
                    
                    // 根据赋值类型处理
                    Object value = resolveAssignmentValue(assignment, data, relationDataCache);
                    if (value != null) {
                        data.put(fieldName, value);
                    }
                }
            }
        }
    }
    
    /**
     * 预加载关联数据
     */
    private Map<String, Map<Long, Map<String, Object>>> preloadRelationData(
            List<FieldAssignmentDO> assignments, List<Map<String, Object>> dataList) {
        
        Map<String, Map<Long, Map<String, Object>>> cache = new HashMap<>();
        
        // 找出所有关联字段赋值
        List<FieldAssignmentDO> relationAssignments = assignments.stream()
            .filter(a -> "relation".equals(a.getAssignmentType()))
            .collect(Collectors.toList());
        
        for (FieldAssignmentDO assignment : relationAssignments) {
            JSONObject config = JSONUtil.parseObj(assignment.getAssignmentConfig());
            String sourceField = config.getStr("source_field");
            String targetCollection = config.getStr("target_collection");
            
            // 收集所有需要查询的 ID
            Set<Long> targetIds = new HashSet<>();
            for (Map<String, Object> data : dataList) {
                Object sourceValue = data.get(sourceField);
                if (sourceValue instanceof Number) {
                    targetIds.add(((Number) sourceValue).longValue());
                }
            }
            
            if (!targetIds.isEmpty()) {
                // 批量查询关联记录
                Map<Long, Map<String, Object>> records = dynamicDataService.getByIds(
                    targetCollection, targetIds, null);
                cache.put(targetCollection, records);
            }
        }
        
        return cache;
    }
    
    /**
     * 解析赋值值
     */
    private Object resolveAssignmentValue(FieldAssignmentDO assignment, 
                                          Map<String, Object> data,
                                          Map<String, Map<Long, Map<String, Object>>> relationDataCache) {
        String assignmentType = assignment.getAssignmentType();
        JSONObject config = JSONUtil.parseObj(assignment.getAssignmentConfig());
        
        switch (assignmentType) {
            case "default":
            case "constant":
                return config.get("value");
            case "expression":
                return evaluateExpression(config.getStr("expression"), data);
            case "relation":
                return resolveRelationFromCache(config, data, relationDataCache);
            case "system":
                return resolveSystemField(config.getStr("system_field"));
            default:
                return null;
        }
    }
    
    /**
     * 从缓存解析关联字段
     */
    private Object resolveRelationFromCache(JSONObject config, Map<String, Object> data,
                                            Map<String, Map<Long, Map<String, Object>>> cache) {
        String sourceField = config.getStr("source_field");
        String targetCollection = config.getStr("target_collection");
        String targetField = config.getStr("target_field");
        
        Object sourceValue = data.get(sourceField);
        if (!(sourceValue instanceof Number)) {
            return null;
        }
        
        Long targetId = ((Number) sourceValue).longValue();
        Map<Long, Map<String, Object>> records = cache.get(targetCollection);
        if (records == null) {
            return null;
        }
        
        Map<String, Object> relatedRecord = records.get(targetId);
        return relatedRecord != null ? relatedRecord.get(targetField) : null;
    }
    
    private Object evaluateExpression(String expression, Map<String, Object> context) {
        try {
            return expressionEvaluator.evaluate(expression, context);
        } catch (Exception e) {
            log.warn("表达式计算失败: expression={}, error={}", expression, e.getMessage());
            return null;
        }
    }
    
    private Object resolveSystemField(String systemField) {
        switch (systemField) {
            case "creator":
            case "updater":
                return SecurityFrameworkUtils.getLoginUserId();
            case "create_time":
            case "update_time":
                return LocalDateTime.now();
            case "tenant_id":
                return SecurityFrameworkUtils.getTenantId();
            default:
                return null;
        }
    }
}
```

##### 5.14.8.2 性能优化说明

**批量赋值优化策略:**

1. **避免 N+1 查询**: 一次性查询所有赋值规则,而非每条记录单独查询
2. **预加载关联数据**: 批量查询所有关联记录,避免循环查询数据库
3. **缓存复用**: 使用 Map 缓存关联数据,减少重复查询
4. **分组处理**: 按字段分组赋值规则,提高处理效率

**性能对比:**

| 场景 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| 100 条记录,5 个赋值规则 | 500 次查询 | 6 次查询 | 83x |
| 1000 条记录,10 个赋值规则 | 10000 次查询 | 11 次查询 | 909x |

---

### 5.15 事件流(Event Flow)设计(对标 NocoBase Event Flow)

NocoBase 2.0 引入 Event → Flow → Step 层级执行机制，支持复杂的事件处理流程。

#### 5.15.1 事件流层级结构

```
event:
  before: [hooks]           # 事件前置钩子
  flows:
    - name: flow1
      before: [hooks]       # 流程前置钩子
      steps:
        - name: step1
          before: [hooks]   # 步骤前置钩子
          run: do_something # 步骤执行逻辑
          after: [hooks]    # 步骤后置钩子
        - name: step2
          run: do_another_thing
      after: [hooks]        # 流程后置钩子
    - name: flow2
      steps: [...]
  after: [hooks]            # 事件后置钩子
```

#### 5.15.2 数据库表设计

```sql
-- 事件流定义表
CREATE TABLE nocobase_event_flow (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    event_name VARCHAR(100) NOT NULL COMMENT '事件名称',
    flow_name VARCHAR(100) NOT NULL COMMENT '流程名称',
    flow_order INT DEFAULT 0 COMMENT '流程执行顺序',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    conditions JSON COMMENT '执行条件（JSON格式）',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_event_name (event_name),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='事件流定义表';

-- 事件流步骤表
CREATE TABLE nocobase_event_flow_step (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    flow_id BIGINT NOT NULL COMMENT '所属流程ID',
    step_name VARCHAR(100) NOT NULL COMMENT '步骤名称',
    step_order INT DEFAULT 0 COMMENT '步骤执行顺序',
    step_type VARCHAR(32) NOT NULL COMMENT '步骤类型：script/http/workflow/condition',
    step_config JSON NOT NULL COMMENT '步骤配置（JSON格式）',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_flow_id (flow_id),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='事件流步骤表';

-- 事件钩子表
CREATE TABLE nocobase_event_hook (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    event_name VARCHAR(100) NOT NULL COMMENT '事件名称',
    flow_id BIGINT COMMENT '所属流程ID（为空表示事件级钩子）',
    step_id BIGINT COMMENT '所属步骤ID（为空表示流程级钩子）',
    hook_position VARCHAR(32) NOT NULL COMMENT '钩子位置：before/after',
    hook_type VARCHAR(32) NOT NULL COMMENT '钩子类型：script/http/workflow',
    hook_config JSON NOT NULL COMMENT '钩子配置（JSON格式）',
    hook_order INT DEFAULT 0 COMMENT '钩子执行顺序',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_event_name (event_name),
    INDEX idx_flow_id (flow_id),
    INDEX idx_step_id (step_id),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='事件钩子表';
```

#### 5.15.3 事件流执行引擎

```java
/**
 * 事件流执行引擎
 */
@Service
public class EventFlowEngine {

    @Resource
    private EventFlowMapper flowMapper;

    @Resource
    private EventFlowStepMapper stepMapper;

    @Resource
    private EventHookMapper hookMapper;

    @Resource
    private ScriptExecutor scriptExecutor;

    @Resource
    private HttpClient httpClient;

    @Resource
    private WorkflowBindingService workflowService;

    /**
     * 执行事件流
     * @param eventName 事件名称
     * @param context 事件上下文
     */
    @Transactional(rollbackFor = Exception.class)
    public void executeEventFlow(String eventName, Map<String, Object> context) {
        // 1. 执行事件前置钩子
        executeHooks(eventName, null, null, "before", context);
        
        // 2. 查询该事件的所有流程
        List<EventFlowDO> flows = flowMapper.selectByEventName(eventName);
        flows.sort((a, b) -> a.getFlowOrder() - b.getFlowOrder());
        
        // 3. 逐个执行流程
        for (EventFlowDO flow : flows) {
            if (!flow.getEnabled()) {
                continue;
            }
            
            // 检查执行条件
            if (!checkConditions(flow.getConditions(), context)) {
                continue;
            }
            
            executeFlow(flow, context);
        }
        
        // 4. 执行事件后置钩子
        executeHooks(eventName, null, null, "after", context);
    }

    /**
     * 执行单个流程
     */
    private void executeFlow(EventFlowDO flow, Map<String, Object> context) {
        Long flowId = flow.getId();
        
        // 1. 执行流程前置钩子
        executeHooks(flow.getEventName(), flowId, null, "before", context);
        
        // 2. 查询该流程的所有步骤
        List<EventFlowStepDO> steps = stepMapper.selectByFlowId(flowId);
        steps.sort((a, b) -> a.getStepOrder() - b.getStepOrder());
        
        // 3. 逐个执行步骤
        for (EventFlowStepDO step : steps) {
            if (!step.getEnabled()) {
                continue;
            }
            
            executeStep(step, context);
        }
        
        // 4. 执行流程后置钩子
        executeHooks(flow.getEventName(), flowId, null, "after", context);
    }

    /**
     * 执行单个步骤
     */
    private void executeStep(EventFlowStepDO step, Map<String, Object> context) {
        Long stepId = step.getId();
        Long flowId = step.getFlowId();
        
        // 1. 执行步骤前置钩子
        executeHooks(null, flowId, stepId, "before", context);
        
        // 2. 执行步骤主体逻辑
        String stepType = step.getStepType();
        JSONObject config = JSONUtil.parseObj(step.getStepConfig());
        
        try {
            switch (stepType) {
                case "script":
                    executeScript(config.getStr("script"), context);
                    break;
                case "http":
                    executeHttpRequest(config, context);
                    break;
                case "workflow":
                    executeWorkflow(config.getStr("workflowKey"), context);
                    break;
                case "condition":
                    executeCondition(config, context);
                    break;
            }
        } catch (Exception e) {
            log.error("步骤执行失败: stepName={}, error={}", step.getStepName(), e.getMessage(), e);
            throw new ServiceException(ErrorCodeConstants.EVENT_FLOW_STEP_FAILED, e.getMessage());
        }
        
        // 3. 执行步骤后置钩子
        executeHooks(null, flowId, stepId, "after", context);
    }

    /**
     * 执行钩子
     */
    private void executeHooks(String eventName, Long flowId, Long stepId, 
                               String position, Map<String, Object> context) {
        List<EventHookDO> hooks = hookMapper.selectByPosition(eventName, flowId, stepId, position);
        hooks.sort((a, b) -> a.getHookOrder() - b.getHookOrder());
        
        for (EventHookDO hook : hooks) {
            if (!hook.getEnabled()) {
                continue;
            }
            
            JSONObject config = JSONUtil.parseObj(hook.getHookConfig());
            
            try {
                switch (hook.getHookType()) {
                    case "script":
                        executeScript(config.getStr("script"), context);
                        break;
                    case "http":
                        executeHttpRequest(config, context);
                        break;
                    case "workflow":
                        executeWorkflow(config.getStr("workflowKey"), context);
                        break;
                }
            } catch (Exception e) {
                log.error("钩子执行失败: hookId={}, error={}", hook.getId(), e.getMessage(), e);
            }
        }
    }

    /**
     * 执行脚本
     */
    private void executeScript(String script, Map<String, Object> context) {
        scriptExecutor.execute(script, context);
    }

    /**
     * 执行 HTTP 请求
     */
    private void executeHttpRequest(JSONObject config, Map<String, Object> context) {
        String url = config.getStr("url");
        String method = config.getStr("method", "POST");
        JSONObject headers = config.getJSONObject("headers");
        JSONObject body = config.getJSONObject("body");
        
        // 替换模板变量
        url = replaceTemplateVariables(url, context);
        body = replaceTemplateVariables(body, context);
        
        // 发送 HTTP 请求
        httpClient.request(method, url, headers, body);
    }

    /**
     * 执行工作流
     */
    private void executeWorkflow(String workflowKey, Map<String, Object> context) {
        workflowService.triggerWorkflow(workflowKey, context);
    }

    /**
     * 执行条件分支
     */
    private void executeCondition(JSONObject config, Map<String, Object> context) {
        String condition = config.getStr("condition");
        JSONObject thenSteps = config.getJSONObject("then");
        JSONObject elseSteps = config.getJSONObject("else");
        
        boolean result = evaluateCondition(condition, context);
        
        if (result && thenSteps != null) {
            executeStepsFromConfig(thenSteps, context);
        } else if (!result && elseSteps != null) {
            executeStepsFromConfig(elseSteps, context);
        }
    }

    /**
     * 检查执行条件
     */
    private boolean checkConditions(String conditionsJson, Map<String, Object> context) {
        if (conditionsJson == null || conditionsJson.isEmpty()) {
            return true;
        }
        
        JSONObject conditions = JSONUtil.parseObj(conditionsJson);
        return evaluateCondition(conditions.getStr("expression"), context);
    }

    /**
     * 评估条件表达式
     */
    private boolean evaluateCondition(String expression, Map<String, Object> context) {
        Object result = expressionEvaluator.evaluate(expression, context);
        return Boolean.TRUE.equals(result);
    }

    /**
     * 替换模板变量
     */
    private String replaceTemplateVariables(String template, Map<String, Object> context) {
        // 使用 Spring EL 或其他模板引擎替换变量
        // 例如: "Hello, ${user.name}" -> "Hello, 张三"
        return template; // 简化实现
    }
}
```

#### 5.15.4 事件发布机制

```java
/**
 * 事件发布服务
 */
@Service
public class EventPublisher {

    @Resource
    private EventFlowEngine eventFlowEngine;

    @Resource
    private ApplicationEventPublisher applicationEventPublisher;

    /**
     * 发布事件
     * @param eventName 事件名称
     * @param context 事件上下文
     */
    @Async
    public void publishEvent(String eventName, Map<String, Object> context) {
        try {
            // 1. 发布 Spring 事件（用于系统内部监听）
            applicationEventPublisher.publishEvent(new NocodeEvent(eventName, context));
            
            // 2. 执行事件流
            eventFlowEngine.executeEventFlow(eventName, context);
        } catch (Exception e) {
            log.error("事件发布失败: eventName={}, error={}", eventName, e.getMessage(), e);
        }
    }
}

/**
 * 无代码事件
 */
public class NocodeEvent extends ApplicationEvent {
    private final String eventName;
    private final Map<String, Object> context;
    
    public NocodeEvent(String eventName, Map<String, Object> context) {
        super(eventName);
        this.eventName = eventName;
        this.context = context;
    }
    
    public String getEventName() {
        return eventName;
    }
    
    public Map<String, Object> getContext() {
        return context;
    }
}
```

#### 5.15.5 内置事件定义

| 事件名称 | 触发时机 | 上下文参数 |
|---------|---------|-----------|
| `collection.beforeCreate` | 创建记录前 | collectionName, data |
| `collection.afterCreate` | 创建记录后 | collectionName, data, recordId |
| `collection.beforeUpdate` | 更新记录前 | collectionName, data, recordId |
| `collection.afterUpdate` | 更新记录后 | collectionName, data, recordId |
| `collection.beforeDelete` | 删除记录前 | collectionName, recordId |
| `collection.afterDelete` | 删除记录后 | collectionName, recordId |
| `workflow.beforeStart` | 工作流启动前 | workflowKey, context |
| `workflow.afterStart` | 工作流启动后 | workflowKey, instanceId, context |
| `workflow.beforeComplete` | 工作流完成前 | workflowKey, instanceId, context |
| `workflow.afterComplete` | 工作流完成后 | workflowKey, instanceId, context |
| `action.beforeExecute` | 自定义操作执行前 | actionId, recordId, params |
| `action.afterExecute` | 自定义操作执行后 | actionId, recordId, params, result |

#### 5.15.6 事件流可视化编辑器

对标 NocoBase 2.0 的事件流可视化编辑器，提供拖拽式配置界面。

##### 5.15.6.1 前端可视化编辑器组件

```typescript
// src/components/nocode/EventFlowEditor.vue
<template>
  <div class="event-flow-editor">
    <div class="editor-toolbar">
      <el-button @click="addFlow">
        <el-icon><Plus /></el-icon> 添加流程
      </el-button>
      <el-button @click="saveFlow">保存</el-button>
      <el-button @click="testFlow">测试执行</el-button>
    </div>
    
    <div class="flow-canvas">
      <!-- 事件节点 -->
      <div class="event-node">
        <div class="node-header">
          <el-icon><VideoPlay /></el-icon>
          <span>事件: {{ eventName }}</span>
        </div>
        <div class="node-hooks">
          <div class="hook-section">
            <div class="hook-label">前置钩子</div>
            <draggable 
              v-model="eventHooks.before" 
              item-key="id"
              class="hook-list"
            >
              <template #item="{ element }">
                <HookCard :hook="element" @edit="editHook(element)" />
              </template>
            </draggable>
            <el-button size="small" @click="addHook('before')">+ 添加钩子</el-button>
          </div>
        </div>
      </div>
      
      <!-- 流程列表 -->
      <div class="flows-container">
        <draggable 
          v-model="flows" 
          item-key="id"
          class="flow-list"
        >
          <template #item="{ element: flow }">
            <div class="flow-node">
              <div class="node-header">
                <el-icon><Operation /></el-icon>
                <span>流程: {{ flow.name }}</span>
                <el-switch v-model="flow.enabled" size="small" />
              </div>
              
              <!-- 流程条件 -->
              <div class="flow-condition" v-if="flow.conditions">
                <el-tag size="small">条件: {{ flow.conditions.expression }}</el-tag>
              </div>
              
              <!-- 流程钩子 -->
              <div class="node-hooks">
                <div class="hook-section">
                  <div class="hook-label">前置钩子</div>
                  <draggable 
                    v-model="flow.hooks.before" 
                    item-key="id"
                    class="hook-list"
                  >
                    <template #item="{ element }">
                      <HookCard :hook="element" @edit="editHook(element)" />
                    </template>
                  </draggable>
                  <el-button size="small" @click="addHook('before', flow)">+ 添加</el-button>
                </div>
              </div>
              
              <!-- 步骤列表 -->
              <div class="steps-container">
                <draggable 
                  v-model="flow.steps" 
                  item-key="id"
                  class="step-list"
                >
                  <template #item="{ element: step }">
                    <div class="step-node">
                      <div class="step-header">
                        <el-icon><ArrowRight /></el-icon>
                        <span>{{ step.name }}</span>
                        <el-tag size="small" type="info">{{ step.stepType }}</el-tag>
                      </div>
                      <div class="step-config">
                        <span v-if="step.stepType === 'script'">脚本执行</span>
                        <span v-else-if="step.stepType === 'http'">HTTP: {{ step.config.url }}</span>
                        <span v-else-if="step.stepType === 'workflow'">工作流: {{ step.config.workflowKey }}</span>
                      </div>
                      <div class="step-actions">
                        <el-button size="small" text @click="editStep(step)">编辑</el-button>
                        <el-button size="small" text type="danger" @click="removeStep(step)">删除</el-button>
                      </div>
                    </div>
                  </template>
                </draggable>
                <el-button @click="addStep(flow)">+ 添加步骤</el-button>
              </div>
              
              <!-- 流程后置钩子 -->
              <div class="node-hooks">
                <div class="hook-section">
                  <div class="hook-label">后置钩子</div>
                  <draggable 
                    v-model="flow.hooks.after" 
                    item-key="id"
                    class="hook-list"
                  >
                    <template #item="{ element }">
                      <HookCard :hook="element" @edit="editHook(element)" />
                    </template>
                  </draggable>
                  <el-button size="small" @click="addHook('after', flow)">+ 添加</el-button>
                </div>
              </div>
            </div>
          </template>
        </draggable>
      </div>
      
      <!-- 事件后置钩子 -->
      <div class="event-node">
        <div class="node-hooks">
          <div class="hook-section">
            <div class="hook-label">后置钩子</div>
            <draggable 
              v-model="eventHooks.after" 
              item-key="id"
              class="hook-list"
            >
              <template #item="{ element }">
                <HookCard :hook="element" @edit="editHook(element)" />
              </template>
            </draggable>
            <el-button size="small" @click="addHook('after')">+ 添加钩子</el-button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- 步骤编辑对话框 -->
    <el-dialog v-model="stepDialogVisible" title="编辑步骤" width="600px">
      <el-form :model="stepForm" label-width="100px">
        <el-form-item label="步骤名称" required>
          <el-input v-model="stepForm.name" />
        </el-form-item>
        <el-form-item label="步骤类型" required>
          <el-select v-model="stepForm.stepType">
            <el-option label="脚本执行" value="script" />
            <el-option label="HTTP 请求" value="http" />
            <el-option label="触发工作流" value="workflow" />
            <el-option label="条件分支" value="condition" />
          </el-select>
        </el-form-item>
        
        <!-- 脚本配置 -->
        <el-form-item v-if="stepForm.stepType === 'script'" label="脚本内容">
          <el-input 
            v-model="stepForm.config.script" 
            type="textarea" 
            rows="10"
            placeholder="JavaScript 脚本"
          />
        </el-form-item>
        
        <!-- HTTP 配置 -->
        <template v-if="stepForm.stepType === 'http'">
          <el-form-item label="请求方法">
            <el-select v-model="stepForm.config.method">
              <el-option label="GET" value="GET" />
              <el-option label="POST" value="POST" />
              <el-option label="PUT" value="PUT" />
              <el-option label="DELETE" value="DELETE" />
            </el-select>
          </el-form-item>
          <el-form-item label="请求 URL" required>
            <el-input v-model="stepForm.config.url" placeholder="https://api.example.com" />
          </el-form-item>
          <el-form-item label="请求头">
            <el-input 
              v-model="stepForm.config.headers" 
              type="textarea" 
              rows="3"
              placeholder='{"Content-Type": "application/json"}'
            />
          </el-form-item>
          <el-form-item label="请求体">
            <el-input 
              v-model="stepForm.config.body" 
              type="textarea" 
              rows="5"
              placeholder='{"key": "value"}'
            />
          </el-form-item>
        </template>
        
        <!-- 工作流配置 -->
        <el-form-item v-if="stepForm.stepType === 'workflow'" label="工作流 Key" required>
          <el-input v-model="stepForm.config.workflowKey" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="stepDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveStep">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import draggable from 'vuedraggable'
import HookCard from './HookCard.vue'

const props = defineProps<{
  eventName: string
}>()

const flows = ref<any[]>([])
const eventHooks = ref({
  before: [] as any[],
  after: [] as any[],
})

const stepDialogVisible = ref(false)
const stepForm = ref<any>({
  name: '',
  stepType: 'script',
  config: {},
})

const addFlow = () => {
  flows.value.push({
    id: Date.now(),
    name: `流程 ${flows.value.length + 1}`,
    enabled: true,
    conditions: null,
    hooks: { before: [], after: [] },
    steps: [],
  })
}

const addStep = (flow: any) => {
  stepForm.value = {
    name: '',
    stepType: 'script',
    config: {},
    flowId: flow.id,
  }
  stepDialogVisible.value = true
}

const saveStep = () => {
  const flow = flows.value.find(f => f.id === stepForm.value.flowId)
  if (flow) {
    flow.steps.push({
      id: Date.now(),
      ...stepForm.value,
    })
  }
  stepDialogVisible.value = false
}

const addHook = (position: 'before' | 'after', flow?: any) => {
  // 添加钩子逻辑
}

const saveFlow = () => {
  // 保存事件流配置
}

const testFlow = () => {
  // 测试执行事件流
}
</script>
```

#### 5.15.7 事件流执行日志追踪

##### 5.15.7.1 执行日志表设计

```sql
-- 事件流执行日志表
CREATE TABLE nocobase_event_flow_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    trace_id VARCHAR(64) NOT NULL COMMENT '追踪ID',
    event_name VARCHAR(100) NOT NULL COMMENT '事件名称',
    flow_id BIGINT COMMENT '流程ID',
    flow_name VARCHAR(100) COMMENT '流程名称',
    step_id BIGINT COMMENT '步骤ID',
    step_name VARCHAR(100) COMMENT '步骤名称',
    hook_id BIGINT COMMENT '钩子ID',
    execution_level VARCHAR(32) NOT NULL COMMENT '执行层级：event/flow/step/hook',
    execution_position VARCHAR(32) COMMENT '执行位置：before/run/after',
    status VARCHAR(32) NOT NULL COMMENT '执行状态：success/failed/skipped',
    start_time DATETIME NOT NULL COMMENT '开始时间',
    end_time DATETIME COMMENT '结束时间',
    duration_ms INT COMMENT '执行耗时(毫秒)',
    context_snapshot JSON COMMENT '上下文快照',
    error_message TEXT COMMENT '错误信息',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    
    INDEX idx_trace_id (trace_id),
    INDEX idx_event_name (event_name),
    INDEX idx_start_time (start_time),
    INDEX idx_tenant (tenant_id)
) COMMENT='事件流执行日志表';
```

##### 5.15.7.2 执行日志记录服务

```java
/**
 * 事件流执行日志记录服务
 */
@Service
public class EventFlowLogService {
    
    @Resource
    private EventFlowLogMapper logMapper;
    
    /**
     * 记录执行开始
     */
    public String logExecutionStart(String eventName, Long flowId, String flowName,
                                    Long stepId, String stepName, Long hookId,
                                    String executionLevel, String executionPosition,
                                    Map<String, Object> context) {
        String traceId = UUID.randomUUID().toString().replace("-", "");
        
        EventFlowLogDO log = new EventFlowLogDO();
        log.setTraceId(traceId);
        log.setEventName(eventName);
        log.setFlowId(flowId);
        log.setFlowName(flowName);
        log.setStepId(stepId);
        log.setStepName(stepName);
        log.setHookId(hookId);
        log.setExecutionLevel(executionLevel);
        log.setExecutionPosition(executionPosition);
        log.setStatus("running");
        log.setStartTime(LocalDateTime.now());
        log.setContextSnapshot(JSONUtil.toJsonStr(context));
        log.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        logMapper.insert(log);
        return traceId;
    }
    
    /**
     * 记录执行成功
     */
    public void logExecutionSuccess(String traceId) {
        EventFlowLogDO log = logMapper.selectByTraceId(traceId);
        if (log != null) {
            log.setStatus("success");
            log.setEndTime(LocalDateTime.now());
            log.setDurationMs(calculateDuration(log.getStartTime(), log.getEndTime()));
            logMapper.updateById(log);
        }
    }
    
    /**
     * 记录执行失败
     */
    public void logExecutionFailed(String traceId, String errorMessage) {
        EventFlowLogDO log = logMapper.selectByTraceId(traceId);
        if (log != null) {
            log.setStatus("failed");
            log.setEndTime(LocalDateTime.now());
            log.setDurationMs(calculateDuration(log.getStartTime(), log.getEndTime()));
            log.setErrorMessage(errorMessage);
            logMapper.updateById(log);
        }
    }
    
    /**
     * 查询执行日志
     */
    public List<EventFlowLogDO> getExecutionLogs(String eventName, LocalDateTime startTime, 
                                                  LocalDateTime endTime) {
        return logMapper.selectByEventNameAndTimeRange(eventName, startTime, endTime);
    }
    
    /**
     * 查询执行追踪链
     */
    public List<EventFlowLogDO> getExecutionTrace(String traceId) {
        return logMapper.selectByTraceId(traceId);
    }
    
    private long calculateDuration(LocalDateTime start, LocalDateTime end) {
        if (start == null || end == null) return 0;
        return Duration.between(start, end).toMillis();
    }
}
```

#### 5.15.8 失败重试机制

##### 5.15.8.1 重试配置表

```sql
-- 事件流重试配置表
CREATE TABLE nocobase_event_flow_retry_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    flow_id BIGINT NOT NULL COMMENT '流程ID',
    step_id BIGINT COMMENT '步骤ID（为空表示流程级重试）',
    max_retries INT DEFAULT 3 COMMENT '最大重试次数',
    retry_interval INT DEFAULT 5 COMMENT '重试间隔(秒)',
    retry_strategy VARCHAR(32) DEFAULT 'fixed' COMMENT '重试策略：fixed/exponential',
    retry_on_error_types JSON COMMENT '重试的错误类型列表',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    
    INDEX idx_flow_step (flow_id, step_id),
    INDEX idx_tenant (tenant_id)
) COMMENT='事件流重试配置表';

-- 事件流重试记录表
CREATE TABLE nocobase_event_flow_retry_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    trace_id VARCHAR(64) NOT NULL COMMENT '原始执行追踪ID',
    flow_id BIGINT NOT NULL COMMENT '流程ID',
    step_id BIGINT COMMENT '步骤ID',
    retry_count INT DEFAULT 0 COMMENT '当前重试次数',
    status VARCHAR(32) NOT NULL COMMENT '状态：pending/executing/success/failed',
    next_retry_time DATETIME COMMENT '下次重试时间',
    error_message TEXT COMMENT '错误信息',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    INDEX idx_trace_id (trace_id),
    INDEX idx_status_next_retry (status, next_retry_time),
    INDEX idx_tenant (tenant_id)
) COMMENT='事件流重试记录表';
```

##### 5.15.8.2 重试执行器

```java
/**
 * 事件流重试执行器
 */
@Service
public class EventFlowRetryExecutor {
    
    @Resource
    private EventFlowRetryConfigMapper retryConfigMapper;
    
    @Resource
    private EventFlowRetryLogMapper retryLogMapper;
    
    @Resource
    private EventFlowEngine eventFlowEngine;
    
    /**
     * 注册重试任务
     */
    public void registerRetry(String traceId, Long flowId, Long stepId, 
                              String errorMessage, Map<String, Object> context) {
        EventFlowRetryConfigDO config = retryConfigMapper.selectByFlowAndStep(flowId, stepId);
        if (config == null || !config.getEnabled()) {
            return;
        }
        
        EventFlowRetryLogDO retryLog = new EventFlowRetryLogDO();
        retryLog.setTraceId(traceId);
        retryLog.setFlowId(flowId);
        retryLog.setStepId(stepId);
        retryLog.setRetryCount(0);
        retryLog.setStatus("pending");
        retryLog.setErrorMessage(errorMessage);
        retryLog.setNextRetryTime(calculateNextRetryTime(0, config));
        retryLog.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        retryLogMapper.insert(retryLog);
    }
    
    /**
     * 执行重试任务（定时任务调用）
     */
    @Scheduled(fixedDelay = 5000)
    public void executeRetryTasks() {
        List<EventFlowRetryLogDO> pendingRetries = retryLogMapper.selectPendingRetries(
            LocalDateTime.now());
        
        for (EventFlowRetryLogDO retryLog : pendingRetries) {
            try {
                retryLog.setStatus("executing");
                retryLogMapper.updateById(retryLog);
                
                // 重新执行步骤
                eventFlowEngine.retryStep(retryLog.getTraceId(), retryLog.getStepId());
                
                retryLog.setStatus("success");
                retryLogMapper.updateById(retryLog);
                
            } catch (Exception e) {
                retryLog.setRetryCount(retryLog.getRetryCount() + 1);
                retryLog.setErrorMessage(e.getMessage());
                
                EventFlowRetryConfigDO config = retryConfigMapper.selectByFlowAndStep(
                    retryLog.getFlowId(), retryLog.getStepId());
                
                if (retryLog.getRetryCount() >= config.getMaxRetries()) {
                    retryLog.setStatus("failed");
                } else {
                    retryLog.setStatus("pending");
                    retryLog.setNextRetryTime(calculateNextRetryTime(
                        retryLog.getRetryCount(), config));
                }
                
                retryLogMapper.updateById(retryLog);
            }
        }
    }
    
    /**
     * 计算下次重试时间
     */
    private LocalDateTime calculateNextRetryTime(int retryCount, 
                                                 EventFlowRetryConfigDO config) {
        int interval = config.getRetryInterval();
        
        if ("exponential".equals(config.getRetryStrategy())) {
            // 指数退避：interval * 2^retryCount
            interval = interval * (int) Math.pow(2, retryCount);
        }
        
        return LocalDateTime.now().plusSeconds(interval);
    }
}
```

#### 5.15.9 AI 辅助事件流配置

##### 5.15.9.1 AI 事件流配置工具

```java
/**
 * AI 工具：配置事件流
 */
@Component
public class ConfigureEventFlowTool implements ToolCallback {
    
    @Resource
    private EventFlowMapper flowMapper;
    
    @Resource
    private EventFlowStepMapper stepMapper;
    
    @Override
    public String getName() {
        return "configure_event_flow";
    }
    
    @Override
    public String getDescription() {
        return "为事件配置处理流程，支持添加流程、步骤、钩子等";
    }
    
    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String eventName = args.getStr("eventName");
        String flowName = args.getStr("flowName");
        String conditions = args.getStr("conditions");
        JSONArray steps = args.getJSONArray("steps");
        
        // 创建流程
        EventFlowDO flow = new EventFlowDO();
        flow.setEventName(eventName);
        flow.setFlowName(flowName);
        flow.setFlowOrder(flowMapper.selectCountByEventName(eventName) + 1);
        flow.setConditions(conditions);
        flow.setEnabled(true);
        flow.setTenantId(SecurityFrameworkUtils.getTenantId());
        
        flowMapper.insert(flow);
        
        // 创建步骤
        if (steps != null) {
            for (int i = 0; i < steps.size(); i++) {
                JSONObject stepJson = steps.getJSONObject(i);
                
                EventFlowStepDO step = new EventFlowStepDO();
                step.setFlowId(flow.getId());
                step.setStepName(stepJson.getStr("stepName"));
                step.setStepOrder(i + 1);
                step.setStepType(stepJson.getStr("stepType"));
                step.setStepConfig(stepJson.getJSONObject("config").toString());
                step.setEnabled(true);
                step.setTenantId(SecurityFrameworkUtils.getTenantId());
                
                stepMapper.insert(step);
            }
        }
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true,
            "flowId", flow.getId(),
            "message", "事件流配置成功"
        ));
    }
}
```

##### 5.15.9.2 AI 对话示例

```
用户: 帮我配置一个事件流，当订单创建后，自动发送通知给管理员，并记录日志

AI: 好的，我来为您配置订单创建后的事件流。

[调用 configure_event_flow 工具]
{
  "eventName": "collection.afterCreate",
  "flowName": "订单创建后通知管理员",
  "conditions": "{\"expression\": \"collectionName == 'orders'\"}",
  "steps": [
    {
      "stepName": "发送通知",
      "stepType": "http",
      "config": {
        "url": "https://api.example.com/notify",
        "method": "POST",
        "body": "{\"message\": \"新订单已创建，订单ID: ${recordId}\"}"
      }
    },
    {
      "stepName": "记录日志",
      "stepType": "script",
      "config": {
        "script": "console.log('订单创建成功:', context.recordId);"
      }
    }
  ]
}

AI: 已成功配置事件流！当订单创建后，系统会自动：
1. 发送通知给管理员
2. 记录创建日志
```

---

### 5.16 数据源管理设计（对标 NocoBase Data Source）

NocoBase 支持多数据源管理，可以连接外部数据库作为数据源。

#### 5.16.1 数据源类型

| 数据源类型 | 说明 | 典型场景 |
|-----------|------|---------|
| **主数据源** | 系统内置数据库 | 默认数据存储 |
| **MySQL** | MySQL 数据库 | 连接外部 MySQL |
| **PostgreSQL** | PostgreSQL 数据库 | 连接外部 PG |
| **API** | RESTful API | 对接第三方系统 |
| **GraphQL** | GraphQL API | 对接 GraphQL 服务 |

#### 5.16.2 数据库表设计

```sql
-- 数据源配置表
CREATE TABLE nocobase_data_source (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    name VARCHAR(100) NOT NULL COMMENT '数据源名称',
    display_name VARCHAR(100) NOT NULL COMMENT '显示名称',
    data_source_type VARCHAR(32) NOT NULL COMMENT '数据源类型：primary/mysql/postgresql/api/graphql',
    config JSON NOT NULL COMMENT '数据源配置（JSON格式）',
    is_default TINYINT(1) DEFAULT 0 COMMENT '是否默认数据源',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    INDEX idx_name (name),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='数据源配置表';

-- 集合与数据源关联表
CREATE TABLE nocobase_collection_data_source (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    collection_name VARCHAR(100) NOT NULL COMMENT '集合名称',
    data_source_id BIGINT NOT NULL COMMENT '数据源ID',
    table_name VARCHAR(100) NOT NULL COMMENT '实际表名（外部数据源的表名）',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除',
    
    UNIQUE INDEX uk_collection_datasource (collection_name, data_source_id),
    INDEX idx_data_source (data_source_id),
    INDEX idx_tenant (tenant_id)
) COMMENT='集合与数据源关联表';
```

#### 5.16.3 数据源配置示例

```json
// MySQL 数据源配置
{
  "data_source_type": "mysql",
  "config": {
    "host": "192.168.1.100",
    "port": 3306,
    "database": "external_db",
    "username": "root",
    "password": "encrypted_password",
    "charset": "utf8mb4",
    "pool": {
      "min": 5,
      "max": 20
    }
  }
}

// API 数据源配置
{
  "data_source_type": "api",
  "config": {
    "base_url": "https://api.example.com",
    "auth_type": "bearer",
    "auth_config": {
      "token": "encrypted_token"
    },
    "headers": {
      "Content-Type": "application/json"
    },
    "timeout": 30000
  }
}

// GraphQL 数据源配置
{
  "data_source_type": "graphql",
  "config": {
    "endpoint": "https://graphql.example.com/graphql",
    "auth_type": "bearer",
    "auth_config": {
      "token": "encrypted_token"
    }
  }
}
```

#### 5.16.4 数据源管理器

```java
/**
 * 数据源管理器
 */
@Service
public class DataSourceManager {

    @Resource
    private DataSourceMapper dataSourceMapper;

    @Resource
    private CollectionDataSourceMapper collectionDataSourceMapper;

    @Resource
    private DataSourceFactory dataSourceFactory;

    // 数据源连接池缓存
    private final Map<Long, DataSource> dataSourceCache = new ConcurrentHashMap<>();

    /**
     * 获取数据源连接
     */
    public DataSource getDataSource(Long dataSourceId) {
        return dataSourceCache.computeIfAbsent(dataSourceId, id -> {
            DataSourceDO dataSource = dataSourceMapper.selectById(id);
            if (dataSource == null) {
                throw new ServiceException(ErrorCodeConstants.DATA_SOURCE_NOT_FOUND);
            }
            return dataSourceFactory.createDataSource(dataSource);
        });
    }

    /**
     * 获取集合对应的数据源
     */
    public DataSource getDataSourceByCollection(String collectionName) {
        CollectionDataSourceDO relation = collectionDataSourceMapper.selectByCollectionName(collectionName);
        if (relation == null) {
            // 使用默认数据源
            return getDefaultDataSource();
        }
        return getDataSource(relation.getDataSourceId());
    }

    /**
     * 获取默认数据源
     */
    public DataSource getDefaultDataSource() {
        DataSourceDO defaultDataSource = dataSourceMapper.selectDefault();
        if (defaultDataSource == null) {
            throw new ServiceException(ErrorCodeConstants.DEFAULT_DATA_SOURCE_NOT_FOUND);
        }
        return getDataSource(defaultDataSource.getId());
    }

    /**
     * 测试数据源连接
     */
    public boolean testConnection(Long dataSourceId) {
        try {
            DataSource dataSource = getDataSource(dataSourceId);
            try (Connection conn = dataSource.getConnection()) {
                return conn.isValid(5);
            }
        } catch (Exception e) {
            log.error("数据源连接测试失败: dataSourceId={}, error={}", dataSourceId, e.getMessage());
            return false;
        }
    }

    /**
     * 刷新数据源缓存
     */
    public void refreshDataSource(Long dataSourceId) {
        DataSource oldDataSource = dataSourceCache.remove(dataSourceId);
        if (oldDataSource != null) {
            try {
                ((HikariDataSource) oldDataSource).close();
            } catch (Exception e) {
                log.warn("关闭旧数据源失败: dataSourceId={}", dataSourceId);
            }
        }
    }
}

/**
 * 数据源工厂
 */
@Component
public class DataSourceFactory {

    /**
     * 创建数据源
     */
    public DataSource createDataSource(DataSourceDO dataSource) {
        String dataSourceType = dataSource.getDataSourceType();
        JSONObject config = JSONUtil.parseObj(dataSource.getConfig());
        
        switch (dataSourceType) {
            case "primary":
                return createPrimaryDataSource(config);
            case "mysql":
                return createMysqlDataSource(config);
            case "postgresql":
                return createPostgresqlDataSource(config);
            case "api":
                return createApiDataSource(config);
            case "graphql":
                return createGraphqlDataSource(config);
            default:
                throw new ServiceException(ErrorCodeConstants.UNSUPPORTED_DATA_SOURCE_TYPE);
        }
    }

    private DataSource createPrimaryDataSource(JSONObject config) {
        // 使用系统默认数据源配置
        return SpringUtil.getBean(DataSource.class);
    }

    private DataSource createMysqlDataSource(JSONObject config) {
        HikariConfig hikariConfig = new HikariConfig();
        hikariConfig.setJdbcUrl(String.format("jdbc:mysql://%s:%d/%s?useUnicode=true&characterEncoding=utf8&useSSL=false",
            config.getStr("host"),
            config.getInt("port", 3306),
            config.getStr("database")));
        hikariConfig.setUsername(config.getStr("username"));
        hikariConfig.setPassword(config.getStr("password"));
        hikariConfig.setDriverClassName("com.mysql.cj.jdbc.Driver");
        
        // 连接池配置
        JSONObject poolConfig = config.getJSONObject("pool");
        if (poolConfig != null) {
            hikariConfig.setMinimumIdle(poolConfig.getInt("min", 5));
            hikariConfig.setMaximumPoolSize(poolConfig.getInt("max", 20));
        }
        
        return new HikariDataSource(hikariConfig);
    }

    private DataSource createPostgresqlDataSource(JSONObject config) {
        HikariConfig hikariConfig = new HikariConfig();
        hikariConfig.setJdbcUrl(String.format("jdbc:postgresql://%s:%d/%s",
            config.getStr("host"),
            config.getInt("port", 5432),
            config.getStr("database")));
        hikariConfig.setUsername(config.getStr("username"));
        hikariConfig.setPassword(config.getStr("password"));
        hikariConfig.setDriverClassName("org.postgresql.Driver");
        
        return new HikariDataSource(hikariConfig);
    }

    private DataSource createApiDataSource(JSONObject config) {
        // API 数据源返回一个特殊的 DataSource 实现
        return new ApiDataSource(config);
    }

    private DataSource createGraphqlDataSource(JSONObject config) {
        // GraphQL 数据源返回一个特殊的 DataSource 实现
        return new GraphqlDataSource(config);
    }
}
```

#### 5.16.5 外部数据源查询服务

```java
/**
 * 外部数据源查询服务
 */
@Service
public class ExternalDataSourceService {

    @Resource
    private DataSourceManager dataSourceManager;

    @Resource
    private CollectionDataSourceMapper collectionDataSourceMapper;

    /**
     * 查询外部数据源数据
     */
    public List<Map<String, Object>> queryExternalData(String collectionName, DynamicQueryReq req) {
        CollectionDataSourceDO relation = collectionDataSourceMapper.selectByCollectionName(collectionName);
        if (relation == null) {
            throw new ServiceException(ErrorCodeConstants.COLLECTION_NOT_BIND_DATA_SOURCE);
        }
        
        DataSource dataSource = dataSourceManager.getDataSource(relation.getDataSourceId());
        String tableName = relation.getTableName();
        
        // 构建 SQL 查询
        SqlBuilder sqlBuilder = new SqlBuilder();
        sqlBuilder.select("*").from(tableName);
        
        // 添加过滤条件
        if (req.getFilters() != null && !req.getFilters().isEmpty()) {
            sqlBuilder.where(buildWhereClause(req.getFilters()));
        }
        
        // 添加排序
        if (req.getSort() != null && !req.getSort().isEmpty()) {
            sqlBuilder.orderBy(buildOrderByClause(req.getSort()));
        }
        
        // 添加分页
        if (req.getPageNo() != null && req.getPageSize() != null) {
            sqlBuilder.limit(req.getPageSize()).offset((req.getPageNo() - 1) * req.getPageSize());
        }
        
        // 执行查询
        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sqlBuilder.toSql())) {
            
            ResultSet rs = stmt.executeQuery();
            return convertResultSetToList(rs);
        } catch (SQLException e) {
            log.error("外部数据源查询失败: collectionName={}, error={}", collectionName, e.getMessage());
            throw new ServiceException(ErrorCodeConstants.EXTERNAL_DATA_SOURCE_QUERY_FAILED);
        }
    }

    /**
     * 转换 ResultSet 为 List
     */
    private List<Map<String, Object>> convertResultSetToList(ResultSet rs) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();
        
        while (rs.next()) {
            Map<String, Object> row = new HashMap<>();
            for (int i = 1; i <= columnCount; i++) {
                String columnName = metaData.getColumnName(i);
                Object value = rs.getObject(i);
                row.put(columnName, value);
            }
            list.add(row);
        }
        
        return list;
    }
}
```

---

### 5.7 工作流集成设计（FlowLong + 无代码）

#### 5.7.1 集成架构概述

无代码系统与 FlowLong 工作流引擎的集成采用松耦合架构，通过事件驱动机制实现数据操作与工作流的自动触发。

**核心集成点：**
1. **无代码页面触发工作流**：用户在无代码页面进行数据操作（创建/更新/删除）时，系统自动检查是否绑定了工作流，并触发相应的流程实例
2. **工作流节点操作无代码数据**：FlowLong 工作流节点可以通过自定义 TaskListener 或 ServiceTask 回调无代码系统的 DynamicDataService，实现数据的自动处理
3. **AI 对话创建工作流**：AI 可以通过 CreateWorkflowTool 直接创建 FlowLong 流程定义，并通过 BindWorkflowTool 将流程绑定到无代码 Collection 的事件上

**技术栈复用：**
- 复用现有的 `FlowHelper.getFlowCreator()` 获取流程发起人信息
- 复用 `FlowTaskActorProvider` 处理任务参与者分配逻辑
- 复用 `FlowTaskListener` 扩展点实现自定义工作流事件处理
- 基于 Spring Event 机制实现异步事件触发，避免阻塞主业务流程

#### 5.7.2 数据模型扩展

**1. Collection 表扩展**

在 `nocobase_collection` 表上增加工作流启用标记：

```sql
ALTER TABLE nocobase_collection 
ADD COLUMN workflow_enabled TINYINT(1) DEFAULT 0 COMMENT '是否启用工作流：0-否，1-是',
ADD COLUMN workflow_config JSON COMMENT '工作流配置（JSON格式，预留扩展）';
```

**2. 新增工作流绑定表**

创建 `nocobase_workflow_binding` 表，用于绑定 Collection 事件到 FlowLong 工作流：

```sql
CREATE TABLE nocobase_workflow_binding (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
    collection_name VARCHAR(100) NOT NULL COMMENT 'Collection名称',
    event_type VARCHAR(20) NOT NULL COMMENT '事件类型：CREATE/UPDATE/DELETE',
    process_id BIGINT NOT NULL COMMENT 'FlowLong流程定义ID',
    process_key VARCHAR(100) NOT NULL COMMENT 'FlowLong流程KEY',
    enabled TINYINT(1) DEFAULT 1 COMMENT '是否启用：0-禁用，1-启用',
    conditions JSON COMMENT '触发条件（JSON格式，支持字段值判断）',
    tenant_id BIGINT NOT NULL COMMENT '租户ID',
    creator VARCHAR(64) COMMENT '创建者',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updater VARCHAR(64) COMMENT '更新者',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted TINYINT(1) DEFAULT 0 COMMENT '逻辑删除：0-未删除，1-已删除',
    
    INDEX idx_collection_event (collection_name, event_type),
    INDEX idx_process (process_id),
    INDEX idx_tenant_enabled (tenant_id, enabled)
) COMMENT='无代码工作流绑定配置';
```

**表结构说明：**
- `collection_name`：关联的无代码 Collection 名称
- `event_type`：支持 CREATE（创建数据）、UPDATE（更新数据）、DELETE（删除数据）三种事件
- `process_id`：FlowLong 流程定义表 `flw_process` 的主键 ID
- `process_key`：FlowLong 流程定义的 KEY，用于快速查询
- `conditions`：JSON 格式的触发条件，例如 `{"field": "status", "operator": "eq", "value": "approved"}`，支持基于字段值的条件判断
- `enabled`：支持临时禁用绑定关系而不删除配置

#### 5.7.3 AI 工具设计

为支持 AI 通过对话创建工作流，设计以下三个核心工具：

**1. CreateWorkflowTool - 创建工作流**

```java
/**
 * AI 工具：创建 FlowLong 工作流
 * 
 * 功能：通过 AI 对话创建新的流程定义
 * 输入：流程名称、流程描述、流程节点配置（JSON）
 * 输出：创建成功的流程 ID
 */
@Component
public class CreateWorkflowTool implements ToolCallback {
    
    @Resource
    private IFlwProcessService flwProcessService;
    
    @Override
    public String getName() {
        return "create_workflow";
    }
    
    @Override
    public String getDescription() {
        return "创建一个新的工作流流程定义，返回流程ID";
    }
    
    @Override
    public String execute(String arguments) {
        // 解析参数
        JSONObject args = JSONUtil.parseObj(arguments);
        String processName = args.getStr("processName");
        String processKey = args.getStr("processKey");
        String modelContent = args.getStr("modelContent"); // JSON格式的流程模型
        
        // 构建流程定义 DTO
        FlwProcessDTO dto = new FlwProcessDTO();
        dto.setProcessName(processName);
        dto.setProcessKey(processKey);
        dto.setModelContent(modelContent);
        
        // 调用现有 Service 创建流程
        Long processId = flwProcessService.saveDto(dto);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true,
            "processId", processId,
            "message", "工作流创建成功"
        ));
    }
}
```

**2. BindWorkflowTool - 绑定工作流到 Collection 事件**

```java
/**
 * AI 工具：绑定工作流到 Collection 事件
 * 
 * 功能：将指定的 Collection 事件绑定到已有的工作流
 * 输入：Collection名称、事件类型、流程ID、触发条件（可选）
 * 输出：绑定成功信息
 */
@Component
public class BindWorkflowTool implements ToolCallback {
    
    @Resource
    private WorkflowBindingService workflowBindingService;
    
    @Override
    public String getName() {
        return "bind_workflow";
    }
    
    @Override
    public String getDescription() {
        return "将工作流绑定到 Collection 的指定事件（CREATE/UPDATE/DELETE）";
    }
    
    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String collectionName = args.getStr("collectionName");
        String eventType = args.getStr("eventType"); // CREATE/UPDATE/DELETE
        Long processId = args.getLong("processId");
        String conditions = args.getStr("conditions"); // 可选的触发条件
        
        // 创建绑定关系
        WorkflowBindingDO binding = new WorkflowBindingDO();
        binding.setCollectionName(collectionName);
        binding.setEventType(eventType);
        binding.setProcessId(processId);
        binding.setConditions(conditions);
        binding.setEnabled(true);
        
        Long bindingId = workflowBindingService.createBinding(binding);
        
        return JSONUtil.toJsonStr(Map.of(
            "success", true,
            "bindingId", bindingId,
            "message", "工作流绑定成功"
        ));
    }
}
```

**3. TriggerWorkflowTool - 手动触发工作流**

```java
/**
 * AI 工具：手动触发工作流
 * 
 * 功能：手动触发指定 Collection 数据的工作流
 * 输入：Collection名称、数据ID、事件类型
 * 输出：触发结果
 */
@Component
public class TriggerWorkflowTool implements ToolCallback {
    
    @Resource
    private WorkflowTriggerService workflowTriggerService;
    
    @Override
    public String getName() {
        return "trigger_workflow";
    }
    
    @Override
    public String getDescription() {
        return "手动触发指定数据的工作流实例";
    }
    
    @Override
    public String execute(String arguments) {
        JSONObject args = JSONUtil.parseObj(arguments);
        String collectionName = args.getStr("collectionName");
        Long dataId = args.getLong("dataId");
        String eventType = args.getStr("eventType");
        
        // 触发工作流
        boolean triggered = workflowTriggerService.triggerWorkflow(
            collectionName, dataId, eventType
        );
        
        return JSONUtil.toJsonStr(Map.of(
            "success", triggered,
            "message", triggered ? "工作流已触发" : "未找到匹配的工作流绑定"
        ));
    }
}
```

#### 5.7.4 事件触发机制

**1. DynamicDataService 扩展**

在 `DynamicDataServiceImpl` 的 CRUD 操作中注入工作流触发逻辑：

```java
@Service
public class DynamicDataServiceImpl implements DynamicDataService {
    
    @Resource
    private ApplicationEventPublisher applicationEventPublisher;
    
    @Resource
    private WorkflowBindingService workflowBindingService;
    
    @Override
    public Long createData(String collectionName, Map<String, Object> data) {
        // 1. 执行原有的数据创建逻辑
        Long dataId = doCreateData(collectionName, data);
        
        // 2. 发布工作流触发事件
        publishWorkflowEvent(collectionName, dataId, "CREATE", data);
        
        return dataId;
    }
    
    @Override
    public void updateData(String collectionName, Long id, Map<String, Object> data) {
        // 1. 执行原有的数据更新逻辑
        doUpdateData(collectionName, id, data);
        
        // 2. 发布工作流触发事件
        publishWorkflowEvent(collectionName, id, "UPDATE", data);
    }
    
    @Override
    public void deleteData(String collectionName, Long id) {
        // 1. 查询待删除数据（用于传递给工作流）
        Map<String, Object> data = doGetData(collectionName, id);
        
        // 2. 执行原有的数据删除逻辑
        doDeleteData(collectionName, id);
        
        // 3. 发布工作流触发事件
        publishWorkflowEvent(collectionName, id, "DELETE", data);
    }
    
    /**
     * 发布工作流触发事件
     */
    private void publishWorkflowEvent(String collectionName, Long dataId, 
                                      String eventType, Map<String, Object> data) {
        // 检查是否存在绑定的工作流
        List<WorkflowBindingDO> bindings = workflowBindingService.getEnabledBindings(
            collectionName, eventType
        );
        
        if (CollUtil.isNotEmpty(bindings)) {
            // 发布 Spring 事件，异步触发工作流
            WorkflowTriggerEvent event = new WorkflowTriggerEvent(
                this, collectionName, dataId, eventType, data, bindings
            );
            applicationEventPublisher.publishEvent(event);
        }
    }
}
```

**2. 工作流事件监听器**

```java
/**
 * 工作流事件监听器
 * 
 * 监听 Collection 数据变更事件，异步触发 FlowLong 工作流
 */
@Component
@Slf4j
public class WorkflowEventListener {
    
    @Resource
    private IFlwProcessService flwProcessService;
    
    @Resource
    private FlowLongEngine flowLongEngine;
    
    /**
     * 监听工作流触发事件
     */
    @Async
    @EventListener
    public void onWorkflowTrigger(WorkflowTriggerEvent event) {
        String collectionName = event.getCollectionName();
        Long dataId = event.getDataId();
        String eventType = event.getEventType();
        Map<String, Object> data = event.getData();
        List<WorkflowBindingDO> bindings = event.getBindings();
        
        for (WorkflowBindingDO binding : bindings) {
            try {
                // 1. 验证触发条件
                if (!matchConditions(data, binding.getConditions())) {
                    log.debug("数据不满足工作流触发条件，跳过: bindingId={}", binding.getId());
                    continue;
                }
                
                // 2. 获取流程定义
                FlwProcess process = flwProcessService.getById(binding.getProcessId());
                if (process == null || process.getProcessState() != 1) {
                    log.warn("工作流不存在或已禁用: processId={}", binding.getProcessId());
                    continue;
                }
                
                // 3. 构建流程发起人（使用系统管理员或数据创建者）
                FlowCreator flowCreator = FlowHelper.getFlowCreator();
                
                // 4. 准备流程变量
                Map<String, Object> variables = new HashMap<>();
                variables.put("collectionName", collectionName);
                variables.put("dataId", dataId);
                variables.put("eventType", eventType);
                variables.put("data", data);
                
                // 5. 启动流程实例
                ProcessStartDTO startDTO = new ProcessStartDTO();
                startDTO.setProcessId(binding.getProcessId());
                startDTO.setVariables(variables);
                
                FlwInstance instance = flwProcessService.launchProcess(startDTO, flowCreator);
                
                log.info("工作流触发成功: collectionName={}, dataId={}, processId={}, instanceId={}",
                    collectionName, dataId, binding.getProcessId(), instance.getId());
                    
            } catch (Exception e) {
                log.error("工作流触发失败: bindingId={}, error={}", binding.getId(), e.getMessage(), e);
                // 不抛出异常，避免影响主业务流程
            }
        }
    }
    
    /**
     * 验证数据是否满足触发条件
     */
    private boolean matchConditions(Map<String, Object> data, String conditionsJson) {
        if (StrUtil.isBlank(conditionsJson)) {
            return true; // 无条件，直接触发
        }
        
        try {
            JSONObject conditions = JSONUtil.parseObj(conditionsJson);
            String field = conditions.getStr("field");
            String operator = conditions.getStr("operator");
            Object expectedValue = conditions.get("value");
            
            Object actualValue = data.get(field);
            if (actualValue == null) {
                return false;
            }
            
            // 根据操作符判断
            switch (operator) {
                case "eq":
                    return Objects.equals(actualValue, expectedValue);
                case "neq":
                    return !Objects.equals(actualValue, expectedValue);
                case "gt":
                    return compareValues(actualValue, expectedValue) > 0;
                case "lt":
                    return compareValues(actualValue, expectedValue) < 0;
                case "contains":
                    return String.valueOf(actualValue).contains(String.valueOf(expectedValue));
                default:
                    return true;
            }
        } catch (Exception e) {
            log.warn("条件解析失败: {}", conditionsJson, e);
            return true; // 解析失败时默认触发
        }
    }
    
    private int compareValues(Object v1, Object v2) {
        if (v1 instanceof Number && v2 instanceof Number) {
            return Double.compare(((Number) v1).doubleValue(), ((Number) v2).doubleValue());
        }
        return String.valueOf(v1).compareTo(String.valueOf(v2));
    }
}
```

**3. 工作流触发事件定义**

```java
/**
 * 工作流触发事件
 */
public class WorkflowTriggerEvent extends ApplicationEvent {
    
    private final String collectionName;
    private final Long dataId;
    private final String eventType;
    private final Map<String, Object> data;
    private final List<WorkflowBindingDO> bindings;
    
    public WorkflowTriggerEvent(Object source, String collectionName, Long dataId,
                                String eventType, Map<String, Object> data,
                                List<WorkflowBindingDO> bindings) {
        super(source);
        this.collectionName = collectionName;
        this.dataId = dataId;
        this.eventType = eventType;
        this.data = data;
        this.bindings = bindings;
    }
    
    // Getters
    public String getCollectionName() { return collectionName; }
    public Long getDataId() { return dataId; }
    public String getEventType() { return eventType; }
    public Map<String, Object> getData() { return data; }
    public List<WorkflowBindingDO> getBindings() { return bindings; }
}
```

#### 5.7.5 关键代码示例

**1. WorkflowBindingService 接口**

```java
/**
 * 工作流绑定服务接口
 */
public interface WorkflowBindingService {
    
    /**
     * 创建绑定关系
     */
    Long createBinding(WorkflowBindingDO binding);
    
    /**
     * 更新绑定关系
     */
    void updateBinding(WorkflowBindingDO binding);
    
    /**
     * 删除绑定关系
     */
    void deleteBinding(Long id);
    
    /**
     * 获取指定 Collection 和事件的启用绑定
     */
    List<WorkflowBindingDO> getEnabledBindings(String collectionName, String eventType);
    
    /**
     * 获取指定流程的所有绑定
     */
    List<WorkflowBindingDO> getBindingsByProcessId(Long processId);
    
    /**
     * 启用/禁用绑定
     */
    void updateBindingEnabled(Long id, boolean enabled);
}
```

**2. WorkflowBindingServiceImpl 实现**

```java
@Service
public class WorkflowBindingServiceImpl implements WorkflowBindingService {
    
    @Resource
    private WorkflowBindingMapper workflowBindingMapper;
    
    @Override
    public Long createBinding(WorkflowBindingDO binding) {
        // 验证流程是否存在
        FlwProcess process = flwProcessService.getById(binding.getProcessId());
        if (process == null) {
            throw new ServiceException("工作流不存在");
        }
        
        // 设置 processKey
        binding.setProcessKey(process.getProcessKey());
        
        // 检查是否已存在相同的绑定
        LambdaQueryWrapper<WorkflowBindingDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(WorkflowBindingDO::getCollectionName, binding.getCollectionName())
               .eq(WorkflowBindingDO::getEventType, binding.getEventType())
               .eq(WorkflowBindingDO::getProcessId, binding.getProcessId());
        
        if (workflowBindingMapper.selectCount(wrapper) > 0) {
            throw new ServiceException("该 Collection 事件已绑定此工作流");
        }
        
        workflowBindingMapper.insert(binding);
        return binding.getId();
    }
    
    @Override
    public List<WorkflowBindingDO> getEnabledBindings(String collectionName, String eventType) {
        LambdaQueryWrapper<WorkflowBindingDO> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(WorkflowBindingDO::getCollectionName, collectionName)
               .eq(WorkflowBindingDO::getEventType, eventType)
               .eq(WorkflowBindingDO::getEnabled, true);
        
        return workflowBindingMapper.selectList(wrapper);
    }
    
    // 其他方法实现...
}
```

**3. 在 DynamicDataServiceImpl 中注入事件发布逻辑**

```java
@Service
public class DynamicDataServiceImpl implements DynamicDataService {
    
    @Resource
    private ApplicationEventPublisher applicationEventPublisher;
    
    @Resource
    private WorkflowBindingService workflowBindingService;
    
    @Resource
    private CollectionMapper collectionMapper;
    
    @Override
    public Long createData(String collectionName, Map<String, Object> data) {
        // 1. 验证 Collection 是否启用工作流
        NocobaseCollection collection = collectionMapper.selectByName(collectionName);
        if (collection == null || !collection.getWorkflowEnabled()) {
            return doCreateData(collectionName, data);
        }
        
        // 2. 执行数据创建
        Long dataId = doCreateData(collectionName, data);
        
        // 3. 发布工作流触发事件
        publishWorkflowEvent(collectionName, dataId, "CREATE", data);
        
        return dataId;
    }
    
    private void publishWorkflowEvent(String collectionName, Long dataId, 
                                      String eventType, Map<String, Object> data) {
        List<WorkflowBindingDO> bindings = workflowBindingService.getEnabledBindings(
            collectionName, eventType
        );
        
        if (CollUtil.isNotEmpty(bindings)) {
            WorkflowTriggerEvent event = new WorkflowTriggerEvent(
                this, collectionName, dataId, eventType, data, bindings
            );
            applicationEventPublisher.publishEvent(event);
        }
    }
}
```

#### 5.7.6 集成流程示例

**场景：客户审批流程**

1. **AI 创建工作流**
   ```
   用户：帮我创建一个客户审批流程，当新客户创建时需要经理审批
   AI：好的，我将为您创建客户审批流程...
   → 调用 CreateWorkflowTool 创建流程定义
   → 返回 processId = 1001
   ```

2. **AI 绑定工作流到 Collection**
   ```
   AI：现在我将此流程绑定到 customer 集合的创建事件...
   → 调用 BindWorkflowTool
   → collectionName = "customer"
   → eventType = "CREATE"
   → processId = 1001
   → conditions = {"field": "status", "operator": "eq", "value": "pending"}
   ```

3. **用户创建客户数据**
   ```
   用户在无代码页面创建新客户
   → DynamicDataService.createData() 执行
   → 检测到 customer 集合启用了工作流
   → 发布 WorkflowTriggerEvent
   → WorkflowEventListener 异步监听事件
   → 验证条件满足（status = pending）
   → 调用 FlowLong 启动流程实例
   → 流程进入经理审批节点
   ```

4. **经理审批**
   ```
   经理在审批中心看到待审批任务
   → 审批通过后，FlowLong 自动流转到下一节点
   → 可以通过 FlowTaskListener 扩展点回调更新客户状态
   ```

#### 5.7.7 扩展点设计

**1. 自定义工作流节点操作无代码数据**

通过 FlowLong 的 ServiceTask 节点类型，可以实现工作流节点自动操作无代码数据：

```java
/**
 * 无代码数据操作服务任务
 */
@Component
public class NocobaseDataServiceTask implements ServiceTaskHandler {
    
    @Resource
    private DynamicDataService dynamicDataService;
    
    @Override
    public void handle(Execution execution, NodeModel nodeModel) {
        Map<String, Object> variables = execution.getVariables();
        String collectionName = (String) variables.get("collectionName");
        Long dataId = (Long) variables.get("dataId");
        String action = (String) variables.get("action"); // update/approve/reject
        
        Map<String, Object> updateData = new HashMap<>();
        switch (action) {
            case "approve":
                updateData.put("status", "approved");
                break;
            case "reject":
                updateData.put("status", "rejected");
                break;
        }
        
        dynamicDataService.updateData(collectionName, dataId, updateData);
    }
}
```

**2. 工作流状态回调**

通过扩展 `FlowTaskListener`，可以在工作流状态变更时回调更新无代码数据：

```java
@Component
public class NocobaseWorkflowTaskListener extends FlowTaskListener {
    
    @Resource
    private DynamicDataService dynamicDataService;
    
    @Override
    public boolean notify(TaskEventType eventType, Supplier<FlwTask> supplier,
                         List<FlwTaskActor> taskActors, NodeModel nodeModel,
                         FlowCreator flowCreator) {
        boolean result = super.notify(eventType, supplier, taskActors, nodeModel, flowCreator);
        
        // 流程结束时更新无代码数据状态
        if (eventType == TaskEventType.finish || eventType == TaskEventType.terminate) {
            FlwTask task = supplier.get();
            FlwInstance instance = flowLongEngine.queryService().getInstance(task.getInstanceId());
            
            Map<String, Object> variables = instance.getVariables();
            String collectionName = (String) variables.get("collectionName");
            Long dataId = (Long) variables.get("dataId");
            
            Map<String, Object> updateData = new HashMap<>();
            updateData.put("workflowStatus", eventType == TaskEventType.finish ? "completed" : "terminated");
            updateData.put("workflowEndTime", LocalDateTime.now());
            
            dynamicDataService.updateData(collectionName, dataId, updateData);
        }
        
        return result;
    }
}
```

#### 5.7.8 性能与可靠性考虑

1. **异步处理**：使用 `@Async` 注解确保工作流触发不阻塞主业务操作
2. **事务隔离**：工作流触发在独立事务中执行，失败不影响数据操作
3. **重试机制**：对于触发失败的工作流，可以通过定时任务扫描重试
4. **条件缓存**：对常用的绑定关系和条件进行缓存，减少数据库查询
5. **批量触发**：当一次操作触发多个工作流时，使用批量启动减少数据库交互

---

## 六、AI 对话完整流程设计

### 6.1 对话流程

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. 用户输入                                                         │
│  "帮我创建一个客户管理系统，需要记录客户的基本信息、联系方式、           │
│   跟进记录，还要能看客户跟进的统计图表"                                 │
│                                                                      │
│  2. 后端构建 Prompt                                                   │
│  ┌────────────────────────────────────────────────────────┐          │
│  │ System Prompt:                                         │          │
│  │   你是一个业务系统搭建助手。                             │          │
│  │   [数据建模技能] [页面构建技能] [工作流技能]              │          │
│  │                                                         │          │
│  │ Context:                                                │          │
│  │   当前租户: xxx                                         │          │
│  │   已有集合: system_user, system_role, ...               │          │
│  │   已有页面: ...                                         │          │
│  │                                                         │          │
│  │ Tools:                                                  │          │
│  │   create_collection, add_field, create_page_schema,     │          │
│  │   create_workflow, query_data, ...                      │          │
│  │                                                         │          │
│  │ User Message:                                           │          │
│  │   帮我创建一个客户管理系统...                             │          │
│  └────────────────────────────────────────────────────────┘          │
│                                                                      │
│  3. LLM 分析并返回 tool_calls                                         │
│  [                                                                   │
│    { tool: "create_collection", params: {                            │
│      name: "crm_customer", displayName: "客户",                      │
│      fields: [                                                       │
│        { name: "customer_name", type: "string", displayName: "客户名称" },│
│        { name: "phone", type: "string", displayName: "电话" },       │
│        { name: "email", type: "string", displayName: "邮箱" },       │
│        { name: "status", type: "enum", displayName: "状态",          │
│          options: ["潜在客户","正式客户","流失客户"] },                │
│      ]                                                               │
│    }},                                                               │
│    { tool: "create_collection", params: {                            │
│      name: "crm_follow_up", displayName: "跟进记录",                 │
│      fields: [                                                       │
│        { name: "customer_id", type: "belongsTo", target: "crm_customer" },│
│        { name: "content", type: "text", displayName: "跟进内容" },   │
│        { name: "follow_time", type: "datetime", displayName: "跟进时间" },│
│        { name: "result", type: "enum", displayName: "跟进结果" },    │
│      ]                                                               │
│    }},                                                               │
│    { tool: "create_page_schema", params: {                           │
│      name: "客户列表", collectionName: "crm_customer",               │
│      pageType: "table", schema: { ... Formily Schema ... }           │
│    }},                                                               │
│    { tool: "create_page_schema", params: {                           │
│      name: "客户详情", collectionName: "crm_customer",               │
│      pageType: "detail", schema: { ... Formily Schema ... }          │
│    }},                                                               │
│    { tool: "create_page_schema", params: {                           │
│      name: "跟进记录列表", collectionName: "crm_follow_up",          │
│      pageType: "table", schema: { ... Formily Schema ... }           │
│    }},                                                               │
│  ]                                                                   │
│                                                                      │
│  4. 后端执行工具调用                                                   │
│  ✅ create_collection("crm_customer") → 创建集合 + 字段 + 物理表      │
│  ✅ create_collection("crm_follow_up") → 创建集合 + 字段 + 物理表     │
│  ✅ create_page_schema("客户列表") → 保存 Schema + 创建菜单           │
│  ✅ create_page_schema("客户详情") → 保存 Schema + 创建菜单           │
│  ✅ create_page_schema("跟进记录列表") → 保存 Schema + 创建菜单       │
│                                                                      │
│  5. LLM 生成回复                                                     │
│  "已为您创建客户管理系统，包含：                                       │
│   - 📊 客户数据表（客户名称、电话、邮箱、状态）                        │
│   - 📋 跟进记录表（关联客户、跟进内容、时间、结果）                    │
│   - 📄 客户列表页、客户详情页、跟进记录列表页                          │
│   - 📌 已添加到左侧菜单「客户管理」                                    │
│   您可以立即使用，也可以告诉我需要调整的地方。"                        │
│                                                                      │
│  6. 前端展示结果 + 操作入口                                           │
│  [查看客户列表] [查看客户详情] [修改页面] [继续对话]                   │
│                                                                      │
│  全程无代码生成、无编译、无部署！即时生效！                             │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.2 AI 生成的 Schema 示例

```json
{
  "type": "void",
  "x-component": "PageLayout",
  "properties": {
    "searchBar": {
      "type": "object",
      "x-component": "FilterBlock",
      "x-component-props": {
        "collection": "crm_customer"
      },
      "properties": {
        "customerName": {
          "type": "string",
          "title": "客户名称",
          "x-component": "Input",
          "x-component-props": { "placeholder": "请输入客户名称" }
        },
        "status": {
          "type": "string",
          "title": "状态",
          "x-component": "Select",
          "x-component-props": {
            "options": [
              { "label": "潜在客户", "value": "potential" },
              { "label": "正式客户", "value": "active" },
              { "label": "流失客户", "value": "lost" }
            ]
          }
        }
      }
    },
    "actionBar": {
      "type": "void",
      "x-component": "ActionBar",
      "properties": {
        "create": {
          "type": "void",
          "title": "新增客户",
          "x-component": "ActionButton",
          "x-component-props": {
            "action": "create",
            "collection": "crm_customer"
          }
        },
        "export": {
          "type": "void",
          "title": "导出",
          "x-component": "ActionButton",
          "x-component-props": { "action": "export" }
        }
      }
    },
    "table": {
      "type": "array",
      "x-component": "TableBlock",
      "x-component-props": {
        "collection": "crm_customer",
        "pagination": { "pageSize": 20 }
      },
      "properties": {
        "customerName": {
          "type": "string",
          "title": "客户名称",
          "x-component": "TableColumn",
          "x-component-props": { "sortable": true }
        },
        "phone": {
          "type": "string",
          "title": "电话",
          "x-component": "TableColumn"
        },
        "email": {
          "type": "string",
          "title": "邮箱",
          "x-component": "TableColumn"
        },
        "status": {
          "type": "string",
          "title": "状态",
          "x-component": "TableColumn",
          "x-component-props": { "dictType": "crm_customer_status" }
        },
        "actions": {
          "type": "void",
          "title": "操作",
          "x-component": "TableColumn",
          "properties": {
            "view": {
              "type": "void",
              "title": "查看",
              "x-component": "ActionButton",
              "x-component-props": { "action": "detail", "pageKey": "customer-detail" }
            },
            "edit": {
              "type": "void",
              "title": "编辑",
              "x-component": "ActionButton",
              "x-component-props": { "action": "edit" }
            },
            "delete": {
              "type": "void",
              "title": "删除",
              "x-component": "ActionButton",
              "x-component-props": { "action": "delete", "confirm": true }
            }
          }
        }
      }
    }
  }
}
```

---

## 七、实施路线图

### 7.1 阶段规划

| 阶段 | 目标 | 核心产出 | 前置条件 |
|------|------|---------|---------|
| **Phase 0** | 基础设施搭建 | Formily 集成 + 组件注册 + 动态路由 | 无 |
| **Phase 1** | 元数据 + 动态 API | Collection/Field 元数据 + 动态 CRUD API | Phase 0 |
| **Phase 2** | Schema 存储 + 渲染 | 页面 Schema 持久化 + SchemaRenderer | Phase 0+1 |
| **Phase 3** | 可视化设计器 | Designable 集成 + 拖拽配置页面 | Phase 0+2 |
| **Phase 4** | AI 接入 | LLM 集成 + 工具系统 + 对话界面 | Phase 1+2 |
| **Phase 5** | AI 员工 + 工作流 | AI 员工 + 工作流节点 | Phase 4 |

### 7.2 Phase 0 详细任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 1 | 安装 Formily 依赖 | `@formily/vue` `@formily/element-plus` `@formily/designable` |
| 2 | 创建组件注册表 | 注册所有 Element Plus 组件 + 自定义组件 |
| 3 | 实现 SchemaRenderer | 核心渲染组件 |
| 4 | 实现动态路由 | `/dynamic/:pageKey` 路由 |
| 5 | 实现 DynamicPage | 动态页面容器 |
| 6 | 实现 TableBlock | 表格区块（核心组件） |
| 7 | 实现 FormBlock | 表单区块（核心组件） |
| 8 | 实现 DetailBlock | 详情区块 |
| 9 | 实现 ActionBar | 操作栏组件 |
| 10 | 实现 ActionButton | 操作按钮组件 |

### 7.3 Phase 1 详细任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 1 | 创建 `nocobase_collection` 表 | 数据集合元数据 |
| 2 | 创建 `nocobase_field` 表 | 数据字段元数据 |
| 3 | 实现 CollectionService | 集合 CRUD |
| 4 | 实现 FieldService | 字段 CRUD |
| 5 | 实现 CollectionMetaCache | 元数据缓存 |
| 6 | 实现 DdlSyncService | 元数据 → 物理表同步 |
| 7 | 实现 DynamicDataController | 动态 API |
| 8 | 实现 DynamicDataService | 动态 SQL 构建 |
| 9 | 实现 SqlBuilder | SQL 构建器 |
| 10 | 集成数据权限 | 动态 API 的数据权限过滤 |

### 7.4 Phase 2 详细任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 1 | 创建 `nocobase_page_schema` 表 | Schema 存储 |
| 2 | 实现 PageSchemaService | Schema CRUD |
| 3 | 实现 SchemaValidator | Schema 格式校验 |
| 4 | 实现 useSchemaLoader | 前端 Schema 加载 Hook |
| 5 | SchemaRenderer 对接动态 API | 表格/表单自动绑定数据 |
| 6 | 实现 Schema 版本管理 | 支持回滚 |

### 7.5 Phase 4 详细任务

| 序号 | 任务 | 说明 |
|------|------|------|
| 1 | 创建 `nocobase_ai_employee` 表 | AI 员工 |
| 2 | 创建 `nocobase_ai_chat_message` 表 | 对话记录 |
| 3 | 实现 LlmClient | LLM 调用客户端 |
| 4 | 实现 ToolManager | 工具管理器 |
| 5 | 实现 CreateCollectionTool | 创建集合工具 |
| 6 | 实现 CreatePageSchemaTool | 创建页面工具 |
| 7 | 实现 AiChatService | 对话服务（含 Function Calling） |
| 8 | 实现 AiChatController | SSE 流式对话接口 |
| 9 | 编写 Skills | 数据建模/页面构建技能 |
| 10 | 实现前端 AiChat 组件 | 对话界面 |

---

## 八、现有代码迁移策略

### 8.1 迁移评估标准

**决策**：**渐进式迁移，不做大规模重构**

**评估维度**：
| 维度 | 评估标准 | 迁移优先级 |
|------|---------|-----------|
| **业务变化频率** | 需求变更频繁的页面 | 高优先级迁移 |
| **代码复杂度** | 超过 1000 行的 .vue 文件 | 中优先级迁移 |
| **复用价值** | 多个模块使用的通用功能 | 高优先级迁移 |
| **稳定性** | 已经稳定很少修改的页面 | 低优先级，保持现状 |
| **技术债务** | 存在明显问题的旧代码 | 视情况迁移 |

### 8.2 迁移优先级矩阵

```
                    高业务价值
                        │
            ┌───────────┼───────────┐
            │  优先迁移  │  立即迁移  │
            │ (Phase 3+) │ (Phase 2) │
            └───────────┼───────────┘
                        │
低复用价值 ─────────────┼───────────── 高复用价值
                        │
            ┌───────────┼───────────┐
            │  保持现状  │  择机迁移  │
            │  (不迁移)  │ (Phase 4+) │
            └───────────┼───────────┘
                        │
                    低业务价值
```

### 8.3 具体迁移策略

#### 8.3.1 不迁移的场景

**以下情况保持现状**：
1. **已稳定的核心模块**
   - 用户管理、角色权限、菜单管理等
   - 这些模块已经稳定，改动风险大于收益
   
2. **复杂业务逻辑页面**
   - 包含大量业务计算的页面
   - 与外部系统深度集成的页面
   
3. **性能敏感页面**
   - 大数据量展示页面（>10000 条）
   - 需要极致性能优化的场景

#### 8.3.2 优先迁移的场景

**以下情况优先迁移到无代码模式**：

1. **CRUD 类管理页面**
   ```
   现有代码：
   - UserView.vue (列表页)
   - UserForm.vue (表单页)
   - UserDetail.vue (详情页)
   
   迁移方案：
   - 创建 Collection: system_user
   - AI 生成 Schema: user-list, user-form, user-detail
   - 菜单指向 /dynamic/user-list
   ```

2. **配置类页面**
   ```
   现有代码：
   - DictView.vue (字典管理)
   - ConfigView.vue (系统配置)
   
   迁移方案：
   - 创建 Collection: system_dict, system_config
   - 使用 TableBlock + FormBlock 快速搭建
   ```

3. **报表类页面**
   ```
   现有代码：
   - ReportView.vue (统计报表)
   
   迁移方案：
   - 使用 ChartBlock + TableBlock
   - 数据源绑定动态 API
   ```

#### 8.3.3 迁移步骤

**标准迁移流程**：

```
1. 评估阶段
   ├─ 分析现有页面功能
   ├─ 识别数据模型（Collection）
   ├─ 识别页面结构（Schema）
   └─ 评估迁移工作量

2. 准备阶段
   ├─ 创建 Collection 元数据
   ├─ 定义字段和关联关系
   ├─ DDL 同步创建物理表
   └─ 数据迁移（如需要）

3. 实现阶段
   ├─ AI 生成页面 Schema
   ├─ 人工审查和调整 Schema
   ├─ 测试动态 API
   └─ 前端渲染验证

4. 切换阶段
   ├─ 新旧页面并存（A/B 测试）
   ├─ 收集用户反馈
   ├─ 逐步切换流量
   └─ 下线旧页面

5. 清理阶段
   ├─ 删除旧 .vue 文件
   ├─ 删除旧 API 接口
   └─ 更新文档
```

### 8.4 迁移风险控制

#### 8.4.1 技术风险

| 风险 | 控制措施 |
|------|---------|
| **数据丢失** | 迁移前完整备份；双写机制过渡 |
| **功能缺失** | 详细功能清单对比；逐项验收 |
| **性能下降** | 压力测试对比；优化动态 API 性能 |
| **用户体验退化** | UI/UX 对比测试；收集用户反馈 |

#### 8.4.2 业务风险

| 风险 | 控制措施 |
|------|---------|
| **业务中断** | 灰度发布；快速回滚机制 |
| **用户不适应** | 培训文档；过渡期双版本并存 |
| **数据不一致** | 数据校验脚本；对账机制 |

### 8.5 迁移示例：客户管理模块

**现有代码**：
```
src/views/crm/customer/
├── CustomerList.vue      (800 行)
├── CustomerForm.vue      (600 行)
├── CustomerDetail.vue    (500 行)
└── components/
    ├── CustomerSearch.vue
    └── CustomerTable.vue

src/api/crm/customer.ts   (200 行)
```

**迁移方案**：

1. **创建 Collection**
   ```json
   {
     "name": "crm_customer",
     "displayName": "客户",
     "fields": [
       { "name": "customer_name", "type": "string", "displayName": "客户名称" },
       { "name": "phone", "type": "string", "displayName": "电话" },
       { "name": "email", "type": "string", "displayName": "邮箱" },
       { "name": "status", "type": "enum", "displayName": "状态" }
     ]
   }
   ```

2. **AI 生成 Schema**
   ```
   AI 工具调用：
   - create_page_schema("customer-list", type="table")
   - create_page_schema("customer-form", type="form")
   - create_page_schema("customer-detail", type="detail")
   ```

3. **菜单切换**
   ```sql
   UPDATE system_menu 
   SET page_type = 'dynamic', page_key = 'customer-list'
   WHERE path = '/crm/customer';
   ```

4. **验证清单**
   - [ ] 列表查询功能正常
   - [ ] 新增客户功能正常
   - [ ] 编辑客户功能正常
   - [ ] 删除客户功能正常
   - [ ] 搜索筛选功能正常
   - [ ] 分页功能正常
   - [ ] 权限控制正常

### 8.6 迁移时间规划

| 阶段 | 时间 | 迁移目标 |
|------|------|---------|
| **Phase 0-2** | 第 1-2 月 | 不迁移，专注基础设施建设 |
| **Phase 3** | 第 3 月 | 试点迁移 1-2 个简单模块（字典管理） |
| **Phase 4** | 第 4-5 月 | 迁移 3-5 个 CRUD 模块 |
| **Phase 5+** | 第 6 月+ | 根据实际需求持续迁移 |

---

## 九、后端核心服务详细设计

### 9.1 CollectionService — 数据集合管理服务

```java
/**
 * 数据集合管理服务
 * 负责 Collection 和 Field 的 CRUD 操作
 */
@Service
public class CollectionServiceImpl implements CollectionService {
    
    @Autowired
    private CollectionMapper collectionMapper;
    
    @Autowired
    private FieldMapper fieldMapper;
    
    @Autowired
    private DdlSyncService ddlSyncService;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    /**
     * 创建 Collection
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public CollectionDO create(CreateCollectionReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 校验集合名唯一性
        CollectionDO existing = collectionMapper.selectByName(req.getName(), tenantId);
        if (existing != null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "集合名已存在");
        }
        
        // 2. 创建 Collection 记录
        CollectionDO collection = new CollectionDO();
        collection.setName(req.getName());
        collection.setDisplayName(req.getDisplayName());
        collection.setDescription(req.getDescription());
        collection.setTyping(req.getTyping() != null ? req.getTyping() : "business");
        collection.setTenantId(tenantId);
        collectionMapper.insert(collection);
        
        // 3. 创建 Field 记录
        if (req.getFields() != null) {
            for (CreateFieldReq fieldReq : req.getFields()) {
                FieldDO field = createFieldInternal(collection.getId(), fieldReq, tenantId);
                field.setTenantId(tenantId);
                fieldMapper.insert(field);
            }
        }
        
        // 4. 同步物理表（DDL）
        ddlSyncService.syncCollection(req.getName());
        
        // 5. 刷新缓存
        metaCache.refresh(req.getName());
        
        return collection;
    }
    
    /**
     * 添加字段
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public FieldDO addField(String collectionName, CreateFieldReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 获取 Collection
        CollectionDO collection = collectionMapper.selectByName(collectionName, tenantId);
        if (collection == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found");
        }
        
        // 2. 校验字段名唯一性
        FieldDO existing = fieldMapper.selectByCollectionIdAndName(collection.getId(), req.getName(), tenantId);
        if (existing != null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "字段名已存在");
        }
        
        // 3. 创建 Field 记录
        FieldDO field = createFieldInternal(collection.getId(), req, tenantId);
        fieldMapper.insert(field);
        
        // 4. 同步物理表（新增列）
        ddlSyncService.syncCollection(collectionName);
        
        // 5. 刷新缓存
        metaCache.refresh(collectionName);
        
        return field;
    }
    
    /**
     * 更新字段
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateField(String collectionName, String fieldName, UpdateFieldReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 获取 Collection
        CollectionDO collection = collectionMapper.selectByName(collectionName, tenantId);
        if (collection == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found");
        }
        
        // 2. 获取 Field
        FieldDO field = fieldMapper.selectByCollectionIdAndName(collection.getId(), fieldName, tenantId);
        if (field == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Field not found");
        }
        
        // 3. 更新 Field 记录
        if (req.getDisplayName() != null) {
            field.setDisplayName(req.getDisplayName());
        }
        if (req.getDescription() != null) {
            field.setDescription(req.getDescription());
        }
        if (req.getUiSchema() != null) {
            field.setUiSchema(req.getUiSchema());
        }
        if (req.getValidators() != null) {
            field.setValidators(req.getValidators());
        }
        fieldMapper.updateById(field);
        
        // 4. 刷新缓存（不需要 DDL 同步，因为只是元数据变更）
        metaCache.refresh(collectionName);
    }
    
    /**
     * 删除字段
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteField(String collectionName, String fieldName) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 获取 Collection
        CollectionDO collection = collectionMapper.selectByName(collectionName, tenantId);
        if (collection == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found");
        }
        
        // 2. 获取 Field
        FieldDO field = fieldMapper.selectByCollectionIdAndName(collection.getId(), fieldName, tenantId);
        if (field == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Field not found");
        }
        
        // 3. 逻辑删除 Field
        fieldMapper.deleteById(field.getId());
        
        // 4. TODO: 物理表删除列（可选，建议保留以避免数据丢失）
        
        // 5. 刷新缓存
        metaCache.refresh(collectionName);
    }
    
    /**
     * 删除 Collection
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(String collectionName) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 获取 Collection
        CollectionDO collection = collectionMapper.selectByName(collectionName, tenantId);
        if (collection == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Collection not found");
        }
        
        // 2. 逻辑删除 Collection
        collectionMapper.deleteById(collection.getId());
        
        // 3. 逻辑删除所有 Field
        fieldMapper.deleteByCollectionId(collection.getId());
        
        // 4. TODO: 物理表删除（可选，建议保留）
        
        // 5. 刷新缓存
        metaCache.refresh(collectionName);
    }
    
    /**
     * 内部方法：创建 Field 对象
     */
    private FieldDO createFieldInternal(Long collectionId, CreateFieldReq req, Long tenantId) {
        FieldDO field = new FieldDO();
        field.setCollectionId(collectionId);
        field.setName(req.getName());
        field.setDisplayName(req.getDisplayName());
        field.setDescription(req.getDescription());
        field.setFieldType(req.getFieldType());
        field.setDbType(req.getDbType() != null ? req.getDbType() : inferDbType(req.getFieldType()));
        field.setIsNullable(req.getIsNullable() != null ? req.getIsNullable() : 1);
        field.setIsUnique(req.getIsUnique() != null ? req.getIsUnique() : 0);
        field.setDefaultValue(req.getDefaultValue());
        field.setValidators(req.getValidators());
        field.setUiSchema(req.getUiSchema());
        field.setRelationConfig(req.getRelationConfig());
        field.setOptions(req.getOptions());
        field.setTenantId(tenantId);
        return field;
    }
    
    /**
     * 根据 field_type 推断 db_type
     */
    private String inferDbType(String fieldType) {
        switch (fieldType.toLowerCase()) {
            case "string": return "varchar(255)";
            case "text": return "text";
            case "integer": return "bigint";
            case "decimal": return "decimal(24,6)";
            case "boolean": return "tinyint";
            case "datetime": return "datetime";
            case "date": return "date";
            case "json": return "json";
            default: return "varchar(255)";
        }
    }
}
```

### 9.2 PageSchemaService — 页面 Schema 管理服务

```java
/**
 * 页面 Schema 管理服务
 * 负责 Schema 的 CRUD 和树形结构管理
 */
@Service
public class PageSchemaServiceImpl implements PageSchemaService {
    
    @Autowired
    private PageSchemaMapper pageSchemaMapper;
    
    @Autowired
    private SchemaValidator schemaValidator;
    
    /**
     * 创建页面 Schema
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public PageSchemaDO create(CreatePageSchemaReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 校验 Schema 格式
        schemaValidator.validate(req.getSchemaJson());
        
        // 2. 生成 UID
        String uid = UUID.randomUUID().toString();
        
        // 3. 创建 Schema 记录
        PageSchemaDO schema = new PageSchemaDO();
        schema.setUid(uid);
        schema.setName(req.getName());
        schema.setSchemaType(req.getSchemaType());
        schema.setParentUid(req.getParentUid());
        schema.setSchemaJson(req.getSchemaJson());
        schema.setCollectionName(req.getCollectionName());
        schema.setSort(req.getSort() != null ? req.getSort() : 0);
        schema.setTenantId(tenantId);
        pageSchemaMapper.insert(schema);
        
        // 4. 如果有子 Schema，递归创建
        if (req.getChildren() != null) {
            for (CreatePageSchemaReq child : req.getChildren()) {
                child.setParentUid(uid);
                create(child);
            }
        }
        
        return schema;
    }
    
    /**
     * 获取页面 Schema（包含子 Schema）
     */
    @Override
    public PageSchemaVO getPageSchema(String pageKey) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 查询根 Schema
        PageSchemaDO root = pageSchemaMapper.selectByUid(pageKey, tenantId);
        if (root == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Schema not found");
        }
        
        // 2. 递归查询子 Schema
        List<PageSchemaDO> children = pageSchemaMapper.selectByParentUid(pageKey, tenantId);
        
        // 3. 拼装完整 Schema
        return buildSchemaTree(root, children);
    }
    
    /**
     * 更新 Schema
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void update(String uid, UpdatePageSchemaReq req) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 查询 Schema
        PageSchemaDO schema = pageSchemaMapper.selectByUid(uid, tenantId);
        if (schema == null) {
            throw new BusinessException(ErrorCode.NOT_FOUND, "Schema not found");
        }
        
        // 2. 校验新 Schema 格式
        if (req.getSchemaJson() != null) {
            schemaValidator.validate(req.getSchemaJson());
            schema.setSchemaJson(req.getSchemaJson());
        }
        
        // 3. 更新
        if (req.getName() != null) {
            schema.setName(req.getName());
        }
        if (req.getSort() != null) {
            schema.setSort(req.getSort());
        }
        pageSchemaMapper.updateById(schema);
    }
    
    /**
     * 删除 Schema（级联删除子 Schema）
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(String uid) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        
        // 1. 查询所有子 Schema
        List<PageSchemaDO> children = pageSchemaMapper.selectByParentUid(uid, tenantId);
        
        // 2. 递归删除子 Schema
        for (PageSchemaDO child : children) {
            delete(child.getUid());
        }
        
        // 3. 删除当前 Schema
        pageSchemaMapper.deleteByUid(uid, tenantId);
    }
    
    /**
     * 构建 Schema 树
     */
    private PageSchemaVO buildSchemaTree(PageSchemaDO root, List<PageSchemaDO> allChildren) {
        PageSchemaVO vo = new PageSchemaVO();
        vo.setUid(root.getUid());
        vo.setName(root.getName());
        vo.setSchemaType(root.getSchemaType());
        vo.setSchemaJson(root.getSchemaJson());
        vo.setCollectionName(root.getCollectionName());
        
        // 找到直接子节点
        List<PageSchemaVO> children = allChildren.stream()
            .filter(c -> root.getUid().equals(c.getParentUid()))
            .map(c -> buildSchemaTree(c, allChildren))
            .sorted(Comparator.comparingInt(PageSchemaVO::getSort))
            .collect(Collectors.toList());
        
        if (!children.isEmpty()) {
            vo.setChildren(children);
        }
        
        return vo;
    }
}
```

### 9.3 SchemaValidator — Schema 格式校验服务

```java
/**
 * Schema 校验服务
 * 确保 Schema 符合 Formily JSON Schema 规范
 */
@Component
public class SchemaValidator {
    
    /**
     * 校验 Schema 格式
     */
    public void validate(Map<String, Object> schema) {
        if (schema == null || schema.isEmpty()) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Schema 不能为空");
        }
        
        // 1. 校验根节点
        validateNode(schema, "$");
        
        // 2. 递归校验子节点
        Map<String, Object> properties = getProperties(schema);
        if (properties != null) {
            for (Map.Entry<String, Object> entry : properties.entrySet()) {
                String path = "$." + entry.getKey();
                if (entry.getValue() instanceof Map) {
                    validateNode((Map<String, Object>) entry.getValue(), path);
                }
            }
        }
    }
    
    /**
     * 校验单个节点
     */
    private void validateNode(Map<String, Object> node, String path) {
        // 1. 必须有 type 或 x-component
        if (!node.containsKey("type") && !node.containsKey("x-component")) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, 
                path + " 必须包含 type 或 x-component");
        }
        
        // 2. 校验 x-component 是否在注册表中
        String component = (String) node.get("x-component");
        if (component != null && !isRegisteredComponent(component)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, 
                path + " 使用了未注册的组件: " + component);
        }
        
        // 3. 校验 x-decorator
        String decorator = (String) node.get("x-decorator");
        if (decorator != null && !isRegisteredComponent(decorator)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, 
                path + " 使用了未注册的装饰器: " + decorator);
        }
        
        // 4. 校验 x-reactions 格式（如果存在）
        if (node.containsKey("x-reactions")) {
            validateReactions(node.get("x-reactions"), path);
        }
        
        // 5. 校验 x-validator 格式（如果存在）
        if (node.containsKey("x-validator")) {
            validateValidators(node.get("x-validator"), path);
        }
    }
    
    /**
     * 校验组件是否已注册
     */
    private boolean isRegisteredComponent(String componentName) {
        // TODO: 从组件注册表中查询
        // 这里简化处理，实际应该从前端组件注册表同步一份到后端
        Set<String> registered = Set.of(
            "Input", "Select", "DatePicker", "TimePicker", "InputNumber",
            "Switch", "Checkbox", "Radio", "Upload", "Editor",
            "TableBlock", "FormBlock", "DetailBlock", "FilterBlock",
            "PageLayout", "CardLayout", "GridLayout",
            "ActionBar", "ActionButton",
            "FormItem", "FormLayout",
            "CollectionSelect", "DictSelect", "UserSelect", "DeptSelect"
        );
        return registered.contains(componentName);
    }
    
    /**
     * 校验 x-reactions 格式
     */
    private void validateReactions(Object reactions, String path) {
        // x-reactions 可以是字符串、数组或对象
        if (reactions instanceof String) {
            // 字符串形式： "{{ $self.value === 'xxx' }}"
            // 不做严格校验
        } else if (reactions instanceof List) {
            // 数组形式：多个 reaction
            List<?> list = (List<?>) reactions;
            for (int i = 0; i < list.size(); i++) {
                validateSingleReaction(list.get(i), path + ".x-reactions[" + i + "]");
            }
        } else if (reactions instanceof Map) {
            // 对象形式：单个 reaction
            validateSingleReaction(reactions, path + ".x-reactions");
        }
    }
    
    /**
     * 校验单个 reaction
     */
    private void validateSingleReaction(Object reaction, String path) {
        if (!(reaction instanceof Map)) {
            return;
        }
        Map<String, Object> map = (Map<String, Object>) reaction;
        
        // 必须有 dependencies 或 target
        if (!map.containsKey("dependencies") && !map.containsKey("target")) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, 
                path + " 必须包含 dependencies 或 target");
        }
    }
    
    /**
     * 校验 x-validator 格式
     */
    private void validateValidators(Object validators, String path) {
        // x-validator 可以是数组或对象
        if (validators instanceof List) {
            List<?> list = (List<?>) validators;
            for (int i = 0; i < list.size(); i++) {
                // 每个 validator 可以是字符串或对象
                Object validator = list.get(i);
                if (!(validator instanceof String) && !(validator instanceof Map)) {
                    throw new BusinessException(ErrorCode.BAD_REQUEST, 
                        path + ".x-validator[" + i + "] 格式错误");
                }
            }
        }
    }
    
    /**
     * 获取 properties
     */
    private Map<String, Object> getProperties(Map<String, Object> node) {
        Object props = node.get("properties");
        if (props instanceof Map) {
            return (Map<String, Object>) props;
        }
        return null;
    }
}
```

### 9.4 AI 对话服务完整实现

#### 9.4.1 LlmClient — LLM 调用客户端接口

```java
/**
 * LLM 客户端接口
 * 统一抽象层，支持多种 LLM 提供商
 */
public interface LlmClient {
    
    /**
     * 同步调用 LLM
     * @param request 请求参数
     * @return 响应结果
     */
    LlmResponse chat(LlmRequest request);
    
    /**
     * 流式调用 LLM（SSE）
     * @param request 请求参数
     * @param emitter SSE 发射器
     */
    void chatStream(LlmRequest request, SseEmitter emitter);
    
    /**
     * 获取模型名称
     */
    String getModelName();
}

/**
 * LLM 请求参数
 */
@Data
public class LlmRequest {
    private String model;
    private List<ChatMessage> messages;
    private List<ToolDefinition> tools;
    private Double temperature;
    private Integer maxTokens;
    private String responseFormat; // "text" | "json_object"
}

/**
 * 聊天消息
 */
@Data
public class ChatMessage {
    private String role; // "user" | "assistant" | "system" | "tool"
    private String content;
    private List<ToolCall> toolCalls;
    private String toolCallId;
}

/**
 * 工具调用
 */
@Data
public class ToolCall {
    private String id;
    private String type; // "function"
    private FunctionCall function;
}

@Data
public class FunctionCall {
    private String name;
    private String arguments; // JSON string
}

/**
 * LLM 响应
 */
@Data
public class LlmResponse {
    private String id;
    private String content;
    private List<ToolCall> toolCalls;
    private Usage usage;
    private String finishReason; // "stop" | "tool_calls"
}

@Data
public class Usage {
    private Integer promptTokens;
    private Integer completionTokens;
    private Integer totalTokens;
}
```

#### 9.4.2 OpenAiCompatibleClient — OpenAI 兼容实现

```java
/**
 * OpenAI 兼容协议的 LLM 客户端实现
 * 支持 DeepSeek、通义千问、OpenAI 等
 */
@Component
public class OpenAiCompatibleClient implements LlmClient {
    
    @Autowired
    private RestTemplate restTemplate;
    
    @Value("${ai.llm.default-provider}")
    private String defaultProvider;
    
    @Value("${ai.llm.providers}")
    private Map<String, LlmProviderConfig> providers;
    
    @Override
    public LlmResponse chat(LlmRequest request) {
        LlmProviderConfig config = providers.get(defaultProvider);
        
        // 构建 HTTP 请求
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(config.getApiKey());
        
        Map<String, Object> body = buildRequestBody(request, false);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        
        // 调用 API
        String url = config.getApiUrl() + "/chat/completions";
        ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
        
        // 解析响应
        return parseResponse(response.getBody());
    }
    
    @Override
    public void chatStream(LlmRequest request, SseEmitter emitter) {
        LlmProviderConfig config = providers.get(defaultProvider);
        
        // 构建 HTTP 请求
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(config.getApiKey());
        
        Map<String, Object> body = buildRequestBody(request, true);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        
        // 使用 WebClient 进行流式调用
        WebClient client = WebClient.builder()
            .baseUrl(config.getApiUrl())
            .defaultHeaders(h -> h.addAll(headers))
            .build();
        
        String url = "/chat/completions";
        client.post()
            .uri(url)
            .bodyValue(entity.getBody())
            .retrieve()
            .bodyToFlux(String.class)
            .doOnNext(chunk -> {
                // 解析 SSE 数据
                if (chunk.startsWith("data: ")) {
                    String data = chunk.substring(6);
                    if (!"[DONE]".equals(data)) {
                        try {
                            Map<String, Object> parsed = JSON.parseObject(data, Map.class);
                            emitter.send(SseEmitter.event().data(parsed));
                        } catch (Exception e) {
                            // 忽略解析错误
                        }
                    } else {
                        try {
                            emitter.complete();
                        } catch (Exception e) {
                            // 忽略
                        }
                    }
                }
            })
            .doOnError(emitter::completeWithError)
            .subscribe();
    }
    
    @Override
    public String getModelName() {
        LlmProviderConfig config = providers.get(defaultProvider);
        return config.getModel();
    }
    
    private Map<String, Object> buildRequestBody(LlmRequest request, boolean stream) {
        Map<String, Object> body = new HashMap<>();
        body.put("model", request.getModel() != null ? request.getModel() : getModelName());
        body.put("messages", request.getMessages());
        body.put("stream", stream);
        
        if (request.getTools() != null && !request.getTools().isEmpty()) {
            body.put("tools", request.getTools());
        }
        if (request.getTemperature() != null) {
            body.put("temperature", request.getTemperature());
        }
        if (request.getMaxTokens() != null) {
            body.put("max_tokens", request.getMaxTokens());
        }
        if (request.getResponseFormat() != null) {
            body.put("response_format", Map.of("type", request.getResponseFormat()));
        }
        
        return body;
    }
    
    private LlmResponse parseResponse(Map responseBody) {
        LlmResponse response = new LlmResponse();
        response.setId((String) responseBody.get("id"));
        
        Map choices = (Map) ((List) responseBody.get("choices")).get(0);
        Map message = (Map) choices.get("message");
        
        response.setContent((String) message.get("content"));
        response.setFinishReason((String) choices.get("finish_reason"));
        
        if (message.containsKey("tool_calls")) {
            List<Map> toolCallsList = (List<Map>) message.get("tool_calls");
            response.setToolCalls(toolCallsList.stream().map(tc -> {
                ToolCall toolCall = new ToolCall();
                toolCall.setId((String) tc.get("id"));
                toolCall.setType((String) tc.get("type"));
                
                Map function = (Map) tc.get("function");
                FunctionCall functionCall = new FunctionCall();
                functionCall.setName((String) function.get("name"));
                functionCall.setArguments((String) function.get("arguments"));
                toolCall.setFunction(functionCall);
                
                return toolCall;
            }).collect(Collectors.toList()));
        }
        
        Map usage = (Map) responseBody.get("usage");
        if (usage != null) {
            Usage usageObj = new Usage();
            usageObj.setPromptTokens((Integer) usage.get("prompt_tokens"));
            usageObj.setCompletionTokens((Integer) usage.get("completion_tokens"));
            usageObj.setTotalTokens((Integer) usage.get("total_tokens"));
            response.setUsage(usageObj);
        }
        
        return response;
    }
}

@Data
public class LlmProviderConfig {
    private String apiUrl;
    private String apiKey;
    private String model;
}
```

#### 9.4.3 AiChatService — AI 对话服务

```java
/**
 * AI 对话服务
 * 处理用户对话、工具调用、上下文管理
 */
@Service
public class AiChatServiceImpl implements AiChatService {
    
    @Autowired
    private LlmClient llmClient;
    
    @Autowired
    private ToolManager toolManager;
    
    @Autowired
    private SkillManager skillManager;
    
    @Autowired
    private AiChatMessageMapper messageMapper;
    
    @Autowired
    private AiEmployeeMapper employeeMapper;
    
    /**
     * 同步对话
     */
    @Override
    public AiChatResponse chat(AiChatRequest request) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 获取或创建会话
        String sessionId = request.getSessionId();
        if (sessionId == null) {
            sessionId = UUID.randomUUID().toString();
        }
        
        // 2. 加载历史消息
        List<ChatMessage> messages = loadChatHistory(sessionId, tenantId);
        
        // 3. 添加用户消息
        ChatMessage userMessage = new ChatMessage();
        userMessage.setRole("user");
        userMessage.setContent(request.getMessage());
        messages.add(userMessage);
        
        // 4. 保存用户消息
        saveMessage(sessionId, userId, "user", request.getMessage(), null, tenantId);
        
        // 5. 构建 LLM 请求
        LlmRequest llmRequest = new LlmRequest();
        llmRequest.setMessages(messages);
        llmRequest.setTools(toolManager.getAllToolDefinitions());
        llmRequest.setTemperature(0.7);
        
        // 6. 如果有 AI 员工，加载系统提示词和技能
        if (request.getEmployeeId() != null) {
            AiEmployeeDO employee = employeeMapper.selectById(request.getEmployeeId());
            if (employee != null) {
                String systemPrompt = buildSystemPrompt(employee, tenantId);
                messages.add(0, createSystemMessage(systemPrompt));
            }
        }
        
        // 7. 调用 LLM
        LlmResponse llmResponse = llmClient.chat(llmRequest);
        
        // 8. 处理工具调用
        if (llmResponse.getToolCalls() != null && !llmResponse.getToolCalls().isEmpty()) {
            return handleToolCalls(sessionId, userId, messages, llmResponse, tenantId);
        }
        
        // 9. 保存助手消息
        saveMessage(sessionId, userId, "assistant", llmResponse.getContent(), null, tenantId);
        
        // 10. 构建响应
        AiChatResponse response = new AiChatResponse();
        response.setSessionId(sessionId);
        response.setMessage(llmResponse.getContent());
        response.setToolResults(null);
        
        return response;
    }
    
    /**
     * 流式对话（SSE）
     */
    @Override
    public void chatStream(AiChatRequest request, SseEmitter emitter) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        Long userId = SecurityFrameworkUtils.getLoginUserId();
        
        // 1. 获取或创建会话
        String sessionId = request.getSessionId();
        if (sessionId == null) {
            sessionId = UUID.randomUUID().toString();
        }
        
        // 2. 加载历史消息
        List<ChatMessage> messages = loadChatHistory(sessionId, tenantId);
        
        // 3. 添加用户消息
        ChatMessage userMessage = new ChatMessage();
        userMessage.setRole("user");
        userMessage.setContent(request.getMessage());
        messages.add(userMessage);
        
        // 4. 保存用户消息
        saveMessage(sessionId, userId, "user", request.getMessage(), null, tenantId);
        
        // 5. 构建 LLM 请求
        LlmRequest llmRequest = new LlmRequest();
        llmRequest.setMessages(messages);
        llmRequest.setTools(toolManager.getAllToolDefinitions());
        llmRequest.setTemperature(0.7);
        
        // 6. 如果有 AI 员工，加载系统提示词和技能
        if (request.getEmployeeId() != null) {
            AiEmployeeDO employee = employeeMapper.selectById(request.getEmployeeId());
            if (employee != null) {
                String systemPrompt = buildSystemPrompt(employee, tenantId);
                messages.add(0, createSystemMessage(systemPrompt));
            }
        }
        
        // 7. 发送会话 ID
        try {
            emitter.send(SseEmitter.event().name("session").data(Map.of("sessionId", sessionId)));
        } catch (IOException e) {
            // 忽略
        }
        
        // 8. 调用 LLM 流式接口
        llmClient.chatStream(llmRequest, emitter);
    }
    
    /**
     * 处理工具调用
     */
    private AiChatResponse handleToolCalls(
        String sessionId,
        Long userId,
        List<ChatMessage> messages,
        LlmResponse llmResponse,
        Long tenantId
    ) {
        // 1. 保存助手消息（包含工具调用）
        saveMessage(sessionId, userId, "assistant", llmResponse.getContent(), 
            JSON.toJSONString(llmResponse.getToolCalls()), tenantId);
        
        // 2. 执行工具调用
        List<ToolResult> toolResults = new ArrayList<>();
        for (ToolCall toolCall : llmResponse.getToolCalls()) {
            ToolResult result = executeToolCall(toolCall, tenantId);
            toolResults.add(result);
            
            // 添加工具结果到消息列表
            ChatMessage toolMessage = new ChatMessage();
            toolMessage.setRole("tool");
            toolMessage.setToolCallId(toolCall.getId());
            toolMessage.setContent(JSON.toJSONString(result));
            messages.add(toolMessage);
            
            // 保存工具结果
            saveMessage(sessionId, userId, "tool", JSON.toJSONString(result), 
                toolCall.getId(), tenantId);
        }
        
        // 3. 再次调用 LLM 生成最终回复
        LlmRequest finalRequest = new LlmRequest();
        finalRequest.setMessages(messages);
        LlmResponse finalResponse = llmClient.chat(finalRequest);
        
        // 4. 保存最终助手消息
        saveMessage(sessionId, userId, "assistant", finalResponse.getContent(), null, tenantId);
        
        // 5. 构建响应
        AiChatResponse response = new AiChatResponse();
        response.setSessionId(sessionId);
        response.setMessage(finalResponse.getContent());
        response.setToolResults(toolResults);
        
        return response;
    }
    
    /**
     * 执行工具调用
     */
    private ToolResult executeToolCall(ToolCall toolCall, Long tenantId) {
        String toolName = toolCall.getFunction().getName();
        String arguments = toolCall.getFunction().getArguments();
        
        try {
            // 解析参数
            Map<String, Object> params = JSON.parseObject(arguments, Map.class);
            
            // 获取工具实例
            AiTool tool = toolManager.getTool(toolName);
            if (tool == null) {
                return ToolResult.error("工具不存在: " + toolName);
            }
            
            // 构建上下文
            ToolContext context = new ToolContext();
            context.setTenantId(tenantId);
            context.setUserId(SecurityFrameworkUtils.getLoginUserId());
            
            // 执行工具
            return tool.execute(params, context);
        } catch (Exception e) {
            return ToolResult.error("工具执行失败: " + e.getMessage());
        }
    }
    
    /**
     * 加载聊天历史
     */
    private List<ChatMessage> loadChatHistory(String sessionId, Long tenantId) {
        List<AiChatMessageDO> messages = messageMapper.selectBySessionId(sessionId, tenantId);
        
        return messages.stream().map(msg -> {
            ChatMessage chatMessage = new ChatMessage();
            chatMessage.setRole(msg.getRole());
            chatMessage.setContent(msg.getContent());
            
            if (msg.getToolCalls() != null) {
                chatMessage.setToolCalls(JSON.parseArray(msg.getToolCalls(), ToolCall.class));
            }
            if (msg.getToolCallId() != null) {
                chatMessage.setToolCallId(msg.getToolCallId());
            }
            
            return chatMessage;
        }).collect(Collectors.toList());
    }
    
    /**
     * 保存消息
     */
    private void saveMessage(String sessionId, Long userId, String role, 
                            String content, String toolCalls, Long tenantId) {
        AiChatMessageDO message = new AiChatMessageDO();
        message.setSessionId(sessionId);
        message.setRole(role);
        message.setContent(content);
        message.setToolCalls(toolCalls);
        message.setTenantId(tenantId);
        message.setCreator(userId.toString());
        messageMapper.insert(message);
    }
    
    /**
     * 构建系统提示词
     */
    private String buildSystemPrompt(AiEmployeeDO employee, Long tenantId) {
        StringBuilder prompt = new StringBuilder();
        
        // 基础提示词
        prompt.append("你是一个业务系统搭建助手。\n\n");
        
        // 员工自定义提示词
        if (employee.getSystemPrompt() != null) {
            prompt.append(employee.getSystemPrompt()).append("\n\n");
        }
        
        // 加载技能
        if (employee.getSkills() != null) {
            List<String> skillNames = JSON.parseArray(employee.getSkills(), String.class);
            for (String skillName : skillNames) {
                SkillDefinition skill = skillManager.getSkill(skillName);
                if (skill != null) {
                    prompt.append(skill.getContent()).append("\n\n");
                }
            }
        }
        
        // 添加上下文信息
        prompt.append("## 当前上下文\n");
        prompt.append("- 租户ID: ").append(tenantId).append("\n");
        
        // 加载已有的 Collection 列表
        List<CollectionDO> collections = collectionMapper.selectByTenantId(tenantId);
        if (!collections.isEmpty()) {
            prompt.append("- 已有数据集合: ");
            prompt.append(collections.stream()
                .map(CollectionDO::getName)
                .collect(Collectors.joining(", ")));
            prompt.append("\n");
        }
        
        return prompt.toString();
    }
    
    private ChatMessage createSystemMessage(String content) {
        ChatMessage message = new ChatMessage();
        message.setRole("system");
        message.setContent(content);
        return message;
    }
}

@Data
public class AiChatRequest {
    private String sessionId;
    private String message;
    private Long employeeId;
}

@Data
public class AiChatResponse {
    private String sessionId;
    private String message;
    private List<ToolResult> toolResults;
}
```

#### 9.4.4 AiChatController — AI 对话接口

```java
/**
 * AI 对话控制器
 * 提供同步和流式对话接口
 */
@RestController
@RequestMapping("/admin/ai/chat")
public class AiChatController {
    
    @Autowired
    private AiChatService aiChatService;
    
    /**
     * 同步对话
     */
    @PostMapping("/sync")
    public CommonResult<AiChatResponse> chat(@RequestBody AiChatRequest request) {
        AiChatResponse response = aiChatService.chat(request);
        return CommonResult.success(response);
    }
    
    /**
     * 流式对话（SSE）
     */
    @PostMapping("/stream")
    public SseEmitter chatStream(@RequestBody AiChatRequest request) {
        SseEmitter emitter = new SseEmitter(60000L); // 60秒超时
        
        // 异步执行
        CompletableFuture.runAsync(() -> {
            try {
                aiChatService.chatStream(request, emitter);
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
        });
        
        return emitter;
    }
}
```

---

### 9.5 性能优化设计

#### 9.5.1 元数据缓存策略

```java
/**
 * 集合元数据缓存
 * 对标 NocoBase 的 Collection Manager 缓存机制
 */
@Component
public class CollectionMetaCache {
    
    @Autowired
    private CollectionMapper collectionMapper;
    
    @Autowired
    private FieldMapper fieldMapper;
    
    // 使用 Caffeine 本地缓存，TTL 5分钟
    private final Cache<String, CollectionMeta> cache = Caffeine.newBuilder()
        .maximumSize(1000)
        .expireAfterWrite(5, TimeUnit.MINUTES)
        .build();
    
    /**
     * 获取集合元数据（带缓存）
     */
    public CollectionMeta get(String collectionName) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        String cacheKey = buildCacheKey(collectionName, tenantId);
        
        return cache.get(cacheKey, key -> {
            // 缓存未命中，从数据库加载
            CollectionDO collection = collectionMapper.selectByName(collectionName, tenantId);
            if (collection == null) {
                throw new BusinessException(ErrorCode.NOT_FOUND, "集合不存在: " + collectionName);
            }
            
            List<FieldDO> fields = fieldMapper.selectByCollectionId(collection.getId());
            
            return CollectionMeta.from(collection, fields);
        });
    }
    
    /**
     * 刷新缓存（元数据变更时调用）
     */
    public void refresh(String collectionName) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        String cacheKey = buildCacheKey(collectionName, tenantId);
        cache.invalidate(cacheKey);
    }
    
    /**
     * 批量刷新缓存
     */
    public void refreshAll(Long tenantId) {
        cache.invalidateAll();
    }
    
    private String buildCacheKey(String collectionName, Long tenantId) {
        return tenantId + ":" + collectionName;
    }
}

/**
 * 集合元数据（缓存对象）
 */
@Data
public class CollectionMeta {
    private Long id;
    private String name;
    private String tableName;
    private String displayName;
    private Map<String, FieldMeta> fields; // fieldName -> FieldMeta
    
    public static CollectionMeta from(CollectionDO collection, List<FieldDO> fields) {
        CollectionMeta meta = new CollectionMeta();
        meta.setId(collection.getId());
        meta.setName(collection.getName());
        meta.setTableName(collection.getName()); // 表名与集合名相同
        meta.setDisplayName(collection.getDisplayName());
        
        Map<String, FieldMeta> fieldMap = new HashMap<>();
        for (FieldDO field : fields) {
            FieldMeta fieldMeta = FieldMeta.from(field);
            fieldMap.put(field.getName(), fieldMeta);
        }
        meta.setFields(fieldMap);
        
        return meta;
    }
    
    public FieldMeta getField(String fieldName) {
        return fields.get(fieldName);
    }
    
    public List<String> getFieldNames() {
        return new ArrayList<>(fields.keySet());
    }
}

/**
 * 字段元数据
 */
@Data
public class FieldMeta {
    private Long id;
    private String name;
    private String displayName;
    private String fieldType; // string/number/belongsTo/hasMany...
    private String dbType;   // varchar/bigint/datetime...
    private boolean nullable;
    private boolean primaryKey;
    private Object defaultValue;
    private AssociationFieldMeta associationMeta; // 关联字段专用
    
    public static FieldMeta from(FieldDO field) {
        FieldMeta meta = new FieldMeta();
        meta.setId(field.getId());
        meta.setName(field.getName());
        meta.setDisplayName(field.getDisplayName());
        meta.setFieldType(field.getFieldType());
        meta.setDbType(field.getDbType());
        meta.setNullable(field.getIsNullable() == 1);
        meta.setPrimaryKey(field.getIsPrimaryKey() == 1);
        meta.setDefaultValue(field.getDefaultValue());
        
        // 解析关联配置
        if (isAssociationType(field.getFieldType()) && field.getRelationConfig() != null) {
            meta.setAssociationMeta(JSON.parseObject(field.getRelationConfig(), AssociationFieldMeta.class));
        }
        
        return meta;
    }
    
    public boolean isAssociation() {
        return "belongsTo".equals(fieldType) || "hasMany".equals(fieldType) ||
               "hasOne".equals(fieldType) || "belongsToMany".equals(fieldType);
    }
    
    private static boolean isAssociationType(String fieldType) {
        return "belongsTo".equals(fieldType) || "hasMany".equals(fieldType) ||
               "hasOne".equals(fieldType) || "belongsToMany".equals(fieldType);
    }
}
```

#### 9.5.2 SQL 预编译与缓存

```java
/**
 * SQL 预编译缓存
 * 避免每次查询都重新构建 SQL
 */
@Component
public class SqlTemplateCache {
    
    // SQL 模板缓存：collectionName + queryPattern -> SqlTemplate
    private final Cache<String, SqlTemplate> cache = Caffeine.newBuilder()
        .maximumSize(500)
        .expireAfterWrite(10, TimeUnit.MINUTES)
        .build();
    
    /**
     * 获取或构建 SQL 模板
     */
    public SqlTemplate getOrBuild(String collectionName, QueryPattern pattern, CollectionMeta meta) {
        String cacheKey = buildCacheKey(collectionName, pattern);
        
        return cache.get(cacheKey, key -> buildSqlTemplate(collectionName, pattern, meta));
    }
    
    /**
     * 构建 SQL 模板
     */
    private SqlTemplate buildSqlTemplate(String collectionName, QueryPattern pattern, CollectionMeta meta) {
        SqlTemplate template = new SqlTemplate();
        
        switch (pattern.getType()) {
            case "list":
                template.setSql(buildListSql(collectionName, pattern, meta));
                template.setCountSql(buildCountSql(collectionName, pattern, meta));
                break;
            case "get":
                template.setSql(buildGetSql(collectionName, meta));
                break;
            case "create":
                template.setSql(buildInsertSql(collectionName, meta));
                break;
            case "update":
                template.setSql(buildUpdateSql(collectionName, meta));
                break;
            case "delete":
                template.setSql(buildDeleteSql(collectionName, meta));
                break;
        }
        
        return template;
    }
    
    /**
     * 构建列表查询 SQL
     */
    private String buildListSql(String collectionName, QueryPattern pattern, CollectionMeta meta) {
        StringBuilder sql = new StringBuilder("SELECT ");
        
        // 字段列表
        List<String> fields = pattern.getFields();
        if (fields == null || fields.isEmpty()) {
            sql.append("*");
        } else {
            // 校验字段名（防 SQL 注入）
            for (String field : fields) {
                if (!meta.getFields().containsKey(field)) {
                    throw new BusinessException(ErrorCode.BAD_REQUEST, "未知字段: " + field);
                }
            }
            sql.append(String.join(", ", fields));
        }
        
        sql.append(" FROM `").append(collectionName).append("` WHERE deleted = 0");
        
        // 占位符用于动态条件
        sql.append(" /* WHERE_CLAUSE */");
        
        // 排序
        if (pattern.getSort() != null && !pattern.getSort().isEmpty()) {
            sql.append(" ORDER BY ").append(buildOrderByClause(pattern.getSort(), meta));
        }
        
        // 分页
        sql.append(" LIMIT ? OFFSET ?");
        
        return sql.toString();
    }
    
    /**
     * 构建计数 SQL
     */
    private String buildCountSql(String collectionName, QueryPattern pattern, CollectionMeta meta) {
        return "SELECT COUNT(*) FROM `" + collectionName + "` WHERE deleted = 0 /* WHERE_CLAUSE */";
    }
    
    /**
     * 构建单条查询 SQL
     */
    private String buildGetSql(String collectionName, CollectionMeta meta) {
        return "SELECT * FROM `" + collectionName + "` WHERE id = ? AND deleted = 0";
    }
    
    /**
     * 构建插入 SQL
     */
    private String buildInsertSql(String collectionName, CollectionMeta meta) {
        List<String> fieldNames = meta.getFieldNames().stream()
            .filter(name -> !meta.getField(name).isPrimaryKey()) // 排除主键
            .collect(Collectors.toList());
        
        String columns = String.join(", ", fieldNames.stream()
            .map(f -> "`" + f + "`")
            .collect(Collectors.toList()));
        
        String placeholders = fieldNames.stream()
            .map(f -> "?")
            .collect(Collectors.joining(", "));
        
        return "INSERT INTO `" + collectionName + "` (" + columns + ") VALUES (" + placeholders + ")";
    }
    
    /**
     * 构建更新 SQL
     */
    private String buildUpdateSql(String collectionName, CollectionMeta meta) {
        List<String> fieldNames = meta.getFieldNames().stream()
            .filter(name -> !meta.getField(name).isPrimaryKey())
            .collect(Collectors.toList());
        
        String setClause = fieldNames.stream()
            .map(f -> "`" + f + "` = ?")
            .collect(Collectors.joining(", "));
        
        return "UPDATE `" + collectionName + "` SET " + setClause + " WHERE id = ? AND deleted = 0";
    }
    
    /**
     * 构建删除 SQL（软删除）
     */
    private String buildDeleteSql(String collectionName, CollectionMeta meta) {
        return "UPDATE `" + collectionName + "` SET deleted = 1, updater = ? WHERE id IN (?) AND deleted = 0";
    }
    
    private String buildOrderByClause(List<SortItem> sortItems, CollectionMeta meta) {
        return sortItems.stream()
            .map(item -> {
                String field = item.getField();
                if (!meta.getFields().containsKey(field)) {
                    throw new BusinessException(ErrorCode.BAD_REQUEST, "未知排序字段: " + field);
                }
                return "`" + field + "` " + (item.isAsc() ? "ASC" : "DESC");
            })
            .collect(Collectors.joining(", "));
    }
    
    private String buildCacheKey(String collectionName, QueryPattern pattern) {
        return collectionName + ":" + pattern.getType() + ":" + pattern.hashCode();
    }
    
    /**
     * 清除缓存（元数据变更时调用）
     */
    public void evict(String collectionName) {
        cache.asMap().keySet().removeIf(key -> key.startsWith(collectionName + ":"));
    }
}

/**
 * SQL 模板
 */
@Data
public class SqlTemplate {
    private String sql;
    private String countSql;
}

/**
 * 查询模式（用于缓存键）
 */
@Data
public class QueryPattern {
    private String type; // list/get/create/update/delete
    private List<String> fields;
    private List<SortItem> sort;
    private List<FilterItem> filters;
}
```

#### 9.5.3 热点查询缓存

```java
/**
 * 热点查询缓存
 * 针对高频查询结果进行缓存
 */
@Component
public class HotQueryCache {
    
    // 使用 Redis 分布式缓存（支持多实例）
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    // 热点查询配置
    private static final int DEFAULT_TTL_SECONDS = 60; // 默认 1 分钟
    private static final int MAX_CACHE_SIZE = 10000;    // 最多缓存 10000 个查询结果
    
    /**
     * 查询数据（带缓存）
     */
    public PageResult<Map<String, Object>> queryWithCache(
            String collectionName,
            DynamicQueryReq req,
            Supplier<PageResult<Map<String, Object>>> querySupplier) {
        
        // 判断是否可缓存（只读查询且无特殊条件）
        if (!isCacheable(req)) {
            return querySupplier.get();
        }
        
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        String cacheKey = buildCacheKey(collectionName, req, tenantId);
        
        // 尝试从缓存获取
        String cachedJson = redisTemplate.opsForValue().get(cacheKey);
        if (cachedJson != null) {
            try {
                return JSON.parseObject(cachedJson, new TypeReference<PageResult<Map<String, Object>>>() {});
            } catch (Exception e) {
                // 缓存解析失败，继续查询
            }
        }
        
        // 缓存未命中，执行查询
        PageResult<Map<String, Object>> result = querySupplier.get();
        
        // 写入缓存
        try {
            String resultJson = JSON.toJSONString(result);
            redisTemplate.opsForValue().set(cacheKey, resultJson, DEFAULT_TTL_SECONDS, TimeUnit.SECONDS);
        } catch (Exception e) {
            // 缓存写入失败不影响业务
        }
        
        return result;
    }
    
    /**
     * 判断查询是否可缓存
     */
    private boolean isCacheable(DynamicQueryReq req) {
        // 以下情况不缓存：
        // 1. 包含时间相关条件（如 create_time > now()）
        // 2. 包含随机条件
        // 3. 查询结果可能频繁变化
        
        if (req.getFilters() != null) {
            for (FilterItem filter : req.getFilters()) {
                String field = filter.getField();
                // 时间字段不缓存
                if (field.contains("time") || field.contains("date")) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    /**
     * 构建缓存键
     */
    private String buildCacheKey(String collectionName, DynamicQueryReq req, Long tenantId) {
        // 使用查询参数的哈希作为缓存键
        String paramsHash = DigestUtils.md5DigestAsHex(JSON.toJSONString(req).getBytes());
        return String.format("nocobase:query:%d:%s:%s", tenantId, collectionName, paramsHash);
    }
    
    /**
     * 清除集合相关缓存
     */
    public void evictCollection(String collectionName) {
        Long tenantId = SecurityFrameworkUtils.getTenantId();
        String pattern = String.format("nocobase:query:%d:%s:*", tenantId, collectionName);
        
        Set<String> keys = redisTemplate.keys(pattern);
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
    }
    
    /**
     * 清除租户所有缓存
     */
    public void evictTenant(Long tenantId) {
        String pattern = String.format("nocobase:query:%d:*", tenantId);
        
        Set<String> keys = redisTemplate.keys(pattern);
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
    }
}
```

#### 9.5.4 性能优化配置

```yaml
# application.yml 性能优化配置
nocobase:
  cache:
    # 元数据缓存配置
    meta:
      enabled: true
      max-size: 1000          # 最多缓存 1000 个集合
      ttl-minutes: 5          # 缓存过期时间 5 分钟
    
    # SQL 模板缓存配置
    sql-template:
      enabled: true
      max-size: 500           # 最多缓存 500 个 SQL 模板
      ttl-minutes: 10         # 缓存过期时间 10 分钟
    
    # 热点查询缓存配置
    hot-query:
      enabled: true
      ttl-seconds: 60         # 缓存过期时间 60 秒
      max-size: 10000         # 最多缓存 10000 个查询结果
  
  # 数据库连接池优化
  datasource:
    hikari:
      maximum-pool-size: 20   # 最大连接数
      minimum-idle: 5         # 最小空闲连接
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
  
  # 动态 API 优化
  dynamic-api:
    batch-size: 100           # 批量操作大小
    max-page-size: 1000       # 最大分页大小
    default-page-size: 20     # 默认分页大小
```

#### 9.5.5 性能监控与告警

```java
/**
 * 性能监控服务
 */
@Component
public class PerformanceMonitor {
    
    @Autowired
    private MeterRegistry meterRegistry;
    
    @Autowired
    private CollectionMetaCache metaCache;
    
    @Autowired
    private SqlTemplateCache sqlTemplateCache;
    
    @Autowired
    private HotQueryCache hotQueryCache;
    
    /**
     * 记录查询耗时
     */
    public void recordQueryTime(String collectionName, long timeMs) {
        Timer timer = Timer.builder("nocobase.query.time")
            .tag("collection", collectionName)
            .register(meterRegistry);
        timer.record(timeMs, TimeUnit.MILLISECONDS);
        
        // 超过阈值告警
        if (timeMs > 1000) {
            log.warn("慢查询告警: collection={}, time={}ms", collectionName, timeMs);
        }
    }
    
    /**
     * 记录缓存命中率
     */
    public void recordCacheHit(String cacheType, boolean hit) {
        Counter counter = Counter.builder("nocobase.cache.hit")
            .tag("type", cacheType)
            .tag("hit", String.valueOf(hit))
            .register(meterRegistry);
        counter.increment();
    }
    
    /**
     * 获取缓存统计信息
     */
    public CacheStats getCacheStats() {
        CacheStats stats = new CacheStats();
        stats.setMetaCacheSize(metaCache.getCache().estimatedSize());
        stats.setSqlTemplateCacheSize(sqlTemplateCache.getCache().estimatedSize());
        // ... 其他统计
        return stats;
    }
}
```

### 9.6 完整后端 Controller 接口清单与 DTO 设计

> 本节定义所有后端 Controller 接口及其 VO（View Object），严格遵循项目已有的代码规范。
>
> - 请求 VO 命名：`*SaveReqVO`（创建/更新共用）、`*ListReqVO`（列表查询）、`*PageReqVO`（分页查询）
> - 响应 VO 命名：`*RespVO`
> - VO 统一放在 `controller/admin/nocode/vo/` 包下
> - 使用 `@Resource` 注入、`@Tag` / `@Operation` Swagger 注解、`@PreAuthorize` 权限注解
> - 统一响应使用 `com.shengyu.framework.common.pojo.CommonResult<T>`，分页使用 `com.shengyu.framework.common.pojo.PageResult<T>`
> - 错误码使用 `com.shengyu.framework.common.exception.ErrorCode`，常量定义在各模块的 `ErrorCodeConstants` 中

#### 9.6.1 Controller 接口总览

| Controller | 路径前缀 | 职责 | 接口数量 |
|-----------|---------|------|---------|
| `CollectionController` | `/nocode/collection` | 数据集合与字段管理 | 8 |
| `PageSchemaController` | `/nocode/schema` | 页面 Schema 管理 | 6 |
| `DynamicDataController` | `/nocode/dynamic` | 动态业务数据 CRUD | 5 |
| `AiChatController` | `/nocode/ai-chat` | AI 对话（同步/流式） | 4 |
| `SchemaVersionController` | `/nocode/version` | Schema 版本管理 | 5 |
| `AiToolController` | `/nocode/ai-tool` | AI 工具管理 | 4 |
| `AiSkillController` | `/nocode/ai-skill` | AI 技能管理 | 4 |
| `AiEmployeeController` | `/nocode/ai-employee` | AI 员工管理 | 5 |

---

#### 9.6.2 Collection 管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.collection;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.collection.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/collection")
@Validated
public class CollectionController {

    @Resource
    private CollectionService collectionService;

    @PostMapping("create")
    @Operation(summary = "创建数据集合（含字段）")
    @PreAuthorize("@ss.hasPermission('nocode:collection:create')")
    public CommonResult<Long> createCollection(@Valid @RequestBody CollectionSaveReqVO createReqVO) {
        return success(collectionService.createCollection(createReqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新数据集合基本信息")
    @PreAuthorize("@ss.hasPermission('nocode:collection:update')")
    public CommonResult<Boolean> updateCollection(@Valid @RequestBody CollectionSaveReqVO updateReqVO) {
        collectionService.updateCollection(updateReqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除数据集合")
    @Parameter(name = "id", description = "集合编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:collection:delete')")
    public CommonResult<Boolean> deleteCollection(@RequestParam("id") Long id) {
        collectionService.deleteCollection(id);
        return success(true);
    }

    @GetMapping("list")
    @Operation(summary = "获取所有数据集合列表")
    @PreAuthorize("@ss.hasPermission('nocode:collection:query')")
    public CommonResult<List<CollectionRespVO>> listCollections() {
        return success(collectionService.listCollections());
    }

    @GetMapping("get")
    @Operation(summary = "获取数据集合详情（含字段列表）")
    @Parameter(name = "id", description = "集合编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:collection:query')")
    public CommonResult<CollectionRespVO> getCollection(@RequestParam("id") Long id) {
        return success(collectionService.getCollection(id));
    }

    @PostMapping("field/add")
    @Operation(summary = "添加字段")
    @PreAuthorize("@ss.hasPermission('nocode:collection:create')")
    public CommonResult<Long> addField(@Valid @RequestBody FieldSaveReqVO saveReqVO) {
        return success(collectionService.addField(saveReqVO));
    }

    @PutMapping("field/update")
    @Operation(summary = "更新字段")
    @PreAuthorize("@ss.hasPermission('nocode:collection:update')")
    public CommonResult<Boolean> updateField(@Valid @RequestBody FieldSaveReqVO saveReqVO) {
        collectionService.updateField(saveReqVO);
        return success(true);
    }

    @DeleteMapping("field/delete")
    @Operation(summary = "删除字段")
    @Parameter(name = "id", description = "字段编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:collection:delete')")
    public CommonResult<Boolean> deleteField(@RequestParam("id") Long id) {
        collectionService.deleteField(id);
        return success(true);
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.collection.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.List;

@Schema(description = "管理后台 - 无代码 - 数据集合创建/修改 Request VO")
@Data
public class CollectionSaveReqVO {

    @Schema(description = "集合编号", example = "1024")
    private Long id;

    @Schema(description = "集合名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "order")
    @NotBlank(message = "集合名不能为空")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "集合名只能包含小写字母、数字和下划线，且以字母开头")
    @Size(max = 64, message = "集合名长度不能超过 64")
    private String name;

    @Schema(description = "显示名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单表")
    @NotBlank(message = "显示名称不能为空")
    @Size(max = 128, message = "显示名称长度不能超过 128")
    private String displayName;

    @Schema(description = "描述", example = "存储订单相关数据")
    @Size(max = 512, message = "描述长度不能超过 512")
    private String description;

    @Schema(description = "集合类型：system-系统集合，business-业务集合", example = "business")
    @Pattern(regexp = "^(system|business)$", message = "typing 只能是 system 或 business")
    private String typing = "business";

    @Schema(description = "字段列表")
    @Valid
    @NotNull(message = "字段列表不能为空")
    @Size(min = 1, message = "至少需要 1 个字段")
    private List<FieldSaveReqVO> fields;
}

@Schema(description = "管理后台 - 无代码 - 字段创建/修改 Request VO")
@Data
public class FieldSaveReqVO {

    @Schema(description = "字段编号", example = "1024")
    private Long id;

    @Schema(description = "所属集合编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    @NotNull(message = "所属集合编号不能为空")
    private Long collectionId;

    @Schema(description = "字段名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "order_no")
    @NotBlank(message = "字段名不能为空")
    @Pattern(regexp = "^[a-z][a-z0-9_]*$", message = "字段名格式不正确")
    @Size(max = 64, message = "字段名长度不能超过 64")
    private String name;

    @Schema(description = "显示名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单号")
    @NotBlank(message = "显示名称不能为空")
    @Size(max = 128, message = "显示名称长度不能超过 128")
    private String displayName;

    @Schema(description = "字段类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "string")
    @NotBlank(message = "字段类型不能为空")
    @Pattern(regexp = "^(string|text|integer|decimal|boolean|datetime|date|json)$", message = "字段类型不合法")
    private String fieldType;

    @Schema(description = "数据库类型", example = "varchar(255)")
    @Size(max = 64, message = "数据库类型长度不能超过 64")
    private String dbType;

    @Schema(description = "是否可空", example = "true")
    private Boolean isNullable = true;

    @Schema(description = "是否唯一", example = "false")
    private Boolean isUnique = false;

    @Schema(description = "默认值", example = "0")
    @Size(max = 256, message = "默认值长度不能超过 256")
    private String defaultValue;

    @Schema(description = "校验规则（JSON）")
    private Object validators;

    @Schema(description = "UI 展示配置（Formily schema）")
    private Object uiSchema;

    @Schema(description = "字段扩展选项")
    private Object options;
}

@Schema(description = "管理后台 - 无代码 - 数据集合 Response VO")
@Data
public class CollectionRespVO {

    @Schema(description = "集合编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "集合名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "order")
    private String name;

    @Schema(description = "显示名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单表")
    private String displayName;

    @Schema(description = "描述", example = "存储订单相关数据")
    private String description;

    @Schema(description = "集合类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "business")
    private String typing;

    @Schema(description = "字段列表")
    private List<FieldRespVO> fields;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;

    @Schema(description = "更新时间")
    private java.time.LocalDateTime updateTime;
}

@Schema(description = "管理后台 - 无代码 - 字段 Response VO")
@Data
public class FieldRespVO {

    @Schema(description = "字段编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "字段名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "order_no")
    private String name;

    @Schema(description = "显示名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单号")
    private String displayName;

    @Schema(description = "字段类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "string")
    private String fieldType;

    @Schema(description = "数据库类型", example = "varchar(255)")
    private String dbType;

    @Schema(description = "是否可空", example = "true")
    private Boolean isNullable;

    @Schema(description = "是否唯一", example = "false")
    private Boolean isUnique;

    @Schema(description = "默认值", example = "0")
    private String defaultValue;

    @Schema(description = "校验规则（JSON）")
    private Object validators;

    @Schema(description = "UI 展示配置")
    private Object uiSchema;

    @Schema(description = "字段扩展选项")
    private Object options;

    @Schema(description = "排序序号", example = "0")
    private Integer sortOrder;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;
}
```

---

#### 9.6.3 PageSchema 管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.schema;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.schema.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/schema")
@Validated
public class PageSchemaController {

    @Resource
    private PageSchemaService pageSchemaService;

    @PostMapping("create")
    @Operation(summary = "创建页面 Schema")
    @PreAuthorize("@ss.hasPermission('nocode:schema:create')")
    public CommonResult<Long> createPageSchema(@Valid @RequestBody PageSchemaSaveReqVO saveReqVO) {
        return success(pageSchemaService.createPageSchema(saveReqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新页面 Schema")
    @PreAuthorize("@ss.hasPermission('nocode:schema:update')")
    public CommonResult<Boolean> updatePageSchema(@Valid @RequestBody PageSchemaSaveReqVO saveReqVO) {
        pageSchemaService.updatePageSchema(saveReqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除页面 Schema")
    @Parameter(name = "id", description = "Schema 编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:schema:delete')")
    public CommonResult<Boolean> deletePageSchema(@RequestParam("id") Long id) {
        pageSchemaService.deletePageSchema(id);
        return success(true);
    }

    @GetMapping("get")
    @Operation(summary = "获取页面 Schema 详情")
    @Parameter(name = "id", description = "Schema 编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:schema:query')")
    public CommonResult<PageSchemaRespVO> getPageSchema(@RequestParam("id") Long id) {
        return success(pageSchemaService.getPageSchema(id));
    }

    @GetMapping("list")
    @Operation(summary = "获取子 Schema 列表（树形结构）")
    @Parameter(name = "parentUid", description = "父节点 UID", required = true, example = "root")
    @PreAuthorize("@ss.hasPermission('nocode:schema:query')")
    public CommonResult<List<PageSchemaRespVO>> listChildren(@RequestParam("parentUid") String parentUid) {
        return success(pageSchemaService.listChildren(parentUid));
    }

    @GetMapping("get-full-tree")
    @Operation(summary = "根据页面 Key 获取完整 Schema 树")
    @Parameter(name = "pageKey", description = "页面 Key", required = true, example = "order_list")
    @PreAuthorize("@ss.hasPermission('nocode:schema:query')")
    public CommonResult<PageSchemaTreeRespVO> getFullTree(@RequestParam("pageKey") String pageKey) {
        return success(pageSchemaService.getFullTree(pageKey));
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.schema.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.List;

@Schema(description = "管理后台 - 无代码 - 页面 Schema 创建/修改 Request VO")
@Data
public class PageSchemaSaveReqVO {

    @Schema(description = "Schema 编号", example = "1024")
    private Long id;

    @Schema(description = "Schema 名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单列表页")
    @NotBlank(message = "Schema 名称不能为空")
    @Size(max = 256, message = "名称长度不能超过 256")
    private String name;

    @Schema(description = "关联的数据集合名称", example = "order")
    @Size(max = 64, message = "集合名长度不能超过 64")
    private String collectionName;

    @Schema(description = "Schema 类型：page-页面，block-区块，void-空节点", requiredMode = Schema.RequiredMode.REQUIRED, example = "page")
    @NotBlank(message = "Schema 类型不能为空")
    @Pattern(regexp = "^(page|block|void)$", message = "schemaType 只能是 page/block/void")
    private String schemaType;

    @Schema(description = "父节点 UID", example = "root")
    @Size(max = 64, message = "父级 UID 长度不能超过 64")
    private String parentUid;

    @Schema(description = "Schema JSON（Formily 格式）", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "Schema JSON 不能为空")
    private Object schemaJson;
}

@Schema(description = "管理后台 - 无代码 - 页面 Schema Response VO")
@Data
public class PageSchemaRespVO {

    @Schema(description = "Schema UID", requiredMode = Schema.RequiredMode.REQUIRED, example = "uid_001")
    private String uid;

    @Schema(description = "Schema 名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单列表页")
    private String name;

    @Schema(description = "关联的数据集合名称", example = "order")
    private String collectionName;

    @Schema(description = "Schema 类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "page")
    private String schemaType;

    @Schema(description = "父节点 UID", example = "root")
    private String parentUid;

    @Schema(description = "Schema JSON")
    private Object schemaJson;

    @Schema(description = "排序序号", example = "0")
    private Integer sortOrder;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;

    @Schema(description = "更新时间")
    private java.time.LocalDateTime updateTime;
}

@Schema(description = "管理后台 - 无代码 - 页面 Schema 树形 Response VO")
@Data
public class PageSchemaTreeRespVO {

    @Schema(description = "Schema UID", requiredMode = Schema.RequiredMode.REQUIRED, example = "uid_001")
    private String uid;

    @Schema(description = "Schema 名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "订单列表页")
    private String name;

    @Schema(description = "关联的数据集合名称", example = "order")
    private String collectionName;

    @Schema(description = "Schema 类型", requiredMode = Schema.RequiredMode.REQUIRED, example = "page")
    private String schemaType;

    @Schema(description = "Schema JSON")
    private Object schemaJson;

    @Schema(description = "子节点列表")
    private List<PageSchemaTreeRespVO> children;
}
```

---

#### 9.6.4 动态数据接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.dynamic;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.module.nocode.controller.admin.dynamic.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;
import java.util.Map;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/dynamic")
@Validated
public class DynamicDataController {

    @Resource
    private DynamicDataService dynamicDataService;

    @PostMapping("{collectionName}/page")
    @Operation(summary = "分页查询动态数据")
    @PreAuthorize("@ss.hasPermission('nocode:dynamic:query')")
    public CommonResult<PageResult<Map<String, Object>>> page(
            @PathVariable("collectionName") String collectionName,
            @Valid @RequestBody DynamicListReqVO listReqVO) {
        return success(dynamicDataService.page(collectionName, listReqVO));
    }

    @GetMapping("{collectionName}/get")
    @Operation(summary = "获取单条动态数据")
    @Parameter(name = "id", description = "数据 ID", required = true)
    @PreAuthorize("@ss.hasPermission('nocode:dynamic:query')")
    public CommonResult<Map<String, Object>> getById(
            @PathVariable("collectionName") String collectionName,
            @RequestParam("id") Object id) {
        return success(dynamicDataService.getById(collectionName, id));
    }

    @PostMapping("{collectionName}/create")
    @Operation(summary = "创建动态数据")
    @PreAuthorize("@ss.hasPermission('nocode:dynamic:create')")
    public CommonResult<Map<String, Object>> create(
            @PathVariable("collectionName") String collectionName,
            @Valid @RequestBody DynamicSaveReqVO saveReqVO) {
        return success(dynamicDataService.create(collectionName, saveReqVO));
    }

    @PutMapping("{collectionName}/update")
    @Operation(summary = "更新动态数据")
    @PreAuthorize("@ss.hasPermission('nocode:dynamic:update')")
    public CommonResult<Boolean> update(
            @PathVariable("collectionName") String collectionName,
            @Valid @RequestBody DynamicSaveReqVO saveReqVO) {
        dynamicDataService.update(collectionName, saveReqVO);
        return success(true);
    }

    @DeleteMapping("{collectionName}/delete")
    @Operation(summary = "删除动态数据")
    @PreAuthorize("@ss.hasPermission('nocode:dynamic:delete')")
    public CommonResult<Boolean> delete(
            @PathVariable("collectionName") String collectionName,
            @RequestBody List<Object> ids) {
        dynamicDataService.delete(collectionName, ids);
        return success(true);
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.dynamic.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.util.List;
import java.util.Map;

@Schema(description = "管理后台 - 无代码 - 动态数据分页查询 Request VO")
@Data
public class DynamicListReqVO {

    @Schema(description = "页码", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    @NotNull(message = "页码不能为空")
    private Integer pageNo = 1;

    @Schema(description = "每页条数", requiredMode = Schema.RequiredMode.REQUIRED, example = "10")
    @NotNull(message = "每页条数不能为空")
    private Integer pageSize = 10;

    @Schema(description = "过滤条件")
    private Map<String, Object> filters;

    @Schema(description = "排序：{\"field\": \"asc|desc\"}")
    private Map<String, String> sort;

    @Schema(description = "指定返回字段")
    private List<String> fields;

    @Schema(description = "关联字段过滤")
    private Map<String, Object> associationFilters;
}

@Schema(description = "管理后台 - 无代码 - 动态数据创建/修改 Request VO")
@Data
public class DynamicSaveReqVO {

    @Schema(description = "数据 ID（更新时必填）")
    private Object id;

    @Schema(description = "字段值映射", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "数据不能为空")
    private Map<String, Object> data;
}
```

---

#### 9.6.5 AI 对话接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.aichat;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.aichat.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/ai-chat")
@Validated
public class AiChatController {

    @Resource
    private AiChatService aiChatService;

    @PostMapping("sync")
    @Operation(summary = "同步对话")
    @PreAuthorize("@ss.hasPermission('nocode:ai-chat:create')")
    public CommonResult<AiChatRespVO> chat(@Valid @RequestBody AiChatReqVO reqVO) {
        return success(aiChatService.chat(reqVO));
    }

    @PostMapping("stream")
    @Operation(summary = "流式对话（SSE）")
    @PreAuthorize("@ss.hasPermission('nocode:ai-chat:create')")
    public SseEmitter chatStream(@Valid @RequestBody AiChatReqVO reqVO) {
        return aiChatService.chatStream(reqVO);
    }

    @GetMapping("history")
    @Operation(summary = "获取对话历史")
    @Parameter(name = "sessionId", description = "会话 ID", required = true, example = "session_001")
    @PreAuthorize("@ss.hasPermission('nocode:ai-chat:query')")
    public CommonResult<List<ChatMessageRespVO>> getHistory(@RequestParam("sessionId") String sessionId) {
        return success(aiChatService.getHistory(sessionId));
    }

    @DeleteMapping("clear")
    @Operation(summary = "清除会话")
    @Parameter(name = "sessionId", description = "会话 ID", required = true, example = "session_001")
    @PreAuthorize("@ss.hasPermission('nocode:ai-chat:delete')")
    public CommonResult<Boolean> clearSession(@RequestParam("sessionId") String sessionId) {
        aiChatService.clearSession(sessionId);
        return success(true);
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.aichat.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.List;

@Schema(description = "管理后台 - 无代码 - AI 对话 Request VO")
@Data
public class AiChatReqVO {

    @Schema(description = "会话 ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "session_001")
    @NotBlank(message = "会话 ID 不能为空")
    private String sessionId;

    @Schema(description = "消息内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "帮我创建一个订单管理页面")
    @NotBlank(message = "消息内容不能为空")
    @Size(max = 4000, message = "消息长度不能超过 4000")
    private String message;

    @Schema(description = "历史消息（用于上下文传递）")
    private List<ChatMessageReqVO> history;

    @Schema(description = "AI 员工 ID", example = "1024")
    private String employeeId;
}

@Schema(description = "管理后台 - 无代码 - 聊天消息 Request VO")
@Data
public class ChatMessageReqVO {

    @Schema(description = "角色：user/assistant/system", requiredMode = Schema.RequiredMode.REQUIRED, example = "user")
    @NotBlank(message = "角色不能为空")
    @Pattern(regexp = "^(user|assistant|system)$", message = "角色不合法")
    private String role;

    @Schema(description = "内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "你好")
    @NotBlank(message = "内容不能为空")
    private String content;
}

@Schema(description = "管理后台 - 无代码 - AI 对话 Response VO")
@Data
public class AiChatRespVO {

    @Schema(description = "会话 ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "session_001")
    private String sessionId;

    @Schema(description = "AI 回复内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "好的，我来帮你创建...")
    private String reply;

    @Schema(description = "工具调用结果")
    private List<ToolCallResultRespVO> toolResults;

    @Schema(description = "消耗的 token 数", example = "150")
    private Long usageTokens;
}

@Schema(description = "管理后台 - 无代码 - 聊天消息 Response VO")
@Data
public class ChatMessageRespVO {

    @Schema(description = "消息 ID", requiredMode = Schema.RequiredMode.REQUIRED, example = "msg_001")
    private String id;

    @Schema(description = "角色", requiredMode = Schema.RequiredMode.REQUIRED, example = "assistant")
    private String role;

    @Schema(description = "内容", requiredMode = Schema.RequiredMode.REQUIRED, example = "好的")
    private String content;

    @Schema(description = "工具调用列表")
    private List<ToolCallResultRespVO> toolCalls;

    @Schema(description = "时间戳", example = "1700000000000")
    private Long timestamp;
}

@Schema(description = "管理后台 - 无代码 - 工具调用结果 Response VO")
@Data
public class ToolCallResultRespVO {

    @Schema(description = "工具名称", example = "create_collection")
    private String toolName;

    @Schema(description = "调用参数")
    private Object arguments;

    @Schema(description = "执行结果")
    private Object result;

    @Schema(description = "是否成功", example = "true")
    private Boolean success;

    @Schema(description = "错误信息")
    private String errorMessage;
}
```

---

#### 9.6.6 Schema 版本管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.version;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.version.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/version")
@Validated
public class SchemaVersionController {

    @Resource
    private SchemaVersionService schemaVersionService;

    @PostMapping("create")
    @Operation(summary = "创建版本快照")
    @PreAuthorize("@ss.hasPermission('nocode:version:create')")
    public CommonResult<Long> createVersion(@Valid @RequestBody SchemaVersionSaveReqVO saveReqVO) {
        return success(schemaVersionService.createVersion(saveReqVO));
    }

    @GetMapping("list")
    @Operation(summary = "获取版本列表")
    @Parameter(name = "pageKey", description = "页面 Key", required = true, example = "order_list")
    @PreAuthorize("@ss.hasPermission('nocode:version:query')")
    public CommonResult<List<SchemaVersionRespVO>> listVersions(@RequestParam("pageKey") String pageKey) {
        return success(schemaVersionService.listVersions(pageKey));
    }

    @GetMapping("get")
    @Operation(summary = "获取版本详情")
    @Parameter(name = "id", description = "版本编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:version:query')")
    public CommonResult<SchemaVersionRespVO> getVersion(@RequestParam("id") Long id) {
        return success(schemaVersionService.getVersion(id));
    }

    @PostMapping("restore")
    @Operation(summary = "恢复到指定版本")
    @Parameter(name = "id", description = "版本编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:version:update')")
    public CommonResult<Boolean> restoreVersion(@RequestParam("id") Long id) {
        schemaVersionService.restoreVersion(id);
        return success(true);
    }

    @GetMapping("diff")
    @Operation(summary = "对比两个版本差异")
    @PreAuthorize("@ss.hasPermission('nocode:version:query')")
    public CommonResult<VersionDiffRespVO> diffVersions(
            @RequestParam("fromVersionId") Long fromVersionId,
            @RequestParam("toVersionId") Long toVersionId) {
        return success(schemaVersionService.diffVersions(fromVersionId, toVersionId));
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.version.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;
import java.util.List;

@Schema(description = "管理后台 - 无代码 - Schema 版本创建 Request VO")
@Data
public class SchemaVersionSaveReqVO {

    @Schema(description = "版本编号（更新时必填）", example = "1024")
    private Long id;

    @Schema(description = "页面 Key", requiredMode = Schema.RequiredMode.REQUIRED, example = "order_list")
    @NotBlank(message = "页面 Key 不能为空")
    private String pageKey;

    @Schema(description = "版本号", requiredMode = Schema.RequiredMode.REQUIRED, example = "v1.0")
    @NotBlank(message = "版本号不能为空")
    @Pattern(regexp = "^v\\d+\\.\\d+$", message = "版本号格式应为 v1.0, v1.1 等")
    private String versionNumber;

    @Schema(description = "变更说明", example = "新增订单列表筛选功能")
    @Size(max = 512, message = "变更说明长度不能超过 512")
    private String changeSummary;
}

@Schema(description = "管理后台 - 无代码 - Schema 版本 Response VO")
@Data
public class SchemaVersionRespVO {

    @Schema(description = "版本编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "页面 Key", requiredMode = Schema.RequiredMode.REQUIRED, example = "order_list")
    private String pageKey;

    @Schema(description = "版本号", requiredMode = Schema.RequiredMode.REQUIRED, example = "v1.0")
    private String versionNumber;

    @Schema(description = "变更说明", example = "新增订单列表筛选功能")
    private String changeSummary;

    @Schema(description = "创建人", example = "admin")
    private String createdBy;

    @Schema(description = "Schema 快照（仅详情接口返回）")
    private Object schemaSnapshot;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;
}

@Schema(description = "管理后台 - 无代码 - 版本差异对比 Response VO")
@Data
public class VersionDiffRespVO {

    @Schema(description = "源版本编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long fromVersionId;

    @Schema(description = "目标版本编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1025")
    private Long toVersionId;

    @Schema(description = "差异项列表")
    private List<SchemaDiffVO> diffs;
}

@Schema(description = "管理后台 - 无代码 - Schema 差异项 VO")
@Data
public class SchemaDiffVO {

    @Schema(description = "JSON Path", requiredMode = Schema.RequiredMode.REQUIRED, example = "$.components[0].props")
    private String path;

    @Schema(description = "操作类型：add/modify/remove", requiredMode = Schema.RequiredMode.REQUIRED, example = "modify")
    private String action;

    @Schema(description = "旧值")
    private Object oldValue;

    @Schema(description = "新值")
    private Object newValue;
}
```

---

#### 9.6.7 AI 工具管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.aitool;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.aitool.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/ai-tool")
@Validated
public class AiToolController {

    @Resource
    private AiToolService aiToolService;

    @PostMapping("create")
    @Operation(summary = "创建 AI 工具")
    @PreAuthorize("@ss.hasPermission('nocode:ai-tool:create')")
    public CommonResult<Long> createAiTool(@Valid @RequestBody AiToolSaveReqVO saveReqVO) {
        return success(aiToolService.createAiTool(saveReqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新 AI 工具")
    @PreAuthorize("@ss.hasPermission('nocode:ai-tool:update')")
    public CommonResult<Boolean> updateAiTool(@Valid @RequestBody AiToolSaveReqVO saveReqVO) {
        aiToolService.updateAiTool(saveReqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除 AI 工具")
    @Parameter(name = "id", description = "工具编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:ai-tool:delete')")
    public CommonResult<Boolean> deleteAiTool(@RequestParam("id") Long id) {
        aiToolService.deleteAiTool(id);
        return success(true);
    }

    @GetMapping("list")
    @Operation(summary = "获取所有可用工具")
    @PreAuthorize("@ss.hasPermission('nocode:ai-tool:query')")
    public CommonResult<List<AiToolRespVO>> listAiTools() {
        return success(aiToolService.listAiTools());
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.aitool.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Schema(description = "管理后台 - 无代码 - AI 工具创建/修改 Request VO")
@Data
public class AiToolSaveReqVO {

    @Schema(description = "工具编号（更新时必填）", example = "1024")
    private Long id;

    @Schema(description = "工具名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "创建数据集合")
    @NotBlank(message = "工具名称不能为空")
    private String name;

    @Schema(description = "工具描述", requiredMode = Schema.RequiredMode.REQUIRED, example = "用于创建新的数据集合及其字段")
    @NotBlank(message = "工具描述不能为空")
    private String description;

    @Schema(description = "参数 JSON Schema", requiredMode = Schema.RequiredMode.REQUIRED)
    @NotNull(message = "参数 Schema 不能为空")
    private Object parametersSchema;

    @Schema(description = "工具处理器类名", requiredMode = Schema.RequiredMode.REQUIRED, example = "com.shengyu.module.nocode.tool.CreateCollectionTool")
    @NotBlank(message = "处理器类名不能为空")
    private String handlerClass;
}

@Schema(description = "管理后台 - 无代码 - AI 工具 Response VO")
@Data
public class AiToolRespVO {

    @Schema(description = "工具编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "工具名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "创建数据集合")
    private String name;

    @Schema(description = "工具描述", requiredMode = Schema.RequiredMode.REQUIRED, example = "用于创建新的数据集合及其字段")
    private String description;

    @Schema(description = "参数 JSON Schema")
    private Object parametersSchema;

    @Schema(description = "工具处理器类名", requiredMode = Schema.RequiredMode.REQUIRED, example = "com.shengyu.module.nocode.tool.CreateCollectionTool")
    private String handlerClass;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;
}
```

---

#### 9.6.8 AI 技能管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.aiskill;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.aiskill.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/ai-skill")
@Validated
public class AiSkillController {

    @Resource
    private AiSkillService aiSkillService;

    @PostMapping("create")
    @Operation(summary = "创建 AI 技能")
    @PreAuthorize("@ss.hasPermission('nocode:ai-skill:create')")
    public CommonResult<Long> createAiSkill(@Valid @RequestBody AiSkillSaveReqVO saveReqVO) {
        return success(aiSkillService.createAiSkill(saveReqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新 AI 技能")
    @PreAuthorize("@ss.hasPermission('nocode:ai-skill:update')")
    public CommonResult<Boolean> updateAiSkill(@Valid @RequestBody AiSkillSaveReqVO saveReqVO) {
        aiSkillService.updateAiSkill(saveReqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除 AI 技能")
    @Parameter(name = "id", description = "技能编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:ai-skill:delete')")
    public CommonResult<Boolean> deleteAiSkill(@RequestParam("id") Long id) {
        aiSkillService.deleteAiSkill(id);
        return success(true);
    }

    @GetMapping("list")
    @Operation(summary = "获取所有技能")
    @PreAuthorize("@ss.hasPermission('nocode:ai-skill:query')")
    public CommonResult<List<AiSkillRespVO>> listAiSkills() {
        return success(aiSkillService.listAiSkills());
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.aiskill.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.util.List;

@Schema(description = "管理后台 - 无代码 - AI 技能创建/修改 Request VO")
@Data
public class AiSkillSaveReqVO {

    @Schema(description = "技能编号（更新时必填）", example = "1024")
    private Long id;

    @Schema(description = "技能名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "页面生成技能")
    @NotBlank(message = "技能名称不能为空")
    private String name;

    @Schema(description = "技能描述", requiredMode = Schema.RequiredMode.REQUIRED, example = "根据用户需求自动生成页面 Schema")
    @NotBlank(message = "技能描述不能为空")
    private String description;

    @Schema(description = "Prompt 模板", requiredMode = Schema.RequiredMode.REQUIRED, example = "你是一个页面设计专家...")
    @NotBlank(message = "Prompt 模板不能为空")
    private String promptTemplate;

    @Schema(description = "需要的工具列表", example = "[\"create_collection\", \"create_page\"]")
    private List<String> requiredTools;
}

@Schema(description = "管理后台 - 无代码 - AI 技能 Response VO")
@Data
public class AiSkillRespVO {

    @Schema(description = "技能编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "技能名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "页面生成技能")
    private String name;

    @Schema(description = "技能描述", requiredMode = Schema.RequiredMode.REQUIRED, example = "根据用户需求自动生成页面 Schema")
    private String description;

    @Schema(description = "Prompt 模板", requiredMode = Schema.RequiredMode.REQUIRED, example = "你是一个页面设计专家...")
    private String promptTemplate;

    @Schema(description = "需要的工具列表", example = "[\"create_collection\", \"create_page\"]")
    private List<String> requiredTools;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;
}
```

---

#### 9.6.9 AI 员工管理接口与 DTO

##### 接口清单

```java
package com.shengyu.module.nocode.controller.admin.aiemployee;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.module.nocode.controller.admin.aiemployee.vo.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.validation.Valid;
import java.util.List;

import static com.shengyu.framework.common.pojo.CommonResult.success;

@Tag(name = "管理后台 - 无代码")
@RestController
@RequestMapping("/nocode/ai-employee")
@Validated
public class AiEmployeeController {

    @Resource
    private AiEmployeeService aiEmployeeService;

    @PostMapping("create")
    @Operation(summary = "创建 AI 员工")
    @PreAuthorize("@ss.hasPermission('nocode:ai-employee:create')")
    public CommonResult<Long> createAiEmployee(@Valid @RequestBody AiEmployeeSaveReqVO saveReqVO) {
        return success(aiEmployeeService.createAiEmployee(saveReqVO));
    }

    @PutMapping("update")
    @Operation(summary = "更新 AI 员工")
    @PreAuthorize("@ss.hasPermission('nocode:ai-employee:update')")
    public CommonResult<Boolean> updateAiEmployee(@Valid @RequestBody AiEmployeeSaveReqVO saveReqVO) {
        aiEmployeeService.updateAiEmployee(saveReqVO);
        return success(true);
    }

    @DeleteMapping("delete")
    @Operation(summary = "删除 AI 员工")
    @Parameter(name = "id", description = "员工编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:ai-employee:delete')")
    public CommonResult<Boolean> deleteAiEmployee(@RequestParam("id") Long id) {
        aiEmployeeService.deleteAiEmployee(id);
        return success(true);
    }

    @GetMapping("list")
    @Operation(summary = "获取 AI 员工列表")
    @PreAuthorize("@ss.hasPermission('nocode:ai-employee:query')")
    public CommonResult<List<AiEmployeeRespVO>> listAiEmployees() {
        return success(aiEmployeeService.listAiEmployees());
    }

    @GetMapping("get")
    @Operation(summary = "获取 AI 员工详情")
    @Parameter(name = "id", description = "员工编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('nocode:ai-employee:query')")
    public CommonResult<AiEmployeeRespVO> getAiEmployee(@RequestParam("id") Long id) {
        return success(aiEmployeeService.getAiEmployee(id));
    }
}
```

##### DTO 定义

```java
package com.shengyu.module.nocode.controller.admin.aiemployee.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Schema(description = "管理后台 - 无代码 - AI 员工创建/修改 Request VO")
@Data
public class AiEmployeeSaveReqVO {

    @Schema(description = "员工编号（更新时必填）", example = "1024")
    private Long id;

    @Schema(description = "员工名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "页面设计助手")
    @NotBlank(message = "员工名称不能为空")
    @Size(max = 128, message = "员工名称长度不能超过 128")
    private String name;

    @Schema(description = "员工描述", example = "专门负责页面 Schema 的设计与生成")
    @Size(max = 512, message = "描述长度不能超过 512")
    private String description;

    @Schema(description = "系统提示词", requiredMode = Schema.RequiredMode.REQUIRED, example = "你是一个专业的页面设计 AI...")
    @NotBlank(message = "系统提示词不能为空")
    private String systemPrompt;

    @Schema(description = "模型配置（JSON 格式）", example = "{\"model\": \"gpt-4\", \"temperature\": 0.7}")
    private String modelConfig;

    @Schema(description = "状态：0-禁用，1-启用", example = "1")
    private Integer status;
}

@Schema(description = "管理后台 - 无代码 - AI 员工 Response VO")
@Data
public class AiEmployeeRespVO {

    @Schema(description = "员工编号", requiredMode = Schema.RequiredMode.REQUIRED, example = "1024")
    private Long id;

    @Schema(description = "员工名称", requiredMode = Schema.RequiredMode.REQUIRED, example = "页面设计助手")
    private String name;

    @Schema(description = "员工描述", example = "专门负责页面 Schema 的设计与生成")
    private String description;

    @Schema(description = "系统提示词", requiredMode = Schema.RequiredMode.REQUIRED, example = "你是一个专业的页面设计 AI...")
    private String systemPrompt;

    @Schema(description = "模型配置（JSON 格式）", example = "{\"model\": \"gpt-4\", \"temperature\": 0.7}")
    private String modelConfig;

    @Schema(description = "状态：0-禁用，1-启用", requiredMode = Schema.RequiredMode.REQUIRED, example = "1")
    private Integer status;

    @Schema(description = "创建时间")
    private java.time.LocalDateTime createTime;

    @Schema(description = "更新时间")
    private java.time.LocalDateTime updateTime;
}
```

---

#### 9.6.10 接口设计规范

##### 统一响应格式

项目已有统一响应类 `com.shengyu.framework.common.pojo.CommonResult<T>`，所有 Controller 直接引用，无需重新定义。

```java
// 已有框架类，直接引用
import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;

// Controller 中使用 static import
import static com.shengyu.framework.common.pojo.CommonResult.success;

// 成功返回
return success(data);

// 失败返回（通过 ErrorCode）
return error(ErrorCodeConstants.NOCODE_COLLECTION_NOT_EXISTS);
```

##### 错误码定义

项目使用 `com.shengyu.framework.common.exception.ErrorCode` 类定义错误码，各模块在 `ErrorCodeConstants` 中以 `static final` 常量方式声明。

nocode 模块需在 `com.shengyu.module.nocode.enums.ErrorCodeConstants` 中定义错误码，错误码段建议从 `1_010_000_000` 开始：

```java
package com.shengyu.module.nocode.enums;

import com.shengyu.framework.common.exception.ErrorCode;

/**
 * NOCODE 模块错误码枚举类
 *
 * nocode 模块，使用 1-010-000-000 段
 */
public interface ErrorCodeConstants {

    // ========== 数据集合 1-010-001-000 ==========
    ErrorCode NOCODE_COLLECTION_NOT_EXISTS = new ErrorCode(1_010_001_000, "数据集合不存在");
    ErrorCode NOCODE_COLLECTION_NAME_DUPLICATE = new ErrorCode(1_010_001_001, "数据集合名称已存在");
    ErrorCode NOCODE_FIELD_NOT_EXISTS = new ErrorCode(1_010_001_002, "字段不存在");
    ErrorCode NOCODE_FIELD_ALREADY_EXISTS = new ErrorCode(1_010_001_003, "字段已存在");

    // ========== 页面 Schema 1-010-002-000 ==========
    ErrorCode NOCODE_SCHEMA_NOT_EXISTS = new ErrorCode(1_010_002_000, "页面 Schema 不存在");
    ErrorCode NOCODE_SCHEMA_VALIDATION_FAILED = new ErrorCode(1_010_002_001, "Schema 校验失败");

    // ========== 版本管理 1-010-003-000 ==========
    ErrorCode NOCODE_VERSION_NOT_EXISTS = new ErrorCode(1_010_003_000, "版本不存在");
    ErrorCode NOCODE_VERSION_NUMBER_DUPLICATE = new ErrorCode(1_010_003_001, "版本号已存在");

    // ========== AI 工具 1-010-004-000 ==========
    ErrorCode NOCODE_AI_TOOL_NOT_EXISTS = new ErrorCode(1_010_004_000, "AI 工具不存在");

    // ========== AI 技能 1-010-005-000 ==========
    ErrorCode NOCODE_AI_SKILL_NOT_EXISTS = new ErrorCode(1_010_005_000, "AI 技能不存在");

    // ========== AI 员工 1-010-006-000 ==========
    ErrorCode NOCODE_AI_EMPLOYEE_NOT_EXISTS = new ErrorCode(1_010_006_000, "AI 员工不存在");

    // ========== 动态数据 1-010-007-000 ==========
    ErrorCode NOCODE_DYNAMIC_COLLECTION_NOT_FOUND = new ErrorCode(1_010_007_000, "动态数据集合未找到");
}
```

##### 接口命名规范

| 操作 | HTTP 方法 | URL 模式 | 示例 |
|------|----------|---------|------|
| 创建 | POST | `{resource}/create` | `/nocode/collection/create` |
| 更新 | PUT | `{resource}/update` | `/nocode/collection/update` |
| 删除 | DELETE | `{resource}/delete` | `/nocode/collection/delete` |
| 查询详情 | GET | `{resource}/get` | `/nocode/collection/get` |
| 查询列表 | GET | `{resource}/list` | `/nocode/collection/list` |
| 分页查询 | GET | `{resource}/page` | `/nocode/collection/page` |

> **注意**：
> - URL 路径不使用前导斜杠，即 `@PostMapping("create")` 而非 `@PostMapping("/create")`
> - 创建/更新共用同一个 `*SaveReqVO`，通过 `id` 字段区分（有 id 为更新，无 id 为创建）
> - 分页查询 VO 继承 `com.shengyu.framework.common.pojo.PageParam`
> - 删除接口通过 `@RequestParam("id")` 传递主键

---

## 十、风险与应对

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| **Formily Vue 生态不如 React 版成熟** | 部分高级功能可能缺失 | 中 | 提前 POC 验证；必要时自研补充组件 |
| **动态 API 性能** | 运行时构建 SQL 可能慢 | 中 | 元数据缓存 + SQL 预编译 + 热点查询缓存 |
| **LLM 生成 Schema 质量** | 生成的 Schema 可能不符合规范 | 高 | Skills 约束 + Schema Validator + 人工审查 |
| **复杂页面表达力不足** | 某些复杂交互无法用 Schema 表达 | 中 | 支持自定义组件注册；允许混合模式 |
| **Designable Vue 版不完善** | 可视化设计器体验不佳 | 中 | 可先不做设计器，优先 AI 对话模式 |
| **安全性** | AI 可能执行危险操作 | 低 | 工具权限控制 + 操作审计 + 危险操作需确认 |
| **与现有代码的兼容** | 重构影响现有功能 | 中 | 渐进式重构；新旧模式并存 |

---

## 十一、与 NocoBase 的对标分析

### 11.1 能力对标矩阵

| NocoBase 能力 | 本项目方案 | 对标程度 | 说明 |
|--------------|-----------|---------|------|
| Formily Schema 渲染 | Formily Vue | ✅ 完全对标 | NocoBase 本身就用 Formily |
| Schema 递归渲染 | SchemaField | ✅ 完全对标 | Formily 原生能力 |
| 组件注册机制 | componentRegistry | ✅ 完全对标 | Formily 原生能力 |
| Collection-Field 元数据 | nocobase_collection/field 表 | ✅ 完全对标 | 相同的表结构设计 |
| 动态 API | DynamicDataController | ✅ 完全对标 | 运行时 CRUD |
| Schema 存储 | nocobase_page_schema 表 | ✅ 完全对标 | 树形 Schema 存储 |
| Block 系统 | TableBlock/FormBlock 等 | ✅ 完全对标 | 相同的区块概念 |
| AI 工具系统 | ToolManager + AiTool | ✅ 完全对标 | Function Calling |
| AI 技能系统 | SkillManager + SkillDefinition | ✅ 完全对标 | Prompt 知识包 |
| AI 员工 | AiEmployee | ✅ 完全对标 | 独立权限 + 业务上下文 |
| 可视化设计器 | Designable | ⚠️ 部分对标 | Vue 版可能不如 React 版成熟 |
| 工作流引擎 | FlowLong | ⚠️ 不同实现 | NocoBase 自研 DAG vs FlowLong BPMN |
| 插件化架构 | 模块化 | ❌ 不对标 | 不采用微内核，保持 Spring Boot 模块化 |
| MCP 协议 | 暂不实现 | ❌ 不对标 | 优先级低，后续可加 |
| 多工作区 (Multi Portal) | 暂不实现 | ❌ 不对标 | NocoBase 2.2 新增，适用于多应用部署场景 |
| 移动端客户端 | 暂不实现 | ❌ 不对标 | NocoBase 2.2 新增移动端，优先级低于 PC 端 |
| 评论区块 | CommentBlock | ⚠️ 待实现 | NocoBase 2.2 新增，可用于协作场景 |
| AI 知识库 | 待增强 | ⚠️ 部分对标 | NocoBase 持续增强 AI 知识库能力 |
| 事件流 (Event Flow) | 待设计 | ⚠️ 待实现 | NocoBase 2.0 引入，Event → Flow → Step 层级执行 |
| 字段赋值机制 | 待设计 | ⚠️ 待实现 | NocoBase 2.0 统一字段赋值配置 |
| 子表格编辑 | 待实现 | ⚠️ 待实现 | 行内编辑/弹窗编辑两种模式 |
| 工作流画布增强 | 待实现 | ⚠️ 待实现 | 拖拽排序、复制粘贴节点 |

### 11.2 不对标的部分及原因

| NocoBase 特性 | 决策 | 原因 |
|--------------|------|------|
| 微内核插件化 | 不对标 | Spring Boot 模块化更适合 Java 生态 |
| 双客户端运行时 | 不对标 | 不需要 v1/v2 并存的历史包袱 |
| MCP 协议 | 后续考虑 | 优先级低于核心功能 |
| CLI + Agent | 后续考虑 | 优先级低于核心功能 |
| 数据库同步（sync-runner） | 简化实现 | 只需 DDL 同步，不需要完整的 migration 系统 |

---

## 十二、技术决策（已确定）

> 基于调研结果，以下技术选型已确定。

### 12.1 Formily Vue 版本与兼容性 ✅

**决策**：使用 `@formily/vue@2.3.7` + `@formily/element-plus@2.3.7`

**调研结论**：
- Formily Vue 最新版本为 2.3.7（发布于 2025 年初）
- 官方文档明确支持 Vue 3.x，本项目使用 Vue 3.5.12 完全兼容
- `@formily/element-plus` 提供了完整的 Element Plus 组件封装
- Formily 2.x 是稳定版本，已被 NocoBase 等生产项目验证

**安装命令**：
```bash
pnpm add @formily/core @formily/vue @formily/element-plus
```

### 12.2 可视化设计器方案 ✅

**决策**：**Phase 0-2 暂不引入 Designable，优先 AI 对话模式**

**调研结论**：
- Designable 官方 Vue 版本（`@designable/formily-adapter`）维护不活跃，最后更新在 2023 年
- Designable 主要面向 React 生态，Vue 版本功能不完整
- form-create Designer 虽然活跃（v3.5.0 发布于 2026-06-02），但它是 form-create 生态，与 Formily 不兼容
- NocoBase 的可视化设计器是自研的，不是基于 Designable

**替代方案**：
1. **Phase 0-2**：完全依赖 AI 对话生成 Schema，不提供可视化设计器
2. **Phase 3+**：根据实际需求，可选择：
   - 自研轻量级 Schema 编辑器（基于 Formily 的 Schema 编辑 API）
   - 集成 form-create Designer（但需要 Schema 格式转换层）
   - 参考 vjdesign 等 Vue 3 可视化设计器

**理由**：
- AI 对话模式已经能满足"无代码"的核心需求
- 可视化设计器开发成本高，且 Designable Vue 版不可靠
- 优先保证核心功能（元数据 + 动态 API + Schema 渲染）的稳定性

### 12.3 LLM 选型 ✅

**决策**：**采用 OpenAI 兼容协议，支持多模型切换**

**推荐配置**：
| 优先级 | 模型 | 说明 |
|--------|------|------|
| 1 | DeepSeek-V3 | 性价比高，中文能力强，Function Calling 支持好 |
| 2 | 通义千问-Max | 阿里云生态，国内访问稳定 |
| 3 | OpenAI GPT-4o | 能力最强，但成本高、需要翻墙 |
| 4 | 文心一言 4.0 | 百度生态，备选方案 |

**技术实现**：
- 后端实现 `LlmClient` 接口，统一抽象层
- 默认实现 `OpenAiCompatibleClient`，兼容 OpenAI API 格式
- 通过配置文件切换模型提供商
- AI 员工可独立配置使用的模型

**配置示例**：
```yaml
# application.yml
ai:
  llm:
    default-provider: deepseek
    providers:
      deepseek:
        api-url: https://api.deepseek.com/v1
        api-key: ${DEEPSEEK_API_KEY}
        model: deepseek-chat
      tongyi:
        api-url: https://dashscope.aliyuncs.com/compatible-mode/v1
        api-key: ${TONGYI_API_KEY}
        model: qwen-max
```

### 12.4 动态 SQL 方案 ✅

**决策**：**使用 Spring JdbcTemplate + 自研 SqlBuilder**

**对比分析**：
| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| JdbcTemplate | 轻量、灵活、性能好 | 需要手动构建 SQL | ✅ 采用 |
| MyBatis Dynamic SQL | 类型安全、API 友好 | 依赖重、学习成本 | ❌ 不采用 |
| JOOQ | 功能强大、类型安全 | 需要代码生成、依赖重 | ❌ 不采用 |

**理由**：
- 动态 API 的 SQL 构建逻辑相对固定（CRUD + 分页 + 过滤）
- JdbcTemplate 性能最好，适合高频调用
- 自研 SqlBuilder 可以完全控制 SQL 生成逻辑
- 减少外部依赖，降低维护成本

**核心实现**：
```java
public class SqlBuilder {
    private StringBuilder sql = new StringBuilder();
    private List<Object> params = new ArrayList<>();
    
    public SqlBuilder select(String collectionName, List<String> fields) {
        sql.append("SELECT ")
           .append(fields.isEmpty() ? "*" : String.join(", ", fields))
           .append(" FROM ")
           .append(collectionName);
        return this;
    }
    
    public SqlBuilder where(Map<String, Object> filters) {
        if (filters.isEmpty()) return this;
        sql.append(" WHERE ");
        List<String> conditions = new ArrayList<>();
        for (Map.Entry<String, Object> entry : filters.entrySet()) {
            conditions.add(entry.getKey() + " = ?");
            params.add(entry.getValue());
        }
        sql.append(String.join(" AND ", conditions));
        return this;
    }
    
    public SqlBuilder page(int pageNo, int pageSize) {
        int offset = (pageNo - 1) * pageSize;
        sql.append(" LIMIT ? OFFSET ?");
        params.add(pageSize);
        params.add(offset);
        return this;
    }
    
    public String build() {
        return sql.toString();
    }
    
    public Object[] getParams() {
        return params.toArray();
    }
}
```

### 12.5 Schema 存储方案 ✅

**决策**：**采用树形存储（对标 NocoBase）**

**调研结论**：
- NocoBase 使用 `parent_uid` 实现树形 Schema 存储
- 树形结构支持 Schema 片段的复用和嵌套
- 便于实现"区块"概念（区块是独立的 Schema 子树）

**表结构设计**：
```sql
CREATE TABLE nocobase_page_schema (
    id              bigint       NOT NULL AUTO_INCREMENT,
    uid             varchar(36)  NOT NULL COMMENT 'Schema 唯一标识（UUID）',
    name            varchar(256) NOT NULL COMMENT 'Schema 名称',
    schema_type     varchar(32)  NOT NULL COMMENT '类型：page/block/void',
    parent_uid      varchar(36)  NULL     COMMENT '父 Schema UID（树形结构）',
    schema_json     json         NOT NULL COMMENT 'Schema JSON（Formily 格式）',
    collection_name varchar(128) NULL     COMMENT '绑定的数据集合名',
    sort            int          NOT NULL DEFAULT 0,
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_uid (uid, tenant_id),
    KEY idx_parent_uid (parent_uid),
    KEY idx_collection_name (collection_name)
) COMMENT '页面 Schema 存储（树形结构）';
```

**使用示例**：
```
页面 Schema（parent_uid = null）
├── 搜索区块（parent_uid = 页面uid）
├── 表格区块（parent_uid = 页面uid）
│   ├── 操作列（parent_uid = 表格uid）
│   └── 查看按钮（parent_uid = 操作列uid）
└── 分页组件（parent_uid = 页面uid）
```

### 12.6 新旧模式并存策略 ✅

**决策**：**长期并存，渐进式迁移**

**策略说明**：
1. **现有手写页面**：保持不变，不做强制迁移
2. **新业务页面**：优先使用无代码模式（Schema 驱动）
3. **迁移时机**：当某个手写页面需要大幅修改时，考虑重构为 Schema 模式
4. **混合模式**：同一个模块中可以同时存在手写页面和 Schema 页面

**技术实现**：
- 路由系统同时支持静态路由（手写页面）和动态路由（Schema 页面）
- 菜单系统支持两种类型：
  - `type=static`：指向手写 `.vue` 组件
  - `type=dynamic`：指向 `/dynamic/{pageKey}`

**菜单表改造**：
```sql
ALTER TABLE system_menu 
ADD COLUMN page_type varchar(32) NULL COMMENT '页面类型：static/dynamic',
ADD COLUMN page_key varchar(128) NULL COMMENT '动态页面标识（type=dynamic 时使用）';
```

### 12.7 动态 API 与静态 API 的关系 ✅

**决策**：**长期并存，各司其职**

**使用场景**：
| API 类型 | 适用场景 | 说明 |
|---------|---------|------|
| 动态 API | Collection 元数据驱动的 CRUD | 由 AI 或设计器创建的 Collection |
| 静态 API | 复杂业务逻辑、聚合查询、第三方集成 | 手写的 Controller |

**技术实现**：
- 动态 API 路由：`/api/dynamic/{collectionName}/*`
- 静态 API 路由：`/api/{module}/{entity}/*`（保持不变）
- 两者共享同一套权限体系

**示例**：
```
# 动态 API（自动生成的 CRUD）
POST /api/dynamic/crm_customer/list
POST /api/dynamic/crm_customer/create

# 静态 API（手写的业务逻辑）
POST /api/crm/customer/follow-up  # 复杂的跟进逻辑
GET  /api/crm/customer/statistic  # 聚合统计查询
```

### 12.8 权限模型 ✅

**决策**：**复用现有 RBAC 权限体系，扩展数据权限**

**权限层次**：
1. **菜单权限**：控制用户能看到哪些菜单（包括动态菜单）
2. **Collection 权限**：控制用户能访问哪些 Collection
3. **字段权限**：控制用户能查看/编辑哪些字段
4. **数据权限**：控制用户能操作哪些数据记录（Data Scope）

**表结构设计**：
```sql
-- Collection 权限（角色-Collection 关联）
CREATE TABLE nocobase_collection_permission (
    id              bigint       NOT NULL AUTO_INCREMENT,
    role_id         bigint       NOT NULL COMMENT '角色ID',
    collection_name varchar(128) NOT NULL COMMENT 'Collection 名称',
    can_view        tinyint      NOT NULL DEFAULT 0,
    can_create      tinyint      NOT NULL DEFAULT 0,
    can_update      tinyint      NOT NULL DEFAULT 0,
    can_delete      tinyint      NOT NULL DEFAULT 0,
    data_scope      varchar(512) NULL     COMMENT '数据范围表达式',
    -- 基础字段
    creator         varchar(64)  NULL,
    create_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updater         varchar(64)  NULL,
    update_time     datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted         bit(1)       NOT NULL DEFAULT 0,
    tenant_id       bigint       NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_collection (role_id, collection_name, tenant_id)
) COMMENT 'Collection 权限配置';
```

**数据范围表达式示例**：
```json
{
  "data_scope": "creator = #{userId}"  // 只能看自己创建的
}
{
  "data_scope": "dept_id = #{deptId}"  // 只能看本部门的
}
```

### 12.9 多租户隔离 ✅

**决策**：**所有元数据表都支持多租户隔离**

**实现方式**：
- 所有 `nocobase_*` 表都包含 `tenant_id` 字段
- 使用 MyBatis Plus 的 `TenantLineHandler` 自动注入租户条件
- 动态 API 查询时自动过滤当前租户的数据

**已设计的支持多租户的表**：
- `nocobase_collection`（tenant_id）
- `nocobase_field`（tenant_id）
- `nocobase_page_schema`（tenant_id）
- `nocobase_ai_employee`（tenant_id）
- `nocobase_ai_chat_message`（tenant_id）
- `nocobase_collection_permission`（tenant_id）

### 12.10 MVP 范围 ✅

**决策**：**Phase 0-2 的最小可用产品**

**MVP 功能清单**：
| 阶段 | 功能 | 说明 |
|------|------|------|
| Phase 0 | Formily 集成 | 安装依赖、组件注册、SchemaRenderer |
| Phase 0 | 动态路由 | `/dynamic/:pageKey` 路由 |
| Phase 0 | 基础区块 | TableBlock、FormBlock、DetailBlock |
| Phase 1 | Collection 元数据 | 创建/编辑 Collection 和 Field |
| Phase 1 | 动态 API | 通用 CRUD 接口 |
| Phase 1 | DDL 同步 | 自动创建物理表 |
| Phase 2 | Schema 存储 | 页面 Schema 持久化 |
| Phase 2 | Schema 渲染 | 前端加载并渲染 Schema |
| Phase 2 | 菜单集成 | 动态菜单支持 |

**MVP 不包含**：
- ❌ AI 对话（Phase 4）
- ❌ 可视化设计器（Phase 3+）
- ❌ 工作流集成（Phase 5）
- ❌ 复杂权限（MVP 只做菜单权限）

**MVP 验收标准**：
1. 手动创建 Collection（通过 API 测试工具）
2. 手动创建 Schema（通过 API 测试工具）
3. 前端能正确渲染 Schema 页面
4. 动态 API 能正常 CRUD

### 12.11 AI 对话交互方式 ✅

**决策**：**侧边栏模式（推荐）**

**对比分析**：
| 模式 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 悬浮窗 | 不占用固定空间 | 遮挡内容、操作不便 | ❌ 不采用 |
| 侧边栏 | 固定位置、不影响主内容 | 占用横向空间 | ✅ 采用 |
| 独立页面 | 空间大、专注 | 切换成本高 | ❌ 不采用 |

**设计说明**：
- AI 对话界面固定在右侧，宽度 400px
- 可通过按钮展开/收起
- 对话过程中实时展示操作结果（创建的 Collection、页面预览等）
- 支持在新标签页打开创建的页面

**界面布局**：
```
┌─────────────────────────────────────────────────────┬────────────┐
│                                                     │            │
│                   主内容区                           │  AI 对话   │
│              （菜单 + 页面渲染）                      │   侧边栏   │
│                                                     │            │
│                                                     │            │
└─────────────────────────────────────────────────────┴────────────┘
```

### 12.12 可视化设计器优先级 ✅

**决策**：**不在 MVP 中，Phase 3+ 再考虑**

**理由**：
1. AI 对话模式已经能满足"无代码"的核心需求
2. 可视化设计器开发成本高（预计 2-3 个月）
3. Designable Vue 版本不可靠，需要自研或找替代方案
4. 优先保证核心功能的稳定性

**后续规划**：
- Phase 3：评估是否需要可视化设计器
- 如果需要，优先考虑自研轻量级 Schema 编辑器
- 参考 form-create Designer 或 vjdesign 的实现

---

## 十三、进度跟踪

| 日期 | 版本 | 变更内容 |
|------|------|---------|
| 2026-07-09 | v1.0 | 初版：可行性分析 + 四阶段设计方案（已废弃） |
| 2026-07-09 | v2.0 | 重构版：完全对标 NocoBase，基于 Formily Vue，运行时渲染无代码模式 |
| 2026-07-15 | v2.1 | 确定全部技术决策（12项）；补充前端核心组件详细实现；补充后端动态 API 完整接口设计；补充现有代码迁移策略 |
| 2026-07-16 | v2.2 | 补充后端核心服务详细设计（CollectionService、PageSchemaService、SchemaValidator）；完善迁移策略章节 |
| 2026-07-16 | v2.3 | 补充 AI 对话服务完整实现（LlmClient、AiChatService、SSE 流式接口）；补充关联字段处理设计（belongsTo/hasMany/belongsToMany 动态 SQL 实现）；补充 Schema 版本管理与回滚机制（对标 NocoBase Version Control）；补充性能优化设计（元数据缓存、SQL 预编译、热点查询缓存） |
| 2026-07-20 | v2.4 | 补充前端 AI 对话组件详细实现（AiChatSidebar、MessageList、MessageInput、useAiChat Hook）；补充完整后端 Controller 接口清单与 DTO 设计（符合项目规范：*SaveReqVO/*RespVO 命名、@Resource 注入、RESTful URL）；补充 AI 员工接口（AiEmployeeController）；补充工作流集成设计（FlowLong + 无代码，事件触发机制）；提取数据建模规范为独立章节 5.8；修正章节编号错误（9.5.x 层级）；联网校验 NocoBase 2.2-beta 最新机制并补充对标分析 |

---

## 附录 A：Formily Vue 关键 API 参考

### A.1 核心概念映射

| NocoBase 概念 | Formily 概念 | 说明 |
|--------------|-------------|------|
| SchemaComponent | SchemaField | 递归渲染 Schema |
| SchemaComponentProvider | createSchemaField | 创建 SchemaField 并注册组件 |
| x-component | x-component | 完全一致 |
| x-decorator | x-decorator | 完全一致 |
| x-reactions | x-reactions | 完全一致 |
| useFieldSchema | useFieldSchema | 完全一致 |
| RecursionField | RecursionField | 完全一致 |

### A.2 Schema 示例对比

**NocoBase 的 Schema**：
```json
{
  "type": "void",
  "x-component": "FormV2",
  "x-decorator": "CardItem",
  "properties": {
    "name": {
      "type": "string",
      "title": "姓名",
      "x-decorator": "FormItem",
      "x-component": "Input",
      "required": true
    }
  }
}
```

**本项目 Formily Vue 的 Schema**（完全相同格式）：
```json
{
  "type": "void",
  "x-component": "Form",
  "x-decorator": "Card",
  "properties": {
    "name": {
      "type": "string",
      "title": "姓名",
      "x-decorator": "FormItem",
      "x-component": "Input",
      "required": true
    }
  }
}
```

**结论**：Schema 格式完全兼容，可以直接复用 NocoBase 的 Schema 模板。
