import request from '@/config/axios'

export interface TenantDashboardOverview {
  userCount: number
  enabledUserCount: number
  unreadMessageCount: number
  recentNotices: Array<{ id: number; title: string; type: number; createTime: string | number }>
}

export const getTenantDashboardOverview = () =>
  request.get<TenantDashboardOverview>({ url: '/system/dashboard/tenant-overview' })
