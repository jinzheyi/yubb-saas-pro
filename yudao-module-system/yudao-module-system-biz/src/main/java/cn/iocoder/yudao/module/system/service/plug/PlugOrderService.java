package cn.iocoder.yudao.module.system.service.plug;

import cn.iocoder.yudao.framework.common.pojo.PageResult;
import cn.iocoder.yudao.module.system.api.plug.dto.order.AuditPlugOrderReqDTO;
import cn.iocoder.yudao.module.system.api.plug.dto.order.PlugOrderPageReqDTO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderCommitReqVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderDetailRespVO;
import cn.iocoder.yudao.module.system.controller.admin.plug.vo.order.PlugOrderPageReqVO;
import cn.iocoder.yudao.module.system.dal.dataobject.plug.PlugOrderDO;
import com.baomidou.mybatisplus.extension.service.IService;

import javax.validation.Valid;

/**
 * 插件订单 Service 接口
 *
 * @author zhusy
 */
public interface PlugOrderService extends IService<PlugOrderDO> {

    /**
     * 获得插件订单
     *
     * @param id 编号
     * @return 插件订单
     */
    PlugOrderDetailRespVO getOrder(Long id);

    /**
     * 获得插件订单分页
     *
     * @param pageReqVO 分页查询
     * @return 插件订单分页
     */
    PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqVO pageReqVO);

    /**
     * 运营端获取插件订单分页
     * @param reqDTO 入参
     * @return 插件订单分页
     */
    PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqDTO reqDTO);

    /**
     * 运营端审批
     * @param reqDTO 入参
     * @return
     */
    boolean auditOrder(@Valid AuditPlugOrderReqDTO reqDTO);

    /**
     * 重提插件订单审核
     * @param id 插件订单id
     * @return 结果
     */
    boolean commitOrder(@Valid PlugOrderCommitReqVO reqVO);

}
