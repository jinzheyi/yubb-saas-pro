# uni-app x / UTS 开发资料摘录（第 1 批）

> 资料来源：
> - https://doc.dcloud.net.cn/uni-app-x/
> - https://doc.dcloud.net.cn/uni-app-x/uts/

## 1. uni-app x 是什么

- **uni-app x 是下一代 uni-app 的跨平台应用开发引擎**。
- 它由多部分组成：
  - **UTS 语言**
  - **uvue 渲染引擎**（基于 UTS、用 Vue 方式写 UI）
  - uni 的组件与 API
  - 扩展机制（uni_modules 等）
- **UTS 会编译到目标平台语言**：
  - Web/小程序 -> JavaScript
  - Android -> Kotlin（整个工程整体编译为 Kotlin，本质是“用 Vue 写法的原生 Kotlin 应用”，性能对齐原生）
  - iOS -> Swift（但文档说明：uni-app x iOS 目前普通页面/脚本策略更复杂，存在 JS 驱动模式；需要单独看 iOS 驱动说明）
  - 鸿蒙 next -> ArkTS
- 在 Android 端，uni-app x **不自带 JS 引擎**，因此一般不能依赖“运行时 JS 逻辑”。

## 2. UTS / uvue 的关系（理解模型）

- **UTS 是语言**，不包含 UI 框架。
- **uvue 是 UI 框架**（DCloud 提供，基于 UTS，使用 Vue 方式开发 UI）。
- 可以把它理解成：
  - UTS 类似 “js”
  - uvue 类似 “html+css 的 UI 层”
  - 二者组合用于 uni-app x 开发。

## 3. 组件体系（uni-app x）

uni-app x 支持的组件包括：

- **内置基础组件**：如 `view`、`text`、`image`、`scroll-view`、`input` 等（参考组件清单）。
- **自定义 Vue 组件**：可用内置组件 + Vue 组件技术封装，支持 easycom。
- **UTS 组件插件**：把原生 SDK 的 UI 能力封装成组件接入。

## 4. 开源与可替换机制（对企业项目很关键）

- uni-app x 的组件和 API 基本都开源，文档中通常会给出对应实现源码链接（GitHub/GitCode）。
- 支持 **替换单独组件/API 的实现**：
  - 将源码对应的 `uni_modules` 下载到工程下
  - 修改后打包即可替换官方实现
- 编译产物位于项目的 `unpackage` 目录下，可查看生成的 Kotlin/Swift/ETS/JS 代码形态。

## 5. UTS 强类型与语法约束（第 1 批重点）

### 5.1 变量声明

- `let name : type = value`：可重新赋值（类似 TS 的 `let` / Kotlin `var` / Swift `var`）
- `const name : type = value`：只读常量（类似 TS 的 `const` / Kotlin `val` / Swift `let`）
- 文档提示：当前 uts 未限制使用 `var`，但不建议轻易使用，因为跨平台存在差异（尤其 JS 平台会有变量提升）。

### 5.2 `as` 与字面量推导（uvue 页面中尤其常见）

- 在 Vue 选项式开发时，由于 `:` 在对象字面量里是“属性赋值”的语法，无法像 TS 一样用 `let/const + :` 给 data 成员直接声明类型。
- 解决方式：
  - 使用 **字面量赋值**让编译器推导类型
  - 或使用 `as` 做显式类型声明
- 文档示例重点：
  - **UTS 不支持 `undefined`**，变量必须初始化（即使初始化为 `null`）
  - `year: date.getFullYear() as number`：data 场景下很多时候需要 `as` 显式标注类型
  - UTS 的联合类型（文档示例）强调：联合类型在实践中常见写法为 `number | null`（这里的“联合类型只支持 `|null`”属于文档给出的约束提示之一）

### 5.3 作用域/提升差异（跨平台编码规范）

- UTS 会编译到 Kotlin/Swift/TS/ETS，不同平台在“变量提升/顺序依赖”上可能存在差异。
- 文档给出的实践建议：
  - **跨平台项目尽量遵循“先定义、后使用”**
  - 不依赖各平台差异化的提升行为

## 6. 对本 IM 项目的直接落地建议（结合我们现有代码习惯）

- **避免使用 `undefined`**，统一使用 `null` 并做好判空逻辑。
- **条件判断写成显式 boolean**（不要依赖 JS 的 truthy/falsy），这对 UTS/强类型跨平台更稳。
- **所有 Long/ID 在前端必须用 string 表达**，避免精度丢失（重点规则，禁止例外）。

### 6.1 【强制规则】前端避免 Long/ID 精度丢失（必须遵守）

背景：后端大量主键/外键为 Long（64-bit）。在 JS/UTS 侧一旦把它们转为 number，会触发 53-bit 精度限制，导致“选中状态错乱、路由参数不一致、列表 diff 异常、请求查不到数据”等历史问题复现。

强制规则：

- **规则 1：ID 永远当作 string**
  - 所有 `id/userId/deptId/chatId/groupId/messageId/fileId/tenantId` 等一律使用 `string`。
  - 禁止使用 `Number(x)`、`parseInt(x)`、`+x` 等把 ID 转 number。

