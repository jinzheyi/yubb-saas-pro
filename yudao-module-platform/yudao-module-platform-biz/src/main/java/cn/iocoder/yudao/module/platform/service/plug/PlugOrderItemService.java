package cn.iocoder.yudao.module.platform.service.plug;

import cn.iocoder.yudao.module.platform.dal.dataobject.plug.PlugOrderItemDO;

import java.util.List;

/**
 * 订单项 Service 接口
 *
 * @author 朱述勇
 */
public interface PlugOrderItemService {

    /**
     * 根据订单ID查询订单项集合
     * @return 订单项集合
     */
    List<PlugOrderItemDO> getByOrderId(Long orderId);

}
