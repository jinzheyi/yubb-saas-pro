<template>
  <div class="app-container">

    <!-- 搜索工作栏 -->
    <el-form :model="queryParams" ref="queryForm" size="small" :inline="true" v-show="showSearch" label-width="68px">
      <el-form-item label="商品名称" prop="goodsName">
        <el-input v-model="queryParams.goodsName" placeholder="请输入商品名称" clearable @keyup.enter.native="handleQuery"/>
      </el-form-item>
      <el-form-item label="商品条码" prop="goodsSn">
        <el-input v-model="queryParams.goodsSn" placeholder="请输入商品条码" clearable @keyup.enter.native="handleQuery"/>
      </el-form-item>
      <el-form-item label="状态" prop="appStatus">
        <el-select v-model="queryParams.appStatus" placeholder="请选择上下架状态" clearable size="small">
          <el-option v-for="dict in appStatusDictDatas"
                       :key="dict.value" :label="dict.label" :value="dict.value"/>
        </el-select>
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
                   v-hasPermi="['center:plug-goods:create']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain icon="el-icon-download" size="mini" @click="handleExport" :loading="exportLoading"
                   v-hasPermi="['center:plug-goods:export']">导出</el-button>
      </el-col>
      <right-toolbar :showSearch.sync="showSearch" @queryTable="getList"></right-toolbar>
    </el-row>

    <!-- 列表 -->
    <el-table v-loading="loading" :data="list">
      <el-table-column label="编号" align="center" prop="id" />
      <el-table-column label="商品图片" align="center" prop="goodsPic" />
      <el-table-column label="商品名称" align="center" prop="goodsName" />
      <el-table-column label="商品条码" align="center" prop="goodsSn" />
      <el-table-column label="原价" align="center" prop="goodsPrice" />
      <el-table-column label="售价" align="center" prop="payPrice" />
      <el-table-column label="状态" align="center" prop="appStatus">
        <template slot-scope="scope">
          <dict-tag :type="DICT_TYPE.UP_DOWN_SHELF_STATUS" :value="scope.row.appStatus" />
        </template>
      </el-table-column>
      <el-table-column label="创建时间" align="center" prop="createTime" width="180">
        <template slot-scope="scope">
          <span>{{ parseTime(scope.row.createTime) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" class-name="small-padding fixed-width">
        <template slot-scope="scope">
          <el-button size="mini" type="text" icon="el-icon-edit" @click="handleUpdate(scope.row)"
                     v-hasPermi="['center:plug-goods:update']">修改</el-button>
          <el-button size="mini" type="text" icon="el-icon-delete" @click="handleDelete(scope.row)"
                     v-hasPermi="['center:plug-goods:delete']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <!-- 分页组件 -->
    <pagination v-show="total > 0" :total="total" :page.sync="queryParams.pageNo" :limit.sync="queryParams.pageSize"
                @pagination="getList"/>

    <!-- 对话框(添加 / 修改) -->
    <el-dialog :title="title" :visible.sync="open" width="1000px" append-to-body>
      <el-form ref="form" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="商品名称" prop="goodsName">
          <el-input v-model="form.goodsName" placeholder="请输入商品名称" />
        </el-form-item>
        <el-form-item label="商品概要" prop="goodsOutline">
          <el-input v-model="form.goodsOutline" type="textarea" placeholder="请输入内容" />
        </el-form-item>
        <el-form-item label="商品条码" prop="goodsSn">
          <el-input v-model="form.goodsSn" placeholder="请输入商品条码" />
        </el-form-item>
        <el-form-item label="商品图片">
          <imageUpload v-model="form.goodsPic" :limit="10"/>
        </el-form-item>
        <el-form-item label="原价" prop="goodsPrice">
          <el-input-number
            v-model="form.goodsPrice"
            placeholder="请输入原价"
            :precision="2"
            :max="1000000000"
            :min="0.01"/>
        </el-form-item>
        <el-form-item label="售价" prop="payPrice">
          <el-input-number
            v-model="form.payPrice"
            placeholder="请输入售价"
            :precision="2"
            :max="1000000000"
            :min="0.01"/>
        </el-form-item>
        <el-form-item label="积分" prop="giftIntegration">
          <el-input-number
            v-model="form.giftIntegration"
            placeholder="请输入商品赠送积分"
            :max="1000000000"
            :min="0"/>
        </el-form-item>
        <el-form-item label="成长值" prop="giftGrowth">
          <el-input-number
            v-model="form.giftGrowth"
            placeholder="请输入商品赠送成长值"
            :max="1000000000"
            :min="0"/>
        </el-form-item>
        <el-form-item label="状态" prop="appStatus">
          <el-radio-group v-model="form.appStatus">
            <el-radio v-for="dict in appStatusDictDatas"
                      :key="dict.value" :label="parseInt(dict.value)">{{dict.label}}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="商品描述">
          <editor v-model="form.appContents" :min-height="192"/>
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
import { createGoods, updateGoods, deleteGoods, getGoods, getGoodsPage, exportGoodsExcel } from "@/api/plug/goods";
import ImageUpload from '@/components/ImageUpload';
import Editor from '@/components/Editor';
import {DICT_TYPE, getDictDatas} from "@/utils/dict";
import {CommonStatusEnum} from "@/utils/constants";

export default {
  name: "Goods",
  components: {
    ImageUpload,
    Editor,
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
      // 应用商品列表
      list: [],
      // 弹出层标题
      title: "",
      // 是否显示弹出层
      open: false,
      // 查询参数
      queryParams: {
        pageNo: 1,
        pageSize: 10,
        goodsName: null,
        goodsSn: null,
        appStatus: null,
        createTime: [],
      },
      // 表单参数
      form: {},
      // 表单校验
      rules: {
        goodsPic: [{ required: true, message: "商品图片不能为空", trigger: "blur" }],
        goodsName: [{ required: true, message: "商品名称不能为空", trigger: "blur" }],
        goodsSn: [{ required: true, message: "商品条码不能为空", trigger: "blur" }],
        goodsPrice: [{ required: true, message: "原价不能为空", trigger: "blur" }],
        payPrice: [{ required: true, message: "售价不能为空", trigger: "blur" }],
        appStatus: [{ required: true, message: "状态 上下架不能为空", trigger: "blur" }],
        giftIntegration: [{ required: true, message: "积分不能为空", trigger: "blur" }],
        giftGrowth: [{ required: true, message: "成长值不能为空", trigger: "blur" }],
      },
      //数据字典
      appStatusDictDatas: getDictDatas(DICT_TYPE.UP_DOWN_SHELF_STATUS),
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
      getGoodsPage(this.queryParams).then(response => {
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
        goodsPic: undefined,
        goodsName: undefined,
        goodsOutline: undefined,
        goodsSn: undefined,
        goodsPrice: undefined,
        payPrice: undefined,
        giftIntegration: 0,
        giftGrowth: 0,
        appStatus: CommonStatusEnum.ENABLE,
        appContents: undefined,
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
      this.title = "添加商品";
    },
    /** 修改按钮操作 */
    handleUpdate(row) {
      this.reset();
      const id = row.id;
      getGoods(id).then(response => {
        this.form = response.data;
        this.open = true;
        this.title = "修改商品";
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
          updateGoods(this.form).then(response => {
            this.$modal.msgSuccess("修改成功");
            this.open = false;
            this.getList();
          });
          return;
        }
        // 添加的提交
        createGoods(this.form).then(response => {
          this.$modal.msgSuccess("新增成功");
          this.open = false;
          this.getList();
        });
      });
    },
    /** 删除按钮操作 */
    handleDelete(row) {
      const id = row.id;
      this.$modal.confirm('是否确认删除商品编号为"' + id + '"的数据项?').then(function() {
          return deleteGoods(id);
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
      this.$modal.confirm('是否确认导出所有商品数据项?').then(() => {
          this.exportLoading = true;
          return exportGoodsExcel(params);
        }).then(response => {
          this.$download.excel(response, '商品.xls');
          this.exportLoading = false;
        }).catch(() => {});
    }
  }
};
</script>
