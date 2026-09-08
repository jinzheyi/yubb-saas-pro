<template>
  <Dialog v-model="dialogVisible" :title="dialogTitle" width="760">
    <el-form
      ref="formRef"
      v-loading="formLoading"
      :model="formData"
      :rules="formRules"
      label-width="132px"
    >
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item prop="appKey">
            <template #label
              ><FormLabel
                label="应用标识"
                tip="钰信正式环境固定填写 yuxin。它用于把客户端的检查请求匹配到正确应用。"
            /></template>
            <el-input v-model="formData.appKey" placeholder="例如 yuxin" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="channel">
            <template #label
              ><FormLabel
                label="渠道"
                tip="正式用户固定 prod。只有确实维护了独立测试包时，才使用 test、beta 等其他渠道。"
            /></template>
            <el-input v-model="formData.channel" placeholder="例如 prod" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item prop="platform">
            <template #label
              ><FormLabel
                label="平台"
                tip="决定可上传的安装包类型：Android 仅 APK，iOS 仅 IPA，鸿蒙仅 HAP 或 APP。切换平台不会清空已填写内容，请自行确认后再保存。"
            /></template>
            <el-select v-model="formData.platform" placeholder="请选择平台" class="w-1/1">
              <el-option label="Android" value="android" />
              <el-option label="iOS" value="ios" />
              <el-option label="鸿蒙" value="harmony" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="updateType">
            <template #label
              ><FormLabel
                label="更新类型"
                tip="当前正式客户端仅支持整包更新。Dart OTA 补丁尚未接入客户端执行器，不能用于生产发布。"
            /></template>
            <el-select v-model="formData.updateType" placeholder="请选择更新类型" class="w-1/1">
              <el-option label="整包更新" value="FULL" />
              <el-option label="Dart OTA 补丁（二期）" value="PATCH" disabled />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item prop="versionName">
            <template #label
              ><FormLabel
                label="版本名"
                tip="用户可见版本，例如 Flutter pubspec.yaml 中 version: 1.0.2+3 的 1.0.2。"
            /></template>
            <el-input v-model="formData.versionName" placeholder="例如 1.0.2" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="versionCode">
            <template #label
              ><FormLabel
                label="构建号"
                tip="版本比较的唯一递增整数，对应 Flutter version 中 + 后的数字。新发布值必须大于客户端当前构建号。"
            /></template>
            <el-input-number v-model="formData.versionCode" :min="1" class="w-1/1" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item prop="minSupportedVersionCode">
            <template #label
              ><FormLabel
                label="最低可用构建号"
                tip="低于该构建号的客户端会被判定为强制更新。普通更新一般填仍允许使用的最早构建号。"
            /></template>
            <el-input-number v-model="formData.minSupportedVersionCode" :min="1" class="w-1/1" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="forceUpdate">
            <template #label
              ><FormLabel
                label="强制更新"
                tip="开启后客户端不能跳过更新。仅限严重安全问题、服务协议不兼容或必须下线旧版本时使用。"
            /></template>
            <el-switch v-model="formData.forceUpdate" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item v-if="formData.updateType === 'FULL'">
        <template #label><FormLabel label="安装包上传" :tip="packageUploadTip" /></template>
        <div class="flex items-center gap-10px">
          <el-upload
            :accept="packageAccept"
            :auto-upload="true"
            :before-upload="beforePackageUpload"
            :http-request="uploadPackage"
            :show-file-list="false"
          >
            <el-button :loading="packageUploading" type="primary" plain>
              <Icon icon="ep:upload-filled" class="mr-5px" />
              上传 {{ packageExtensionText }}
            </el-button>
          </el-upload>
          <span class="text-12px text-gray-500"
            >上传后自动回填地址、大小与 SHA-256，仍可人工修改。</span
          >
        </div>
      </el-form-item>
      <el-form-item prop="packageUrl">
        <template #label><FormLabel label="下载/跳转地址" :tip="packageUrlTip" /></template>
        <el-input v-model="formData.packageUrl" :placeholder="packageUrlPlaceholder" clearable />
      </el-form-item>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item prop="packageSize">
            <template #label
              ><FormLabel
                label="包大小（Byte）"
                tip="上传安装包后由服务器自动计算。保留可编辑，用于填写外部商店或分发平台展示的实际包大小。"
            /></template>
            <el-input-number v-model="formData.packageSize" :min="0" class="w-1/1" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item prop="sha256">
            <template #label
              ><FormLabel
                label="SHA-256"
                tip="上传安装包后由服务器自动计算。Android 客户端会在安装前校验；外部链接可按分发方提供的值填写或留空。"
            /></template>
            <el-input v-model="formData.sha256" placeholder="上传后自动回填" clearable />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item prop="title">
        <template #label
          ><FormLabel label="更新标题" tip="展示给用户的更新标题，例如“钰信 1.0.2 更新”。"
        /></template>
        <el-input v-model="formData.title" placeholder="请输入更新标题" />
      </el-form-item>
      <el-form-item prop="changelog">
        <template #label
          ><FormLabel
            label="更新日志"
            tip="展示给用户的本次变更说明。建议写 1 至 5 条用户关心的变化，不要包含内部口令或服务器信息。"
        /></template>
        <el-input
          v-model="formData.changelog"
          type="textarea"
          :rows="4"
          placeholder="请输入本次更新内容"
        />
      </el-form-item>
      <el-row v-if="formData.updateType === 'PATCH'" :gutter="16">
        <el-col :span="8">
          <el-form-item prop="patchProvider">
            <template #label
              ><FormLabel
                label="补丁提供商"
                tip="二期 Dart OTA 能力预留字段；当前不要用于生产发布。"
            /></template>
            <el-input v-model="formData.patchProvider" placeholder="shorebird" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item prop="patchReleaseId">
            <template #label
              ><FormLabel label="补丁基线" tip="二期 Dart OTA 的基础发行版本标识。"
            /></template>
            <el-input v-model="formData.patchReleaseId" placeholder="release id" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item prop="patchNo">
            <template #label
              ><FormLabel label="补丁号" tip="二期 Dart OTA 同一基线下的递增补丁编号。"
            /></template>
            <el-input-number v-model="formData.patchNo" :min="0" class="w-1/1" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item prop="remark">
        <template #label
          ><FormLabel
            label="内部备注"
            tip="仅后台管理员可见。可记录测试范围、签名证书、回滚原因等，不会展示给用户。"
        /></template>
        <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button :disabled="formLoading || packageUploading" type="primary" @click="submitForm"
        >确 定</el-button
      >
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>

