import request from '@/config/axios'

export const getInviteList = () => request.get({ url: '/system/tenant-invite/list' })
export const getApplyList = () => request.get({ url: '/system/tenant-invite/apply-list' })
export const createInvite = (data: any) => request.post({ url: '/system/tenant-invite/create', data })
export const disableInvite = (id: number) => request.post({ url: '/system/tenant-invite/disable?id=' + id })
export const approveApply = (applyId: number, approved: boolean) => request.post({ url: `/system/tenant-invite/approve?applyId=${applyId}&approved=${approved}` })
