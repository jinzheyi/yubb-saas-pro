import { useCache, CACHE_KEY } from '@/hooks/web/useCache'
import { TokenType } from '@/api/login/types'
import { decrypt, encrypt } from '@/utils/jsencrypt'

const { wsCache } = useCache()

const AccessTokenKey = 'ACCESS_TOKEN'
const RefreshTokenKey = 'REFRESH_TOKEN'

// 获取token
export const getAccessToken = () => {
  // 此处与TokenKey相同，此写法解决初始化时Cookies中不存在TokenKey报错
  const accessToken = wsCache.get(AccessTokenKey)
  return accessToken ? accessToken : wsCache.get('ACCESS_TOKEN')
}

// 刷新token
export const getRefreshToken = () => {
  return wsCache.get(RefreshTokenKey)
}

// 设置token
export const setToken = (token: TokenType) => {
  wsCache.set(RefreshTokenKey, token.refreshToken)
  wsCache.set(AccessTokenKey, token.accessToken)
  setTenantId(token.tenantId)
  setDeptId(token.deptId)
}

// 删除token
export const removeToken = () => {
  wsCache.delete(AccessTokenKey)
  wsCache.delete(RefreshTokenKey)
  removeTenantId()
  removeDeptId()
}

/** 格式化token（jwt格式） */
export const formatToken = (token: string): string => {
  return 'Bearer ' + token
}
// ========== 账号相关 ==========

export type LoginFormType = {
  tenantName: string
  username: string
  password: string
  rememberMe: boolean
}

export const getLoginForm = () => {
  const loginForm: LoginFormType = wsCache.get(CACHE_KEY.LoginForm)
  if (loginForm) {
    loginForm.password = decrypt(loginForm.password) as string
  }
  return loginForm
}

export const setLoginForm = (loginForm: LoginFormType) => {
  loginForm.password = encrypt(loginForm.password) as string
  wsCache.set(CACHE_KEY.LoginForm, loginForm, { exp: 30 * 24 * 60 * 60 })
}

export const removeLoginForm = () => {
  wsCache.delete(CACHE_KEY.LoginForm)
}

// ========== 租户相关 ==========

const TenantIdKey = 'TENANT_ID'
const TenantNameKey = 'TENANT_NAME'

// =========== 部门相关 =========
const deptIdKey = 'DEPT_ID'

export const getTenantName = () => {
  return wsCache.get(TenantNameKey)
}

export const setTenantName = (username: string) => {
  wsCache.set(TenantNameKey, username, { exp: 30 * 24 * 60 * 60 })
}

export const removeTenantName = () => {
  wsCache.delete(TenantNameKey)
}

export const getTenantId = () => {
  return wsCache.get(TenantIdKey)
}

export const setTenantId = (tenantId: string) => {
  wsCache.set(TenantIdKey, tenantId)
}

export const removeTenantId = () => {
  wsCache.delete(TenantIdKey)
}

export const removeDeptId = () => {
  wsCache.delete(deptIdKey)
}

export const getDeptId = () => {
  return wsCache.get(deptIdKey)
}
export const setDeptId = (deptId: string) => {
  wsCache.set(deptIdKey, deptId)
}

