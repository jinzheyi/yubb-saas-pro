import request from '@/utils/request'

// 创建应用商品
export function createGoods(data) {
  return request({
    url: '/center/plug-goods/create',
    method: 'post',
    data: data
  })
}

// 更新应用商品
export function updateGoods(data) {
  return request({
    url: '/center/plug-goods/update',
    method: 'put',
    data: data
  })
}

// 删除应用商品
export function deleteGoods(id) {
  return request({
    url: '/center/plug-goods/delete?id=' + id,
    method: 'delete'
  })
}

// 获得应用商品
export function getGoods(id) {
  return request({
    url: '/center/plug-goods/get?id=' + id,
    method: 'get'
  })
}

// 获得应用商品分页
export function getGoodsPage(query) {
  return request({
    url: '/center/plug-goods/page',
    method: 'get',
    params: query
  })
}

// 导出应用商品 Excel
export function exportGoodsExcel(query) {
  return request({
    url: '/center/plug-goods/export-excel',
    method: 'get',
    params: query,
    responseType: 'blob'
  })
}
