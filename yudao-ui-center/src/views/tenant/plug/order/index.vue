<template>
  <div class="app-container">

    <!-- 搜索工作栏 -->
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch" label-width="68px">
      <el-form-item label="订单编号" prop="orderNo">
        <el-input v-model="queryParams.orderNo" placeholder="请输入订单编号" clearable @keyup.enter.native="handleQuery"/>
      </el-form-item>
      <el-form-item label="应付金额（实际支付金额）" prop="payAmount">
        <el-input v-model="queryParams.payAmount" placeholder="请输入应付金额（实际支付金额）" clearable @keyup.enter.native="handleQuery"/>
      </el-form-item>
      <el-form-item label="订单类型：0->正常订单；1->赠送订单" prop="orderType">
        <el-select v-model="queryParams.orderType" placeholder="请选择订单类型：0->正常订单；1->赠送订单" clearable size="small">
          <el-option v-for="dict in this.getDictDatas(DICT_TYPE.PLUG_ORDER_TYPE)"
                       :key="dict.value" :label="dict.label" :value="dict.value"/>
        </el-select>
      </el-form-item>
      <el-form-item label="订单状态 未付款,已付款,已安装" prop="orderStatus">
        <el-select v-model="queryParams.orderStatus" placeholder="请选择订单状态 未付款,已付款,已安装" clearable size="small">
          <el-option v-for="dict in this.getDictDatas(DICT_TYPE.PLUG_ORDER_STATUS)"
                       :key="dict.value" :label="dict.label" :value="dict.value"/>
        </el-select>
      </el-form-item>
      <el-form-item label="订单失效时间" prop="expireTime">
        <el-date-picker v-model="queryParams.expireTime" style="width: 240px" value-format="yyyy-MM-dd HH:mm:ss" type="daterange"
                        range-separator="-" start-placeholder="开始日期" end-placeholder="结束日期" :default-time="['00:00:00', '23:59:59']" />
      </el-form-item>
      <el-form-item label="订单支付成功时间" prop="successTime">
        <el-date-picker v-model="queryParams.successTime" style="width: 240px" value-format="yyyy-MM-dd HH:mm:ss" type="daterange"
                        range-separator="-" start-placeholder="开始日期" end-placeholder="结束日期" :default-time="['00:00:00', '23:59:59']" />
      </el-form-item>
      <el-form-item label="创建时间" prop="createTime">
        <el-date-picker v-model="queryParams.createTime" style="width: 240px" value-format="yyyy-MM-dd HH:mm:ss" type="daterange"
                        range-separator="-" start-placeholder="开始日期" end-placeholder="结束日期" :default-time="['00:00:00', '23:59:59']" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="el-icon-search" @click="handleQuery">搜索</el-button>
        <el-button icon="el-icon-refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <!-- 操作工具栏 -->
    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="el-icon-plus" size="mini" @click="handleAdd"
                   v-hasPermi="['plug:order:create']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain icon="el-icon-download" size="mini" @click="handleExport" :loading="exportLoading"
                   v-hasPermi="['plug:order:export']">导出</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <!-- 列表 -->
    <el-table v-loading="loading" :data="list">
      <el-table-column label="订单id" align="center" prop="id" />
      <el-table-column label="订单编号" align="center" prop="orderNo" />
      <el-table-column label="支付金额，单位：钰豆" align="center" prop="totalAmount" />
      <el-table-column label="应付金额（实际支付金额）" align="center" prop="payAmount" />
      <el-table-column label="促销优化金额（促销价、满减、阶梯价）" align="center" prop="promotionAmount" />
      <el-table-column label="管理员后台调整订单使用的折扣金额" align="center" prop="discountAmount" />
      <el-table-column label="订单类型：0->正常订单；1->赠送订单" align="center" prop="orderType">
        <template slot-scope="scope">
          <dict-tag :type="DICT_TYPE.PLUG_ORDER_TYPE" :value="scope.row.orderType" />
        </template>
      </el-table-column>
      <el-table-column label="订单状态 未付款,已付款,已安装" align="center" prop="orderStatus">
        <template slot-scope="scope">
          <dict-tag :type="DICT_TYPE.PLUG_ORDER_STATUS" :value="scope.row.orderStatus" />
        </template>
      </el-table-column>
      <el-table-column label="用户 IP" align="center" prop="userIp" />
      <el-table-column label="购买者编号" align="center" prop="userId" />
      <el-table-column label="订单失效时间" align="center" prop="expireTime" width="180">
        <template slot-scope="scope">
          <span>{{ parseTime(scope.row.expireTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="订单支付成功时间" align="center" prop="successTime" width="180">
        <template slot-scope="scope">
          <span>{{ parseTime(scope.row.successTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="可以获得的积分" align="center" prop="integration" />
      <el-table-column label="可以活动的成长值" align="center" prop="growth" />
      <el-table-column label="订单备注" align="center" prop="note" />
      <el-table-column label="创建时间" align="center" prop="createTime" width="180">
        <template slot-scope="scope">
          <span>{{ parseTime(scope.row.createTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)"
                     v-hasPermi="['plug:order:update']">修改</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" @click="handleDelete(scope.row)"
                     v-hasPermi="['plug:order:delete']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <!-- 分页组件 -->
    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNo" :limit.sync="queryParams.pageSize"
                @pagination="getList"/>

    <!-- 对话框(添加 / 修改) -->
    <el-dialog :title="title" :visible.sync="open" width="500px" v-dialogDrag append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="订单编号" prop="orderNo">
          <el-input v-model="form.orderNo" placeholder="请输入订单编号" />
        </el-form-item>
        <el-form-item label="支付金额，单位：钰豆" prop="totalAmount">
          <el-input v-model="form.totalAmount" placeholder="请输入支付金额，单位：钰豆" />
        </el-form-item>
        <el-form-item label="应付金额（实际支付金额）" prop="payAmount">
          <el-input v-model="form.payAmount" placeholder="请输入应付金额（实际支付金额）" />
        </el-form-item>
        <el-form-item label="促销优化金额（促销价、满减、阶梯价）" prop="promotionAmount">
          <el-input v-model="form.promotionAmount" placeholder="请输入促销优化金额（促销价、满减、阶梯价）" />
        </el-form-item>
        <el-form-item label="管理员后台调整订单使用的折扣金额" prop="discountAmount">
          <el-input v-model="form.discountAmount" placeholder="请输入管理员后台调整订单使用的折扣金额" />
        </el-form-item>
        <el-form-item label="订单类型：0->正常订单；1->赠送订单" prop="orderType">
          <el-select v-model="form.orderType" placeholder="请选择订单类型：0->正常订单；1->赠送订单">
            <el-option v-for="dict in this.getDictDatas(DICT_TYPE.PLUG_ORDER_TYPE)"
                       :key="dict.value" :label="dict.label" :value="parseInt(dict.value)" />
          </el-select>
        </el-form-item>
        <el-form-item label="订单状态 未付款,已付款,已安装" prop="orderStatus">
          <el-radio-group v-model="form.orderStatus">
            <el-radio v-for="dict in this.getDictDatas(DICT_TYPE.PLUG_ORDER_STATUS)"
                      :key="dict.value" :label="parseInt(dict.value)">{{dict.label}}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="用户 IP" prop="userIp">
          <el-input v-model="form.userIp" placeholder="请输入用户 IP" />
        </el-form-item>
        <el-form-item label="购买者编号" prop="userId">
          <el-input v-model="form.userId" placeholder="请输入购买者编号" />
        </el-form-item>
        <el-form-item label="订单失效时间" prop="expireTime">
          <el-date-picker clearable v-model="form.expireTime" type="date" value-format="timestamp" placeholder="选择订单失效时间" />
        </el-form-item>
        <el-form-item label="订单支付成功时间" prop="successTime">
          <el-date-picker clearable v-model="form.successTime" type="date" value-format="timestamp" placeholder="选择订单支付成功时间" />
        </el-form-item>
        <el-form-item label="可以获得的积分" prop="integration">
          <el-input v-model="form.integration" placeholder="请输入可以获得的积分" />
        </el-form-item>
        <el-form-item label="可以活动的成长值" prop="growth">
          <el-input v-model="form.growth" placeholder="请输入可以活动的成长值" />
        </el-form-item>
        <el-form-item label="订单备注" prop="note">
          <el-input v-model="form.note" placeholder="请输入订单备注" />
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="cancel">取 消</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { createOrder, updateOrder, deleteOrder, getOrder, getOrderPage, exportOrderExcel } from "@/api/plug/order";

export default {
  name: "Order",
  components: {
  },
  data() {
    return {
      // 遮罩层
      loading: true,
      // 导出遮罩层
      exportLoading: false,
      // 显示搜索条件
      showSearch: true,
      // 总条数
      total: 0,
      // 订单列表
      list: [],
      // 弹出层标题
      title: "",
      // 是否显示弹出层
      open: false,
      // 查询参数
      queryParams: {
        pageNo: 1,
        pageSize: 10,
        orderNo: null,
        payAmount: [],
        orderType: null,
        orderStatus: null,
        expireTime: [],
        successTime: [],
        createTime: [],
      },
      // 表单参数
      form: {},
      // 表单校验
      rules: {
        orderNo: [{ required: true, message: "订单编号不能为空", trigger: "blur" }],
        totalAmount: [{ required: true, message: "支付金额，单位：钰豆不能为空", trigger: "blur" }],
        payAmount: [{ required: true, message: "应付金额（实际支付金额）不能为空", trigger: "blur" }],
        orderType: [{ required: true, message: "订单类型：0->正常订单；1->赠送订单不能为空", trigger: "change" }],
        orderStatus: [{ required: true, message: "订单状态 未付款,已付款,已安装不能为空", trigger: "blur" }],
        userIp: [{ required: true, message: "用户 IP不能为空", trigger: "blur" }],
        userId: [{ required: true, message: "购买者编号不能为空", trigger: "blur" }],
        expireTime: [{ required: true, message: "订单失效时间不能为空", trigger: "blur" }],
      }
    };
  },
  created() {
    this.getList();
  },
  methods: {
    /** 查询列表 */
    getList() {
      this.loading = true;
      // 执行查询
      getOrderPage(this.queryParams).then(response => {
        this.list = response.data.list;
        this.total = response.data.total;
        this.loading = false;
      });
    },
    /** 取消按钮 */
    cancel() {
      this.open = false;
      this.reset();
    },
    /** 表单重置 */
    reset() {
      this.form = {
        id: undefined,
        orderNo: undefined,
        totalAmount: undefined,
        payAmount: undefined,
        promotionAmount: undefined,
        discountAmount: undefined,
        orderType: undefined,
        orderStatus: undefined,
        userIp: undefined,
        userId: undefined,
        expireTime: undefined,
        successTime: undefined,
        integration: undefined,
        growth: undefined,
        note: undefined,
      };
      this.resetForm("form");
    },
    /** 搜索按钮操作 */
    handleQuery() {
      this.queryParams.pageNo = 1;
      this.getList();
    },
    /** 重置按钮操作 */
    resetQuery() {
      this.resetForm("queryForm");
      this.handleQuery();
    },
    /** 新增按钮操作 */
    handleAdd() {
      this.reset();
      this.open = true;
      this.title = "添加订单";
    },
    /** 修改按钮操作 */
    handleUpdate(row) {
      this.reset();
      const id = row.id;
      getOrder(id).then(response => {
        this.form = response.data;
        this.open = true;
        this.title = "修改订单";
      });
    },
    /** 提交按钮 */
    submitForm() {
      this.$refs["form"].validate(valid => {
        if (!valid) {
          return;
        }
        // 修改的提交
        if (this.form.id != null) {
          updateOrder(this.form).then(response => {
            this.$modal.msgSuccess("修改成功");
            this.open = false;
            this.getList();
          });
          return;
        }
        // 添加的提交
        createOrder(this.form).then(response => {
          this.$modal.msgSuccess("新增成功");
          this.open = false;
          this.getList();
        });
      });
    },
    /** 删除按钮操作 */
    handleDelete(row) {
      const id = row.id;
      this.$modal.confirm('是否确认删除订单编号为"' + id + '"的数据项?').then(function() {
          return deleteOrder(id);
        }).then(() => {
          this.getList();
          this.$modal.msgSuccess("删除成功");
        }).catch(() => {});
    },
    /** 导出按钮操作 */
    handleExport() {
      // 处理查询参数
      let params = {...this.queryParams};
      params.pageNo = undefined;
      params.pageSize = undefined;
      this.$modal.confirm('是否确认导出所有订单数据项?').then(() => {
          this.exportLoading = true;
          return exportOrderExcel(params);
        }).then(response => {
          this.$download.excel(response, '订单.xls');
          this.exportLoading = false;
        }).catch(() => {});
    }
  }
};
</script>