- **规则 2：全局状态/Map/Set 的 key 使用 string**
  - 例如选择成员状态（选中集合）必须以 `string id` 作为 key，比较时使用 `String(id)`。

- **规则 3：路由参数一律字符串化**
  - `navigateTo` 拼接 URL 时，ID 使用 `String(id)`。
  - 页面 `onLoad(options)` 解析后也保持 string，不要转 number。

- **规则 4：请求参数与响应映射**
  - 请求 query/body 中的 ID 全部传 string（由后端做 Long 解析）。
  - 响应里的 `id` 字段在前端落地时立即 `String(resp.id)`，不要在组件树里混用 number/string。

- **规则 5：storage 持久化 ID 只存 string**
  - 读写 storage 时，ID 字段只存 string；取出后不做 number 化。

- **规则 6：列表渲染 key 使用 string**
  - `:key="item.id"` 前确保 `item.id` 为 string，避免 diff 误判。

落地检查清单（评审必查）：

- 是否出现 `Number(id)` / `parseInt(id)` / `+id`
- 是否出现 `id: someNumber`（应为 string）
- 是否出现 Map/Set 用 number id 当 key
- 是否出现 `isSelected(id:number)` 这类签名（应为 string）
- 在 uvue/UTS 中尽量减少“动态结构对象”滥用；能用明确 `type`/明确字段的地方优先明确化，避免 UTSJSONObject 带来的后续 `as`/索引访问复杂度。

## 7. 下一批阅读计划（后续会补充到同一文件或拆分文件）

- 编译器与限制：https://doc.dcloud.net.cn/uni-app-x/compiler/
- uvue(Vue)语法：https://doc.dcloud.net.cn/uni-app-x/vue/
- pages.json：https://doc.dcloud.net.cn/uni-app-x/collocation/pagesjson.html
- 组件：https://doc.dcloud.net.cn/uni-app-x/component/
- API：https://doc.dcloud.net.cn/uni-app-x/api/
- CSS：https://doc.dcloud.net.cn/uni-app-x/css/

## 8. 编译器（第 2 批）

> 来源：https://doc.dcloud.net.cn/uni-app-x/compiler/

- uni-app x 编译器由两部分组成：
  - **UTS 语言编译器**（并会调用 Kotlin/Swift 等平台编译器）
  - **uvue 编译器**（在 Vite 基础上扩展）
- uvue 编译器的大部分特性与配置与 uni-app 的 vue3 编译器一致（例如条件编译、环境变量、CSS 预处理等）。
- **条件编译**：uni-app x 在 uni-app 的基础上新增了 `APP-ANDROID`、`APP-IOS` 等条件编译开关；跨端差异需要用条件编译消化。
- **编译缓存**：
  - 编译产物/缓存会落到项目的 `unpackage` 目录（包含项目内与插件内所有 uts/uvue 的编译结果缓存）。
  - 因 App 端需要先编译成原生语言再走平台编译链，耗时更长，因此缓存对开发体验很关键。
  - 升级 HBuilderX 或编译器版本后会触发重新编译。
  - 如果保存后手机端未更新，可尝试在 HBuilderX 运行窗口勾选 **清理构建缓存**。
- 性能提示：Android 编译过程中会在磁盘产生大量 `kt/class` 等临时文件，安全软件可能扫描导致性能下降；可将项目的 `unpackage` 目录加入信任以提升编译性能。

## 9. pages.json（第 2 批）

> 来源：https://doc.dcloud.net.cn/uni-app-x/collocation/pagesjson.html

- `pages.json` 是 uni-app x 的页面管理配置文件，用于声明：
  - **应用首页**
  - **页面路径注册**（未注册页面不会被打包进应用）
  - **窗口样式**
  - 原生导航栏
  - 原生 tabBar
- HBuilderX 新建页面会自动注册到 `pages.json`；删除页面文件时会提示从 `pages.json` 移除注册。
- uni-app x 的 App 端页面不再由 webview 渲染，但为了多端统一与开发便利，仍保留了导航栏/tabBar 等配置能力。
  - 文档提示：不再支持 uni-app 的 app-plus 专用配置，以及 tabBar 的 `midbutton`。
  - 尺寸：导航栏高度 **44px**（不含状态栏），tabBar 高度 **50px**（不含安全区）。
- 如果 `pages.json` 的导航栏/tabBar 能力不满足需求，可以不配置，自己用 `view` 实现自定义导航栏/tabBar（官方示例工程有参考实现）。
- `globalStyle`：所有页面生效的全局样式配置，优先级低于页面级 `style`。
- `tabBar`：配置底部原生 tabBar。文档提到也支持 `iconfont`（优先级高于 `iconPath`）。
- 其他能力：文档中还列出了 `topWindow/leftWindow/rightWindow`、`condition`（开发期启动模式模拟直达页面）、`easycom`（组件自动引入规则）等配置项。

### 9.1 对本 IM 项目的直接落地建议（pages.json 视角）

- 新增页面（例如 `file-preview`）必须在 `pages.json` 注册，否则打包后无法跳转。
- 路由/页面规划建议：
  - IM 场景页面较多时，建议后续结合 `subPackages` 做分包规划，避免首包过大（具体分包策略后续阅读 `PagesSubPackages/preloadRule` 章节后补齐）。
  - 对“统一预览入口”这类通用页，建议放在主包或按高频路径预加载，避免首次打开文件预览时额外等待。

