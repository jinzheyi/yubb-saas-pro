<template>
  <Form ref="formRef" :labelWidth="200" :rules="rules" :schema="schema">
    <template #sex="form">
      <el-radio-group v-model="form['sex']">
        <el-radio :label="1">{{ t('profile.user.man') }}</el-radio>
        <el-radio :label="2">{{ t('profile.user.woman') }}</el-radio>
      </el-radio-group>
    </template>
  </Form>
  <div style="text-align: center">
    <XButton :title="t('common.save')" type="primary" @click="submit()" />
    <XButton :title="t('common.reset')" type="danger" @click="init()" />
  </div>
</template>
<script lang="ts" setup>
import type { FormRules } from 'element-plus'
import { FormSchema } from '@/types/form'
import type { FormExpose } from '@/components/Form'
import {
  getUserProfile,
  updateUserProfile,
  UserProfileUpdateReqVO
} from '@/api/system/user/profile'

defineOptions({ name: 'BasicInfo' })

const { t } = useI18n()
const message = useMessage() // 消息弹窗
// 表单校验
const rules = reactive<FormRules>({
  nickname: [{ required: true, message: t('profile.rules.nickname'), trigger: 'blur' }]
  // ,
  // username: [
  //   { message: t('profile.rules.mail'), trigger: 'blur' },
  //   {
  //     type: 'email',
  //     message: t('profile.rules.truemail'),
  //     trigger: ['blur', 'change']
  //   }
  // ],
  // mobile: [
  //   { message: t('profile.rules.phone'), trigger: 'blur' },
  //   {
  //     pattern: /^1[3|4|5|6|7|8|9][0-9]\d{8}$/,
  //     message: t('profile.rules.truephone'),
  //     trigger: 'blur'
  //   }
  // ]
})
const schema = reactive<FormSchema[]>([
  {
    field: 'nickname',
    label: t('profile.user.nickname'),
    component: 'Input'
  },
  // {
  //   field: 'username',
  //   label: t('profile.user.username'),
  //   component: 'Input'
  // },
  // {
  //   field: 'mobile',
  //   label: t('profile.user.mobile'),
  //   component: 'Input'
  // },
  {
    field: 'sex',
    label: t('profile.user.sex'),
    component: 'InputNumber',
    value: 0
  }
])
const formRef = ref<FormExpose>() // 表单 Ref
const submit = () => {
  const elForm = unref(formRef)?.getElFormRef()
  if (!elForm) return
  elForm.validate(async (valid) => {
    if (valid) {
      const data = unref(formRef)?.formModel as UserProfileUpdateReqVO
      await updateUserProfile(data)
      message.success(t('common.updateSuccess'))
      const profile = await init()
      await userStore.setUserNicknameAction(profile.nickname)
      // 发送成功事件
      emit('success')
    }
  })
}
const init = async () => {
  const res = await getUserProfile()
  unref(formRef)?.setValues(res)
}
onMounted(async () => {
  await init()
})
</script>
