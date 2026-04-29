# IM Flutter 文件预览与多格式渲染设计 v1.0

> 文档日期：2026-04-29  
> 文档定位：Flutter 多端文件预览、在线文档查看、服务端转换与统一渲染策略设计  

---

## 1. 目标

为 Flutter 多端 IM 定义企业级文件预览方案，目标是：

- 多端体验统一
- 常见文件类型原生体验更好
- 办公文档预览质量稳定
- 长尾文件类型有清晰降级路径
- 服务端可控、安全可控

---

## 2. 总体方案

采用 **分层式文件预览架构**：

1. **常见格式原生预览优先**
2. **Office 文档主方案采用服务端转换，嵌入式文档服务仅作保留扩展**
3. **所有文件打开先走服务端打开策略接口**
4. **无法在线稳定预览时降级为下载**

这是 Flutter 多端体系下的推荐主方案。

---

## 3. 为什么采用分层式架构

在 Flutter 多端体系里，文件预览不是一个单点能力，而是多种能力的组合：

- PDF 查看
- 图片查看
- 视频播放
- 音频播放
- 文本查看
- Office 文档查看
- 大文件安全下载

不同格式的最佳体验并不相同，因此不应强行用单一预览通道承接所有文件类型。

---

## 4. 推荐预览分层

### 4.1 第一层：原生直预览

适用于：

- PDF
- 图片
- 视频
- 音频
- 纯文本
- Markdown
- 常见代码文本

特点：

- Flutter 直接渲染
- 支持更好的滚动、缩放、搜索、分页、状态恢复

### 4.2 第二层：服务端转换预览

适用于：

- DOC / DOCX
- XLS / XLSX
- PPT / PPTX
- ODT / ODS / ODP

特点：

- 不要求 Flutter 本地直接解析 Office
- 由后端统一把 Office 转成 PDF 或 HTML
- Flutter 侧继续使用统一预览容器

### 4.3 第三层：保留型嵌入式文档服务预览

适用于：

- Office 转 PDF
- 文本转 HTML
- 复杂文件转图片流

特点：

- 仅在确有高保真需求时启用
- 必须通过后端 `viewerUrl` 间接打开
- 必须先完成许可证与商业化边界评审

### 4.4 第四层：下载降级

适用于：

- 不适合在线预览
- 服务端暂不支持预览
- 文件过大或能力受限

特点：

- 不强行预览
- 明确提供下载或外部打开能力

---

## 5. 各类文件的推荐策略

### 5.1 PDF

推荐：

- Flutter 端直接用 PDF Viewer 组件渲染

原因：

- PDF 是 IM 中高频文档格式
- 原生/Flutter 组件能提供更好的缩放、搜索、页跳转、阅读位置恢复

### 5.2 图片

推荐：

- Flutter 原生图片查看器

### 5.3 视频 / 音频

推荐：

- Flutter 原生播放器

### 5.4 纯文本 / Markdown / 代码文本

推荐：

- Flutter 直接渲染文本
- 大文件时分页、分块或懒加载

### 5.5 Office 文档

推荐：

- 全平台主路径优先服务端转换为 PDF / HTML
- Mobile 一律优先转换为 PDF 后走 Flutter PDF 预览
- Web / Desktop 如后续确有高保真需求，可增加保留型嵌入 viewer

### 5.6 CAD / OFD / 3D / 压缩包 / 邮件文件

推荐：

- 走专项 preview service
- 若当前不支持，则直接降级为下载

---

## 6. Office 文档的最佳实践

### 6.1 推荐优先级

1. **服务端转换为 PDF / HTML**
2. **下载降级**
3. **保留型嵌入文档 viewer**

### 6.2 原因

Office 文档在 Flutter 端做“本地高保真跨平台解析预览”不是最优路线。

更合理的方式是：

- 把 Office 渲染问题交给服务端转换层
- Flutter 只负责统一预览容器和交互壳

### 6.3 商业化与许可证约束

