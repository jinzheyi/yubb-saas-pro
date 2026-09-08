import request from '@/config/axios'

export interface AppReleaseVO {
  id?: number
  appKey: string
  platform: string
  channel: string
  versionName: string
  versionCode: number
  minSupportedVersionCode: number
  updateType: string
  forceUpdate: boolean
  title: string
  changelog: string
  packageUrl?: string
  packageSize?: number
  sha256?: string
  status?: string
  remark?: string
  patchProvider?: string
  patchReleaseId?: string
  patchNo?: number
  createTime?: Date
  updateTime?: Date
}

export interface AppReleasePackageUploadRespVO {
  packageUrl: string
  fileName: string
  packageSize: number
  sha256: string
}

export const getAppReleasePage = (params: PageParam) => {
  return request.get({ url: '/system/app-release/page', params })
}

export const getAppRelease = (id: number) => {
  return request.get({ url: '/system/app-release/get?id=' + id })
}

export const createAppRelease = (data: AppReleaseVO) => {
  return request.post({ url: '/system/app-release/create', data })
}

export const updateAppRelease = (data: AppReleaseVO) => {
  return request.put({ url: '/system/app-release/update', data })
}

export const deleteAppRelease = (id: number) => {
  return request.delete({ url: '/system/app-release/delete?id=' + id })
}

export const publishAppRelease = (id: number) => {
  return request.put({ url: '/system/app-release/publish?id=' + id })
}

export const pauseAppRelease = (id: number) => {
  return request.put({ url: '/system/app-release/pause?id=' + id })
}

export const uploadAppReleasePackage = (data: {
  appKey: string
  platform: string
  channel: string
  file: File
}) => {
  return request.upload({ url: '/system/app-release/upload-package', data })
}
