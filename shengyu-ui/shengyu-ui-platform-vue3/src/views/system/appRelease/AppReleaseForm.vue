<template>
  <Dialog v-model="dialogVisible" :title="dialogTitle" width="760">
    <el-form
      ref="formRef"
      v-loading="formLoading"
      :model="formData"
      :rules="formRules"
      label-width="120px"
    >
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="应用标识" prop="appKey">
            <el-input v-model="formData.appKey" placeholder="请输入应用标识" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="渠道" prop="channel">
            <el-input v-model="formData.channel" placeholder="请输入渠道" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="平台" prop="platform">
            <el-select v-model="formData.platform" placeholder="请选择平台" class="w-1/1">
              <el-option label="Android" value="android" />
              <el-option label="iOS" value="ios" />
              <el-option label="鸿蒙" value="harmony" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="更新类型" prop="updateType">
            <el-select v-model="formData.updateType" placeholder="请选择更新类型" class="w-1/1">
              <el-option label="整包更新" value="FULL" />
              <el-option label="Dart OTA 补丁" value="PATCH" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="版本名" prop="versionName">
            <el-input v-model="formData.versionName" placeholder="例如 1.0.4" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="构建号" prop="versionCode">
            <el-input-number v-model="formData.versionCode" :min="1" class="w-1/1" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="最低可用构建号" prop="minSupportedVersionCode">
            <el-input-number v-model="formData.minSupportedVersionCode" :min="1" class="w-1/1" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="强制更新" prop="forceUpdate">
            <el-switch v-model="formData.forceUpdate" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="更新标题" prop="title">
        <el-input v-model="formData.title" placeholder="请输入更新标题" />
      </el-form-item>
      <el-form-item label="更新日志" prop="changelog">
        <el-input
          v-model="formData.changelog"
          type="textarea"
          :rows="4"
          placeholder="请输入本次更新内容"
        />
      </el-form-item>
      <el-form-item label="下载/跳转地址" prop="packageUrl">
        <el-input v-model="formData.packageUrl" placeholder="请输入 APK、商店或分发页地址" />
      </el-form-item>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="包大小(Byte)" prop="packageSize">
            <el-input-number v-model="formData.packageSize" :min="0" class="w-1/1" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="SHA-256" prop="sha256">
            <el-input v-model="formData.sha256" placeholder="Android APK 校验值" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row v-if="formData.updateType === 'PATCH'" :gutter="16">
        <el-col :span="8">
          <el-form-item label="补丁提供商" prop="patchProvider">
            <el-input v-model="formData.patchProvider" placeholder="shorebird" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="补丁基线" prop="patchReleaseId">
            <el-input v-model="formData.patchReleaseId" placeholder="release id" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="补丁号" prop="patchNo">
            <el-input-number v-model="formData.patchNo" :min="0" class="w-1/1" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="内部备注" prop="remark">
        <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button :disabled="formLoading" type="primary" @click="submitForm">确 定</el-button>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>

<script lang="ts" setup>
import * as AppReleaseApi from '@/api/system/appRelease'

defineOptions({ name: 'SystemAppReleaseForm' })

const { t } = useI18n()
const message = useMessage()

const dialogVisible = ref(false)
const dialogTitle = ref('')
const formLoading = ref(false)
const formType = ref('')
const formData = ref<AppReleaseApi.AppReleaseVO>({
  appKey: 'yuxin',
  platform: 'android',
  channel: 'prod',
  versionName: '',
  versionCode: 1,
  minSupportedVersionCode: 1,
  updateType: 'FULL',
  forceUpdate: false,
  title: '钰信更新',
  changelog: '',
  packageUrl: '',
  packageSize: undefined,
  sha256: '',
  remark: '',
  patchProvider: '',
  patchReleaseId: '',
  patchNo: undefined
})
const formRules = reactive({
  appKey: [{ required: true, message: '应用标识不能为空', trigger: 'blur' }],
  platform: [{ required: true, message: '平台不能为空', trigger: 'change' }],
  channel: [{ required: true, message: '渠道不能为空', trigger: 'blur' }],
  versionName: [{ required: true, message: '版本名不能为空', trigger: 'blur' }],
  versionCode: [{ required: true, message: '构建号不能为空', trigger: 'blur' }],
  minSupportedVersionCode: [{ required: true, message: '最低可用构建号不能为空', trigger: 'blur' }],
  updateType: [{ required: true, message: '更新类型不能为空', trigger: 'change' }],
  title: [{ required: true, message: '更新标题不能为空', trigger: 'blur' }],
  changelog: [{ required: true, message: '更新日志不能为空', trigger: 'blur' }],
  packageUrl: [
    {
      validator: (_rule: unknown, value: string, callback: (error?: Error) => void) => {
        if (formData.value.updateType === 'FULL' && !value) {
          callback(new Error('整包更新必须填写下载或跳转地址'))
          return
        }
        callback()
      },
      trigger: 'blur'
    }
  ]
})
const formRef = ref()

const open = async (type: string, id?: number) => {
  dialogVisible.value = true
  dialogTitle.value = t('action.' + type)
  formType.value = type
  resetForm()
  if (id) {
    formLoading.value = true
    try {
      formData.value = await AppReleaseApi.getAppRelease(id)
    } finally {
      formLoading.value = false
    }
  }
}
defineExpose({ open })

const emit = defineEmits(['success'])
const submitForm = async () => {
  if (!formRef.value) return
  const valid = await formRef.value.validate()
  if (!valid) return
  formLoading.value = true
  try {
    const data = formData.value
    if (formType.value === 'create') {
      await AppReleaseApi.createAppRelease(data)
      message.success(t('common.createSuccess'))
    } else {
      await AppReleaseApi.updateAppRelease(data)
      message.success(t('common.updateSuccess'))
    }
    dialogVisible.value = false
    emit('success')
  } finally {
    formLoading.value = false
  }
}

const resetForm = () => {
  formData.value = {
    appKey: 'yuxin',
    platform: 'android',
    channel: 'prod',
    versionName: '',
    versionCode: 1,
    minSupportedVersionCode: 1,
    updateType: 'FULL',
    forceUpdate: false,
    title: '钰信更新',
    changelog: '',
    packageUrl: '',
    packageSize: undefined,
    sha256: '',
    remark: '',
    patchProvider: '',
    patchReleaseId: '',
    patchNo: undefined
  }
  formRef.value?.resetFields()
}
</script>
