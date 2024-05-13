import request from '@/config/axios'

export interface AuditPlugOrderReqVO {
  id: number
  note: string
}

// 查询插件应用订单列表
export const getPlugOrderPage = async (params: PageParam) => {
  return await request.get({ url: '/plug/order/page', params })
}

// 查询插件应用订单详情
export const getPlugOrder = async (id: number) => {
  return await request.get({ url: '/plug/order/get?id=' + id })
}

// 重提审核插件应用订单
export const auditPlugOrder = async (data: AuditPlugOrderReqVO) => {
  return await request.put({ url: '/plug/order/commit', data })
}