## 10. uvue(Vue)（第 3 批）

> 来源：https://doc.dcloud.net.cn/uni-app-x/vue/

### 10.1 script 标签与 import 规则

- `script` 的 `lang` 仅支持 **UTS**。
  - 文档表述：不管 script 的 lang 写成什么，都按 UTS 编译；在 iOS 的 js 引擎驱动的 uvue 页面里，uts 会被编译为 js。
- `setup`：带 `setup` 为组合式写法，否则为选项式写法。
- **所有 Vue 公开 API 不需要 import**，uni-app x 会自动引入。
  - 文档明确示例：不需要写 `import { ref } from 'vue'`。

### 10.2 选项式（export default）外层代码的注意事项

- `export default {}` 外层常见用途：
  - 引入第三方 uts 模块
  - 引入非 easycom 的组件（一般推荐 easycom）
  - 定义 type（用于 data 的类型约束）
  - 定义作用域更大的变量
- 外层代码的两个关键风险：
  - **启动时执行**：不管写在哪个页面，这部分代码会在应用启动时执行，而不是页面加载时执行；写复杂会影响启动速度与内存。
  - **不随页面销毁回收**：外层静态变量不会随页面关闭而回收；如确有必要要在 `unmounted` / `onUnload` 手动处理。

### 10.3 绑定 UTSJSONObject vs Map

- uni-app x 支持绑定 **UTSJSONObject** 与 **Map**。
- 文档提示：
  - App-Android 平台 **Map 性能高于 UTSJSONObject**。
  - uni-app x 4.01 起 Web 平台也支持 Map 绑定。
- 对 IM 项目：
  - 若存在频繁动态样式/动态 class（例如聊天气泡、@提及高亮、消息状态样式），可优先考虑 Map 绑定以降低 Android 端开销。

### 10.4 scoped / :deep 样式隔离差异

- scoped CSS 的深度选择器 `:deep()` / `::v-deep`：
  - 文档提示：在 uni-app x 项目中，页面默认可以影响组件样式，组件之间样式彼此隔离。
  - 深度选择器主要在 **Web 平台**有实际含义（因为 Web 最终是 SPA，需要隔离不同页面间样式）。
  - 小程序、App 平台页面可直接影响子组件，添加 scoped、使用深度选择器通常无意义。

## 11. API（第 3 批：与 IM 强相关）

> 来源：
> - https://doc.dcloud.net.cn/uni-app-x/api/
> - https://doc.dcloud.net.cn/uni-app-x/api/navigator.html
> - https://doc.dcloud.net.cn/uni-app-x/api/request.html
> - https://doc.dcloud.net.cn/uni-app-x/api/storage.html
> - https://doc.dcloud.net.cn/uni-app-x/api/download-file.html
> - https://doc.dcloud.net.cn/uni-app-x/api/upload-file.html
> - https://doc.dcloud.net.cn/uni-app-x/api/open-document.html

### 11.1 路由：uni.navigateTo / redirectTo

- `uni.navigateTo({ url })`：保留当前页，跳转到应用内某个页面。
- `uni.redirectTo({ url })`：关闭当前页，跳转到应用内某个页面。
- URL 类型：文档标注为 `string.PageURIString`。
- 对 IM 项目：
  - 建议统一封装一层路由工具（例如 `goFilePreview(fileId/url,name)`），减少页面散落拼 url 的错误率。

### 11.2 网络：uni.request

- 文档定义 `RequestOptions<T>`，返回 `RequestTask`，支持 `abort()`。
- 事件监听：
  - `onHeadersReceived/offHeadersReceived`
  - `onChunkReceived/offChunkReceived`
- 文档提示（截取到的要点）：App-Android 端对参数类型有更严格约束（需要按文档限制使用参数类型 / UTSJSONObject 等）。
- 对 IM 项目：
  - 长连接/分片下载可结合 `onChunkReceived`，但需评估跨端兼容性。
  - 建议在 `utils/request.uts` 层统一处理 token、错误码映射、重试策略，避免每个页面自行拼。

### 11.3 本地存储：storage

- 文档提示：`getStorageSync` 的返回值类型为 **any**，因为 set 时可写入任意类型。
  - 取出后需要 `as` 成正确类型，才能调用类型的方法。
  - 获取不存在 key 会触发 fail，错误信息示例：`getStorage:fail data not found`。
- 对 IM 项目：
  - 建议所有 storage 读写都通过统一 wrapper（集中处理 key 命名、默认值、as 类型转换、异常兜底）。
  - 例如我们已有的“reedit hint 持久化/回填”就非常适合走 wrapper，避免 any 扩散。

### 11.4 文件：downloadFile / uploadFile / openDocument

- `uni.downloadFile`：
  - 下载文件返回临时路径；Android 默认下载目录在外置应用沙盒 cache 下（文档还提示历史版本目录变更）。
  - 需要主动删除时使用 `uni.getFileSystemManager`。
  - iOS 平台（文档提示 4.25）：Task 原生对象会自动销毁；建议在 `complete` 回调中将 Task 置空，否则后续调用 Task 方法可能报错 `instance object does not exist`。
