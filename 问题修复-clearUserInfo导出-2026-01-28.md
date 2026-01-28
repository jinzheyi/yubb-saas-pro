# 问题修复：clearUserInfo 函数未导出

**日期**: 2026-01-28  
**问题**: profile.uvue 导入 clearUserInfo 函数失败  
**状态**: ✅ 已修复

---

## 问题描述

### 错误信息
```
SyntaxError: The requested module '/store/user.uts?t=1769570796134&import' 
does not provide an export named 'clearUserInfo' (at profile.uvue:32:24)
```

### 问题原因
`profile.uvue` 文件导入了 `clearUserInfo` 函数：

```typescript
import { getUserInfo, clearUserInfo } from '../../store/user.uts'
```

但是 `user.uts` 中只有 `clearUserCache()` 函数，没有导出 `clearUserInfo()` 函数。

---

## 修复方案

在 `user.uts` 中添加 `clearUserInfo()` 函数作为 `clearUserCache()` 的别名：

```typescript
/**
 * 清除所有用户缓存
 */
export function clearUserCache() {
	removeToken()
	removeUserInfo()
	removePermissions()
	removeRoles()
}

/**
 * 清除用户信息（别名函数，兼容旧代码）
 */
export function clearUserInfo() {
	clearUserCache()
}
```

---

## 修改的文件
- `shengyu-ui/shengyu-ui-admin-uniappx/store/user.uts`

---

## 验证修复
- ✅ profile.uvue 可以正常导入 clearUserInfo
- ✅ 退出登录功能正常工作
- ✅ 用户缓存正确清除

---

**修复时间**: 2026-01-28  
**状态**: ✅ 已完成
