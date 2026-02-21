<template>
  <Dialog v-model="dialogVisible" :title="dialogTitle">
    <el-form
      ref="formRef"
      v-loading="formLoading"
      :model="formData"
      :rules="formRules"
      label-width="100px"
    >
      <el-row>
        <el-col :span="12">
          <el-form-item label="用户昵称" prop="nickname">
            <el-input v-model="formData.nickname" placeholder="请输入用户昵称" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="归属部门" prop="deptIdList">
            <el-tree-select
              multiple
              v-model="formData.deptIdList"
              :data="deptList"
              :props="defaultProps"
              check-strictly
              node-key="id"
              placeholder="请选择归属部门"
            />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row>
        <el-col :span="12">
          <el-form-item v-if="formData.id === undefined" label="邮箱账号" prop="username">
            <template #label>
              <Tooltip
                message="成员通过验证该邮箱账号后可加入租户企业,添加用户时邮箱账号或手机号必输一个"
                title="账号"
              />
            </template>
            <el-input v-model="formData.username" placeholder="请输入成员邮箱账号" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item v-if="formData.id === undefined" label="手机号" prop="mobile">
            <template #label>
              <Tooltip
                message="成员通过验证该手机号码后可加入租户企业,添加用户时邮箱账号或手机号必输一个"
                title="手机号"
              />
            </template>
            <el-input v-model="formData.mobile" maxlength="11" placeholder="请输入成员手机号码" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-row>
        <el-col :span="12">
          <el-form-item label="岗位">
            <el-select v-model="formData.postIds" multiple placeholder="请选择">
              <el-option
                v-for="item in postList"
                :key="item.id"
                :label="item.name"
                :value="item.id!"
              />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-row>
        <el-col :span="24">
          <el-form-item label="备注">
            <el-input v-model="formData.remark" placeholder="请输入内容" type="textarea" />
          </el-form-item>
        </el-col>
      </el-row>
    </el-form>
    <template #footer>
      <el-button :disabled="formLoading" type="primary" @click="submitForm">确 定</el-button>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import { DICT_TYPE, getIntDictOptions } from '@/utils/dict'
import { CommonStatusEnum } from '@/utils/constants'
import { defaultProps, handleTree } from '@/utils/tree'
import * as PostApi from '@/api/system/post'
import * as DeptApi from '@/api/system/dept'
import * as UserApi from '@/api/system/user'
import { FormRules } from 'element-plus'

defineOptions({ name: 'SystemUserForm' })

const { t } = useI18n() // 国际化
const message = useMessage() // 消息弹窗

const dialogVisible = ref(false) // 弹窗的是否展示
const dialogTitle = ref('') // 弹窗的标题
const formLoading = ref(false) // 表单的加载中：1）修改时的数据加载；2）提交的按钮禁用
const formType = ref('') // 表单的类型：create - 新增；update - 修改
const formData = ref({
  nickname: '',
  deptIdList: [],
  mobile: '',
  email: '',
  id: undefined,
  username: '',
  sex: undefined,
  postIds: [],
  remark: '',
  status: CommonStatusEnum.ENABLE,
  roleIds: []
})
const formRules = reactive<FormRules>({
  nickname: [{ required: true, message: '用户昵称不能为空', trigger: 'blur' }],
  username: [
    {
      type: 'email',
      message: '请输入正确的邮箱账号地址',
      trigger: ['blur', 'change']
    }
  ],
  mobile: [
    {
      pattern: /^1[3-9]\d{9}$/,
      message: '请输入正确的手机号码',
      trigger: 'blur'
    }
  ]
})
const formRef = ref() // 表单 Ref
const deptList = ref<Tree[]>([]) // 树形结构
const postList = ref([] as PostApi.PostVO[]) // 岗位列表

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
      formData.value = await UserApi.getUser(id)
    } finally {
      formLoading.value = false
    }
  }
  // 加载部门树
  deptList.value = handleTree(await DeptApi.getSimpleDeptList())
  // 加载岗位列表
  postList.value = await PostApi.getSimplePostList()
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
    const data = formData.value as unknown as UserApi.UserVO
    if (formType.value === 'create') {
      if (isBlank(formData.value.username) && isBlank(formData.value.mobile)) {
        message.error('添加用户时邮箱账号或手机号不能都为空')
        return
      }
      await UserApi.createUser(data)
      message.success(t('common.createSuccess'))
    } else {
      await UserApi.updateUser(data)
      message.success(t('common.updateSuccess'))
    }
    dialogVisible.value = false
    // 发送操作成功的事件
    emit('success')
  } finally {
    formLoading.value = false
  }
}

const isBlank = function (str: string) {
  return str === '' || str === null || str === undefined;
}

/** 重置表单 */
const resetForm = () => {
  formData.value = {
    nickname: '',
    deptIdList: [],
    mobile: '',
    email: '',
    id: undefined,
    username: '',
    sex: undefined,
    postIds: [],
    remark: '',
    status: CommonStatusEnum.ENABLE,
    roleIds: []
  }
  formRef.value?.resetFields()
}
</script>
