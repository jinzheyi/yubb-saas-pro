<template>
  <Dialog title="详情" v-model="dialogVisible">
    <el-form :model="formData" label-width="100px" v-loading="formLoading">
      <el-form-item label="应用名称：" prop="name">
        {{ formData.name }}
      </el-form-item>
      <el-form-item label="概要描述：" prop="outline">
        {{ formData.outline }}
      </el-form-item>
      <el-form-item label="应用主图：">
        <!-- 图片的显示 -->
        <img :src="formData.mainPic" width="200" height="200" />
      </el-form-item>
      <el-form-item label="描述：">
        <Editor :model-value="formData.description" height="150px" readonly />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import * as PlugAppApi from '@/api/plug/plugApp'

defineOptions({ name: 'PlugAppBuyForm' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const dialogVisible = ref(false) // 弹窗的是否展示
const formLoading = ref(false) // 表单的加载中
const formData = ref({
  id: undefined,
  name: undefined,
  outline: undefined,
  appSn: undefined,
  mainPic: undefined,
  description: undefined
})

/** 打开弹窗 */
const getPlugAppDetail = async (id: number) => {
  dialogVisible.value = true
  resetForm()
  formLoading.value = true
  try {
    formData.value = await PlugAppApi.getPlugApp(id)
  } finally {
    formLoading.value = false
  }
}
defineExpose({ getPlugAppDetail }) // 提供 open 方法，用于打开弹窗

/** 重置表单 */
const resetForm = () => {
  formData.value = {
    id: undefined,
    name: undefined,
    outline: undefined,
    appSn: undefined,
    mainPic: undefined,
    description: undefined
  }
}
</script>
