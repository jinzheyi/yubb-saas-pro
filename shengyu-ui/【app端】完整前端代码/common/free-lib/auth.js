import $U from '@/common/free-lib/util.js'

const AccessTokenKey = 'ACCESS_TOKEN'
const RefreshTokenKey = 'REFRESH_TOKEN'
const TenantIdKey = 'TENANT_ID'
const TenantNameKey = 'TENANT_NAME'
const deptIdKey = 'DEPT_ID'

// ========== Token 相关 ==========

// 获取token
export function getAccessToken() {
  return $U.getStorage(AccessTokenKey)
}

// 刷新token
export function getRefreshToken() {
  return $U.getStorage(RefreshTokenKey)
}

// 设置token
export function setToken(token) {
  $U.setStorage(RefreshTokenKey, token.refreshToken)
  $U.setStorage(AccessTokenKey, token.accessToken)
  setTenantId(token.tenantId)
  setDeptId(token.deptId)
}

// 删除token
export function removeToken() {
  $U.removeStorage(AccessTokenKey)
  $U.removeStorage(RefreshTokenKey)
  removeTenantId()
  removeDeptId()
}

/** 格式化token（jwt格式） */
export function formatToken(token) {
  return 'Bearer ' + token
}

// ========== 租户相关 ==========

export function getTenantName() {
  return $U.getStorage(TenantNameKey)
}

export function setTenantName(username) {
  $U.setStorage(TenantNameKey, username)
}

export function removeTenantName() {
  $U.removeStorage(TenantNameKey)
}

export function getTenantId() {
  return $U.getStorage(TenantIdKey)
}

export function setTenantId(tenantId) {
  $U.setStorage(TenantIdKey, tenantId)
}

export function removeTenantId() {
  $U.removeStorage(TenantIdKey)
}

// =========== 部门相关 =========
export function removeDeptId() {
  $U.removeStorage(deptIdKey)
}

export function getDeptId() {
  return $U.getStorage(deptIdKey)
}

export function setDeptId(deptId) {
  $U.setStorage(deptIdKey, deptId)
}
