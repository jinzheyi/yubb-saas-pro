import request from '@/utils/request'

// 查询菜单列表
export function listMenu(query) {
  return request({
    url: '/platform/menu/list',
    method: 'get',
    params: query
  })
}

// 查询菜单（精简)列表
export function listSimpleMenus() {
  return request({
    url: '/platform/menu/list-all-simple',
    method: 'get'
  })
}

// 查询菜单详细
export function getMenu(id) {
  return request({
    url: '/platform/menu/get?id=' + id,
    method: 'get'
  })
}

// 新增菜单
export function addMenu(data) {
  return request({
    url: '/platform/menu/create',
    method: 'post',
    data: data
  })
}

// 修改菜单
export function updateMenu(data) {
  return request({
    url: '/platform/menu/update',
    method: 'put',
    data: data
  })
}

// 删除菜单
export function delMenu(id) {
  return request({
    url: '/platform/menu/delete?id=' + id,
    method: 'delete'
  })
}