- `uni.uploadFile`：
  - 同样存在 iOS 4.25 Task 自动销毁提示，建议在 `complete` 置空 Task。
- `uni.openDocument`：
  - 文档示例推荐流程：远程 url -> `downloadFile` -> `openDocument({ filePath: tempFilePath })`。
  - 文档明确：该 API 不支持 Web。
- 对 IM 项目（与 V3 统一预览强相关）：
  - 统一预览页中，建议按“可在线预览 -> web-view / 不可预览 -> downloadFile + openDocument”的两段式策略，跨端一致。
  - 对 Web 端需要单独分支（例如 H5 直接 `window.open` 或仅展示下载链接）。

## 12. 开发注意（第 3 批补充：强约束汇总）

> 来源：https://doc.dcloud.net.cn/uni-app-x/tutorial/codegap.html

- 不支持 `undefined`，变量定义后必须赋值。
- 不存在声明提升（变量、函数等），必须先声明后使用。
- 函数声明方式不支持“作为值传递”；函数表达式方式不支持默认参数（需要按 UTS 的函数约束改写）。
- refs 获取组件：
  - JS 里可以直接 `ref.xxx()` 调方法；UTS 中只有 easycom 组件可用 `.` 调方法。
  - 非 easycom 组件需要 `callMethod()`。
- Vue 公开 API 自动引入（不需要 import）。

## 13. 组件（第 4 批）

> 来源：https://doc.dcloud.net.cn/uni-app-x/component/

### 13.1 自定义组件的两种形态

- **前端 uvue 组件**：按 Vue 组件规范编写的 `.uvue` 文件（前端工程师常用）。
- **原生 UTS 组件**：App 平台专用扩展机制，由原生开发者按 uts 组件插件规范开发，把原生 view 以组件方式嵌入 uvue。

### 13.2 引用方式：传统组件 vs easycom

- 前端 uvue 组件引用方式：
  - 传统 Vue 组件：需要 `import`、注册、再在 template 使用。
  - **easycom 组件**：基于路径规范自动 import/注册（插件市场下载的组件多为 easycom 或 uts 原生组件，通常可直接在页面引用）。

### 13.3 uni_modules 与插件生态

- `uni_modules` 是 uni-app 生态的包管理方案。
  - 非内置组件既可以放项目任意位置，也可以封装到 `uni_modules`。
  - 文档建议：对外提供的成熟组件一般应封装在 `uni_modules`。

### 13.4 refs 调用：内置 / easycom / 非 easycom 的差异

- 文档强调：需要区分 **内置组件、easycom 组件、非 easycom 组件**，它们的方法调用方式不同。
- 3.93+：可通过 `this.$refs` 获取组件并 `as` 转换为组件对应的 element 类型，通过 `.` 调用方法或设置属性。
- 3.97+：`uni_modules` 目录下的 easycom 组件也支持与内置组件类似的强类型调用（`this.$refs` + `as` + `.`）。
- **非内置且非 easycom 组件**：无法使用 `.`，需要通过 `this.$refs` 然后 `$callMethod` 调用方法。
  - 文档提示：`$callMethod` 的调用性能低于 easycom 的强类型调用；高频调用建议尽量用 easycom 组件的强类型方式。

### 13.5 对本 IM 项目的直接落地建议（组件视角）

- 聊天页中高频 UI（消息列表、气泡、语音/视频控件等）如果需要通过 refs 高频调用，优先使用 **easycom 组件**，避免 `$callMethod` 造成性能损耗。
- 对通用基础组件（头像、气泡、文件卡片、状态图标等）建议后续封装到 `uni_modules`，便于跨页面复用与版本管理。

## 14. CSS（第 4 批）

> 来源：https://doc.dcloud.net.cn/uni-app-x/css/

### 14.1 App 端是 Web CSS 子集（ucss 思路）

- uni-app x 在 App 平台实现的是 Web CSS 的**子集**（有时称 ucss），但工程仍使用 `.css/.less/.scss` 等后缀。
- 当编译到 Web/小程序时可支持完整 Web CSS；编译器会做 CSS reset 以保证子集在各端效果一致。

### 14.2 App 端常见差异（对 IM 页面影响很大）

- **布局**：App 端主要支持 **flex 布局**与**绝对定位**。
- **选择器限制**：App 端选择器只能用 **class 选择器**，不支持 tag / #id / [attr] 等选择器。
  - class 选择器字符限制：仅支持 `A-Z a-z 0-9 _ -`。
- **样式不继承**：父元素样式不会影响子元素（与 Web 常见的继承模型不同）。

### 14.3 scoped / 样式隔离与 z-index

- 文档提示：在 uni-app x 中，**非 web 平台不支持 css scoped**。
- HBuilderX 5+ 统一了样式隔离策略，可配置页面/组件是否受全局样式影响（文档指向“样式隔离策略2.0”）。
- `z-index`：App 仅对**同层兄弟节点**之间支持 `z-index` 调节层级，不支持脱离 DOM 树任意调节层级。

### 14.4 CSS function 支持范围

- 目前支持：`url()`、`rgb()`、`rgba()`、`var()`、`env()`（更多需看 function 列表）。

