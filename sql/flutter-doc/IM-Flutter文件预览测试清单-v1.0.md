# IM Flutter 文件预览测试清单 v1.0

> 文档日期：2026-04-29  
> 文档定位：文件预览专项的单元测试、Widget 测试、集成测试建议  

---

## 1. 目标

确保文件预览专项在多策略、多端降级下保持稳定。

---

## 2. 单元测试清单

### 2.1 mapper

- `file_open_strategy_response_dto_mapper_test.dart`

覆盖：

- strategy 映射
- 字段规范化
- URL 选择

### 2.2 coordinator

- `file_open_coordinator_test.dart`

覆盖：

- `nativePdf` -> in page
- `serverConvertedPdf` -> in page
- `serverConvertedHtml` -> in page
- `embeddedOfficeViewer` -> embedded reserved path
- `downloadOnly` -> download only
- capability 降级逻辑

### 2.3 controller

- `file_preview_controller_test.dart`

覆盖：

- initialize 成功
- initialize 失败
- retry
- download pendingAction
- openExternal pendingAction

---

## 3. Widget 测试清单

- `file_preview_page_test.dart`
- `file_preview_body_test.dart`
- `download_only_view_test.dart`

覆盖：

- loading view
- failed view
- download only view
- 不同 strategy 显示不同 body

---

## 4. 集成测试建议

- `open_pdf_preview_flow_test.dart`
- `open_office_preview_flow_test.dart`
- `open_download_only_flow_test.dart`

覆盖：

- PDF 打开
- Office 预览
- Office 转换失败后的降级
- 降级下载

---

## 5. P0 测试项

1. `FileOpenStrategyResponseDtoMapper`
2. `FileOpenCoordinator`
3. `FilePreviewController.initialize`
4. `downloadOnly` 降级流程

---

## 6. P1 测试项

1. `FilePreviewPage` Widget 渲染
2. PDF / 文本策略 body 渲染
3. 外部打开动作

---

## 7. 暂缓测试项

暂缓：

- 真机多媒体预览细节
- 保留型 Office viewer 真实嵌入兼容性
- 超大文件性能专项

---

## 8. 验收标准

文件预览专项进入实现阶段前，至少应保证：

1. coordinator 与 mapper 单测已建
2. controller 状态流单测已建
3. downloadOnly 降级链路已覆盖
