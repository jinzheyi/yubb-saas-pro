import request from '@/utils/request'

// 查询角色列表
export function listRole(query) {
  return request({
    url: '/platform/role/page',
    method: 'get',
    params: query
  })
}

// 查询角色（精简)列表
export function listSimpleRoles() {
  return request({
    url: '/platform/role/list-all-simple',
    method: 'get'
  })
}

// 查询角色详细
export function getRole(roleId) {
  return request({
    url: '/platform/role/get?id=' + roleId,
    method: 'get'
  })
}

// 新增角色
export function addRole(data) {
  return request({
    url: '/platform/role/create',
    method: 'post',
    data: data
  })
}

// 修改角色
export function updateRole(data) {
  return request({
    url: '/platform/role/update',
    method: 'put',
    data: data
  })
}

// 角色状态修改
export function changeRoleStatus(id, status) {
  const data = {
    id,
    status
  }
  return request({
    url: '/platform/role/update-status',
    method: 'put',
    data: data
  })
}

// 删除角色
export function delRole(roleId) {
  return request({
    url: '/platform/role/delete?id=' + roleId,
    method: 'delete'
  })
}

// 导出角色
export function exportRole(query) {
  return request({
    url: '/platform/role/export',
    method: 'get',
    params: query,
    responseType: 'blob'
  })
}