### 14.5 对本 IM 项目的直接落地建议（CSS 视角）

- 聊天页面建议统一以 flex 为主布局模型，避免依赖 Web 的 block 默认布局（uni-app x 会重置）。
- 样式选择器统一使用 class，并保证 class 命名仅包含允许字符。
- “遮罩/弹层/菜单”类 UI 设计时注意 `z-index` 只对同层兄弟有效：
  - 结构上尽量让遮罩层与内容层处于同一父容器下的兄弟节点。

## 15. 文件系统与 FileSystemManager（第 5 批）

> 来源：
> - https://doc.dcloud.net.cn/uni-app-x/api/file-system-spec.html
> - https://doc.dcloud.net.cn/uni-app-x/api/get-file-system-manager.html
> - https://doc.dcloud.net.cn/uni-app-x/api/env.html

### 15.1 核心目录常量：CACHE vs USER_DATA

- `uni.env.CACHE_PATH`：缓存文件目录。
  - OS/宿主可能在空间不足时清理，**不要保存关键业务文件**。
  - 平台差异：
    - Android：通常 `/Android/data/<包名>/cache/`
    - iOS：沙盒 `Library/Caches`
  - 文档列出：很多内置 API 产生的临时文件会落在 cache（如 `downloadFile`、`chooseImage/Video/Media`、`compressImage/Video`、网络媒体缓存、截图等）。
  - 从 HBuilderX 3.99 起的规范：`CACHE_PATH` 下官方会使用一批以 `uni-` 开头的目录（例如 `uni-download`、`uni-media`、`uni-snapshot`、`uni-audio`、`uni-recorder`、`uni-store` 等），开发者应避免使用 `uni-` 前缀目录。
- `uni.env.USER_DATA_PATH`：用户数据目录（App/小程序提供），不会被 OS 自动清除，**由开发者自主管理**。
  - 平台差异：
    - Android：通常 `/sdcard/Android/data/<包名>/files/`
    - iOS：沙盒 `Documents`
- 文档给出的重要建议：
  - 在 App 平台，很多 API 产生的文件在 cache；如果后续仍要使用，应通过 `uni.getFileSystemManager()` 将文件移动/保存到 `USER_DATA_PATH`；不用则尽量删除，避免靠系统清理工具回收。

### 15.2 Android 内置应用沙盒目录（只读场景）

- `uni.env.ANDROID_INTERNAL_SANDBOX_PATH`：仅 Android 支持，手机文件管理器不可见，用户不可改（除非 root）。
- 框架内部缓存（image/video/web-view 等）可能使用该目录；文档提示 FileSystemManager 对该目录目前只读，写入需 uts 插件。

### 15.3 FileSystemManager 使用注意事项（与 IM 文件预览/下载直接相关）

- 保留目录/前缀：`DCloud-`、`DCloud_`、`uni-`、`uni_` 为保留目录/文件前缀，业务目录避免使用。
- 大文件读取限制：读取文件 API 受设备内存限制，文档建议避免一次性读大文件（建议不超过 16M）。
- `readFile` 返回类型变更：
  - `ReadFileSuccessResult.data` 以前是 `string`。
  - Android 4.31、iOS 4.61 起为支持 `ArrayBuffer`，变更为 `string | ArrayBuffer`，使用时需手动 `as` 成指定类型。
- iOS 同步 API 限制（无返回值同步 api）：
  - 文档提示：在 uvue 中不能依赖无返回值同步 API 的失败捕获（try/catch 无效），仅建议用于调试；运行逻辑应使用异步版本或可返回错误的信息通道。

### 15.4 路径/协议（unifile）提示

- 文档提到文件系统引入了 `unifile://` 形式的路径/协议（例如 cache/usr/sandbox 等），用于统一表示不同目录下的文件位置。
- 对 IM 项目：
  - “文件下载后打开/分享/转存”建议显式区分：临时文件（cache） vs 需要长期保留（USER_DATA）。
  - 统一预览页若需要“保存到会话文件/本地文件夹”之类能力，建议以 `saveFile`/`copyFile` 体系落到 `USER_DATA_PATH` 并记录元数据。

### 15.5 代码包文件（static/uni_modules 等）与真机运行差异

- 文档说明：代码包文件（项目静态资源）会被打包到发行包中，主要目录包括：
  - `assets`
  - `hybrid`（web-view 相关）
  - `static`
  - `uni_modules`
- 通过 FileSystemManager 访问代码包文件时，可以直接用路径：
  - `/static/xxx`
  - `/uni_modules/<mod>/static/xxx`
- 代码包文件 **只读**，不可动态修改/删除；需要修改时应先 copy 到沙盒目录再操作。
- 文档提示：真机运行期为了动态性，会把代码包同步到沙盒特定目录；但**打包后代码包不在沙盒中**。
  - 建议不要用 FileSystemManager 去操作“应用代码包文件”目录，避免真机可用但线上不可用的隐患。

### 15.6 FileSystemManager 关键语义（对下载/缓存/持久化很关键）

