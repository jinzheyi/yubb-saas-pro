package cn.iocoder.yudao.module.system.api.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.api.plug.dto.order.AuditPlugOrderReqDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.PlugOrderDetailRespDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.PlugOrderRespDTO;

import javax.validation.Valid;

/**
 * @author 朱述勇
 * @copyright: 版权所有 开源组织 gitee(https://gitee.com/jinzheyi)作者：朱述勇<br/>
 * GitHub(https://github.com/jinzheyi)作者：朱述勇 。
 * @since 2023/4/15 15:12
 */
//TODO 这是给运营端用的接口，实际调用中需要验证下租户id的问题
public interface PlugOrderApi {

    /**
     * 根据订单id查询订单详情
     * @param id 订单id
     * @return 详情
     */
    PlugOrderDetailRespDTO getPlugOrder(Long id);

    /**
     * 分页查询订单列表
     * @param reqDTO 入参
     * @return 订单数据
     */
    PageResult<PlugOrderRespDTO> getPlugOrderList(PlugOrderPageReqDTO reqDTO);

    /**
     * 审批订单
     * @param reqDTO 入参
     * @return
     */
    boolean auditOrder(@Valid AuditPlugOrderReqDTO reqDTO);

}
