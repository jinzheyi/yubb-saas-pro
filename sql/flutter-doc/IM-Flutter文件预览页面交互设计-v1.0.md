# IM Flutter 文件预览页面交互设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：`FilePreviewPage` 的组件树、多端布局、交互动作、用户体验约束  

---

## 1. 页面目标

`FilePreviewPage` 是 IM 内统一文件打开入口，负责：

- 承载文件原生预览
- 承载服务端转换结果预览
- 承载下载降级

---

## 2. 页面组件树

```text
FilePreviewPage
  FilePreviewAppBar
  FilePreviewBody
    LoadingStrategyView
    ErrorView
    DownloadOnlyView
    PdfPreviewBody
    ImagePreviewBody
    VideoPreviewBody
    AudioPreviewBody
    TextPreviewBody
    HtmlPreviewBody
    EmbeddedOfficePreviewBody
  FilePreviewBottomActions
```

---

## 3. 页面区域划分

### 3.1 顶部栏

显示：

- 文件名
- 文件类型
- 分享 / 下载 / 外部打开入口

### 3.2 预览主体

根据 `FileRenderStrategy` 渲染不同 body

### 3.3 底部动作区

根据状态显示：

- 下载
- 外部打开
- 重试

---

## 4. 各策略对应页面体

### 4.1 `nativePdf`

组件：

- `PdfPreviewBody`

能力：

- 搜索
- 页码跳转
- 缩放
- 位置恢复

### 4.2 `nativeImage`

组件：

- `ImagePreviewBody`

能力：

- 缩放
- 双击放大
- 图片切换（如未来支持多图）

### 4.3 `nativeVideo`

组件：

- `VideoPreviewBody`

### 4.4 `nativeAudio`

组件：

- `AudioPreviewBody`

### 4.5 `nativeText` / `nativeMarkdown`

组件：

- `TextPreviewBody`

能力：

- 搜索
- 代码高亮（后续可选）
- 大文本懒加载

### 4.6 `serverConvertedHtml`

组件：

- `HtmlPreviewBody`

能力：

- 承载服务端转换后的 HTML 预览
- 适合文本型 Office、说明文档等轻交互场景

### 4.7 `embeddedOfficeViewer`

组件：

- `EmbeddedOfficePreviewBody`

能力：

- 仅在后端明确返回保留型 viewer 策略时启用

### 4.8 `serverConvertedPdf`

组件：

- `PdfPreviewBody`

区别：

- 数据源来自服务端转换结果

### 4.9 `downloadOnly`

组件：

- `DownloadOnlyView`

---

## 5. 多端布局策略

### 5.1 Mobile

- 顶部栏紧凑
- 主体全屏
- 底部动作区固定

### 5.2 Web

- 可增加右侧信息栏
- 转换结果优先全宽展示

### 5.3 Desktop

- 允许更明显的工具栏
- 支持更多外部打开 / 下载操作

---

## 6. 页面交互动作

### 6.1 通用动作

- 下载
- 分享
- 外部打开
- 重试

### 6.2 PDF 专属动作

- 搜索
- 页跳转
- 缩放
- 上次阅读位置恢复

### 6.3 文本专属动作

- 搜索
- 复制
- 行号开关（后续可选）

---

## 7. 页面状态展示规则

### 7.1 `loadingStrategy`

显示：

- 骨架屏或 loading view

### 7.2 `rendering`

显示：

- 对应渲染 body

### 7.3 `downloadOnly`

显示：

- 预览不可用说明
- 下载按钮
- 外部打开按钮

### 7.4 `failed`

显示：

- 错误提示
- 重试按钮
- 下载兜底

---

## 8. 用户体验约束

1. 不允许点击文件后长时间白屏。
2. 无法预览时要快速明确降级。
3. PDF 阅读位置要支持恢复。
4. Office 文档加载失败时要自动降级，不让用户自己判断。
5. 嵌入式 viewer 不是默认路径，只有服务端明确指定时才启用。
6. 所有外部打开动作都要先经过权限与地址有效性校验。

---

## 9. 页面测试重点

1. `nativePdf` 渲染
2. `serverConvertedPdf` 渲染
3. `serverConvertedHtml` 渲染
4. `embeddedOfficeViewer` 保留入口
5. `downloadOnly` 降级态
6. `failed` -> `retry` 恢复
