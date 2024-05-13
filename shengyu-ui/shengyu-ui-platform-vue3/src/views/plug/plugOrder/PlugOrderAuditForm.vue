<template>
  <Dialog v-model="dialogVisible" title="插件订单审批">
    <el-form
      ref="formRef"
      v-loading="formLoading"
      :model="formData"
      :rules="formRules"
      label-width="140px"
    >
      <el-form-item label="订单状态" prop="orderStatus">
        <el-select v-model="formData.orderStatus" placeholder="请选择订单状态">
          <el-option
            v-for="dict in getIntDictOptions(DICT_TYPE.PLUG_ORDER_STATUS)"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="审核描述" prop="auditNote">
        <el-input v-model="formData.auditNote" placeholder="请输入审核描述" type="textarea" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button :disabled="formLoading" type="primary" @click="submitForm">确 定</el-button>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import { DICT_TYPE, getIntDictOptions } from '@/utils/dict'
import * as PlugOrderApi from '@/api/plug/plugOrder'

defineOptions({ name: 'PlugOrderAuditForm' })

const { t } = useI18n() // 国际化
const message = useMessage() // 消息弹窗
const dialogVisible = ref(false) // 弹窗的是否展示
const dialogTitle = ref('') // 弹窗的标题
const formLoading = ref(false) // 表单的加载中：1）修改时的数据加载；2）提交的按钮禁用

// 审核订单表单相关
const formData = ref({
  id: undefined,
  orderStatus: undefined,
  auditNote: undefined
})
const formRules = reactive({
  orderStatus: [{ required: true, message: '订单状态不能为空', trigger: 'change' }]
})
const formRef = ref() // 表单 Ref

const open = async (id: number) => {
  dialogVisible.value = true
  resetForm()
  // 设置数据
  formLoading.value = true
  try {
    // 设置动态表单
    formData.value.id = id
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
