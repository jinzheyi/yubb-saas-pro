const AccessTokenKey = 'ACCESS_TOKEN'
const RefreshTokenKey = 'REFRESH_TOKEN'
const TenantIdKey = 'TENANT_ID'
const TenantNameKey = 'TENANT_NAME'
const deptIdKey = 'DEPT_ID'

// ========== Token 相关 ==========

// 获取token
export function getAccessToken() {
  // 此处与TokenKey相同，此写法解决初始化时Cookies中不存在TokenKey报错
  const accessToken = uni.getStorageSync(AccessTokenKey)
  return accessToken ? accessToken : uni.getStorageSync('ACCESS_TOKEN')
}

// 刷新token
export function getRefreshToken() {
  return uni.getStorageSync(RefreshTokenKey)
}

// 设置token
export function setToken(token) {
  uni.setStorageSync(RefreshTokenKey, token.refreshToken)
  uni.setStorageSync(AccessTokenKey, token.accessToken)
  setTenantId(token.tenantId)
  setDeptId(token.deptId)
}

// 删除token
export function removeToken() {
  uni.removeStorageSync(AccessTokenKey)
  uni.removeStorageSync(RefreshTokenKey)
  removeTenantId()
  removeDeptId()
}

/** 格式化token（jwt格式） */
export function formatToken(token) {
  return 'Bearer ' + token
}

// ========== 租户相关 ==========

export function getTenantName() {
  return uni.getStorageSync(TenantNameKey)
}

export function setTenantName(username) {
  uni.setStorageSync(TenantNameKey, username)
}

export function removeTenantName() {
  uni.removeStorageSync(TenantNameKey)
}

export function getTenantId() {
  return uni.getStorageSync(TenantIdKey)
}

export function setTenantId(tenantId) {
  uni.setStorageSync(TenantIdKey, tenantId)
}

export function removeTenantId() {
  uni.removeStorageSync(TenantIdKey)
}

// =========== 部门相关 =========
export function removeDeptId() {
  uni.removeStorageSync(deptIdKey)
}

export function getDeptId() {
  return uni.getStorageSync(deptIdKey)
}

export function setDeptId(deptId) {
  uni.setStorageSync(deptIdKey, deptId)
}