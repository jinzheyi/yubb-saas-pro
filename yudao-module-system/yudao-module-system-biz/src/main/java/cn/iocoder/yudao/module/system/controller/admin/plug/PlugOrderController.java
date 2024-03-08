package cn.iocoder.yudao.module.system.controller.admin.plug;

import static cn.iocoder.yudao.framework.common.pojo.CommonResult.success;

import cn.iocoder.yudao.framework.common.pojo.CommonResult;
import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.framework.common.util.object.BeanUtils;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderCommitReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderDetailRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderPageReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderRespVO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugOrderDO;
import cn.iocoder.yudao.module.system.service.plug.PlugOrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.annotation.Resource;
import javax.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "管理后台 - 插件订单")
@RestController
@RequestMapping("/plug/order")
@Validated
public class PlugOrderController {

    @Resource
    private PlugOrderService orderService;

    @GetMapping("/get")
    @Operation(summary = "获得插件订单")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('plug:order:query')")
    public CommonResult<PlugOrderDetailRespVO> getOrder(@RequestParam("id") Long id) {
        return success(orderService.getOrder(id));
    }

    @GetMapping("/page")
    @Operation(summary = "获得插件订单分页")
    @PreAuthorize("@ss.hasPermission('plug:order:list')")
    public CommonResult<PageResult<PlugOrderRespVO>> getOrderPage(@Valid PlugOrderPageReqVO pageVO) {
        PageResult<PlugOrderDO> pageResult = orderService.getOrderPage(pageVO);
        return success(BeanUtils.toBean(pageResult, PlugOrderRespVO.class));
    }

    @PutMapping("/commit")
    @Operation(summary = "重提插件订单审核")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ss.hasPermission('plug:order:commit')")
    public CommonResult<Boolean> commitOrder(@Valid @RequestBody PlugOrderCommitReqVO reqVO) {
        return success(orderService.commitOrder(reqVO));
    }

}