- `rename`：文档说明可用于重命名文件，也可以把文件从 `oldPath` 移动到 `newPath`（即“移动”语义）。
- `saveFile`：保存临时文件到本地，该接口会**移动**临时文件；成功后原 `tempFilePath` 将不可用。
- `getSavedFileList/removeSavedFile`：用于管理已保存的本地缓存文件（文档提到 4.71 引入 `unifile://` 形式）。

### 15.7 对本 IM 项目的直接落地建议（文件系统视角）

- V3 “统一预览入口”建议明确三态：
  - **仅临时打开**：走 `downloadFile` 到 cache（允许系统回收），打开后无需留痕。
  - **会话内可复用/二次打开**：考虑 `saveFile`/`copyFile` 到 `USER_DATA_PATH`，并在本地（storage/DB）记录映射（fileId -> localPath + expiresAt）。
  - **需要用户导出/分享**：建议走系统相册/分享等专用 API（FileSystemManager 不支持沙盒外目录）。
- 目录命名避免使用 `DCloud-`、`DCloud_`、`uni-`、`uni_` 等保留前缀。

## 16. 工程化落地模板（面向本 IM 项目）

本章节目标：把“uni-app x / UTS 的约束与最佳实践”固化为项目通用模板，减少页面散落实现与踩坑。

### 16.1 路由统一封装（避免散落拼接 url）

- 建议项目约定：所有跨页跳转（尤其含参数的跳转）都统一通过一个路由工具函数封装。
- 核心原因：
  - 避免散落 `encodeURIComponent` 漏写/重复写
  - 避免页面路径变更导致全局散改
  - 便于后续统一埋点/权限/灰度

建议封装能力清单（示意）：

```ts
// utils/nav.uts（示意）
export function navToFilePreview(args: { fileId?: string; url?: string; name?: string }): void
export function navToChat(args: { chatId: string; targetId?: string; messageId?: string }): void
```

约束建议：
- `fileId` 优先于 `url`（可走后端 open-strategy 统一策略）。
- 所有 id 使用 `string`（避免精度问题）。

### 16.2 Storage 统一 wrapper（强类型 + 默认值 + key 规范）

背景：文档提示 `getStorageSync` 返回 `any`，不存在 key 会 fail；直接散落读写容易产生 `any` 扩散与异常分支遗漏。

建议提供 wrapper（示意）：

```ts
// utils/storage.uts（示意）
export function getString(key: string, def: string = ''): string
export function getJsonObject<T>(key: string, def: T): T
export function setJsonObject<T>(key: string, value: T): void
export function remove(key: string): void
```

key 命名建议（示意）：
- `im.chat.<chatId>.draft`
- `im.chat.<chatId>.reedit_hint.<messageId>`
- `im.file.local_cache.<fileId>`

### 16.3 文件下载/预览缓存策略（cache 与 user_data 明确分层）

结合文档：`CACHE_PATH` 可能被清理，`USER_DATA_PATH` 需要自主管理；`saveFile` 会移动临时文件。

建议把文件处理拆成 3 种用途：

- **临时打开**：
  - `downloadFile` 到 cache（允许系统回收）
  - `openDocument` 打开
  - 退出预览后无需保证文件仍存在
- **会话内可复用（优化二次打开）**：
  - 判断文件是否高频（例如最近 7 天打开过）
  - 使用 `FileSystemManager.saveFile/copyFile` 落到 `USER_DATA_PATH`
  - 记录本地索引：`fileId -> localPath + savedAt + size + lastAccessAt`
  - 定期清理策略：LRU 或按大小上限清理
- **导出/分享**：
  - 走系统能力（相册/分享）对应 API；不要试图用 FileSystemManager 访问沙盒外目录

### 16.4 网络请求（uni.request）在 UTS 下的类型与约束建议

结合文档：App-Android 对参数类型更严格，且请求任务对象有 abort/headers/chunk 等回调。

建议：
- 项目只暴露一个 `request<T>()` 入口（例如你们现有的 `utils/request.uts`），页面不直接调用 `uni.request`。
- `request<T>()` 做的事（建议清单）：
  - 统一 baseUrl
  - 统一 token/header
  - 统一错误码/超时/重试映射
  - 统一把响应 data 转成项目层 `type`（减少 UTSJSONObject 扩散）
  - 对下载场景可暴露 `onHeadersReceived/onChunkReceived` 的转接能力（如确需）

### 16.5 条件编译模板（跨端差异集中管理）

结合文档：uni-app x 支持 `APP-ANDROID`、`APP-IOS` 等条件编译；同时 API 能力在 Web 与 App 存在差异（例如 `openDocument` 不支持 Web）。

建议把典型跨端差异写成“模板块”，避免临时手写：

```ts
// 示例：在 Web 与 App 上分别打开 URL
// #ifdef H5
// window.open(url, '_blank')
// #endif

// #ifdef APP-ANDROID || APP-IOS
// plus.runtime.openURL(url)
// #endif
```

约束建议：
- 条件编译尽量收敛在 utils 层（例如 file/nav/platform），页面只调用统一函数。

### 16.6 与 V3 统一预览页直接对应的“可执行检查清单”

