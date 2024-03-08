<template>
  <Dialog v-model="dialogVisible" title="插件订单详情" width="50%">
    <el-form :model="plugOrder">
      <el-form-item label="订单编号">
        <span>{{ plugOrder.orderNo }}</span>
      </el-form-item>
      <el-form-item label="客户IP">
        <span>{{ plugOrder.userIp }}</span>
      </el-form-item>
      <el-form-item label="客户编号">
        <span>{{ plugOrder.userId }}</span>
      </el-form-item>
      <el-form-item label="订单日期">
        <span>{{ formatDate(plugOrder.createTime) }}</span>
      </el-form-item>
      <el-form-item label="审批通过日期">
        <span>{{ formatDate(plugOrder.successTime) }}</span>
      </el-form-item>
      <el-form-item label="订单状态">
        <dict-tag :type="DICT_TYPE.PLUG_ORDER_STATUS" :value="plugOrder.orderStatus" />
      </el-form-item>
      <el-form-item label="审批描述">
        <span>{{ plugOrder.auditNote }}</span>
      </el-form-item>
      <el-form-item label="订单备注">
        <span>{{ plugOrder.note }}</span>
      </el-form-item>
      <el-table :data="plugOrder.itemRespVOS" style="width: 100%">
        <el-table-column prop="id" label="订单项编号" />
        <el-table-column prop="appPic" label="应用图片">
          <!-- 图片的显示 -->
          <template #default="scope">
            <img :src="scope.row.appPic" min-width="70" height="70" />
          </template>
        </el-table-column>
        <el-table-column prop="appName" label="应用名称" />
        <el-table-column prop="appSn" label="应用条码" />
      </el-table>
    </el-form>
    <template #footer>
      <el-button @click="dialogVisible = false">取 消</el-button>
    </template>
  </Dialog>
</template>
<script lang="ts" setup>
import { DICT_TYPE } from '@/utils/dict'
import * as PlugOrderApi from '@/api/plug/plugOrder'
import { formatDate } from '@/utils/formatTime'

defineOptions({ name: 'PlugOrderDetailForm' })

const message = useMessage() // 消息弹窗
const { t } = useI18n() // 国际化

const dialogVisible = ref(false) // 弹窗的是否展示
const formLoading = ref(false) // 表单的加载中

// 详情
const plugOrder = ref({
  id: undefined,
  orderNo: '',
  orderStatus: undefined,
  auditNote: '',
  userIp: '',
  userId: undefined,
  successTime: undefined,
  note: '',
  createTime: undefined,
  itemRespVOS: []
})

const getPlugOrder = async (id: number) => {
  dialogVisible.value = true
  formLoading.value = true
  try {
    const data = await PlugOrderApi.getPlugOrder(id)
    plugOrder.value = data
  } finally {
    formLoading.value = false
  }
}
defineExpose({ getPlugOrder }) // 提供 getPlugOrder 方法，用于打开弹窗
</script>
