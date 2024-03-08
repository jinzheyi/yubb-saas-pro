import request from '@/config/axios'

export interface TenantAppVO {
  id: number
  name: string
  outline: string
  appSn: string
  status: number
  enable: number
  mainPic: string
  description: string
}

// 查询租户插件应用列表
export const getTenantAppPage = async (params: PageParam) => {
  return await request.get({ url: '/plug/tenant/page', params })
}

// 查询租户插件应用详情
export const getTenantApp = async (id: number) => {
  return await request.get({ url: '/plug/tenant/get?id=' + id })
}

// 上下架状态修改
export const updateTenantPlugStatus = (id: number, status: number) => {
  const data = {
    id,
    status
  }
  return request.put({ url: '/plug/tenant/update-status', data: data })
}
