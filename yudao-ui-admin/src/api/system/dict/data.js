import request from '@/utils/request'

// 查询字典数据详细
export function getData(dictCode) {
  return request({
    url: '/system/dict-data/get?id=' + dictCode,
    method: 'get'
  })
}

// 根据字典类型查询字典数据信息
export function getDicts(dictType) {
  return request({
    url: '/system/dict-data/type/' + dictType,
    method: 'get'
  })
}

// 查询全部字典数据列表
export function listSimpleDictDatas() {
  return request({
    url: '/system/dict-data/list-all-simple',
    method: 'get',
  })
}