- `pages.json` 已注册 `file-preview`
- 入口统一：chat / chat-files / 搜索结果（如有文件结果项）都跳 `file-preview`
- `fileId` 优先传递；缺失时才传 `url`
- 预览策略统一走后端 `open-strategy`
- Web 分支：不调用 `openDocument`
- cache 文件不做“可靠持久化”承诺；需要持久化时必须落 `USER_DATA_PATH` 并建立索引

### 16.7 对齐本仓库的真实落点（文件路径与职责边界）

本小节把上面的“模板”映射到当前仓库已有实现，后续新增能力优先沿用这些文件，不再分散到页面里。

#### 16.7.1 网络请求（统一入口）

- **文件**：`shengyu-ui/shengyu-ui-admin-uniappx/utils/request.uts`
- **职责**：
  - 统一 baseUrl（当前使用 `API_BASE_URL`）
  - 统一 token header（`Authorization` 大小写去重、`formatToken`）
  - 统一 tenant header（`tenant-id`）
  - 统一 GET 禁用缓存 header
  - 统一响应解析与错误处理（`responseInterceptor`）
- **约束**：业务页面/业务 api 文件不得直接调用 `uni.request`，只能通过该文件暴露的 `request(...)` 能力。

#### 16.7.2 文件相关工具（下载/打开/类型判断）

- **文件**：`shengyu-ui/shengyu-ui-admin-uniappx/utils/file.uts`
- **职责**：
  - 文件类型识别（image/video/audio/document）
  - MIME 推导、文件名提取、大小格式化
  - 下载/打开的跨端兼容逻辑（例如你们的 `downloadAndOpenDocumentWithRetry` 在该文件内）
- **约束**：页面层不直接写 `downloadFile + openDocument` 组合逻辑，统一走此 utils（便于处理 iOS Task 回收、H5 分支、重试策略）。

#### 16.7.3 文件后端 API（open-strategy/presigned/url 等）

- **文件**：`shengyu-ui/shengyu-ui-admin-uniappx/api/file.uts`
- **职责**：
  - 群文件：`getGroupFileList / deleteGroupFile / downloadGroupFile / uploadGroupFile`
  - 文件能力：`getFilePresignedGetUrl`、`getFileOpenStrategy`
- **约束**：页面层不直接拼接后端 url；所有与文件相关的 HTTP 访问，集中写在该 API 文件。

#### 16.7.4 统一文件预览页（V3 核心落点）

- **文件**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/common/file-preview.uvue`
- **职责**：
  - 入参：`fileId` 或 `url` + `name`
  - 若 `fileId` 存在：调用 `getFileOpenStrategy(fileId)` 决定 `previewUrl` 或 `downloadUrl`
  - 若仅 `url`：降级为直接下载打开
  - 在线预览：`web-view` 打开 `previewUrl`
  - 下载打开：调用 `downloadAndOpenDocumentWithRetry`

#### 16.7.5 入口页面（必须跳统一预览页）

- **聊天页**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`
  - 文件消息点击：必须跳 `/pages/common/file-preview`，并尽量携带 `fileId`
- **聊天文件页**：`shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat-files.uvue`
  - 非 image/video 点击：必须跳 `/pages/common/file-preview`
  - 建议优先传 `fileId`（后端列表返回的 `fileId`）

### 16.8 统一封装落地清单（PR/代码评审检查项）

用于评审/自查，避免工程回退到“页面散落实现”。

#### 16.8.1 禁止项（出现即需要整改）

- 页面/组件中直接调用：
  - `uni.request`
  - 直接拼接 `API_BASE_URL + '/xxx'`
- 页面层散落实现文件打开链路：
  - `uni.downloadFile` + `uni.openDocument`（应收敛到 `utils/file.uts`）
- 页面层为非 easycom 组件高频使用 `$callMethod`（性能隐患；应改为 easycom/强类型 refs 方式）。

#### 16.8.2 必须项（与 V3/文件能力相关）

- 新增任意页面后：必须在 `pages.json` 注册。
- 新增“打开文件”入口：必须跳 `pages/common/file-preview.uvue`。
- 参数优先级：`fileId` > `url`。
- H5 分支：不得调用 `openDocument`。

#### 16.8.3 推荐项（提升一致性与可维护性）

- 所有 storage 读写收敛到统一 wrapper（避免 `any` 扩散）。
- 所有路由跳转收敛到统一 nav utils（减少 url 拼接错误，便于埋点）。

## 17. 企业级补齐：文件打开/下载/WebView/权限（官方文档摘录与项目建议）

### 17.1 `uni.openDocument`（打开文档）

- 官方说明：`openDocument` **不支持 Web**，需在 App 平台体验。
- 官方示例建议的链路：
  - 若是网络地址：先 `uni.downloadFile` 得到 `tempFilePath`，再 `uni.openDocument({ filePath: tempFilePath })`。
  - 若是本地静态资源：可直接传本地路径（例如 `/static/...`）。
- 错误处理：失败回调里会带 `errCode`，官方示例里用 `errCode.toString()` 做提示。

对 IM 项目建议：
- `openDocument` 仅作为“兜底打开方式”，统一封装在 `utils/file.uts`，页面层不要直接调用。
- H5 分支：必须走 `web-view` 或浏览器打开（按策略决定），不得调用 `openDocument`。

### 17.2 `uni.downloadFile`（下载文件）

