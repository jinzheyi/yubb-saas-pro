<template>
  <Dialog :title="dialogTitle" v-model="dialogVisible">
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="100px"
      v-loading="formLoading"
    >
      <el-form-item label="应用名称" prop="name">
        <el-input v-model="formData.name" placeholder="请输入应用名称" />
      </el-form-item>
      <el-form-item label="概要描述" prop="outline">
        <el-input v-model="formData.outline" placeholder="请输入概要描述" type="textarea" />
      </el-form-item>
      <el-form-item label="模块条码" prop="appSn">
        <template #label>
          <Tooltip
            message="添加一个插件时需要选择模块条码，选择的内容需要开发人员定向研发才能提供选择"
            title="模块条码"
          />
        </template>
        <el-select v-model="formData.appSn" :disabled="typeof formData.id !== 'undefined'" placeholder="请选择模块条码">
          <el-option
            v-for="item in subModuleList"
            :key="item.code"
            :label="item.name"
            :value="item.code"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="应用主图地址" prop="mainPic">
        <UploadImg v-model="formData.mainPic" />
      </el-form-item>
      <el-form-item label="描述" prop="description">
        <Editor v-model="formData.description" height="150px" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="submitForm" type="primary" :disabled="formLoading">确 定</el-button>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import * as PlugAppApi from '@/api/plug/plugApp'

defineOptions({ name: 'PlugAppForm' })

const { t } = useI18n() // 国际化
const message = useMessage() // 消息弹窗

const dialogVisible = ref(false) // 弹窗的是否展示
const dialogTitle = ref('') // 弹窗的标题
const formLoading = ref(false) // 表单的加载中：1）修改时的数据加载；2）提交的按钮禁用
const formType = ref('') // 表单的类型：create - 新增；update - 修改
const formData = ref({
  id: undefined,
  name: undefined,
  outline: '',
  appSn: undefined,
  mainPic: undefined,
  description: ''
})
const formRules = reactive({
  name: [{ required: true, message: '应用名称不能为空', trigger: 'blur' }],
  outline: [{ required: true, message: '概要描述不能为空', trigger: 'blur' }],
  appSn: [{ required: true, message: '条码不能为空', trigger: 'change' }],
  mainPic: [{ required: true, message: '应用主图地址不能为空', trigger: 'blur' }]
})
const formRef = ref() // 表单 Ref
const subModuleList = ref([]) // 模块条码列表

/** 打开弹窗 */
const open = async (type: string, id?: number) => {
  dialogVisible.value = true
  dialogTitle.value = t('action.' + type)
  formType.value = type
  resetForm()
  // 修改时，设置数据
  if (id) {
    formLoading.value = true
    try {
      formData.value = await PlugAppApi.getPlugApp(id)
    } finally {
      formLoading.value = false
    }
  }
  // 加载模块条码列表
  subModuleList.value = await PlugAppApi.getSubModuleList()
}
defineExpose({ open }) // 提供 open 方法，用于打开弹窗

/** 提交表单 */
const emit = defineEmits(['success']) // 定义 success 事件，用于操作成功后的回调
const submitForm = async () => {
  // 校验表单
  if (!formRef) return
  const valid = await formRef.value.validate()
  if (!valid) return
  // 提交请求
  formLoading.value = true
  try {
    const data = formData.value as unknown as PlugAppApi.PlugAppVO
    if (formType.value === 'create') {
      await PlugAppApi.createPlugApp(data)
      message.success(t('common.createSuccess'))
    } else {
      await PlugAppApi.updatePlugApp(data)
      message.success(t('common.updateSuccess'))
    }
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
    name: undefined,
    outline: '',
    appSn: undefined,
    mainPic: undefined,
    description: ''
  }
  formRef.value?.resetFields()
}
</script>
