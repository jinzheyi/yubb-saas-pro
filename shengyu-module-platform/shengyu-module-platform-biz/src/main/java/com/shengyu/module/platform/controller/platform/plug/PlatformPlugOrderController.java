package com.shengyu.module.platform.controller.platform.plug;

import static com.shengyu.framework.common.pojo.CommonResult.success;

import com.shengyu.framework.common.pojo.CommonResult;
import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.platform.controller.platform.plug.vo.order.AuditPlugOrderReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.order.PlugOrderDetailRespVO;
import com.shengyu.module.platform.controller.platform.plug.vo.order.PlugOrderPageReqVO;
import com.shengyu.module.platform.controller.platform.plug.vo.order.PlugOrderRespVO;
import com.shengyu.module.platform.convert.plug.PlatformPlugOrderConvert;
import com.shengyu.module.system.api.plug.PlugOrderApi;
import com.shengyu.module.system.api.plug.dto.order.AuditPlugOrderReqDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderDetailRespDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderRespDTO;
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

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/5/4 22:16
 */
@Tag(name = "管理后台 - 租户插件订单")
@RestController
@RequestMapping("/plug/plug-order")
@Validated
public class PlatformPlugOrderController {

    @Resource
    private PlugOrderApi plugOrderApi;

    @GetMapping("/get")
    @Operation(summary = "获得插件订单")
    @Parameter(name = "id", description = "编号", required = true, example = "1024")
    @PreAuthorize("@ps.hasPermission('plug:plug-order:query')")
    public CommonResult<PlugOrderDetailRespVO> getPlugOrder(@RequestParam("id") Long id) {
        PlugOrderDetailRespDTO plugOrder = plugOrderApi.getPlugOrder(id);
        return success(PlatformPlugOrderConvert.INSTANCE.convert(plugOrder));
    }

    @GetMapping("/page")
    @Operation(summary = "获得插件订单分页")
    @PreAuthorize("@ps.hasPermission('plug:plug-order:query')")
    public CommonResult<PageResult<PlugOrderRespVO>> getOrderPage(@Valid PlugOrderPageReqVO pageReqVO) {
        PageResult<PlugOrderRespDTO> pageResult = plugOrderApi.getPlugOrderList(BeanUtils.toBean(pageReqVO,
          PlugOrderPageReqDTO.class));
        return success(BeanUtils.toBean(pageResult, PlugOrderRespVO.class));
    }

    @PutMapping("/audit-order")
    @Operation(summary = "审批租户插件订单")
    @PreAuthorize("@ps.hasPermission('plug:plug-order:audit')")
    public CommonResult<Boolean> auditOrder(@Valid @RequestBody AuditPlugOrderReqVO reqVO) {
        return success(plugOrderApi.auditOrder(BeanUtils.toBean(reqVO, AuditPlugOrderReqDTO.class)));
    }

}
