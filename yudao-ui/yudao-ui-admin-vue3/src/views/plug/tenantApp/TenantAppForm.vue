<template>
  <Dialog title="插件应用详情" v-model="dialogVisible">
    <el-form :model="formData" label-width="100px" v-loading="formLoading">
      <el-form-item label="应用名称:" prop="name">
        {{ formData.name }}
      </el-form-item>
      <el-form-item label="概要描述:" prop="outline">
        {{ formData.outline }}
      </el-form-item>
      <el-form-item label="平台状态:" prop="type">
        <dict-tag :type="DICT_TYPE.COMMON_STATUS" :value="formData.enable" />
      </el-form-item>
      <el-form-item label="应用主图:">
        <!-- 图片的显示 -->
        <img :src="formData.mainPic" width="200" height="200" />
      </el-form-item>
      <el-form-item label="描述:">
        <Editor :model-value="formData.description" readonly height="150px" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import { DICT_TYPE } from '@/utils/dict'
import * as TenantAppApi from '@/api/plug/tenantApp'

defineOptions({ name: 'TenantAppForm' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const dialogVisible = ref(false) // 弹窗的是否展示
const formLoading = ref(false) // 表单的加载中：1）修改时的数据加载；2）提交的按钮禁用
const formData = ref({
  id: undefined,
  name: undefined,
  outline: undefined,
  appSn: undefined,
  enable: undefined,
  mainPic: undefined,
  description: undefined
})

/** 打开弹窗 */
const getTenantAppDetail = async (id: number) => {
  dialogVisible.value = true
  resetForm()
  formLoading.value = true
  try {
    formData.value = await TenantAppApi.getTenantApp(id)
  } finally {
    formLoading.value = false
  }
}
defineExpose({ getTenantAppDetail }) // 提供 getTenantAppDetail 方法，用于打开弹窗

/** 重置表单 */
const resetForm = () => {
  formData.value = {
    id: undefined,
    name: undefined,
    outline: undefined,
    appSn: undefined,
    enable: undefined,
    mainPic: undefined,
    description: undefined
  }
}
</script>
