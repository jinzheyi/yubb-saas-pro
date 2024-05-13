package com.shengyu.module.system.api.plug;

import com.shengyu.framework.common.pojo.PageResult;
import com.shengyu.framework.common.util.object.BeanUtils;
import com.shengyu.module.system.api.plug.dto.order.AuditPlugOrderReqDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderDetailRespDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import com.shengyu.module.system.api.plug.dto.order.PlugOrderRespDTO;
import com.shengyu.module.system.convert.plug.PlugOrderConvert;
import com.shengyu.module.system.service.plug.PlugOrderService;
import org.springframework.stereotype.Service;

import javax.annotation.Resource;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 15:13
 */
@Service
public class PlugOrderApiImpl implements PlugOrderApi {

    @Resource
    private PlugOrderService orderService;


    @Override
    public PlugOrderDetailRespDTO getPlugOrder(Long id) {
        return PlugOrderConvert.INSTANCE.convertDTO(orderService.getOrder(id));
    }

    @Override
    public PageResult<PlugOrderRespDTO> getPlugOrderList(PlugOrderPageReqDTO reqDTO) {
        return BeanUtils.toBean(orderService.getOrderPage(reqDTO), PlugOrderRespDTO.class);
    }

    @Override
    public boolean auditOrder(AuditPlugOrderReqDTO reqDTO) {
        return orderService.auditOrder(reqDTO);
    }

}
