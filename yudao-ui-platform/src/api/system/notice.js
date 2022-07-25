import request from '@/utils/request'

// 查询公告列表
export function listNotice(query) {
  return request({
    url: '/platform/notice/page',
    method: 'get',
    params: query
  })
}

// 查询公告详细
export function getNotice(noticeId) {
  return request({
    url: '/platform/notice/get?id=' + noticeId,
    method: 'get'
  })
}

// 新增公告
export function addNotice(data) {
  return request({
    url: '/platform/notice/create',
    method: 'post',
    data: data
  })
}

// 修改公告
export function updateNotice(data) {
  return request({
    url: '/platform/notice/update',
    method: 'put',
    data: data
  })
}

// 删除公告
export function delNotice(noticeId) {
  return request({
    url: '/platform/notice/delete?id=' + noticeId,
    method: 'delete'
  })
}
