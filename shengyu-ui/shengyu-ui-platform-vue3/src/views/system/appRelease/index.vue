<template>
  <ContentWrap>
    <el-form
      ref="queryFormRef"
      class="-mb-15px"
      :model="queryParams"
      :inline="true"
      label-width="80px"
    >
      <el-form-item label="应用标识" prop="appKey">
        <el-input
          v-model="queryParams.appKey"
          placeholder="请输入应用标识"
          clearable
          class="!w-200px"
          @keyup.enter="handleQuery"
        />
      </el-form-item>
      <el-form-item label="平台" prop="platform">
        <el-select
          v-model="queryParams.platform"
          placeholder="请选择平台"
          clearable
          class="!w-160px"
        >
          <el-option label="Android" value="android" />
          <el-option label="iOS" value="ios" />
          <el-option label="鸿蒙" value="harmony" />
        </el-select>
      </el-form-item>
      <el-form-item label="更新类型" prop="updateType">
        <el-select
          v-model="queryParams.updateType"
          placeholder="请选择类型"
          clearable
          class="!w-160px"
        >
          <el-option label="整包更新" value="FULL" />
          <el-option label="Dart OTA" value="PATCH" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="请选择状态" clearable class="!w-160px">
          <el-option label="草稿" value="DRAFT" />
          <el-option label="已发布" value="PUBLISHED" />
          <el-option label="已暂停" value="PAUSED" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button @click="handleQuery">
          <Icon icon="ep:search" class="mr-5px" />
          搜索
        </el-button>
        <el-button @click="resetQuery">
          <Icon icon="ep:refresh" class="mr-5px" />
          重置
        </el-button>
        <el-button
          type="primary"
          plain
          @click="openForm('create')"
          v-hasPermi="['system:app-release:create']"
        >
          <Icon icon="ep:plus" class="mr-5px" />
          新增
        </el-button>
      </el-form-item>
    </el-form>
  </ContentWrap>

  <ContentWrap>
    <el-table v-loading="loading" :data="list">
      <el-table-column label="编号" align="center" prop="id" width="90" />
      <el-table-column label="应用" align="center" prop="appKey" min-width="100" />
      <el-table-column label="平台" align="center" prop="platform" width="100">
        <template #default="scope">
          {{ platformLabel(scope.row.platform) }}
        </template>
      </el-table-column>
      <el-table-column label="渠道" align="center" prop="channel" width="90" />
      <el-table-column label="版本" align="center" min-width="150">
        <template #default="scope">
          {{ scope.row.versionName }} ({{ scope.row.versionCode }})
        </template>
      </el-table-column>
      <el-table-column label="最低可用" align="center" prop="minSupportedVersionCode" width="100" />
      <el-table-column label="类型" align="center" prop="updateType" width="120">
        <template #default="scope">
          <el-tag :type="scope.row.updateType === 'PATCH' ? 'warning' : 'primary'">
            {{ scope.row.updateType === 'PATCH' ? 'Dart OTA' : '整包更新' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="强制" align="center" prop="forceUpdate" width="90">
        <template #default="scope">
          <el-tag :type="scope.row.forceUpdate ? 'danger' : 'info'">
            {{ scope.row.forceUpdate ? '是' : '否' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="status" width="100">
        <template #default="scope">
          <el-tag :type="statusTagType(scope.row.status)">
            {{ statusLabel(scope.row.status) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column
        label="创建时间"
        align="center"
        prop="createTime"
        width="180"
        :formatter="dateFormatter"
      />
      <el-table-column label="操作" align="center" fixed="right" width="230">
        <template #default="scope">
          <el-button
            link
            type="primary"
            :disabled="scope.row.status === 'PUBLISHED'"
            @click="openForm('update', scope.row.id)"
            v-hasPermi="['system:app-release:update']"
          >
            编辑
          </el-button>
          <el-button
            link
            type="success"
            :disabled="scope.row.status === 'PUBLISHED'"
            @click="handlePublish(scope.row.id)"
            v-hasPermi="['system:app-release:publish']"
          >
            发布
          </el-button>
          <el-button
            link
            type="warning"
            :disabled="scope.row.status !== 'PUBLISHED'"
            @click="handlePause(scope.row.id)"
            v-hasPermi="['system:app-release:pause']"
          >
            暂停
          </el-button>
          <el-button
            link
            type="danger"
            :disabled="scope.row.status === 'PUBLISHED'"
            @click="handleDelete(scope.row.id)"
            v-hasPermi="['system:app-release:delete']"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>
    <Pagination
      :total="total"
      v-model:page="queryParams.pageNo"
      v-model:limit="queryParams.pageSize"
      @pagination="getList"
    />
  </ContentWrap>

  <AppReleaseForm ref="formRef" @success="getList" />
</template>

<script lang="ts" setup>
import { dateFormatter } from '@/utils/formatTime'
import * as AppReleaseApi from '@/api/system/appRelease'
import AppReleaseForm from './AppReleaseForm.vue'

defineOptions({ name: 'SystemAppRelease' })

const message = useMessage()
const { t } = useI18n()

const loading = ref(true)
const total = ref(0)
const list = ref<AppReleaseApi.AppReleaseVO[]>([])
const queryParams = reactive({
  pageNo: 1,
  pageSize: 10,
  appKey: 'yuxin',
  platform: undefined,
  channel: 'prod',
  versionName: undefined,
  updateType: undefined,
  status: undefined
})
const queryFormRef = ref()

const getList = async () => {
  loading.value = true
  try {
    const data = await AppReleaseApi.getAppReleasePage(queryParams)
    list.value = data.list
    total.value = data.total
  } finally {
    loading.value = false
  }
}

const handleQuery = () => {
  queryParams.pageNo = 1
  getList()
}

const resetQuery = () => {
  queryFormRef.value.resetFields()
  handleQuery()
}

const formRef = ref()
const openForm = (type: string, id?: number) => {
  formRef.value.open(type, id)
}

const handleDelete = async (id: number) => {
  try {
    await message.delConfirm()
    await AppReleaseApi.deleteAppRelease(id)
    message.success(t('common.delSuccess'))
    await getList()
  } catch {}
}

const handlePublish = async (id: number) => {
  try {
    await message.confirm('发布后客户端将检查到该版本，确认发布？')
    await AppReleaseApi.publishAppRelease(id)
    message.success('发布成功')
    await getList()
  } catch {}
}

const handlePause = async (id: number) => {
  try {
    await message.confirm('暂停后客户端不再收到该版本更新，确认暂停？')
    await AppReleaseApi.pauseAppRelease(id)
    message.success('暂停成功')
    await getList()
  } catch {}
}

const platformLabel = (platform: string) => {
  const labels = {
    android: 'Android',
    ios: 'iOS',
    harmony: '鸿蒙'
  }
  return labels[platform] || platform
}

const statusLabel = (status: string) => {
  const labels = {
    DRAFT: '草稿',
    PUBLISHED: '已发布',
    PAUSED: '已暂停'
  }
  return labels[status] || status
}

const statusTagType = (status: string) => {
  if (status === 'PUBLISHED') return 'success'
  if (status === 'PAUSED') return 'warning'
  return 'info'
}

onMounted(() => {
  getList()
})
</script>