<script lang="ts" setup>
import { ElTooltip, type UploadProps, type UploadRequestOptions } from 'element-plus'
import { defineComponent, h } from 'vue'
import { Icon } from '@/components/Icon'
import * as AppReleaseApi from '@/api/system/appRelease'

defineOptions({ name: 'SystemAppReleaseForm' })

const FormLabel = defineComponent({
  name: 'AppReleaseFormLabel',
  props: { label: { type: String, required: true }, tip: { type: String, required: true } },
  setup(props) {
    return () =>
      h('span', { class: 'inline-flex items-center' }, [
        props.label,
        h(
          ElTooltip,
          { content: props.tip, placement: 'top', showAfter: 200 },
          {
            default: () =>
              h(Icon, { icon: 'ep:question-filled', class: 'ml-4px cursor-help text-gray-400' })
          }
        )
      ])
  }
})

const { t } = useI18n()
const message = useMessage()
const dialogVisible = ref(false)
const dialogTitle = ref('')
const formLoading = ref(false)
const packageUploading = ref(false)
const formType = ref('')
const formData = ref<AppReleaseApi.AppReleaseVO>(createDefaultFormData())
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
  packageUrl: [{ validator: validatePackageUrl, trigger: 'blur' }]
})
const formRef = ref()

const packageMeta = computed(() => {
  switch (formData.value.platform) {
    case 'ios':
      return {
        extensions: ['ipa'],
        text: 'IPA',
        uploadTip:
          '上传 IPA 后由后端生成可访问地址、文件大小和 SHA-256。iOS 正式用户通常应填写 TestFlight、App Store 或企业分发链接；IPA 本身需具备有效签名。'
      }
    case 'harmony':
      return {
        extensions: ['hap', 'app'],
        text: 'HAP / APP',
        uploadTip:
          '上传鸿蒙 HAP 或 APP 后由后端生成可访问地址、文件大小和 SHA-256。鸿蒙客户端接入后会按此记录检查更新。'
      }
    default:
      return {
        extensions: ['apk'],
        text: 'APK',
        uploadTip:
          '仅上传已用正式签名签发的 APK。上传后 Android 客户端可下载并在安装前自动校验 SHA-256。'
      }
  }
})
const packageAccept = computed(() =>
  packageMeta.value.extensions.map((item) => `.${item}`).join(',')
)
const packageExtensionText = computed(() => packageMeta.value.text)
const packageUploadTip = computed(() => packageMeta.value.uploadTip)
const packageUrlPlaceholder = computed(() => {
  if (formData.value.platform === 'ios')
    return '上传 IPA 后自动回填，或填写 TestFlight / App Store / 企业分发链接'
  if (formData.value.platform === 'harmony') return '上传 HAP / APP 后自动回填，或填写可信分发链接'
  return '上传 APK 后自动回填，或填写 HTTPS APK 下载地址'
})
const packageUrlTip = computed(() => {
  if (formData.value.platform === 'ios')
    return '上传 IPA 会自动填写地址；也可人工填写 TestFlight、App Store、MDM 或企业分发页。客户端会打开该地址，不会绕过 Apple 的签名和分发规则。'
  if (formData.value.platform === 'harmony')
    return '上传 HAP/APP 会自动填写地址；也可填写鸿蒙应用市场或企业分发链接。'
  return '上传 APK 会自动填写地址。手工填写时必须使用可公开访问的 HTTPS APK 直链，且文件名应以 .apk 结尾，客户端才能下载、校验并唤起安装。'
})

