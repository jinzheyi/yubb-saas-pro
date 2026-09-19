# Ant Design 视觉对齐优化方案

## 背景

两个管理端（admin-vue3 / platform-vue3）已集成 Semi Design 主题（advance-semi-theme），但与 Ant Design 的美观度仍有差距。Semi 主题主要覆盖了**色板**，但在**圆角、阴影、过渡曲线、组件形态**（如输入框填充式 vs 描边式）方面与 AntD 差异明显。本方案在保留 Semi 主题的基础上，通过 3 个样式文件将 Element Plus 组件视觉进一步对齐 AntD。

## 修改文件（双端同步，共 6 个文件）

| 文件 | 动作 | 说明 |
|------|------|------|
| `src/styles/var.css` | 追加 | 在 `:root` 末尾新增 AntD 设计令牌（DRY 单一来源） |
| `src/styles/index.scss` | 追加 | 在 `body.semi` 块末尾映射 AntD 令牌到 EP 变量 |
| `src/styles/theme.scss` | 替换 | 当前为空，写入 11 类组件级 AntD 风格覆盖 |

## 实施步骤

### 第 1 步：var.css 新增 AntD 设计令牌

在 `:root` 末尾（`--transition-time-02` 之后）追加：
- 圆角：`--antd-border-radius-sm: 2px` / `--antd-border-radius-base: 6px` / `--antd-border-radius-lg: 8px`
- 阴影三级：`--antd-shadow-card` / `--antd-shadow-dropdown` / `--antd-shadow-modal`
- 过渡：`--antd-transition-duration: 0.3s` + `--antd-transition-timing: cubic-bezier(0.645, 0.045, 0.355, 1)`
- 字重：`--antd-font-weight-regular: 400` / `medium: 500` / `bold: 600`
- 表格专用色：`--antd-table-header-bg: #fafafa` / `--antd-table-row-hover-bg: #fafafa` / `--antd-table-border-color: #f0f0f0`
- 输入框边框色：`--antd-input-border-color: #d9d9d9` / hover & focus: `#0064fa`

### 第 2 步：index.scss 映射 EP 全局变量

在 `body.semi` 块末尾（菜单覆盖之后）追加：
- `--el-border-radius-base/sm/round/circle` → AntD 圆角
- `--el-box-shadow/light/lighter/dark` → AntD 三级阴影
- `--el-transition-duration/fast` → AntD 过渡曲线
- `--el-font-size-base/small` → Semi 字号

### 第 3 步：theme.scss 组件级覆盖（11 类组件）

| 组件 | AntD 目标 | Semi 现状 | 覆盖要点 |
|------|----------|----------|---------|
| Button | radius 6px, weight 400 | radius 3px, weight 600 | 圆角调大 + 降权重 |
| Input/Select/Textarea | 描边式, border #d9d9d9, focus 蓝色光晕 | 填充式无边框 | **形态转换**：背景透明 + 显式边框 |
| Table | header #fafafa, border #f0f0f0 | header fill-0 略深 | 表头/边框/hover 色 |
| Card | radius 8px, 有阴影 | radius 6px, 无阴影 | 圆角 + 阴影 + padding |
| Dialog/Drawer | radius 8px, modal 级阴影 | radius 8px 已匹配 | 阴影 + padding |
| Tag | radius 4px | radius 3px | 微调圆角 |
| Form | label weight 400 | 已接近 | 确保 label 权重 |
| Pagination | button 6px 圆角 | radius 3px | 圆角统一 |
| Dropdown/Popover | radius 8px, dropdown 阴影 | radius 6px | 圆角 + 阴影 |
| Scrollbar | 6px 宽, 圆角 | 8px 宽 | 收窄 + 半透明 |
| 全局过渡 | AntD cubic-bezier | Semi 0.15s | 弹出动画曲线 |

### 第 4 步：diff 验证双端同步

### 第 5 步：构建验证（双端 build）

### 第 6 步：dev server 视觉验证

**重点回归测试**：深色侧边栏菜单文字必须仍为浅色（`#bfcbd9`），不可回归为不可见状态。

## 关键设计决策

1. **令牌定义在 var.css**：所有 `--antd-*` 令牌集中定义，后续调整只需改一处（DRY）
2. **输入框从填充式改为描边式**：这是 Semi 与 AntD 最显著的形态差异，改后最接近 AntD 观感
3. **大量使用 `!important`**：Semi 组件 CSS 选择器优先级高（`.semi .el-xxx` = 0,2,0,0），需 `!important` 确保覆盖稳定
4. **不改 Semi 主题包源码**：所有覆盖在外部文件，删除 theme.scss 内容即可回退
5. **深色模式**：本次主要优化浅色模式。`#fafafa`、`#d9d9d9` 等硬编码值在深色模式下偏亮，如需完美适配可在 `.dark` 作用域追加覆盖，作为后续迭代

## 验证方法

1. `pnpm run build:pro` 双端构建无 SCSS 编译错误
2. dev server 启动后逐组件对比：按钮圆角、输入框描边、表格表头色、卡片阴影、弹窗阴影
3. 登录后验证深色侧边栏菜单文字仍可见（回归测试）
