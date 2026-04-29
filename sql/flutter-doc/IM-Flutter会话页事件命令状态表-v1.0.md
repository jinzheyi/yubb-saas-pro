# IM Flutter 会话页事件-命令-状态表 v1.0

> 文档日期：2026-04-29  
> 文档定位：会话列表页、badge、sync、socket hint 的核心事件与状态迁移表  

---

## 1. 目标

明确会话列表页的主要事件流，避免会话状态和 badge 状态在编码中失控。

---

## 2. 页面加载事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 首次进入页面 | `load()` | `initial -> loading` |
| 本地缓存加载完成 | `hydrateFromCache()` | `loading -> loading` |
| 服务端列表返回 | `applyRemoteList()` | `loading -> ready` |
| 首次加载失败 | `retryLoad()` | `loading -> failed` |

---

## 3. 刷新事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 下拉刷新 | `refresh()` | `ready -> refreshing` |
| 刷新成功 | `applyRemoteList()` | `refreshing -> ready` |
| 刷新失败 | `showInlineNotice()` | `refreshing -> ready` |

---

## 4. 增量同步事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| socket 提示有会话变化 | `syncIncrementally()` | `ready -> syncing` |
| 手动触发同步 | `syncIncrementally()` | `ready -> syncing` |
| reconnect 后同步 | `syncIncrementally()` | `ready -> syncing` |
| 同步成功 | `applySyncResult()` | `syncing -> ready` |
| 同步失败 | `scheduleRetry()` | `syncing -> ready` |

---

## 5. badge 事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 服务端返回 badge | `applyBadgeState()` | `ready -> ready` |
| 某会话被打开 | `clearConversationBadge()` | `ready -> ready` |
| socket badge 更新 | `applyBadgeState()` | `ready -> ready` |

---

## 6. 会话动作事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| 置顶会话 | `pinConversation()` | `ready -> ready` |
| 取消置顶 | `pinConversation()` | `ready -> ready` |
| 免打扰切换 | `toggleNoDisturb()` | `ready -> ready` |
| 删除会话 | `deleteConversation()` | `ready -> ready` |
| 标记已读 | `markConversationRead()` | `ready -> ready` |

---

## 7. socket 会话事件

| 事件 | 命令/动作 | 状态变化 |
|---|---|---|
| socket connected | `markSocketConnected()` | `ready -> ready` |
| socket reconnecting | `showConnectionHint()` | `ready -> ready` |
| socket invalidated | `redirectToLogin()` | `ready -> initial` |

---

## 8. 排序与最终态规则

| 场景 | 规则 |
|---|---|
| 收到旧版本会话 | 丢弃 |
| 收到新版本会话 | 覆盖本地 |
| 置顶状态变化 | 重新分组排序 |
| 未读变化 | 最终以服务端 sync 收敛 |

---

## 9. 测试建议

优先测试：

1. `load -> ready`
2. `refresh -> ready`
3. `syncIncrementally -> ready`
4. `pinConversation` 后排序正确
5. `conversationVersion` 小版本不覆盖大版本
6. `badge` 与会话未读显示一致

