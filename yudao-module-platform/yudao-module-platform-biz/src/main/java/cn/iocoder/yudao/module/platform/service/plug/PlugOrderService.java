package cn.iocoder.yudao.module.platform.service.plug;

import java.util.*;
import javax.validation.*;
import cn.iocoder.yudao.module.plug.controller.admin.order.vo.*;
import cn.iocoder.yudao.module.plug.dal.dataobject.order.PlugOrderDO;
import cn.iocoder.yudao.framework.common.pojo.PageResult;

/**
 * 订单 Service 接口
 *
 * @author 朱述勇
 */
public interface PlugOrderService {

    /**
     * 创建订单
     *
     * @param createReqVO 创建信息
     * @return 编号
     */
    Long createOrder(@Valid PlugOrderCreateReqVO createReqVO);

    /**
     * 更新订单
     *
     * @param updateReqVO 更新信息
     */
    void updateOrder(@Valid PlugOrderUpdateReqVO updateReqVO);

    /**
     * 删除订单
     *
     * @param id 编号
     */
    void deleteOrder(Long id);

    /**
     * 获得订单
     *
     * @param id 编号
     * @return 订单
     */
    PlugOrderDO getOrder(Long id);

    /**
     * 获得订单列表
     *
     * @param ids 编号
     * @return 订单列表
     */
    List<PlugOrderDO> getOrderList(Collection<Long> ids);

    /**
     * 获得订单分页
     *
     * @param pageReqVO 分页查询
     * @return 订单分页
     */
    PageResult<PlugOrderDO> getOrderPage(PlugOrderPageReqVO pageReqVO);

    /**
     * 获得订单列表, 用于 Excel 导出
     *
     * @param exportReqVO 查询条件
     * @return 订单列表
     */
    List<PlugOrderDO> getOrderList(PlugOrderExportReqVO exportReqVO);

}