function createDefaultFormData(): AppReleaseApi.AppReleaseVO {
  return {
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
}

function validatePackageUrl(_rule: unknown, value: string, callback: (error?: Error) => void) {
  if (formData.value.updateType === 'FULL' && !value) {
    callback(new Error('整包更新必须上传安装包或填写下载/跳转地址'))
    return
  }
  callback()
}

const beforePackageUpload: UploadProps['beforeUpload'] = (file) => {
  const extension = file.name.split('.').pop()?.toLowerCase()
  if (!extension || !packageMeta.value.extensions.includes(extension)) {
    message.error(`所选平台仅允许上传 ${packageMeta.value.text} 文件`)
    return false
  }
  if (file.size > 200 * 1024 * 1024) {
    message.error('安装包不能超过 200MB；更大的包请先调整服务器上传限制或使用对象存储分发')
    return false
  }
  return true
}

const uploadPackage = async (options: UploadRequestOptions) => {
  packageUploading.value = true
  try {
    const response: any = await AppReleaseApi.uploadAppReleasePackage({
      appKey: formData.value.appKey,
      platform: formData.value.platform,
      channel: formData.value.channel,
      file: options.file
    })
    if (response.code !== 0) throw new Error(response.msg || '安装包上传失败')
    const uploaded = response.data as AppReleaseApi.AppReleasePackageUploadRespVO
    formData.value.packageUrl = uploaded.packageUrl
    formData.value.packageSize = uploaded.packageSize
    formData.value.sha256 = uploaded.sha256
    options.onSuccess(response)
    message.success(`已上传 ${uploaded.fileName}，发行信息已自动回填`)
  } catch (error: any) {
    options.onError(error instanceof Error ? error : new Error('安装包上传失败'))
    message.error(error?.message || '安装包上传失败')
  } finally {
    packageUploading.value = false
  }
}

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
    if (formType.value === 'create') {
      await AppReleaseApi.createAppRelease(formData.value)
      message.success(t('common.createSuccess'))
    } else {
      await AppReleaseApi.updateAppRelease(formData.value)
      message.success(t('common.updateSuccess'))
    }
    dialogVisible.value = false
    emit('success')
  } finally {
    formLoading.value = false
  }
}

const resetForm = () => {
  formData.value = createDefaultFormData()
  formRef.value?.resetFields()
}
</script>
