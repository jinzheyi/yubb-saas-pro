import request from '@/config/axios'

export interface TenantMenuVO {
  id: number
  name: string
  permission: string
  type: number
  sort: number
  parentId: number
  path: string
  icon: string
  component: string
  componentName?: string
  status: number
  visible: boolean
  keepAlive: boolean
  alwaysShow?: boolean
  createTime: Date
  dimension: number,
  plugAppSn: string
}

// 查询菜单（精简）列表
export const getSimpleTenantMenusList = () => {
  return request.get({ url: '/system/tenant-menu/list-all-simple' })
}

// 查询应用插件菜单（精简）列表
export const getSimpleTenantPlugMenusList = (plugAppSn: string) => {
  return request.get({ url: '/system/tenant-menu/list-all-plug-simple?plugAppSn=' + plugAppSn })
}

// 查询菜单列表
export const getTenantMenuList = (params) => {
  return request.get({ url: '/system/tenant-menu/list', params })
}

// 获取菜单详情
export const getTenantMenu = (id: number) => {
  return request.get({ url: '/system/tenant-menu/get?id=' + id })
}

// 新增菜单
export const createTenantMenu = (data: TenantMenuVO) => {
  return request.post({ url: '/system/tenant-menu/create', data })
}

// 修改菜单
export const updateTenantMenu = (data: TenantMenuVO) => {
  return request.put({ url: '/system/tenant-menu/update', data })
}

// 删除菜单
export const deleteTenantMenu = (id: number) => {
  return request.delete({ url: '/system/tenant-menu/delete?id=' + id })
}