- 官方说明：该 API 发起 HTTP GET 下载，返回本地临时路径。
- 文件名冲突：当目录下有同名文件时，会自动增加数字后缀（例如 `abc(1).txt`）。
- App-Android 默认下载目录：外置应用沙盒的 cache 目录下。
  - 官方提示：默认下载路径为 `uni.env.CACHE_PATH/cache/uni-download`。
  - 历史版本在 HBuilderX 3.99 前目录有变更（例如 `uniDownloads`），不建议业务代码强依赖“具体子目录名”。
- 主动删除下载文件：使用 `uni.getFileSystemManager`。
- DownloadTask：支持 `abort()`、`onProgressUpdate(...)`。
- iOS 注意事项：4.25 起 iOS 平台增加 Task 原生对象自动销毁逻辑；官方建议在 `complete` 回调中将 Task 对象置空（否则后续调用 Task 方法会报 `instance object does not exist`）。

对 IM 项目建议：
- 下载必须统一封装（你们已有 `downloadAndOpenDocumentWithRetry`），并在封装内部处理：
  - 进度回调（如需要）
  - 失败重试与提示
  - iOS Task 置空（避免“对象不存在”日志）
- 不把 cache 下载结果当作可靠持久化；如需“二次打开加速”，应 `saveFile/copyFile` 到 `USER_DATA_PATH` 并维护索引。

### 17.3 `web-view` 组件（用于在线预览）

- 平台差异：
  - Web/小程序：`web-view` 为全屏（页面只能显示一个铺满的 web-view）。
  - App：可自由调整大小/位置；在 4.0 之前默认宽高为 0，需要显式设宽高；4.0 起默认宽高 100%。
- 嵌套滚动（在 `scroll-view/list-view` 等容器中使用）注意事项：
  - Android：默认开启嵌套滚动；可通过 `android-nested-scroll="none"` 让外层容器不处理滚动。
  - iOS：滚动行为受 web 页面 `preventDefault` 影响，区域滚动场景更复杂。
- 本地页面加载：只会打包 `/static` 下的静态资源；`src` 必须指向 `/static` 目录，否则无法访问。
- 文件路径大小写敏感：App 平台存在大小写敏感问题，建议按“大小写敏感”原则处理资源路径。

对 IM 项目建议：
- `file-preview.uvue` 使用 `web-view` 预览时：
  - 预览地址优先走后端 `previewUrl`（避免端侧拼 kkFileView 等规则）。
  - 如果未来需要在可滚动页面内嵌 web-view，需在 Android 评估 `android-nested-scroll`，iOS 评估页面内部滚动实现。
- 本地离线预览页面（如未来考虑）：只放 `/static`，不要放在其他目录。

### 17.4 Android 权限适配（相册/文件相关）

- 官方说明：Android 不同 API Level 下相册/媒体权限变化较大：
  - 33 起细化相册权限，废弃 `READ_EXTERNAL_STORAGE`，新增 `READ_MEDIA_IMAGES/READ_MEDIA_VIDEO/READ_MEDIA_AUDIO`。
  - 34 新增 `READ_MEDIA_VISUAL_USER_SELECTED`。
- 官方给出的兼容配置（示例）：
  - `READ_EXTERNAL_STORAGE` 可加 `maxSdkVersion="32"`
  - 追加 `READ_MEDIA_IMAGES/READ_MEDIA_VIDEO/READ_MEDIA_VISUAL_USER_SELECTED`
- 官方提示：如果使用了相册相关 API，打包时会自动添加上述权限配置，不需额外配置。

对 IM 项目建议：
- “文件预览/下载”多数在沙盒内完成，不应为了文件能力额外申请不必要权限（避免上架审核风险）。
- 若确实需要“从相册选取/保存到相册/分享媒体”，再按功能点按需申请对应权限。

### 17.5 权限申请全局监听（华为上架合规点）

- 官方 API：`uni.createRequestPermissionListener()`（App-Android）。
  - 可监听权限申请确认框弹出（`onConfirm`）与关闭（`onComplete`）。
  - 官方说明：华为应用市场审核要求申请权限时同步告知用途，可在 `app.uvue` 全局监听并做统一提示。
- 官方注意事项：
  - 权限已同意后再次申请，`onConfirm` 不会触发。
  - 同时申请多个权限，`onComplete` 可能触发多次。
  - 请求已被永久拒绝的权限时，可能仍触发 `onConfirm`；官方示例采用延时处理作为临时方案。

对 IM 项目建议：
- 如果你们要做“企业级上架合规”，建议在 `app.uvue`（而不是业务页）统一挂载 listener，并统一弹出“用途说明”。
- 权限申请与提示 UI 必须是全局能力（避免各页面文案不一致）。

### 17.6 Reviewer checklist 补充（与文件/权限相关）

- 新增在线预览：必须评估 Web/小程序的 web-view 全屏约束与 App 端嵌套滚动。
- 新增下载：必须明确文件落点（cache vs user_data），并在 iOS 侧处理 DownloadTask 生命周期（complete 置空）。
- 新增涉及相册/系统文件访问的能力：必须按 Android API Level 权限适配要求评审，避免“多申请权限”导致审核风险。
*** End Patch
