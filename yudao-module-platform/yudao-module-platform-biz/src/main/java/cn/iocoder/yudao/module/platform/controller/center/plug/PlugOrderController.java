package cn.iocoder.yudao.module.platform.controller.center.plug;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.excel.core.util.ExcelUtils;
import cn.iocoder.yudao.framework.operatelog.core.annotations.OperateLog;
import cn.iocoder.yudao.module.platform.controller.center.plug.vo.order.*;
import cn.iocoder.yudao.module.platform.convert.plug.PlugOrderConvert;
import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderDO;
import cn.iocoder.yudao.module.platform.service.plug.PlugOrderService;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiImplicitParam;
import io.swagger.annotations.ApiOperation;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.io.IOException;
import java.util.List;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;
import static cn.iocoder.yudao.framework.operatelog.core.enums.OperateTypeEnum.EXPORT;

@Api(tags = "管理后台 - 订单")
@RestController
@RequestMapping("/center/plug-order")
@Validated
public class PlugOrderController {

    @Resource
    private PlugOrderService orderService;

    @PutMapping("/update")
    @ApiOperation("更新订单")
    @PreAuthorize("@cs.hasPermission('center:plug-order:update')")
    public CommonResult<Boolean> updateOrder(@Valid @RequestBody PlugOrderUpdateReqVO updateReqVO) {
        orderService.updateOrder(updateReqVO);
        return success(true);
    }

    @DeleteMapping("/delete")
    @ApiOperation("删除订单")
    @ApiImplicitParam(name = "id", value = "编号", required = true, dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:plug-order:delete')")
    public CommonResult<Boolean> deleteOrder(@RequestParam("id") Long id) {
        orderService.deleteOrder(id);
        return success(true);
    }

    @GetMapping("/get")
    @ApiOperation("获得订单")
    @ApiImplicitParam(name = "id", value = "编号", required = true, example = "1024", dataTypeClass = Long.class)
    @PreAuthorize("@cs.hasPermission('center:plug-order:query')")
    public CommonResult<PlugOrderRespVO> getOrder(@RequestParam("id") Long id) {
        PlugOrderDO order = orderService.getOrder(id);
        return success(PlugOrderConvert.INSTANCE.convert(order));
    }

    @GetMapping("/page")
    @ApiOperation("获得订单分页")
    @PreAuthorize("@cs.hasPermission('center:plug-order:list')")
    public CommonResult<PageResult<PlugOrderRespVO>> getOrderPage(@Valid PlugOrderPageReqVO pageVO) {
        PageResult<PlugOrderDO> pageResult = orderService.getOrderPage(pageVO);
        return success(PlugOrderConvert.INSTANCE.convertPage(pageResult));
    }

    @GetMapping("/export-excel")
    @ApiOperation("导出订单 Excel")
    @PreAuthorize("@cs.hasPermission('center:plug-order:export')")
    @OperateLog(type = EXPORT)
    public void exportOrderExcel(@Valid PlugOrderExportReqVO exportReqVO,
              HttpServletResponse response) throws IOException {
        List<PlugOrderDO> list = orderService.getOrderList(exportReqVO);
        // 导出 Excel
        List<PlugOrderExcelVO> datas = PlugOrderConvert.INSTANCE.convertList02(list);
        ExcelUtils.write(response, "订单.xls", "数据", PlugOrderExcelVO.class, datas);
    }

}
