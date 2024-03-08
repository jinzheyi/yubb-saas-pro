<template>
  <ContentWrap>
    <!-- 搜索工作栏 -->
    <el-form
      class="-mb-15px"
      :model="queryParams"
      ref="queryFormRef"
      :inline="true"
      label-width="68px"
    >
      <el-form-item label="上架状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="请选择状态" clearable class="!w-240px">
          <el-option
            v-for="dict in getIntDictOptions(DICT_TYPE.COMMON_STATUS)"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="停用状态" prop="enable">
        <el-select v-model="queryParams.enable" placeholder="请选择状态" clearable class="!w-240px">
          <el-option
            v-for="dict in getIntDictOptions(DICT_TYPE.COMMON_STATUS)"
            :key="dict.value"
            :label="dict.label"
            :value="dict.value"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="创建时间" prop="createTime">
        <el-date-picker
          v-model="queryParams.createTime"
          value-format="yyyy-MM-dd HH:mm:ss"
          type="daterange"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          :default-time="[new Date('1 00:00:00'), new Date('1 23:59:59')]"
          class="!w-240px"
        />
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
      </el-form-item>
    </el-form>
  </ContentWrap>

  <!-- 列表 -->
  <ContentWrap>
    <div class="card-list">
      <div v-for="app in list" :key="app.id" class="card">
        <div class="card-image">
          <img :src="app.mainPic" :alt="app.name" />
        </div>
        <div class="card-content">
          <h4 class="card-title"
            ><Tooltip :message="app.outline" :title="app.name" icon="ep:chat-line-round"
          /></h4>
          <p>{{ app.appSn }}</p>
          <p>平台状态：<dict-tag :type="DICT_TYPE.COMMON_STATUS" :value="app.enable" /></p>
          <p class="card-created-time">{{ formatDate(app.createTime) }}</p>
          <div>
            <div class="card-type">
              <div
                >是否上架：
                <el-switch
                  v-model="app.status"
                  :active-value="0"
                  :inactive-value="1"
                  @change="handleStatusChange(app)"
                />
              </div>
            </div>
            <div>
              <el-button
                link
                type="primary"
                @click="openDetailForm(app.id)"
                v-hasPermi="['plug:tenant:query']"
              >
                查看
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- 分页 -->
    <Pagination
      :total="total"
      v-model:page="queryParams.pageNo"
      v-model:limit="queryParams.pageSize"
      @pagination="getList"
    />
  </ContentWrap>

  <!-- 表单弹窗：详情 -->
  <TenantAppForm ref="detailFormRef" @success="getList" />
</template>

<script lang="ts" setup>
import { DICT_TYPE, getIntDictOptions } from '@/utils/dict'
import { CommonStatusEnum } from '@/utils/constants'
import * as TenantAppApi from '@/api/plug/tenantApp'
import TenantAppForm from './TenantAppForm.vue'
import { formatDate } from '@/utils/formatTime'

defineOptions({ name: 'TenantApp' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const loading = ref(true) // 列表的加载中
const total = ref(0) // 列表的总页数
const list = ref([]) // 列表的数据
const queryParams = reactive({
  pageNo: 1,
  pageSize: 10,
  status: null,
  enable: null,
  createTime: []
})
const queryFormRef = ref() // 搜索的表单

/** 查询列表 */
const getList = async () => {
  loading.value = true
  try {
    const data = await TenantAppApi.getTenantAppPage(queryParams)
    list.value = data.list
    total.value = data.total
  } finally {
    loading.value = false
  }
}

/** 搜索按钮操作 */
const handleQuery = () => {
  queryParams.pageNo = 1
  getList()
}

/** 重置按钮操作 */
const resetQuery = () => {
  queryFormRef.value.resetFields()
  handleQuery()
}

/** 查看详情 */
const detailFormRef = ref()
const openDetailForm = (id: number) => {
  detailFormRef.value.getTenantAppDetail(id)
}

/** 修改插件状态 */
const handleStatusChange = async (row: TenantAppApi.TenantAppVO) => {
  try {
    // 修改状态的二次确认
    const text = row.status === CommonStatusEnum.ENABLE ? '上架' : '下架'
    await message.confirm('确认要"' + text + '""' + row.name + '"插件应用吗?')
    // 发起修改状态
    await TenantAppApi.updateTenantPlugStatus(row.id, row.status)
    // 刷新列表
    await getList()
  } catch {
    // 取消后，进行恢复按钮
    row.status =
      row.status === CommonStatusEnum.ENABLE ? CommonStatusEnum.DISABLE : CommonStatusEnum.ENABLE
  }
}

/** 初始化 **/
onMounted(() => {
  getList()
})
</script>
<style scoped>
.card-list {
  display: flex;
  flex-wrap: wrap;
}

.card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: calc(19% - 20px);
  margin-bottom: 20px;
  padding: 10px;
  margin-right: 10px;
  border: 1px solid #ccc;
}

.card-image {
  width: 100%;
  height: 250px;
  overflow: hidden;
  margin-bottom: 10px;
}

.card-image img {
  width: 100%;
  height: 100%;
}

.card-content {
  display: flex;
  flex-direction: column;
  height: 60%;
}

.card-title {
  font-size: 22px;
}

.card-description {
  font-size: 14px;
  color: #606266;
  line-height: 22px;
}

.card-type {
  font-size: 14px;
  color: #909399;
  width: 50%;
}

.card-created-time {
  font-size: 12px;
  color: #c0c4cc;
}
</style>
