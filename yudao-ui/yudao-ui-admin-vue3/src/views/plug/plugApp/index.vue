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
      <el-form-item label="应用名称" prop="name">
        <el-input
          v-model="queryParams.name"
          placeholder="请输入应用名称"
          clearable
          @keyup.enter="handleQuery"
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
          <p>应用条码：{{ app.appSn }}</p>
          <p class="card-created-time">{{ formatDate(app.createTime) }}</p>
          <div>
            <div>
              <el-button
                round
                type="primary"
                @click="openDetailForm(app.id)"
              >
                <Icon class="mr-5px" icon="ep:view" />
                查看
              </el-button>
              <el-button
                round type="primary"
                @click="openBuyForm(app.id)"
              >
                <Icon class="mr-5px" icon="ep:goods" />
                申请使用
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
  <PlugAppForm ref="detailFormRef" />
  <!-- 表单弹窗：购买 -->
  <PlugAppBuyForm ref="buyFormRef" />
</template>

<script lang="ts" setup>
import * as PlugAppApi from '@/api/plug/plugApp'
import PlugAppForm from './PlugAppForm.vue'
import PlugAppBuyForm from './PlugAppBuyForm.vue'
import { formatDate } from '@/utils/formatTime'

defineOptions({ name: 'PlugApp' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const loading = ref(true) // 列表的加载中
const total = ref(0) // 列表的总页数
const list = ref([]) // 列表的数据
const queryParams = reactive({
  pageNo: 1,
  pageSize: 10,
  name: null,
  appSn: null,
  type: null
})
const queryFormRef = ref() // 搜索的表单

/** 查询列表 */
const getList = async () => {
  loading.value = true
  try {
    const data = await PlugAppApi.getPlugAppPage(queryParams)
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

/** 插件购买 */
const buyFormRef = ref()
const openBuyForm = (id: number) => {
  buyFormRef.value.open(id)
}

/** 查看详情 */
const detailFormRef = ref()
const openDetailForm = (id: number) => {
  detailFormRef.value.getPlugAppDetail(id)
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
