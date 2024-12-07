import request from '@/config/axios'

export interface PlugAppVO {
  id: number
  name: string
  outline: string
  appSn: string
  status: number
  enable: number
  mainPic: string
  description: string
}

// 查询插件应用列表
export const getPlugAppPage = async (params: PageParam) => {
  return await request.get({ url: '/plug/plug-app/page', params })
}

// 获取插件精简信息列表
export const getSimplePlugList = async () => {
  return await request.get({ url: '/plug/plug-app/list' })
}

// 获得模块条码列表
export const getSubModuleList = async () => {
  return await request.get({ url: '/plug/plug-app/app-sn-sub-module' })
}

// 查询插件应用详情
export const getPlugApp = async (id: number) => {
  return await request.get({ url: '/plug/plug-app/get?id=' + id })
}

// 新增插件应用
export const createPlugApp = async (data: PlugAppVO) => {
  return await request.post({ url: '/plug/plug-app/create', data })
}

// 修改插件应用
export const updatePlugApp = async (data: PlugAppVO) => {
  return await request.put({ url: '/plug/plug-app/update', data })
}

// 导出插件应用
export const exportPlugApp = async (params) => {
  return await request.download({ url: '/plug/plug-app/export-excel', params })
}

// 上下架状态修改
export const updatePlugStatus = (id: number, status: number) => {
  const data = {
    id,
    status
  }
  return request.put({ url: '/plug/plug-app/update-status', data: data })
}

// 启用停用状态修改
export const updatePlugEnable = (id: number, enable: number) => {
  const data = {
    id,
    enable
  }
  return request.put({ url: '/plug/plug-app/update-enable', data: data })
}
