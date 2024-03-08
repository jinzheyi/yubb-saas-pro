import request from '@/config/axios'

export interface PlugAppBuyVO {
  id: number
  note: string
}

// 查询插件应用列表
export const getPlugAppPage = async (params: PageParam) => {
  return await request.get({ url: '/tenant/plug-app/page', params })
}

// 查询插件应用详情
export const getPlugApp = async (id: number) => {
  return await request.get({ url: '/tenant/plug-app/get?id=' + id })
}

// 购买插件应用
export const plugAppBuy = async (data: PlugAppBuyVO) => {
  return await request.post({ url: '/tenant/plug-app/buy', data })
}
