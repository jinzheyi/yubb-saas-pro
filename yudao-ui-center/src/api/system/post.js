import request from '@/utils/request'

// 查询岗位列表
export function listPost(query) {
  return request({
    url: '/center/post/page',
    method: 'get',
    params: query
  })
}

// 获取岗位精简信息列表
export function listSimplePosts() {
  return request({
    url: '/center/post/list-all-simple',
    method: 'get'
  })
}

// 查询岗位详细
export function getPost(postId) {
  return request({
    url: '/center/post/get?id=' + postId,
    method: 'get'
  })
}

// 新增岗位
export function addPost(data) {
  return request({
    url: '/center/post/create',
    method: 'post',
    data: data
  })
}

// 修改岗位
export function updatePost(data) {
  return request({
    url: '/center/post/update',
    method: 'put',
    data: data
  })
}

// 删除岗位
export function delPost(postId) {
  return request({
    url: '/center/post/delete?id=' + postId,
    method: 'delete'
  })
}

// 导出岗位
export function exportPost(query) {
  return request({
    url: '/center/post/export',
    method: 'get',
    params: query,
    responseType: 'blob'
  })
}
