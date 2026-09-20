import request from '@/config/axios'

export interface PlatformDashboardOverview {
  tenantCount: number
  enabledTenantCount: number
  tenantUserCount: number
  platformUserCount: number
  platformOnlineCount: number
  tenantOnlineCount: number
  recentTenants: Array<{ id: number; name: string; accountCount: number; expireTime?: string | number; createTime: string | number }>
  recentNotices: Array<{ id: number; title: string; type: number; createTime: string | number }>
}

export const getPlatformDashboardOverview = () =>
  request.get<PlatformDashboardOverview>({ url: '/system/dashboard/platform-overview' })
