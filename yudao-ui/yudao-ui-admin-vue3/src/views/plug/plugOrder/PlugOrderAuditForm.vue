<template>
  <Dialog v-model="dialogVisible" title="重提插件订单">
    <el-form
      ref="formRef"
      v-loading="formLoading"
      :model="formData"
      :rules="formRules"
      label-width="140px"
    >
      <el-form-item label="原因" prop="note">
        <el-input v-model="formData.note" placeholder="请输入重提审核原因" type="textarea" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button :disabled="formLoading" type="primary" @click="submitForm">确 定</el-button>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import * as PlugOrderApi from '@/api/plug/plugOrder'

defineOptions({ name: 'PlugOrderAuditForm' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const dialogVisible = ref(false) // 弹窗的是否展示
const formLoading = ref(false) // 表单的加载中：1）修改时的数据加载；2）提交的按钮禁用

// 审核订单表单相关
const formData = ref({
  id: undefined,
  note: undefined
})
const formRules = reactive({})
const formRef = ref() // 表单 Ref

const open = async (id: number) => {
  dialogVisible.value = true
  resetForm()
  // 设置数据
  formLoading.value = true
  try {
    // 设置动态表单
    formData.value = await PlugOrderApi.getPlugOrder(id)
  } finally {
    formLoading.value = false
  }
}
defineExpose({ open }) // 提供 open 方法，用于打开弹窗
/** 提交表单 */
const emit = defineEmits(['success']) // 定义 success 事件，用于操作成功后的回调
/** 提交表单 */
const submitForm = async () => {
  // 校验表单
  if (!formRef) return
  const valid = await formRef.value.validate()
  if (!valid) return
  // 提交请求
  formLoading.value = true
  try {
    const data = formData.value as PlugOrderApi.AuditPlugOrderReqVO
    await PlugOrderApi.auditPlugOrder(data)
    message.success('审批成功')
    dialogVisible.value = false
    // 发送操作成功的事件
    emit('success')
  } finally {
    formLoading.value = false
  }
}

/** 重置表单 */
const resetForm = () => {
  formData.value = {
    id: undefined,
    orderStatus: undefined,
    auditNote: undefined
  }
  formRef.value?.resetFields()
}
</script>
