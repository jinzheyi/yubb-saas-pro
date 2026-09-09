<template>
  <ContentWrap>
    <el-button type="primary" @click="dialogVisible = true"><Icon icon="ep:plus" class="mr-5px" />新建邀请码</el-button>
    <el-table :data="invites" class="mt-16px"><el-table-column prop="name" label="名称" /><el-table-column prop="inviteCode" label="邀请码" /><el-table-column prop="usedCount" label="已使用" /><el-table-column label="状态"><template #default="{ row }"><el-tag :type="row.status === 0 ? 'success' : 'info'">{{ row.status === 0 ? '启用' : '已停用' }}</el-tag></template></el-table-column><el-table-column label="操作"><template #default="{ row }"><el-button v-if="row.status === 0" link type="danger" @click="disable(row.id)">停用</el-button></template></el-table-column></el-table>
  </ContentWrap>
  <ContentWrap><template #header><span>加入申请</span></template><el-table :data="applies"><el-table-column prop="saasUserId" label="申请账号" /><el-table-column prop="status" label="状态"><template #default="{ row }">{{ ['待审批', '已通过', '已拒绝'][row.status] }}</template></el-table-column><el-table-column label="操作"><template #default="{ row }"><template v-if="row.status === 0"><el-button link type="primary" @click="audit(row.id, true)">通过</el-button><el-button link type="danger" @click="audit(row.id, false)">拒绝</el-button></template></template></el-table-column></el-table></ContentWrap>
  <el-dialog v-model="dialogVisible" title="新建邀请码" width="420px"><el-form :model="form" label-width="100px"><el-form-item label="名称"><el-input v-model="form.name" /></el-form-item><el-form-item label="使用次数"><el-input-number v-model="form.maxUseCount" :min="0" /><span class="ml-8px text-gray">0 为不限</span></el-form-item><el-form-item label="自动通过"><el-switch v-model="form.autoApprove" /></el-form-item></el-form><template #footer><el-button @click="dialogVisible=false">取消</el-button><el-button type="primary" @click="create">创建</el-button></template></el-dialog>
</template>
<script setup lang="ts">
import * as Api from '@/api/system/tenantInvite'
defineOptions({ name: 'TenantInvite' })
const message = useMessage(); const invites = ref<any[]>([]); const applies = ref<any[]>([]); const dialogVisible = ref(false); const form = reactive({ name: '企业邀请', maxUseCount: 0, autoApprove: true })
const load = async () => { [invites.value, applies.value] = await Promise.all([Api.getInviteList(), Api.getApplyList()]) }
const create = async () => { await Api.createInvite(form); message.success('邀请码已创建'); dialogVisible.value=false; load() }
const disable = async (id:number) => { await Api.disableInvite(id); message.success('已停用'); load() }
const audit = async (id:number, yes:boolean) => { await Api.approveApply(id, yes); message.success(yes ? '已通过' : '已拒绝'); load() }
onMounted(load)
</script>