本项目后续存在售卖场景，因此 Office 预览主方案不能默认依赖可能带来强许可证义务或品牌限制的嵌入式社区版文档服务。

冻结结论：

1. 默认主方案是自有后端转换链路。
2. 嵌入式 Office viewer 只作为可选扩展位，不作为首期实现目标。
3. 若后续接入开源文档服务，必须单独完成许可证、二次分发、品牌展示和商业模式审查。

---

## 7. Flutter 端推荐架构

### 7.1 页面

- `FilePreviewPage`

### 7.2 控制器

- `FilePreviewController`
- `FileOpenCoordinator`

### 7.3 Domain 对象

- `FilePreviewArgs`
- `FilePreviewDescriptor`
- `FileRenderStrategy`
- `FileCapability`

### 7.4 Repository

- `FileRepository`

---

## 8. 服务端接口策略

不要只返回“下载地址”，而要返回 **打开策略**。

建议服务端返回：

- `renderStrategy`
- `contentType`
- `previewUrl`
- `downloadUrl`
- `viewerUrl`
- `convertedPdfUrl`
- `expiresAt`
- `unstable`
- `message`

---

## 9. `FileRenderStrategy` 建议枚举

- `nativePdf`
- `nativeImage`
- `nativeVideo`
- `nativeAudio`
- `nativeText`
- `nativeMarkdown`
- `serverConvertedPdf`
- `serverConvertedHtml`
- `embeddedOfficeViewer`
- `downloadOnly`

---

## 10. 多端策略建议

### 10.1 Mobile

- PDF：原生 PDF Viewer
- 图片/视频/音频：原生预览
- Office：优先转 PDF
- 超大文档：分页 / 分块加载

### 10.2 Web

- PDF：Web PDF viewer
- Office：优先转换结果渲染
- 图片/视频：浏览器原生能力

### 10.3 Desktop

- PDF：原生 PDF viewer
- Office：优先转换 PDF，必要时才接保留型 viewer
- 文件下载与另存为能力增强

---

## 11. 文件预览状态机

状态：

- `initial`
- `loadingStrategy`
- `resolvingCapability`
- `rendering`
- `downloadOnly`
- `failed`

---

## 12. 推荐体验策略

### 12.1 同一文件类型体验一致

例如 PDF：

- 统一搜索
- 统一页码记忆
- 统一缩放记忆

### 12.2 失败降级明确

Office 文档预览失败时：

1. 先尝试转换版 PDF
2. 若明确启用了保留型 viewer，再尝试 viewer
3. 最后允许下载

### 12.3 文件安全

- 所有 preview/download URL 必须短时效
- 不暴露长期直链
- 预览前要经过权限校验

---

## 13. 推荐最终技术方案

- **PDF：Flutter 原生 PDF Viewer**
- **图片/视频/音频/文本：Flutter 原生**
- **Office：服务端转换优先，嵌入式 viewer 仅作保留扩展**
- **复杂特殊格式：专项服务或下载降级**

这是当前 Flutter 多端体系下更适合长期演进的企业级方案。

---

## 14. 对现有 Flutter 文档的落点

当前文档里已经有轻量设计说明，位置如下：

- [IM-Flutter多端重构设计任务文档-v1.0.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/flutter-doc/IM-Flutter多端重构设计任务文档-v1.0.md)
  - 文件规则
  - `FilePreviewPage`
- [IM-Flutter页面实现蓝图-v1.0.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/flutter-doc/IM-Flutter页面实现蓝图-v1.0.md)
  - `FilePreviewPage`
- [IM-Flutter页面与路由详细设计-v1.0.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/flutter-doc/IM-Flutter页面与路由详细设计-v1.0.md)
  - `FilePreviewPage`
  - `FilePreviewArgs`
- [IM-Flutter聊天页详细设计-v1.0.md](/Users/zsy/IdeaProjects/shengyu/yubb-saas-pro/sql/flutter-doc/IM-Flutter聊天页详细设计-v1.0.md)
  - `ChatMediaController`
  - `FileOpenCoordinator`

本文件是这一块的专项加强版。
