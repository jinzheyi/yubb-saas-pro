# Frontend Placeholder Feature Audit

Updated: 2026-04-19

## Implemented In This Pass

- `pages/contacts/user-detail.uvue`
  - `分享名片功能开发中` 已改为真实跳转到 `pages/message/share-contact`
- `pages/message/share-contact.uvue`
  - 从模拟数据页改为真实分享页
  - 最近聊天改为读取 `conversationService`
  - 联系人改为读取 `getContactList()`
  - 确认分享后调用 `messageService.sendContactCardMessageByRest()`
- `services/group-service.uts`
  - `全员禁言接口未实现` 已接通真实接口
  - `发布群公告接口未实现` 已接通 `updateGroupNotice`
  - `获取群公告列表接口未实现` 已改为基于群详情返回当前公告
- `pages/message/group-notice.uvue`
  - 编辑权限不再按“仅群主”临时判断，改为使用后端返回的 `myRole`
- `shengyu-module-system-biz AppImGroupController`
  - 新增 `/system/im/group/mute-all`，把前端全员禁言服务链路补齐
- `services/read-receipt-service.uts`
  - `获取未读消息列表接口未实现` 已改为基于本地消息缓存的兜底实现
- 已删除未接入的废旧文件
  - `pages/profile/favorites.uvue`
  - `components/emoji-picker.uvue`
  - `components/message-action-menu.uvue`
  - `components/message-reaction-display.uvue`
  - `services/message-reaction-service.uts`

## User-Facing Placeholder Copy Still Exposed

### High Priority

- `pages/contacts/user-detail.uvue`
  - `通话功能开发中`
  - 当前仍无通话页或完整呼叫链路

### Platform Limitation Copy

- `pages/message/chat.uvue`
  - `当前平台暂不支持语音发送`
  - 这是平台能力分支，不属于纯占位

- `pages/message/chat-files.uvue`
  - `当前文件暂不支持转发`
  - 属于能力限制，非单纯未接线

- `pages/message/group-qrcode.uvue`
  - `当前平台暂不支持直接分享`
  - 属于平台限制

- `pages/common/file-preview.uvue`
  - `暂不支持在线预览`
  - 属于预览能力边界

## Service-Level Unimplemented APIs

### IM Core

## Dead Or Defensive Placeholder Branches

These branches currently exist, but with the current menu configuration they are mostly fallback paths rather than active user-facing features.

- `pages/profile/profile.uvue`
  - `type + ' 功能开发中'`

- `pages/message/chat-settings.uvue`
  - `type + ' 功能开发中'`

- `pages/contacts/contacts.uvue`
  - `t(item.nameKey) + '功能开发中'`
  - 当前已有四个分类均已显式处理

- `pages/workbench/workbench.uvue`
  - 保留业务入口占位
  - 已按当前范围排除，不纳入本轮 IM 主链路推进

## Removed Legacy Files

- `pages/profile/favorites.uvue`
  - 未注册到 `pages.json`，已删除

- `components/emoji-picker.uvue`
  - 无任何引用，且与现有聊天页表情面板无关，已删除

- `components/message-action-menu.uvue`
  - 无任何引用，聊天页使用的是内联菜单实现，已删除

- `components/message-reaction-display.uvue`
  - 无任何引用，且仓库未具备消息回应后端能力，已删除

- `services/message-reaction-service.uts`
  - 对应的 UI / API / WS 链路均未接入，已删除，避免和已实现的 emoji/sticker 能力混淆

## Recommended Implementation Order

1. Read Receipt Deepening
   - 如果后续需要“服务端权威的会话未读消息列表”，要新增专门后端接口
