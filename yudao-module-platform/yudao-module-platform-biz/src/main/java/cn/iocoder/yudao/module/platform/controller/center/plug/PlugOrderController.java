package cn.iocoder.yudao.module.platform.controller.center.plug;

import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import org.springframework.validation.annotation.Validated;
import org.springframework.security.access.prepost.PreAuthorize;
import io.swagger.annotations.*;

import javax.validation.constraints.*;
import javax.validation.*;
import javax.servlet.http.*;
import java.util.*;
import java.io.IOException;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;

import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.*;

import cn.iocoder.yudao.module.plug.controller.admin.order.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.order.PlugOrderDO;
import cn.iocoder.yudao.module.plug.convert.order.PlugOrderConvert;
import cn.iocoder.yudao.module.plug.service.order.PlugOrderService;

@Api(tags = "管理后台 - 订单")
@RestController
@RequestMapping("/plug/order")
@Validated
public class PlugOrderController {

    @Resource
    private PlugOrderService orderService;

    @PostMapping("/create")
    @ApiOperation("创建订单")
    @PreAuthorize("@ss.hasPermission('plug:order:create')")
    public CommonResult<Long> createOrder(@Valid @RequestBody PlugOrderCreateReqVO createReqVO) {
        return success(orderService.createOrder(createReqVO));
    }

    @PutMapping("/update")
    @ApiOperation("更新订单")
    @PreAuthorize("@ss.hasPermission('plug:order:update')")
    public CommonResult<Boolean> updateOrder(@Valid @RequestBody PlugOrderUpdateReqVO updateReqVO) {
        orderService.updateOrder(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除订单")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@ss.hasPermission('plug:order:delete')")
    public CommonResult<Boolean> deleteOrder(@RequestParam("id") Long id) {
        orderService.deleteOrder(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得订单")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@ss.hasPermission('plug:order:query')")
    public CommonResult<PlugOrderRespVO> getOrder(@RequestParam("id") Long id) {
        PlugOrderDO order = orderService.getOrder(id);
        return success(PlugOrderConvert.INSTANCE.convert(order));
    }

    @GetMapping("/list")
    @ApiOperation("获得订单列表")
    @ApiImplicitParam(name = "ids", value = "编号列表", required = true, example = "1024,2048", dataTypeClass = List.class)
    @PreAuthorize("@ss.hasPermission('plug:order:query')")
    public CommonResult<List<PlugOrderRespVO>> getOrderList(@RequestParam("ids") Collection<Long> ids) {
        List<PlugOrderDO> list = orderService.getOrderList(ids);
        return success(PlugOrderConvert.INSTANCE.convertList(list));
    }

    @GetMapping("/page")
    @ApiOperation("获得订单分页")
    @PreAuthorize("@ss.hasPermission('plug:order:query')")
    public CommonResult<PageResult<PlugOrderRespVO>> getOrderPage(@Valid PlugOrderPageReqVO pageVO) {
        PageResult<PlugOrderDO> pageResult = orderService.getOrderPage(pageVO);
        return success(PlugOrderConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出订单 Excel")
    @PreAuthorize("@ss.hasPermission('plug:order:export')")
    @OperateLog(type = EXPORT)
    public void exportOrderExcel(@Valid PlugOrderExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlugOrderDO> list = orderService.getOrderList(exportReqVO);
        // 导出 Excel
        List<PlugOrderExcelVO> datas = PlugOrderConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "订单.xls", "数据", PlugOrderExcelVO.class, datas);
    }

}
